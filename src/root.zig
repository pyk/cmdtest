const std = @import("std");
const Build = std.Build;
const testing = std.testing;

/// Options for `add` used by user's `build.zig`.
const Options = struct {
    /// name of the test target
    name: []const u8,
    /// path to the test source file
    test_file: Build.LazyPath,
    /// the `exetest` build module to import into the test.
    exetest_mod: *Build.Module,
};

/// Register an integration test runnable with the build.
///
/// This creates a test module that imports the `exetest` runtime and
/// produces a `run` step that executes the compiled test binary. It also
/// ensures all build-installed executables are available via `PATH`.
pub fn add(b: *Build, options: Options) *Build.Step.Run {
    // Create the test module that imports the runtime module
    const test_mod = b.createModule(.{
        .root_source_file = options.test_file,
        .target = b.graph.host,
        .imports = &.{
            .{
                .name = "exetest",
                .module = options.exetest_mod,
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

/// Options for `run` controlling I/O, allocator and output limits.
pub const RunOptions = struct {
    allocator: std.mem.Allocator = testing.allocator,
    // Accept a single argument string to be forwarded as one argv element.
    // Null means no extra args.
    args: ?[]const u8 = null,
    stdin: ?[]const u8 = null,
    max_output_bytes: usize = 50 * 1024,
};

/// Result returned by `run` with exit info and captured output.
pub const RunResult = struct {
    /// Exit code (0 on success, otherwise process-specific value).
    code: u8,
    /// Termination reason returned by `std.process.Child.wait()`.
    term: std.process.Child.Term,
    /// Captured stdout bytes.
    stdout: std.ArrayList(u8),
    /// Captured stderr bytes.
    stderr: std.ArrayList(u8),
    /// Allocator used for the captured buffers.
    allocator: std.mem.Allocator,

    pub fn deinit(self: *RunResult) void {
        self.stdout.deinit(self.allocator);
        self.stderr.deinit(self.allocator);
    }
};

/// Spawn and run an executable with the given `RunOptions`.
///
/// This is a synchronous helper that spawns the child, collects stdout and
/// stderr up to `max_output_bytes`, waits for termination and returns a
/// `RunResult` with captured output and termination info.
pub fn run_old(exe_name: []const u8, options: RunOptions) RunResult {
    // Create argv
    var argv: [2][]const u8 = undefined;
    var arg_count: usize = 1;
    if (options.args) |_| arg_count += 1;
    argv[0] = exe_name;
    if (options.args) |s| argv[1] = s;

    // Create child process
    var child = std.process.Child.init(argv[0..arg_count], options.allocator);
    child.stdin_behavior = if (options.stdin) |_| .Pipe else .Ignore;
    child.stdout_behavior = .Pipe;
    child.stderr_behavior = .Pipe;

    // Set PATH
    var env_map = std.process.getEnvMap(options.allocator) catch @panic("OOM");
    defer env_map.deinit();
    const path = env_map.get("PATH") orelse "(PATH empty)";

    // Spawn the child process and provide more context on failures
    // Prepare a concise representation of args for diagnostics: if there is exactly
    // one arg, print it; if multiple, print "<multiple>"; otherwise empty.
    const args_repr: []const u8 = if (options.args) |s| s else "";

    child.spawn() catch |err| std.debug.panic(
        \\failed to spawn executable '{s}' with args '{s}': {any}
        \\PATH: {s}
        \\Hint: ensure the executable is present in PATH or the provided name is correct.
    , .{ exe_name, args_repr, err, path });

    // Ensure we attempt to kill the child if this function unwinds
    errdefer {
        _ = child.kill() catch |err| std.debug.panic(
            \\failed to kill child process for executable '{s}': {any}
            \\PATH: {s}
        , .{ exe_name, err, path });
    }

    // Prepare buffers to collect stdout and stderr
    var stdout_buffer: std.ArrayList(u8) = .empty;
    var stderr_buffer: std.ArrayList(u8) = .empty;

    child.collectOutput(options.allocator, &stdout_buffer, &stderr_buffer, options.max_output_bytes) catch |err|
        std.debug.panic(
            \\failed collecting output from executable '{s}' (args='{s}'): {any}
            \\Stdout length: {d}
            \\Stderr length: {d}
            \\PATH: {s}
            \\Hint: increase max_output_bytes if output was truncated or inspect the program for excessive output.
        , .{ exe_name, args_repr, err, stdout_buffer.items.len, stderr_buffer.items.len, path });

    // Wait for child termination and include the termination reason in the panic message.
    const term = child.wait() catch |err| std.debug.panic(
        \\failed waiting for executable '{s}' to terminate (args='{s}'): {any}
        \\PATH: {s}
        \\Hint: the process may have failed to start or the system ran out of resources
    , .{ exe_name, args_repr, err, path });

    return RunResult{
        .code = if (term == .Exited) term.Exited else 0,
        .term = term,
        .stdout = stdout_buffer,
        .stderr = stderr_buffer,
        .allocator = options.allocator,
    };
}

/// Minimal helper used when `run` is invoked with a string literal.
fn runLiteralString(cmd: []const u8) void {
    std.debug.print("{s}\n", .{cmd});
}

const RunArgKind = enum { Other, StringLiteral };

/// This function inspects its argument at compile-time and dispatches
/// to the appropriate runtime helper.
pub fn run(arg: anytype) void {
    // Gets the RunArgKind at compile time
    const kind = comptime switch (@typeInfo(@TypeOf(arg))) {
        .pointer => |p| switch (@typeInfo(p.child)) {
            .array => |a| if (a.child == u8) RunArgKind.StringLiteral else RunArgKind.Other,
            else => RunArgKind.Other,
        },
        else => RunArgKind.Other,
    };

    // Emit a clear compile-time error for unsupported value kind
    comptime if (kind == RunArgKind.Other) {
        @compileError("exetest.run: unsupported argument: expected a string, an argv array, or an options struct");
    };

    if (kind == RunArgKind.StringLiteral) {
        return runLiteralString(arg);
    }
}
