const utils = @import("utils.zig");

pub const Vec2 = struct {
    x: f32,
    y: f32,

    pub fn init(x: f32, y: f32) Vec2 {
        return Vec2{ .x = x, .y = y };
    }
    pub fn add(a: Vec2, b: Vec2) Vec2 {
        return Vec2.init(a.x + b.x, a.y + b.y);
    }
    pub fn sub(a: Vec2, b: Vec2) Vec2 {
        return Vec2.init(a.x - b.x, a.y - b.y);
    }
    pub fn distanceSqr(a: Vec2, b: Vec2) f32 {
        return b.sub(a).sizeSqr();
    }
    pub fn dirTo(a: Vec2, b: Vec2) Vec2 {
        return b.sub(a).normalized();
    }
    pub fn sizeSqr(v: Vec2) f32 {
        return v.x * v.x + v.y * v.y;
    }
    pub fn scale(v: Vec2, n: f32) Vec2 {
        return Vec2.init(v.x * n, v.y * n);
    }
    pub fn normalized(v: Vec2) Vec2 {
        const invSize = 1 / @sqrt(v.sizeSqr());
        return Vec2.init(v.x, v.y).scale(invSize);
    }
    pub fn toPixels(v: Vec2) struct { x: i16, y: i16 } {
        return .{
            .x = @intFromFloat(v.x * utils.UNIT_SIZE),
            .y = @intFromFloat(v.y * utils.UNIT_SIZE),
        };
    }
    pub fn isOnGrid(v: Vec2) bool {
        const coord = v.toPixels();
        return @mod(coord.x, utils.UNIT_SIZE) == 0 and @mod(coord.y, utils.UNIT_SIZE) == 0;
    }
};
