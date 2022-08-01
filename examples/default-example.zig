const spng = @import("spng");
const std = @import("std");

const file = @embedFile(thisDir() ++ "/../assets/zig.png");

pub fn main() !void
{
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = general_purpose_allocator.allocator();

    var ctx = spng.c.spng_ctx_new(0);
    _ = spng.c.spng_set_png_buffer(ctx, file, file.*.len);

    var size: usize = 0;
    _ = spng.c.spng_decoded_image_size(ctx, spng.c.SPNG_FMT_RGBA8, &size);
    std.log.info("Image size: {}", .{size});

    var buffer = try gpa.alloc(u8, size);
    defer gpa.free(buffer);

    std.mem.set(u8, buffer, 0);

    _ = spng.c.spng_decode_image(ctx, buffer.ptr, buffer.len, spng.c.SPNG_FMT_RGB8, 0);

    std.log.info("Image first bytes: {s}", .{buffer[0..8]});
}

fn thisDir() []const u8 
{
    return std.fs.path.dirname(@src().file) orelse ".";
}