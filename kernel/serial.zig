const std = @import("std");
const Port = @import("port.zig").Port;

pub const SerialPort = packed struct {
    const Self = @This();

    data: Port(u8),
    interrupt_enable: Port(u8),
    fifo: Port(u8),
    line_control: Port(u8),
    modem_control: Port(u8),
    line_status: Port(u8),
    modem_status: Port(u8),
    scratch: Port(u8),

    pub fn init(port: u16) *volatile Self {
        var serial_port = @intToPtr(*volatile SerialPort, port);

        // disable all interrupts
        serial_port.interrupt_enable.write(0x00);

        // enable DLAB
        serial_port.line_control.write(0x80);

        // set baud rate divisor to 3
        serial_port.data.write(0x03);
        serial_port.interrupt_enable.write(0x00);

        // disable DLAB and set 8 data bits, no parity, and one stop bit
        serial_port.line_control.write(0x03);

        // enable FIFO, clear them, with 14-byte threshold
        serial_port.fifo.write(0xC7);

        // IRQs enabled, RTS/DSR set
        serial_port.modem_control.write(0x0B);

        // enable interrupts
        serial_port.interrupt_enable.write(0x01);

        return serial_port;
    }

    pub fn readByte(self: *volatile Self) u8 {
        while (!self.readLineStatus().data_ready) {}
        return self.data.read();
    }

    pub fn writeByte(self: *volatile Self, byte: u8) void {
        while (!self.readLineStatus().buffer_empty) {}
        self.data.write(byte);
    }

    pub fn write(self: *volatile Self, bytes: []const u8) void {
        for (bytes) |b| {
            self.writeByte(b);
        }
    }

    pub fn readLineStatus(self: Self) LineStatus {
        return @ptrCast(*volatile LineStatus, &self.line_status.read()).*;
    }
};

const LineStatus = packed struct {
    data_ready: bool,
    overrun_error: bool,
    parity_error: bool,
    framing_error: bool,
    break_indicator: bool,
    buffer_empty: bool,
    transmitter_empty: bool,
    impending_error: bool,
};
