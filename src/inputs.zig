const w4 = @import("wasm4.zig");

pub fn InputBuf(comptime size: usize) type {
    return struct {
        _prevGamepad: u8 = 0,
        _queue: [size]Input = undefined,
        _len: usize = 0,

        pub fn init() @This() {
            return .{};
        }
        pub fn len(b: @This()) u32 {
            return b.len;
        }
        pub fn update(b: *@This()) void {
            if (b._len == size) {
                return;
            }
            const gamepad = w4.GAMEPAD1.*;
            const diff = gamepad ^ b._prevGamepad;
            if (diff == 0) {
                return;
            }

            b._queue[b._len] = Input{
                ._keypress = gamepad,
                ._keyup = diff & b._prevGamepad,
                ._keydown = diff & gamepad,
            };
            b._len += 1;
            b._prevGamepad = gamepad;
        }
        pub fn get(b: *@This()) Input {
            if (b._len == 0) {
                return .{};
            }

            const item = b._queue[0];
            for (1..b._len) |i| {
                b._queue[i - 1] = b._queue[i];
            }
            b._len -= 1;
            return item;
        }
    };
}

pub const Input = struct {
    _keypress: u8 = 0,
    _keydown: u8 = 0,
    _keyup: u8 = 0,

    pub fn isKeyPressed(in: Input, mask: u8) bool {
        return in._keypress & mask != 0;
    }
    pub fn isKeyDown(in: Input, mask: u8) bool {
        return in._keydown & mask != 0;
    }
    pub fn isKeyUp(in: Input, mask: u8) bool {
        return in._keyup & mask != 0;
    }
};
