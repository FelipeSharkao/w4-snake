const std = @import("std");
const w4 = @import("wasm4.zig");

const SNAKE_SPEED = 0.5;

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
};

const Snake = struct {
    head: Vec2,
    dir: Vec2,
    fn init(x: i32, y: i32) Snake {
        return Snake{ .head = Vec2.init(x, y), .dir = Vec2.init(1, 0) };
    }
    fn update(s: *Snake) void {
        if (wasKeyPressed(w4.BUTTON_UP) and s.dir.y == 0) {
            s.nextDir = Vec2.init(0, -1);
        } else if (wasKeyPressed(w4.BUTTON_DOWN) and s.dir.y == 0) {
            s.nextDir = Vec2.init(0, 1);
        } else if (wasKeyPressed(w4.BUTTON_LEFT) and s.dir.x == 0) {
            s.nextDir = Vec2.init(-1, 0);
        } else if (wasKeyPressed(w4.BUTTON_RIGHT) and s.dir.x == 0) {
            s.nextDir = Vec2.init(1, 0);
        }

        s.head = s.head.add(s.dir.scale(SNAKE_SPEED));

        log(0, 0, "head {d:.0} {d:.0}", .{ s.head.x, s.head.y });
        log(0, 8, "dir {d:.0} {d:.0}", .{ s.dir.x, s.dir.y });
        if (s.head.x >= w4.SCREEN_SIZE) {
            s.head.x -= w4.SCREEN_SIZE;
        }
        if (s.head.x <= -16) {
            s.head.x += w4.SCREEN_SIZE + 16;
        }
        if (s.head.y >= w4.SCREEN_SIZE) {
            s.head.y -= w4.SCREEN_SIZE;
        }
        if (s.head.y <= -16) {
            s.head.y += w4.SCREEN_SIZE + 16;
        }
    }
    fn render(s: Snake) void {
        setColors(2, 3, 0, 0);
        w4.rect(@intFromFloat(s.head.x), @intFromFloat(s.head.y), 8, 8);
    }
};

var snake = Snake.init(16, 80);

var previous_gamepad: u8 = 0;

export fn start() void {}

export fn update() void {
    snake.update();
    snake.render();
    previous_gamepad = w4.GAMEPAD1.*;
}

fn wasKeyPressed(mask: u8) bool {
    return (w4.GAMEPAD1.* & mask) != 0 and (previous_gamepad & mask) != 0;
}

fn setColors(c1: u4, c2: u4, c3: u4, c4: u4) void {
    w4.DRAW_COLORS.* =
        @as(u16, @intCast(c1)) | (@as(u16, @intCast(c2)) << 4) | (@as(u16, @intCast(c3)) << 8) | (@as(u16, @intCast(c4)) << 12);
}

fn log(x: i32, y: i32, comptime template: []const u8, args: anytype) void {
    var s: [256]u8 = undefined;
    _ = std.fmt.bufPrintZ(&s, template, args) catch |err| {
        switch (err) {
            error.NoSpaceLeft => w4.trace("[ERR] log buffer not large enough"),
        }
        return;
    };
    w4.text(&s, x, y);
}
