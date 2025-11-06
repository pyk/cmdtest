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

    if (args.len <= 1) {
        var buffer: [64]u8 = undefined;
        var stdout_writer = std.fs.File.stdout().writer(&buffer);
        const stdout = &stdout_writer.interface;
        try stdout.writeAll("OK\n");
        try stdout.flush();
        return;
    }

    // Simple, order-insensitive handling of a few flags.
    // We inspect the args slice directly.
    // Supported flags:
    // --print-argv
    // --print-argv-stderr
    // --echo-stdin
    // --exit <code>
    // --spam <total> <chunk>

    var i: usize = 1;
    var exit_code: u8 = 0;
    // obtain stdout/stderr writers with stack buffers (matches stdlib usage)
    var stdout_stack: [1024]u8 = undefined;
    var stderr_stack: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_stack);
    var stderr_writer = std.fs.File.stderr().writer(&stderr_stack);
    const stdout = &stdout_writer.interface;
    const stderr = &stderr_writer.interface;

    while (i < args.len) : (i += 1) {
        const s = args[i];
        if (std.mem.eql(u8, s, "--print-argv")) {
            var j: usize = i + 1;
            while (j < args.len) : (j += 1) {
                const a = args[j];
                try stdout.writeAll(a);
                try stdout.writeAll("\n");
            }
            break;
        } else if (std.mem.eql(u8, s, "--print-argv-stderr")) {
            var j: usize = i + 1;
            while (j < args.len) : (j += 1) {
                const a = args[j];
                try stderr.writeAll("ERR: ");
                try stderr.writeAll(a);
                try stderr.writeAll("\n");
            }
            break;
        } else if (std.mem.eql(u8, s, "--echo-arg")) {
            // echo provided argument (avoid stdin API differences across std versions)
            if (i + 1 >= args.len) {
                try stderr.writeAll("missing echo argument\n");
                std.process.exit(2);
            }
            const data = args[i + 1];
            try stdout.writeAll(data);
            break;
        } else if (std.mem.eql(u8, s, "--exit")) {
            if (i + 1 >= args.len) {
                try stderr.writeAll("missing exit code\n");
                std.process.exit(2);
            }
            const parsed = std.fmt.parseInt(u8, args[i + 1], 10) catch {
                try stderr.writeAll("invalid exit code\n");
                std.process.exit(2);
            };
            exit_code = parsed;
            break;
        } else if (std.mem.eql(u8, s, "--spam")) {
            if (i + 2 >= args.len) {
                try stderr.writeAll("spam missing args\n");
                std.process.exit(2);
            }
            const total = std.fmt.parseInt(usize, args[i + 1], 10) catch {
                std.process.exit(2);
            };
            const chunk = std.fmt.parseInt(usize, args[i + 2], 10) catch {
                std.process.exit(2);
            };
            var remaining = total;
            var out_buf = try allocator.alloc(u8, chunk);
            defer allocator.free(out_buf);
            // fill buffer with 'A' (avoid std.mem.set API differences)
            for (out_buf) |*b| b.* = 'A';
            while (remaining > 0) {
                const to_write = if (remaining < chunk) remaining else chunk;
                try stdout.writeAll(out_buf[0..to_write]);
                remaining -= to_write;
            }
            break;
        } else {
            try stderr.writeAll("unknown flag: ");
            try stderr.writeAll(s);
            try stderr.writeAll("\n");
            std.process.exit(2);
        }
    }

    // flush writers to ensure output is written
    try stdout.flush();
    try stderr.flush();
    std.process.exit(exit_code);
}
