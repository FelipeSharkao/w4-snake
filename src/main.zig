const std = @import("std");
const w4 = @import("wasm4.zig");
const inputs = @import("inputs.zig");

const TICK_TIME = 1.0 / 1.0;
const DELTA = 1.0 / 60.0 / TICK_TIME;
const UNIT_SIZE = 8;
const SCREEN_SIZE = w4.SCREEN_SIZE / UNIT_SIZE;

const Model = struct {
    snake: Snake,
    inputBuf: inputs.InputBuf(3),

    fn init() Model {
        return Model{
            .snake = Snake.init(3, SCREEN_SIZE / 2),
            .inputBuf = inputs.InputBuf(3){},
        };
    }
    fn gameOver(m: *Model) void {
        m.* = Model.init();
    }
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
    fn dirTo(a: Vec2, b: Vec2) Vec2 {
        return b.sub(a).normalized();
    }
    fn sizeSqr(v: Vec2) f32 {
        return v.x * v.x + v.y * v.y;
    }
    fn scale(v: Vec2, n: f32) Vec2 {
        return Vec2.init(v.x * n, v.y * n);
    }
    fn normalized(v: Vec2) Vec2 {
        const invSize = 1 / std.math.sqrt(v.sizeSqr());
        return Vec2.init(v.x, v.y).scale(invSize);
    }
    fn toPixels(v: Vec2) struct { x: i16, y: i16 } {
        return .{
            .x = @intFromFloat(v.x * UNIT_SIZE),
            .y = @intFromFloat(v.y * UNIT_SIZE),
        };
    }
    fn isOnGrid(v: Vec2) bool {
        const coord = v.toPixels();
        return @mod(coord.x, UNIT_SIZE) == 0 and @mod(coord.y, UNIT_SIZE) == 0;
    }
};

const Snake = struct {
    pos: Vec2,
    dir: Vec2,
    segments: [10]SnakeSegment = undefined,
    len: usize,
    fn init(x: f32, y: f32) Snake {
        const pos = Vec2.init(x, y);
        const dir = Vec2.init(1, 0);

        var s = Snake{
            .pos = pos,
            .dir = dir,
            .len = 3,
        };

        s.segments[0] = .{
            .pos = pos,
            .dir = dir,
            .isHead = true,
        };

        for (1..s.len) |i| {
            s.segments[i] = .{
                .pos = pos.sub(dir.scale(@floatFromInt(i))),
                .dir = dir,
            };
        }

        return s;
    }
    fn update(s: *Snake, m: *Model) void {
        if (s.pos.isOnGrid()) {
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

        s.pos = s.pos.add(s.dir.scale(DELTA));

        log(0, 0, "pos {d:.1} {d:.1}", .{ s.pos.x, s.pos.y });
        log(0, 8, "dir {d:.0} {d:.0}", .{ s.dir.x, s.dir.y });
        log(0, 16, "len {}", .{s.len});

        s.segments[0].update(s.dir);

        var prevSegPos = s.pos;
        for (1..s.len) |i| {
            var seg = &s.segments[i];
            seg.update(seg.pos.dirTo(prevSegPos));
            prevSegPos = seg.pos;
        }

        if (s.pos.x > SCREEN_SIZE - 1 or s.pos.x < 0 or
            s.pos.y > SCREEN_SIZE - 1 or s.pos.x < 0)
        {
            m.gameOver();
            return;
        }
    }
    fn render(s: Snake) void {
        var i = s.len;
        while (i > 0) {
            i -= 1;
            s.segments[i].render();
        }
    }
};

const SnakeSegment = struct {
    pos: Vec2,
    dir: Vec2,
    isHead: bool = false,

    fn render(s: SnakeSegment) void {
        setColors(3, 4, 0, 0);
        const coord = s.pos.toPixels();
        if (s.isHead) {
            w4.rect(coord.x, coord.y, UNIT_SIZE, UNIT_SIZE);
        } else {
            w4.rect(coord.x + 1, coord.y + 1, UNIT_SIZE - 2, UNIT_SIZE - 2);
        }
    }
    fn update(s: *SnakeSegment, nextDir: Vec2) void {
        s.pos = s.pos.add(s.dir.scale(DELTA));

        if (nextDir.isOnGrid()) {
            s.dir = nextDir;
        }
    }
};

var model = Model.init();

export fn start() void {}

export fn update() void {
    for (0..SCREEN_SIZE) |x| {
        for (0..SCREEN_SIZE) |y| {
            if ((x % 2) == (y % 2)) {
                setColors(1, 0, 0, 0);
            } else {
                setColors(2, 0, 0, 0);
            }
            w4.rect(
                @intCast(x * UNIT_SIZE),
                @intCast(y * UNIT_SIZE),
                UNIT_SIZE,
                UNIT_SIZE,
            );
        }
    }

    model.inputBuf.update();
    model.snake.update(&model);
    model.snake.render();
}

fn setColors(c1: u4, c2: u4, c3: u4, c4: u4) void {
    w4.DRAW_COLORS.* =
        @as(u16, @intCast(c1)) |
        (@as(u16, @intCast(c2)) << 4) |
        (@as(u16, @intCast(c3)) << 8) |
        (@as(u16, @intCast(c4)) << 12);
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
