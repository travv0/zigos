const std = @import("std");
const Builder = std.build.Builder;
const fs = std.fs;

pub fn build(b: *Builder) !void {
    const target = .{
        .cpu_arch = .i386,
        .os_tag = .freestanding,
    };

    const mode = b.standardReleaseOptions();

    const bin_name = "zigos";

    const fmtPaths = [_][]const u8{ "build.zig", "kernel" };
    const fmt = b.addFmt(&fmtPaths);

    const fmt_step = b.step("fmt", "Format source files");
    fmt_step.dependOn(&fmt.step);

    const exe = b.addExecutable(bin_name, "kernel/main.zig");
    exe.setLinkerScriptPath("linker.ld");
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.install();

    const run_cmd = b.addSystemCommand(&[_][]const u8{
        "qemu-system-i386",
        "-kernel",
        try fs.path.join(b.allocator, &[_][]const u8{ b.exe_dir, bin_name }),
    });
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the kernel in qemu");
    run_step.dependOn(&run_cmd.step);
}
