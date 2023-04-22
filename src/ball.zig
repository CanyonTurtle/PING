const w4 = @import("wasm4.zig");
const gc = @import("game_constants.zig");
const gr = @import("graphics.zig");

pub const ball_start_y: f16 = @intToFloat(f16, w4.SCREEN_SIZE) / 2.0;
pub const ball_start_x: f16 = @intToFloat(f16, w4.SCREEN_SIZE) / 2.0;

pub const Ball = struct {
    x: f16,
    y: f16,
    x_int: i32,
    y_int: i32,
    vx: f16,
    vy: f16,
    spin: f16,
};

pub var ball = Ball{
    .x = ball_start_x,
    .y = ball_start_y,
    .x_int = 0,
    .y_int = 0,
    .vx = 1,
    .vy = 0.0,
    .spin = 0.0,
};