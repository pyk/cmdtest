const std = @import("std");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var it = try std.process.argsWithAllocator(allocator);
    defer it.deinit();

    var args_list = std.array_list.Managed([]const u8).init(allocator);
    defer args_list.deinit();
    while (it.next()) |arg| {
        try args_list.append(arg);
    }
    const args = args_list.items;

    // detect --stderr and collect positional args (excluding program name)
    var pos_list = std.array_list.Managed([]const u8).init(allocator);
    defer pos_list.deinit();
    var use_stderr = false;
    var i: usize = 1;
    while (i < args.len) : (i += 1) {
        const s = args[i];
        if (std.mem.eql(u8, s, "--stderr")) {
            use_stderr = true;
            continue;
        }
        try pos_list.append(s);
    }
    const pos = pos_list.items;

    // single writer buffer used for whichever stream we pick
    var buf: [1024]u8 = undefined;
    var writer = if (use_stderr) std.fs.File.stderr().writer(&buf) else std.fs.File.stdout().writer(&buf);
    const io = &writer.interface;

    if (pos.len == 0) {
        try io.writeAll("OK\n");
    } else {
        var j: usize = 0;
        while (j < pos.len) : (j += 1) {
            try io.writeAll(pos[j]);
            try io.writeAll("\n");
        }
    }

    try io.flush();
}
