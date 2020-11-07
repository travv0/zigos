const std = @import("std");

const Tty = @This();

const VgaColor = enum(u4) {
    black = 0x0,
    blue = 0x1,
    green = 0x2,
    cyan = 0x3,
    red = 0x4,
    magenta = 0x5,
    brown = 0x6,
    light_gray = 0x7,
    dark_gray = 0x8,
    light_blue = 0x9,
    light_green = 0xA,
    light_cyan = 0xB,
    light_red = 0xC,
    light_magenta = 0xD,
    light_brown = 0xE,
    white = 0xF,

    inline fn code(fg: VgaColor, bg: VgaColor) u8 {
        return @as(u8, @enumToInt(fg)) | @as(u8, @enumToInt(bg)) << 4;
    }
};

inline fn char(c: u8, color_code: u8) u16 {
    return @as(u16, c) | @as(u16, color_code) << 8;
}

const width = 80;
const height = 25;

row: usize,
col: usize,
color: u8,
buffer: [*]volatile u16,

pub fn init() Tty {
    const color = VgaColor.code(VgaColor.light_brown, VgaColor.black);
    var buffer = @intToPtr([*]volatile u16, 0xB8000);
    var y: usize = 0;
    while (y < height) : (y += 1) {
        var x: usize = 0;
        while (x < width) : (x += 1) {
            buffer[Tty.index(x, y)] = char(' ', color);
        }
    }
    return .{
        .row = 0,
        .col = 0,
        .color = color,
        .buffer = buffer,
    };
}

inline fn index(x: usize, y: usize) usize {
    return y * width + x;
}

fn putAt(self: *Tty, c: u8, color: u8, x: usize, y: usize) void {
    self.buffer[Tty.index(x, y)] = char(c, color);
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
        self.buffer[Tty.index(x, height - 1)] = char(' ', self.color);
    }
}

pub fn write(self: *Tty, data: []const u8) void {
    for (data) |c| {
        self.putChar(c);
    }
}
