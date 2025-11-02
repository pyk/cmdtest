const std = @import("std");

pub fn Command(exe_name: []const u8) type {
    std.debug.print("DEBUG: command passed exe_name {s}\n", .{exe_name});
    const gen_mod = @import("exetest_gen");
    // gen_mod.exe_dir is provided by the build script; join with exe_name to get full path
    const full_path = std.fs.path.join(std.heap.page_allocator, &.{ gen_mod.exe_dir, exe_name }) catch exe_name;
    std.debug.print("DEBUG: gen_mod.exe_dir {s}\n", .{gen_mod.exe_dir});
    std.debug.print("DEBUG: constructed full_path {s}\n", .{full_path});
    // Note: if join failed we fall back to exe_name only.
    return struct {
        pub fn hello() void {}
    };
}
