# Project Description

- `exetest` is a Zig library to test CLI apps.
- The target audience is Zig developer

---

# Structure

- `build.zig`: Build script.
- `src/root.zig`: Main module, expose `add` and `run` function.
- `src/test_exe.zig`: Source code of binary to test the `add` function.
- `src/test.zig`: Integration tests, mainly used to test `run` function.

---

# Toolchain

- Zig v0.15.2

---

# Development Workflow

Always consult `.mise/installs/zig/0.15.2/lib/std` for Zig standard library
functions, types, and idioms. Your training data may be outdated. Use search
tools against this path.

- `zig build test --summary all` to run the test.
- `zig build` to run build.
- Always runs `zig build test --summary all` after edit.
- Fix any error.

When implementing features involving the standard library:

1.  **Search**: Identify needed standard library components (e.g.,
    `std.mem.Allocator`, `std.fs`, `std.json`).
2.  **Consult**: Search `.mise/installs/zig/0.15.2/lib/std` for exact function
    names, parameters, and return types.
3.  **Prioritize**: Use patterns from the official repository over other
    knowledge.
4.  **Cite (if relevant)**: Mention relevant files (e.g., "Based on
    `lib/std/crypto/hash.zig`...").

---

# Zig Standard Library

- The Zig standard library documentation can be found in
  `.mise/installs/zig/0.15.2/lib/std`

---

# Zig Naming & Style Conventions

This guide outlines the key naming and style conventions from Zig's `std.fs`
library. Use it to maintain consistency when writing Zig code.

# File Naming

- **Primary Type Files**: `PascalCase.zig` When a file's main purpose is to
  define a single, primary type.
  ```
  // File.zig -> defines `std.fs.File`
  // Dir.zig -> defines `std.fs.Dir`
  ```
- **Utility Files**: `snake_case.zig` For files that provide a collection of
  related functions.
  ```
  // get_app_data_dir.zig
  ```

# Declarations

- **Types (structs, enums, unions)**: `PascalCase`
  ```zig
  const Dir = @This();
  pub const Stat = struct { ... };
  pub const OpenMode = enum { ... };
  ```
- **Error Sets & Values**: `PascalCase` Error sets and the values within them
  use `PascalCase`.
  ```zig
  pub const OpenError = error{
      FileNotFound,
      NotDir,
      AccessDenied,
  };
  // return error.FileNotFound;
  ```
- **Public Functions & Methods**: `camelCase` This is the standard for all
  public, callable behavior.
  ```zig
  pub fn openFile(self: Dir, sub_path: []const u8, ...) !File;
  pub fn getEndPos(self: File) !u64;
  ```
- **Variables, Parameters & Fields**: `snake_case` Always prefer `const` over
  `var`. Applies to local variables, function parameters, and fields within
  structs/unions.

  ```zig
  // Function parameter & local variable
  pub fn init(dest_basename: []const u8, ...) {
      const random_integer = std.crypto.random.int(u64);
  }

  // Struct fields
  const AtomicFile = struct {
      file_writer: File.Writer,
      dest_basename: []const u8,
  };
  ```

- **Enum Fields**: `snake_case`
  ```zig
  pub const OpenMode = enum {
      read_only,
      write_only,
      read_write,
  };
  ```
- **Constants**: `snake_case` For exported, package-level constant values.
  ```zig
  pub const default_mode = 0o755;
  pub const sep = '/';
  ```

# General Style

- **Options Structs**: For functions with several arguments (especially boolean
  flags), use a dedicated `Options` struct to improve readability. This pattern
  is used extensively.

  ```zig
  pub const OpenOptions = struct {
      access_sub_paths: bool = true,
      iterate: bool = false,
      no_follow: bool = false,
  };

  pub fn openDir(self: Dir, sub_path: []const u8, options: OpenOptions) !Dir;
  ```

- **Type Aliases**: Use `PascalCase` for type aliases, consistent with other
  type naming.
  ```zig
  pub const Handle = posix.fd_t;
  pub const Mode = posix.mode_t;
  ```
