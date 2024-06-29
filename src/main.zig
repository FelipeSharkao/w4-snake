const std = @import("std");
const w4 = @import("wasm4.zig");
const inputs = @import("inputs.zig");

const TICK_TIME = 1.0 / 4.0;
const DELTA = 1.0 / 60.0 / TICK_TIME;
const UNIT_SIZE = 8;
const SCREEN_SIZE = w4.SCREEN_SIZE / UNIT_SIZE;

const Model = struct {
    snake: Snake,
    inputBuf: inputs.InputBuf(2),
};

const Vec2 = struct {
    x: f32,
    y: f32,

    fn init(x: f32, y: f32) Vec2 {
        return Vec2{ .x = x, .y = y };
    }
    fn add(a: Vec2, b: Vec2) Vec2 {
        return Vec2.init(a.x + b.x, a.y + b.y);
    }
    fn sub(a: Vec2, b: Vec2) Vec2 {
        return Vec2.init(a.x - b.x, a.y - b.y);
    }
    fn distanceSqr(a: Vec2, b: Vec2) f32 {
        return b.sub(a).sizeSqr();
    }
    fn sizeSqr(v: Vec2) f32 {
        return v.x * v.x + v.y * v.y;
    }
    fn scale(v: Vec2, n: f32) Vec2 {
        return Vec2.init(v.x * n, v.y * n);
    }
    fn toPixes(v: Vec2) struct { x: i16, y: i16 } {
        return .{
            .x = @intFromFloat(v.x * UNIT_SIZE),
            .y = @intFromFloat(v.y * UNIT_SIZE),
        };
    }
};

const Snake = struct {
    head: Vec2,
    dir: Vec2,
    fn init(x: i32, y: i32) Snake {
        return Snake{ .head = Vec2.init(x, y), .dir = Vec2.init(1, 0) };
    }
    fn update(s: *Snake, m: *Model) void {
        const coord = s.head.toPixes();
        if (@mod(coord.x, UNIT_SIZE) == 0 and @mod(coord.y, UNIT_SIZE) == 0) {
            const inp = m.inputBuf.get();
            if (inp.isKeyDown(w4.BUTTON_UP) and s.dir.y == 0) {
                s.dir = Vec2.init(0, -1);
            } else if (inp.isKeyDown(w4.BUTTON_DOWN) and s.dir.y == 0) {
                s.dir = Vec2.init(0, 1);
            } else if (inp.isKeyDown(w4.BUTTON_LEFT) and s.dir.x == 0) {
                s.dir = Vec2.init(-1, 0);
            } else if (inp.isKeyDown(w4.BUTTON_RIGHT) and s.dir.x == 0) {
                s.dir = Vec2.init(1, 0);
            }
        }

        s.head = s.head.add(s.dir.scale(DELTA));

        log(0, 0, "head {d:.0} {d:.0}", .{ s.head.x, s.head.y });
        log(0, 8, "dir {d:.0} {d:.0}", .{ s.dir.x, s.dir.y });
        if (s.head.x >= SCREEN_SIZE) {
            s.head.x -= SCREEN_SIZE;
        }
        if (s.head.x <= -1) {
            s.head.x += SCREEN_SIZE + 1;
        }
        if (s.head.y >= SCREEN_SIZE) {
            s.head.y -= SCREEN_SIZE;
        }
        if (s.head.y <= -1) {
            s.head.y += SCREEN_SIZE + 1;
        }
    }
    fn render(s: Snake) void {
        setColors(3, 4, 0, 0);
        const x: i16 = @intFromFloat(s.head.x * UNIT_SIZE);
        const y: i16 = @intFromFloat(s.head.y * UNIT_SIZE);
        w4.rect(x, y, UNIT_SIZE, UNIT_SIZE);
    }
};

var model = Model{
    .snake = Snake.init(1, SCREEN_SIZE / 2),
    .inputBuf = inputs.InputBuf(2){},
};

export fn start() void {}

export fn update() void {
    for (0..SCREEN_SIZE) |x| {
        for (0..SCREEN_SIZE) |y| {
            if ((x % 2) == (y % 2)) {
                setColors(1, 0, 0, 0);
            } else {
                setColors(2, 0, 0, 0);
            }
            w4.rect(@intCast(x * UNIT_SIZE), @intCast(y * UNIT_SIZE), UNIT_SIZE, UNIT_SIZE);
        }
    }

    model.inputBuf.update();
    model.snake.update(&model);
    model.snake.render();
}

fn setColors(c1: u4, c2: u4, c3: u4, c4: u4) void {
    w4.DRAW_COLORS.* =
        @as(u16, @intCast(c1)) | (@as(u16, @intCast(c2)) << 4) | (@as(u16, @intCast(c3)) << 8) | (@as(u16, @intCast(c4)) << 12);
}

fn log(x: i32, y: i32, comptime template: []const u8, args: anytype) void {
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
