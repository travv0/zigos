const std = @import("std");

pub fn Port(comptime T: type) type {
    return packed struct {
        const Self = @This();

        port: u16,

        fn init(port: u16) Self {
            return .{ .port = port };
        }

        pub fn write(self: Self, value: T) void {
            asm volatile ("outb %[value], %[port]"
                :
                : [port] "{dx}" (self.port),
                  [value] "{al}" (value)
            );
        }

        pub fn read(self: Self) T {
            return asm volatile ("inb %[port], %[value]"
                : [value] "={al}" (-> T)
                : [port] "{dx}" (self.port)
            );
        }
    };
}
