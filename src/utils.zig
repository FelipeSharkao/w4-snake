const std = @import("std");

const w4 = @import("wasm4.zig");

pub const TICK_TIME = 1.0 / 1.0;
pub const DELTA = 1.0 / 60.0 / TICK_TIME;
pub const UNIT_SIZE = 8;
pub const SCREEN_SIZE = w4.SCREEN_SIZE / UNIT_SIZE;

pub fn setColors(c1: u4, c2: u4, c3: u4, c4: u4) void {
    w4.DRAW_COLORS.* =
        @as(u16, @intCast(c1)) |
        (@as(u16, @intCast(c2)) << 4) |
        (@as(u16, @intCast(c3)) << 8) |
        (@as(u16, @intCast(c4)) << 12);
}

pub fn log(x: i32, y: i32, comptime template: []const u8, args: anytype) void {
    setColors(3, 2, 0, 0);
    var s: [256]u8 = undefined;
    _ = std.fmt.bufPrintZ(&s, template, args) catch |err| {
        switch (err) {
            error.NoSpaceLeft => w4.trace("[ERR] log buffer not large enough"),
        }
        return;
    };
    w4.text(&s, x, y);
}

pub fn Event(comptime TMsg: type) type {
    return struct {
        pub const Msg = TMsg;
        ptr: *anyopaque,
        handler: *const fn (ptr: *anyopaque, msg: Msg) void,

        pub fn emit(e: @This(), msg: Msg) void {
            e.handler(e.ptr, msg);
        }
    };
}

pub const EmptyEvent = Event(void);
