const std = @import("std");
const fs = std.fs;
const mem = std.mem;
const Build = std.Build;

pub const AddOptions = struct {
    /// Name of the test target
    name: []const u8,
    /// Path to the test source file
    test_file: Build.LazyPath,
    /// The `exetest` build module to import into the test
    exetest_mod: ?*Build.Module,
};

/// Register new test
pub fn add(b: *Build, options: AddOptions) *Build.Step.Run {
    const exetest_mod = if (options.exetest_mod) |mod|
        mod
    else
        b.dependency("exetest", .{
            .target = b.graph.host,
        }).module("exetest");

    // Create the test module that imports the runtime module
    const test_mod = b.createModule(.{
        .root_source_file = options.test_file,
        .target = b.graph.host,
        .imports = &.{
            .{
                .name = "exetest",
                .module = exetest_mod,
            },
        },
    });

    // Create the test executable compilation step
    const test_exe = b.addTest(.{
        .name = options.name,
        .root_module = test_mod,
    });
    const run_test_exe = b.addRunArtifact(test_exe);

    // IMPORTANT: Make sure all exe are installed first
    run_test_exe.step.dependOn(b.getInstallStep());

    const original_path = b.graph.env_map.get("PATH") orelse "";
    const path = b.fmt("{s}{c}{s}", .{
        b.exe_dir,
        std.fs.path.delimiter,
        original_path,
    });

    run_test_exe.setEnvironmentVariable("PATH", path);

    return run_test_exe;
}

pub fn build(b: *Build) !void {
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

    // Test executables
    const test_exe = b.addExecutable(.{
        .name = "exetest",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/test_exe.zig"),
            .target = b.graph.host,
        }),
    });
    b.installArtifact(test_exe);

    const run_integration_tests = add(b, .{
        .name = "integration",
        .test_file = b.path("src/test.zig"),
        .exetest_mod = mod,
    });

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_unit_tests.step);
    test_step.dependOn(&run_integration_tests.step);
}
