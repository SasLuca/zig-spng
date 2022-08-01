const std = @import("std");
const zlib = @import("thirdparty/zig-zlib/zlib.zig");

const path_to_zig_main = thisDir() ++ "/source/spng.zig";
const path_to_c_main = thisDir() ++ "/thirdparty/libspng/spng/spng.c";
const path_to_c_include = thisDir() ++ "/thirdparty/libspng/spng";

pub const Options = struct 
{
    enable_arch_specific_optimizations: bool = true,
    use_bundled_zlib: bool = true,
    zlib_import_string: ?[]const u8 = "zlib",
};

pub fn link(b: *std.build.Builder, step: *std.build.LibExeObjStep, options: Options) void
{
    const target = (std.zig.system.NativeTargetInfo.detect(b.allocator, step.target) catch unreachable).target;
    const lib = buildLibrary(b, step, options);
    
    step.linkLibrary(lib);
    step.addIncludePath(path_to_c_include);
    switch (target.os.tag)
    {
        .windows => {
            step.linkSystemLibraryName("user32");
        },

        else => {
            unreachable;
        }
    }
}

fn buildLibrary(b: *std.build.Builder, step: *std.build.LibExeObjStep, options: Options) *std.build.LibExeObjStep 
{
    const arch_specific_opts_flag = if (options.enable_arch_specific_optimizations) "-DSPNG_DISABLE_OPT=1" else "-DSPNG_DISABLE_OPT=0";
    const lib = b.addStaticLibrary("spng", path_to_zig_main);
    lib.setBuildMode(step.build_mode);
    lib.setTarget(step.target);
    lib.addIncludePath(path_to_c_include);
    lib.addCSourceFiles(&.{ path_to_c_main }, &.{ "-I" ++ path_to_c_include, arch_specific_opts_flag });
    if (options.use_bundled_zlib) 
    {
        const z = zlib.create(b, step.target, step.build_mode);
        z.link(lib, .{ .import_name = options.zlib_import_string });
        z.link(step, .{ .import_name = options.zlib_import_string });
    }
    lib.linkLibC();
    lib.install();
    return lib;
}

pub fn build(b: *std.build.Builder) void 
{
    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();
    
    const exe = b.addExecutable("spng-default-example", "examples/default-example.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.addPackage(getPackage("spng"));
    link(b, exe, .{});
    exe.install();
}

pub fn getPackage(name: []const u8) std.build.Pkg
{
    return std.build.Pkg
    {
        .name = name,
        .source = .{ .path = thisDir() ++ "/source/spng.zig" },
        .dependencies = null, // null by default, but can be set to a slice of `std.build.Pkg`s that your package depends on.
    };
}

fn thisDir() []const u8 
{
    return std.fs.path.dirname(@src().file) orelse ".";
}