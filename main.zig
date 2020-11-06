const std = @import("std");

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
    var term = Terminal.init();
    term.write("a\nb\nc\nd\ne\nf\ng\nh\ni\nj\nk\nl\nm\nn\no\np\nq\nr\ns\nt\nu\nv\nw\nx\ny\nz\n");
    term.write("Hello world!");
}

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

const Terminal = struct {
    const Self = @This();

    const width = 80;
    const height = 25;

    row: usize,
    col: usize,
    color: u8,
    buffer: [*]volatile u16,

    fn init() Self {
        const color = VgaColor.code(VgaColor.light_brown, VgaColor.black);
        var buffer = @intToPtr([*]volatile u16, 0xB8000);
        var y: usize = 0;
        while (y < height) : (y += 1) {
            var x: usize = 0;
            while (x < width) : (x += 1) {
                buffer[Terminal.index(x, y)] = char(' ', color);
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

    fn putAt(self: *Self, c: u8, color: u8, x: usize, y: usize) void {
        self.buffer[Terminal.index(x, y)] = char(c, color);
    }

    fn putChar(self: *Self, c: u8) void {
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

    fn moveDown(self: *Self) void {
        if (self.row == height - 1) {
            self.scrollDown();
        } else self.row += 1;
    }

    fn scrollDown(self: *Self) void {
        var y: usize = 0;
        while (y < height - 1) : (y += 1) {
            var x: usize = 0;
            while (x < width) : (x += 1) {
                self.buffer[Terminal.index(x, y)] = self.buffer[Terminal.index(x, y + 1)];
            }
        }
        var x: usize = 0;
        while (x < width) : (x += 1) {
            self.buffer[Terminal.index(x, height - 1)] = char(' ', self.color);
        }
    }

    fn write(self: *Self, data: []const u8) void {
        for (data) |c| {
            self.putChar(c);
        }
    }
};
