const std = @include("std");

const Vga = @This();

pub const Color = enum(u4) {
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
};

pub inline fn code(fg: Vga.Color, bg: Vga.Color) u8 {
    return @as(u8, @enumToInt(fg)) | @as(u8, @enumToInt(bg)) << 4;
}

pub inline fn entry(c: u8, color_code: u8) u16 {
    return @as(u16, c) | @as(u16, color_code) << 8;
}
