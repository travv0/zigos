const std = @import("std");
const Tty = @import("Tty.zig");

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

fn kmain() void {
    var tty = Tty.init();
    tty.write("Hello world!");
}
