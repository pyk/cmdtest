const std = @import("std");
const testing = std.testing;
const exetest = @import("exetest");

test "run: string" {
    exetest.run("exetest");
    // exetest.run([_][]const u8{"exetest"});
    // exetest.run(.{ .argv = [_][]const u8{"exetest"}, .stdin = "data" });
}

// test "args: null" {
//     var result = exetest.run("exetest", .{});
//     defer result.deinit();
//     testing.expectEqualStrings(result.stdout,
//         \\ test
//     );
// }

// test "args: empty string" {
//     var result = exetest.run("exetest", .{
//         .args = "--greet",
//     });
//     defer result.deinit();
// }
