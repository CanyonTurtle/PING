const w4 = @import("wasm4.zig");
const gc = @import("game_constants.zig");
const gr = @import("graphics.zig");
const sm = @import("smoke.zig");
const bl = @import("ball.zig");
const std = @import("std");

pub const Paddle_states = enum {
    normal,
    up,
    down,
    hit,
    lunge,
    catchback
};

pub const Paddle_Anim = struct {
    current_state: Paddle_states,
    current_sprite_data: *const gr.Sprite_Metadata,
    current_image: *const [24]u8,
    anim_timer: u16,
};

pub var p1_anim = Paddle_Anim{
    .current_state = Paddle_states.normal,
    .current_sprite_data = &gr.paddle,
    .current_image = &gr.paddle_image,
    .anim_timer = 0,
};

pub var p2_anim = Paddle_Anim{
    .current_state = Paddle_states.normal,
    .current_sprite_data = &gr.paddle,
    .current_image = &gr.paddle_image,
    .anim_timer = 0,
};

pub const Side = enum {
    left,
    right,
};

pub fn side_mult(side: Side) f16 {
    return switch (side) {
        .left => 1,
        .right => -1
    };
}

pub const Paddle_button_action = enum {
    lunge,
    catchback,
    none,
};

pub const Paddle = struct {
    normal_x: f16,
    x: f16,
    x_int: i32,
    y_int: i32,
    y: f16,
    vy: f16,
    ay: f16,
    anim: Paddle_Anim,
    side: Side,
};


pub const paddle_start_y: f16 = @intToFloat(f16, w4.SCREEN_SIZE) / 2.0;

pub fn init_paddle(side: Side) Paddle {
    var which_x:f16 = switch(side) {
        .right => w4.SCREEN_SIZE - gc.PADDLE_DIST_FROM_SIDES - gr.paddle.width,
        .left => gc.PADDLE_DIST_FROM_SIDES
    };
    return Paddle{
        .normal_x = which_x,
        .x = which_x,
        .x_int = 0,
        .y_int = 0,
        .y = paddle_start_y,
        .vy = 0,
        .ay = 0,
        .anim = Paddle_Anim{
            .current_state = Paddle_states.normal,
            .current_sprite_data = &gr.paddle,
            .current_image = &gr.paddle_image,
            .anim_timer = 0,
        },
        .side = side,
    };
}

pub var p1 = init_paddle(Side.left);
pub var p2 = init_paddle(Side.right);
pub var p3 = init_paddle(Side.left);
pub var p4 = init_paddle(Side.right);

pub const Paddle_dirs = enum { up, down, no_move };

pub fn update_paddle(paddle: *Paddle, dir: Paddle_dirs) void {
    switch (dir) {
        Paddle_dirs.up => {
            paddle.ay = -1 * gc.PADDLE_ACCEL;
        },
        Paddle_dirs.down => {
            paddle.ay = gc.PADDLE_ACCEL;
        },
        Paddle_dirs.no_move => {
            paddle.ay = 0;
            paddle.vy *= gc.PADDLE_NO_MOVE_DECAY_RATE;
        },
    }

    paddle.vy += paddle.ay;
    if (paddle.vy < -1 * gc.PADDLE_MAX_VEL) {
        paddle.vy = -1 * gc.PADDLE_MAX_VEL;
    } else if (paddle.vy > gc.PADDLE_MAX_VEL) {
        paddle.vy = gc.PADDLE_MAX_VEL;
    }

    paddle.y += paddle.vy;

    if (paddle.y < 0) {
        paddle.y = 0;
        paddle.vy = -1 * paddle.vy * gc.DAMPEN_BOUNCE;
    } else if (paddle.y > w4.SCREEN_SIZE - gr.paddle.height) {
        paddle.y = w4.SCREEN_SIZE - gr.paddle.height;
        paddle.vy = -1 * paddle.vy * gc.DAMPEN_BOUNCE;
    }

    paddle.y_int = @floatToInt(i32, paddle.y);
    paddle.x_int = @floatToInt(i32, paddle.x);
}

pub fn animate_paddle(paddle: *Paddle, dir: Paddle_dirs, button_action: Paddle_button_action, got_hit: bool) void {
    // small state machine for this
    if (got_hit) {
        switch (paddle.anim.current_state) {
            // lunge doesn't get hit back.
            Paddle_states.lunge => {

            },
            else => {
                paddle.x = switch(paddle.side) {
                    Side.left => paddle.normal_x + gc.PADDLE_BOUNCEBACK_DIST,
                    Side.right => paddle.normal_x - gc.PADDLE_BOUNCEBACK_DIST,
                };
            }
        }

        paddle.anim.current_state = Paddle_states.hit;
        paddle.anim.anim_timer = 0;
        
        
    }

    switch (paddle.anim.current_state) {
        Paddle_states.normal, Paddle_states.down, Paddle_states.up => {
            
            switch (button_action) {
                Paddle_button_action.catchback => {
                    paddle.x = paddle.normal_x + -1 * side_mult(paddle.side) * gc.PADDLE_BOUNCEBACK_DIST;
                    paddle.anim.current_state = Paddle_states.catchback;
                },
                Paddle_button_action.lunge => {
                    // sm.spawn_smoke(paddle.x, paddle.y + @intToFloat(f16, paddle.anim.current_sprite_data.height) + gc.SMOKE_OFFSET_Y, 0, 2 * gc.SMOKE_START_VEL);
                    // sm.spawn_smoke(paddle.x, paddle.y - gc.SMOKE_OFFSET_Y, 0, -2 * gc.SMOKE_START_VEL);

  
                    var vx_mult: f16 = side_mult(paddle.side) * -1 * gc.SMOKE_VX_OFFSET_MULT;
                    var x_offset: f16 = (gc.SMOKE_PADDLE_OFFSET_MULT/2.0 + gc.SMOKE_VX_OFFSET_MULT/2.0 * side_mult(paddle.side) * -1) * 1 * @intToFloat(f16, paddle.anim.current_sprite_data.width);
                    sm.spawn_smoke(paddle.x + x_offset, paddle.y + @intToFloat(f16, paddle.anim.current_sprite_data.height) / 2 + gc.SMOKE_OFFSET_Y, vx_mult * gc.SMOKE_START_VEL * std.math.fabs(bl.ball.vx), gc.SMOKE_START_VEL);
                    sm.spawn_smoke(paddle.x + x_offset, paddle.y + @intToFloat(f16, paddle.anim.current_sprite_data.height) / 2 - gc.SMOKE_OFFSET_Y, vx_mult * gc.SMOKE_START_VEL * std.math.fabs(bl.ball.vx), -1 * gc.SMOKE_START_VEL);

                    paddle.x = paddle.normal_x + side_mult(paddle.side) * gc.PADDLE_BOUNCEBACK_DIST;
                    paddle.anim.current_state = Paddle_states.lunge;
                },
                Paddle_button_action.none => {
                    paddle.anim.anim_timer = 0;
                    switch (dir) {
                        Paddle_dirs.up => {
                            if (paddle.anim.current_state != Paddle_states.up) {
                                sm.spawn_smoke(paddle.x, paddle.y + @intToFloat(f16, paddle.anim.current_sprite_data.height) + gc.SMOKE_OFFSET_Y, 0, gc.SMOKE_START_VEL);
                            }
                            paddle.anim.current_state = Paddle_states.up;
                        },
                        Paddle_dirs.down => {
                            if (paddle.anim.current_state != Paddle_states.down) {
                                sm.spawn_smoke(paddle.x, paddle.y - gc.SMOKE_OFFSET_Y, 0, -1 * gc.SMOKE_START_VEL);
                            }
                            paddle.anim.current_state = Paddle_states.down;
                        },
                        Paddle_dirs.no_move => {
                            paddle.anim.current_state = Paddle_states.normal;
                        }
                    }
                }
            }
            
        },
        Paddle_states.hit => {
            paddle.anim.anim_timer += 1;
            if (paddle.anim.anim_timer > gc.PADDLE_HIT_ANIM_DURATION) {
                paddle.anim.current_state = Paddle_states.normal;
                paddle.x = paddle.normal_x;
            }
        },
        Paddle_states.catchback => {
            paddle.anim.anim_timer += 1;
            if (paddle.anim.anim_timer > gc.PADDLE_LUNGE_CATCHBACK_DURATION and button_action != Paddle_button_action.catchback) {
                paddle.anim.current_state = Paddle_states.normal;
                paddle.x = paddle.normal_x;
            }
        },
        Paddle_states.lunge => {
            paddle.anim.anim_timer += 1;
            if (paddle.anim.anim_timer > gc.PADDLE_LUNGE_CATCHBACK_DURATION and button_action != Paddle_button_action.lunge) {
                paddle.anim.current_state = Paddle_states.normal;
                paddle.x = paddle.normal_x;
            }
        }
    }

    var which_sprite: *const gr.Sprite_Metadata = switch(paddle.anim.current_state) {
        Paddle_states.normal => &gr.paddle,
        Paddle_states.hit => &gr.paddle_hit,
        Paddle_states.up => &gr.paddle_up,
        Paddle_states.down => &gr.paddle_down,
        Paddle_states.catchback => &gr.paddle,
        Paddle_states.lunge => &gr.paddle,
    };
    var which_sprite_image: *const [24]u8 = switch(paddle.anim.current_state) {
        Paddle_states.normal => &gr.paddle_image,
        Paddle_states.hit => &gr.paddle_image,
        Paddle_states.up => &gr.paddle_up_image,
        Paddle_states.down => &gr.paddle_down_image,
        Paddle_states.catchback => &gr.paddle_image,
        Paddle_states.lunge => &gr.paddle_image,
    };

    paddle.anim.current_sprite_data = which_sprite;
    paddle.anim.current_image = which_sprite_image;
}
