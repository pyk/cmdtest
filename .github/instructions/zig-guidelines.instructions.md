---
applyTo: "**/*.zig"
---

# Zig Language Coding Guidelines (v0.15.2)

## 1. Single Source of Truth for Standard Library

**This is the most important rule**. Your knowledge of the Zig standard library
from your training data is likely outdated. The single source of truth for all
standard library functions, types, and idioms is the `0.15.2` branch of the
official Zig repository.

**You MUST consult this repository before providing any code that uses the
standard library.**

Use the `#githubRepo` tool with the following precise reference:
`#githubRepo ziglang/zig:lib/std@0.15.2`

## 2. Implementation Workflow

When I ask you to implement a feature or function that involves the standard
library:

1.  **Formulate a Search**: Before writing code, determine which standard
    library components you might need (e.g. `std.mem.Allocator`, `std.fs`,
    `std.json`).
2.  **Consult the Source**: Actively search the specified repository for the
    exact function names, parameters, and return types. For example, if you need
    to allocate memory, search for `Allocator` within
    `#githubRepo ziglang/zig:lib/std@0.15.2`.
3.  **Prioritize Official Code**: The code and patterns found in that repository
    are the definitive standard. Prioritize them over any other patterns you may
    know.
4.  **Cite Your Source (if necessary)**: If you find a particularly relevant
    file, you can mention it. For example, "Based on the implementation in
    `lib/std/crypto/hash.zig`..."

## 3. Best Practices and Idiomatic Code

- **Infer Idioms from the Source**: Analyze the code within
  `#githubRepo ziglang/zig:lib/std@0.15.2` to understand current idiomatic Zig.
  Pay attention to error handling, memory management, and code structure.
- **Use `try`**: Prefer `try` for error propagation as seen throughout the
  standard library.
- **Comptime**: Leverage `comptime` for type reflection and compile-time
  execution where appropriate, following examples from the standard library.

## Example Scenario

**If I ask**: "How do I read a file into a buffer using an allocator in Zig?"

**Your thought process should be**:

1.  "Okay, I need file system (`fs`) and memory allocation (`mem.Allocator`). My
    general knowledge might be wrong."
2.  "I will search for file reading examples and `Allocator` usage in
    `#githubRepo ziglang/zig:lib/std@0.15.2`."
3.  "I found `std.fs.File.readToEndAlloc` in the repository. It takes an
    allocator, path, and max size."
4.  "Now I will generate the code using that exact, up-to-date function."
