const exetest = @import("exetest");

test "basic" {
    _ = exetest.command("hello");
}
