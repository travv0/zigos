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
var serial_port: SerialPort = undefined;
fn kmain() void {
    tty = Tty.init();
    serial_port = SerialPort.init(0x3F8);
    std.log.notice("hello there", .{});
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
    const tty_writer = tty.writer();
    const serial_writer = serial_port.writer();
    nosuspend tty_writer.print(level_txt ++ prefix2 ++ format ++ "\n", args) catch return;
    nosuspend serial_writer.print(level_txt ++ prefix2 ++ format ++ "\n", args) catch return;
}

pub fn panic(msg: []const u8, error_return_trace: ?*std.builtin.StackTrace) noreturn {
    @setCold(true);
    const tty_writer = tty.writer();
    const serial_writer = serial_port.writer();
    printPanicMessage(tty_writer, msg);
    printPanicMessage(serial_writer, msg);
    while (true) {}
}

fn printPanicMessage(writer: anytype, msg: []const u8) void {
    try writer.writeAll("KERNEL PANIC: ");
    try writer.writeAll(msg);
    try writer.writeAll(" :(");
}
