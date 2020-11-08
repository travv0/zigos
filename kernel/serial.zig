const std = @import("std");
const Port = @import("port.zig").Port;

pub const SerialPort = struct {
    const Self = @This();

    const WriteError = error{};

    pub const Writer = std.io.Writer(*Self, WriteError, writeE);

    data: Port(u8),
    interrupt_enable: Port(u8),
    fifo_control: Port(u8),
    line_control: Port(u8),
    modem_control: Port(u8),
    line_status: Port(u8),
    modem_status: Port(u8),
    scratch: Port(u8),

    pub fn init(port: u16) Self {
        const ptr = @intToPtr([*]volatile SerialPort, port);
        var serial_port = Self{
            .data = Port(u8).init(@truncate(u16, @ptrToInt(ptr))),
            .interrupt_enable = Port(u8).init(@truncate(u16, @ptrToInt(ptr + 1))),
            .fifo_control = Port(u8).init(@truncate(u16, @ptrToInt(ptr + 2))),
            .line_control = Port(u8).init(@truncate(u16, @ptrToInt(ptr + 3))),
            .modem_control = Port(u8).init(@truncate(u16, @ptrToInt(ptr + 4))),
            .line_status = Port(u8).init(@truncate(u16, @ptrToInt(ptr + 5))),
            .modem_status = Port(u8).init(@truncate(u16, @ptrToInt(ptr + 6))),
            .scratch = Port(u8).init(@truncate(u16, @ptrToInt(ptr + 7))),
        };

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
        serial_port.fifo_control.write(0xC7);

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

    pub fn write(self: *volatile Self, bytes: []const u8) usize {
        var i: usize = 0;
        for (bytes) |b| {
            self.writeByte(b);
            i += 1;
        }
        return i;
    }

    fn writeE(self: *Self, data: []const u8) WriteError!usize {
        return self.write(data);
    }

    pub fn writer(self: *Self) Writer {
        return .{ .context = self };
    }

    pub fn readLineStatus(self: Self) LineStatus {
        return @bitCast(LineStatus, self.line_status.read());
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
