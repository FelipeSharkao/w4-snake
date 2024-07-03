const inputs = @import("inputs.zig");
const snake = @import("snake.zig");
const utils = @import("utils.zig");
const w4 = @import("wasm4.zig");

const Model = struct {
    snake: snake.Snake,

    fn start(m: *Model) void {
        const gameOverEvent = utils.EmptyEvent{
            .ptr = m,
            .handler = Model.handleGameOver
        };
        m.snake = snake.Snake.init(3, utils.SCREEN_SIZE / 2, gameOverEvent);

    }
    fn handleGameOver(ptr: *anyopaque, _: utils.EmptyEvent.Msg) void {
        const m: *Model = @ptrCast(@alignCast(ptr));
        m.gameOver();
    }
    fn gameOver(m: *Model) void {
        m.start();
    }
};

var model = Model{.snake = undefined};

export fn start() void {
    model.start();
}

export fn update() void {
    for (0..utils.SCREEN_SIZE) |x| {
        for (0..utils.SCREEN_SIZE) |y| {
            if ((x % 2) == (y % 2)) {
                utils.setColors(1, 0, 0, 0);
            } else {
                utils.setColors(2, 0, 0, 0);
            }
            w4.rect(
                @intCast(x * utils.UNIT_SIZE),
                @intCast(y * utils.UNIT_SIZE),
                utils.UNIT_SIZE,
                utils.UNIT_SIZE,
            );
        }
    }

    model.snake.update();
    model.snake.render();
}
