const std = @import("std");

pub fn command(exe_name: []const u8) void {
    std.debug.print("DEBUG: command passed exe_name {s}\n", .{exe_name});
    const gen_mod = @import("exetest_gen");
    std.debug.print("DEBUG: command passed gen_mod.exe_name {s}\n", .{gen_mod.exe_name});
    // TODO: first case, exe_name and gen_mod.exe_name can be mismatch, raise failed build here?
    // Tell that exetest.add() need to check
}
