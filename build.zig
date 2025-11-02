const std = @import("std");
const fs = std.fs;
const mem = std.mem;

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});

    ////////////////////////////////////////////////////////////////
    //                       exetest module                       //
    ////////////////////////////////////////////////////////////////

    const mod = b.addModule("exetest", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
    });

    ////////////////////////////////////////////////////////////////
    //                       exetest tests                        //
    ////////////////////////////////////////////////////////////////

    const unit_tests = b.addTest(.{
        .name = "unit",
        .root_module = mod,
    });
    const run_unit_tests = b.addRunArtifact(unit_tests);

    const exetest = @import("src/root.zig");
    const run_integration_tests = exetest.add(b, .{
        .name = "integration",
        .exe_file = b.path("src/main.zig"),
        .test_file = b.path("src/integration_test.zig"),
    });

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_unit_tests.step);
    test_step.dependOn(&run_integration_tests.step);
}
