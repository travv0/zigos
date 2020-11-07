const std = @import("std");
const Vga = @import("Vga.zig");

const Tty = @This();

const width = 80;
const height = 25;

row: usize,
col: usize,
color: u8,
buffer: [*]volatile u16,

pub fn init() Tty {
    var tty = Tty{
        .row = 0,
        .col = 0,
        .color = Vga.code(Vga.Color.light_brown, Vga.Color.black),
        .buffer = @intToPtr([*]volatile u16, 0xB8000),
    };
    tty.clear();
    return tty;
}

inline fn index(x: usize, y: usize) usize {
    return y * width + x;
}

fn putAt(self: *Tty, c: u8, color: u8, x: usize, y: usize) void {
    self.buffer[Tty.index(x, y)] = Vga.entry(c, color);
}

pub fn putChar(self: *Tty, c: u8) void {
    switch (c) {
        '\n' => {
            self.moveDown();
            self.col = 0;
        },
        else => {
            self.putAt(c, self.color, self.col, self.row);
            self.col += 1;
        },
    }
    if (self.col == width) {
        self.col = 0;
        self.moveDown();
    }
}

fn moveDown(self: *Tty) void {
    if (self.row == height - 1) {
        self.scrollDown();
    } else self.row += 1;
}

fn scrollDown(self: *Tty) void {
    var y: usize = 0;
    while (y < height - 1) : (y += 1) {
        var x: usize = 0;
        while (x < width) : (x += 1) {
            self.buffer[Tty.index(x, y)] = self.buffer[Tty.index(x, y + 1)];
        }
    }
    var x: usize = 0;
    while (x < width) : (x += 1) {
        self.buffer[Tty.index(x, height - 1)] = Vga.entry(' ', self.color);
    }
}

pub fn clear(self: *Tty) void {
    var y: usize = 0;
    while (y < height) : (y += 1) {
        var x: usize = 0;
        while (x < width) : (x += 1) {
            self.buffer[Tty.index(x, y)] = Vga.entry(' ', self.color);
        }
    }
}

pub fn write(self: *Tty, data: []const u8) void {
    for (data) |c| {
        self.putChar(c);
    }
}
