const std = @import("std");

pub fn Port(comptime T: type) type {
    return packed struct {
        const Self = @This();

        port: u16,

        pub fn init(port: u16) Self {
            return .{ .port = port };
        }

        pub fn write(self: Self, value: T) void {
            asm volatile ("out %[value], %[port]"
                :
                : [port] "{dx}" (self.port),
                  [value] "{eax}" (value)
            );
        }

        pub fn read(self: Self) T {
            return asm volatile ("in %[port], %[value]"
                : [value] "={eax}" (-> T)
                : [port] "{dx}" (self.port)
            );
        }
    };
}
