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

        // disable all interrupts
        writeToPort(serial_port.interrupt_enable, 0x00);

        // enable DLAB
        writeToPort(serial_port.line_control, 0x00);

        // set baud rate divisor to 3
        writeToPort(serial_port.data, 0x03);
        writeToPort(serial_port.interrupt_enable, 0x00);

        // disable DLAB and set 8 data bits, no parity, and one stop bit
        writeToPort(serial_port.line_control, 0x03);

        // enable FIFO, clear them, with 14-byte threshold
        writeToPort(serial_port.fifo, 0xC7);

        return serial_port;
    }

    pub fn readByte(self: *volatile Self) u8 {
        while (!readLineStatus(self.line_status).data_ready) {}
        return readFromPort(self.data);
    }

    pub fn writeByte(self: *volatile Self, byte: u8) void {
        while (!readLineStatus(self.line_status).buffer_empty) {}
        writeToPort(self.data, byte);
    }

    pub fn write(self: *volatile Self, bytes: []const u8) void {
        for (bytes) |b| {
            self.writeByte(b);
        }
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

fn writeToPort(port: u16, value: u8) void {
    asm volatile ("outb %[value], %[port]"
        :
        : [port] "{dx}" (port),
          [value] "{al}" (value)
    );
}

pub fn readFromPort(port: u16) u8 {
    return asm volatile ("inb %[port], %[value]"
        : [value] "={al}" (-> u8)
        : [port] "{dx}" (port)
    );
}

pub fn readLineStatus(port: u16) LineStatus {
    return @ptrCast(*LineStatus, &readFromPort(port)).*;
}
