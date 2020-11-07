const std = @import("std");
const Tty = @import("Tty.zig");
const serial = @import("serial.zig");
const SerialPort = serial.SerialPort;
pub const os = @import("os.zig");

const ALIGN = 1 << 0;
const MEMINFO = 1 << 1;
const MAGIC = 0x1BADB002;
const FLAGS = ALIGN | MEMINFO;

const MultiBoot = packed struct {
    magic: c_long,
    flags: c_long,
    checksum: c_long,
};

export const multiboot align(4) linksection(".multiboot") = MultiBoot{
    .magic = MAGIC,
    .flags = FLAGS,
    .checksum = -(MAGIC + FLAGS),
};

var stack: [16 * 1024]u8 align(16) linksection(".bss") = undefined;
var stack_top: usize = undefined;

export fn _start() callconv(.Naked) noreturn {
    stack_top = @ptrToInt(&stack) + stack.len;

    asm volatile (""
        :
        : [stack_top] "{esp}" (stack_top)
    );

    kmain();

    while (true) {}
}

var tty: Tty = undefined;
fn kmain() void {
    tty = Tty.init();
    var port = SerialPort.init(0x3F8);
    port.write("Hello world!\n");
    std.log.notice("Hello world!", .{});
}

pub fn log(
    comptime message_level: std.log.Level,
    comptime scope: @Type(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    const level_txt = switch (message_level) {
        .emerg => "emergency",
        .alert => "alert",
        .crit => "critical",
        .err => "error",
        .warn => "warning",
        .notice => "notice",
        .info => "info",
        .debug => "debug",
    };
    const prefix2 = if (scope == .default) ": " else "(" ++ @tagName(scope) ++ "): ";
    const stderr = tty.writer();
    nosuspend stderr.print(level_txt ++ prefix2 ++ format ++ "\n", args) catch return;
}

pub fn panic(msg: []const u8, error_return_trace: ?*std.builtin.StackTrace) noreturn {
    @setCold(true);
    const writer = tty.writer();
    try writer.writeAll("KERNEL PANIC: ");
    try writer.writeAll(msg);
    try writer.writeAll(" :(");
    while (true) {}
}
