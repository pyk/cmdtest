const std = @import("std");
const Build = std.Build;
const testing = std.testing;

const Options = struct {
    name: []const u8,
    exe_file: Build.LazyPath,
    test_file: Build.LazyPath,
};

pub fn add(b: *Build, options: Options) *Build.Step.Run {
    // Create target executable
    const exe = b.addExecutable(.{
        .name = options.name,
        .root_module = b.createModule(.{
            .root_source_file = options.exe_file,
            .target = b.graph.host,
        }),
    });

    const dest_sub_path = std.fs.path.join(
        b.allocator,
        &.{ "exetest", exe.name },
    ) catch @panic("OOM");
    const install_exe = b.addInstallArtifact(exe, .{
        .dest_sub_path = dest_sub_path,
    });

    // Create runtime module
    const dir = b.path(@src().file).dirname();
    const runtime_path = dir.join(b.allocator, "Command.zig") catch @panic("OOM");
    const runtime_mod = b.createModule(.{
        .root_source_file = runtime_path,
        .target = b.graph.host,
    });

    // Create the test module that imports the runtime module
    const test_mod = b.createModule(.{
        .root_source_file = options.test_file,
        .target = b.graph.host,
        .imports = &.{
            .{
                .name = "exetest",
                .module = runtime_mod,
            },
        },
    });

    // Create the test executable compilation step
    const test_exe = b.addTest(.{
        .name = options.name,
        .root_module = test_mod,
    });
    const run_test_exe = b.addRunArtifact(test_exe);

    run_test_exe.step.dependOn(&install_exe.step);

    const runtime_mod_options = b.addOptions();
    const exe_path = b.getInstallPath(install_exe.dest_dir.?, install_exe.dest_sub_path);
    const exe_dir = std.fs.path.dirname(exe_path) orelse exe_path;

    // Provide the installation directory only. the runtime can append the
    // executable name to construct the full path.
    runtime_mod_options.addOption([]const u8, "exe_dir", exe_dir);
    runtime_mod.addOptions("exetest_gen", runtime_mod_options);

    return run_test_exe;
}
