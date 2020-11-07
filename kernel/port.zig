const std = @import("std");

pub fn Port(comptime T: type) type {
    return packed struct {
        const Self = @This();

        port: T,

        fn init(address: T) Self {
            return .{ .port = address };
        }

        pub fn write(self: Self, value: u8) void {
            const port = if (comptime @sizeOf(@TypeOf(self.port)) < 16)
                @as(u16, self.port)
            else
                self.port;
            asm volatile ("outb %[value], %[port]"
                :
                : [port] "{dx}" (port),
                  [value] "{al}" (value)
            );
        }

        pub fn read(self: Self) u8 {
            const port = if (comptime @sizeOf(@TypeOf(self.port)) < 16)
                @as(u16, self.port)
            else
                self.port;
            return asm volatile ("inb %[port], %[value]"
                : [value] "={al}" (-> u8)
                : [port] "{dx}" (port)
            );
        }
    };
}
