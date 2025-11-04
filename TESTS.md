# Test cases for `exetest::run`

This file lists the planned tests for `run` in `src/root.zig`. Use this
checklist to track progress. Tests implemented in the repository are checked.

## How to run

Run the full test suite:

```bash
zig build test --summary all
```

Run only the integration tests (if applicable):

```bash
zig test --dep exetest -Mroot=src/test.zig -Mexetest=src/root.zig
```

---

## Checklist

- [x] run: empty args

  - Scenario: call `run("exetest", .{})` with no args.
  - Expected: child runs, exit code 0, no extra argv element is passed.
  - File: `src/test.zig` (implemented)

- [x] run: args forwarded

  - Scenario: call `run("exetest", .{ .args = &[_][]const u8{"--greet"} })`.
  - Expected: child receives `--greet` as argv[1] and prints it.
  - File: `src/test.zig` (implemented)

- [ ] stdin forwarded and pipe behavior

  - Scenario: provide `stdin` bytes in `RunOptions`, child should read from
    stdin.
  - Expected: child receives the data on stdin; no hang when stdin not provided.
  - Notes: implement a small echo helper in `src/test_exe.zig`.

- [ ] stdout capture

  - Scenario: child writes to stdout; `RunResult.stdout` contains the bytes.
  - Expected: correct bytes captured; verify with binary and text content.

- [ ] stderr capture

  - Scenario: child writes to stderr (e.g. via `std.debug.print`);
    `RunResult.stderr` contains the bytes.
  - Expected: correct bytes captured.

- [ ] non-zero exit code propagation

  - Scenario: child exits with code 42.
  - Expected: `RunResult.code == 42`, `term == .Exited`.

- [ ] child terminated by signal

  - Scenario: child is killed (SIGKILL) or raises a signal.
  - Expected: `term` reflects the termination reason; `code` handling is
    documented.
  - Notes: may require careful test harnessing to avoid flakiness.

- [ ] executable not found (spawn failure)

  - Scenario: run a non-existent executable.
  - Expected: spawn panics with a message containing `PATH:` and the executable
    name.

- [ ] PATH handling & `add` integration

  - Scenario: ensure `add` sets PATH to include built executables and
    integration tests can call the installed exe.
  - Expected: installed exe found via PATH in integration step.

- [ ] max_output_bytes truncation

  - Scenario: child emits more than `max_output_bytes` bytes.
  - Expected: either collectOutput fails with a helpful panic or buffers are
    truncated; test should assert behavior.

- [ ] large output within limit

  - Scenario: child emits a large but permitted amount (e.g. 40 KiB).
  - Expected: captured fully, no panic.

- [ ] allocator/OOM behavior

  - Scenario: simulate allocator failures when creating env map or buffers.
  - Expected: code panics or returns helpful errors; tests may be marked as
    expected-failure on CI.

- [ ] deinit and resource cleanup

  - Scenario: call `RunResult.deinit()` and ensure no leaks.
  - Expected: resources freed; document double-deinit behavior.

- [ ] unicode / binary output handling

  - Scenario: child prints non-UTF8 bytes (including 0x00 inside output).
  - Expected: raw bytes are preserved in stdout/stderr arrays.

- [ ] multi-arg forwarding

  - Scenario: pass multiple args via
    `RunOptions.args = &[_][]const u8{"a","b","c"}`.
  - Expected: all args are forwarded in order.

- [ ] concurrent runs

  - Scenario: run multiple `run()` calls concurrently in tests.
  - Expected: no cross-talk and allocator safety.

- [ ] wait() failure path
  - Scenario: simulate a failure from `child.wait()` (platform-dependent).
  - Expected: panic message includes useful diagnostics.

---

Notes

- Implemented tests:

  - `run: empty args` (checks exit code and no extra empty argv)
  - `run: args forwarded` (checks arg forwarding; asserts via `stderr` because
    `std.debug.print` writes to stderr)

- Recommended API note: `RunOptions.args` is now a slice of strings to support
  multiple argv entries.
