const std = @import("std");

pub const SerialPort = packed struct {
    const Self = @This();

    data: u8,
    interrupt_enable: u8,
    fifo: u8,
    line_control: u8,
    modem_control: u8,
    line_status: u8,
    modem_status: u8,
    scratch: u8,

    pub fn init(port: u16) *volatile Self {
        var serial_port = @intToPtr(*volatile SerialPort, port);

        serial_port.data = 0x00;

        return serial_port;
    }
};
