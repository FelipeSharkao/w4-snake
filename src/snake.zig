const inputs = @import("inputs.zig");
const vec = @import("vec.zig");
const Vec2 = vec.Vec2;
const utils = @import("utils.zig");
const w4 = @import("wasm4.zig");

pub const Snake = struct {
    pos: Vec2,
    dir: Vec2,
    segments: [10]SnakeSegment = undefined,
    len: usize,
    inputBuf: inputs.InputBuf(3),
    onGameOver: utils.EmptyEvent,
    pub fn init(x: f32, y: f32, onGameOver: utils.EmptyEvent) Snake {
        const pos = Vec2.init(x, y);
        const dir = Vec2.init(1, 0);

        var s = Snake{
            .pos = pos,
            .dir = dir,
            .len = 3,
            .inputBuf = inputs.InputBuf(3){},
            .onGameOver = onGameOver,
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
    pub fn update(s: *Snake) void {
        s.inputBuf.update();

        if (s.pos.isOnGrid()) {
            const inp = s.inputBuf.get();
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

        s.pos = s.pos.add(s.dir.scale(utils.DELTA));

        utils.log(0, 0, "pos {d:.1} {d:.1}", .{ s.pos.x, s.pos.y });
        utils.log(0, 8, "dir {d:.0} {d:.0}", .{ s.dir.x, s.dir.y });
        utils.log(0, 16, "len {}", .{s.len});

        s.segments[0].update(s.dir);

        var prevSegPos = s.pos;
        for (1..s.len) |i| {
            var seg = &s.segments[i];
            seg.update(seg.pos.dirTo(prevSegPos));
            prevSegPos = seg.pos;
        }

        if (s.pos.x > utils.SCREEN_SIZE - 1 or s.pos.x < 0 or
            s.pos.y > utils.SCREEN_SIZE - 1 or s.pos.x < 0)
        {
            s.onGameOver.emit({});
            return;
        }
    }
    pub fn render(s: Snake) void {
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
        utils.setColors(3, 4, 0, 0);
        const coord = s.pos.toPixels();
        if (s.isHead) {
            w4.rect(coord.x, coord.y, utils.UNIT_SIZE, utils.UNIT_SIZE);
        } else {
            w4.rect(coord.x + 1, coord.y + 1, utils.UNIT_SIZE - 2, utils.UNIT_SIZE - 2);
        }
    }
    fn update(s: *SnakeSegment, nextDir: Vec2) void {
        s.pos = s.pos.add(s.dir.scale(utils.DELTA));

        if (nextDir.isOnGrid()) {
            s.dir = nextDir;
        }
    }
};
