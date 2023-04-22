const w4 = @import("wasm4.zig");
const std = @import("std");
const gr = @import("graphics.zig");
const gc = @import("game_constants.zig");
const pd = @import("paddles.zig");
const bl = @import("ball.zig");
const sm = @import("smoke.zig");

var p1_score: i32 = 0;
var p2_score: i32 = 0;
var timer: u32 = 0;
var is_cpu: bool = true;

var current_p1_dir: pd.Paddle_dirs = pd.Paddle_dirs.no_move;
var current_p2_dir: pd.Paddle_dirs = pd.Paddle_dirs.no_move;

var current_p1_action_input: pd.Paddle_button_action = pd.Paddle_button_action.none;
var current_p2_action_input: pd.Paddle_button_action = pd.Paddle_button_action.none;

fn is_colliding(ball: *bl.Ball, paddle: *pd.Paddle) bool {
    const ball_radius = gr.ball.width / 2;
    _ = ball_radius;
    var ball_right_x = ball.x + @intToFloat(f16, gr.ball.width);
    var ball_bottom_y = ball.y + @intToFloat(f16, gr.ball.width);

    var paddle_right_x = paddle.x + @intToFloat(f16, gr.paddle.width);
    var paddle_bottom_y = paddle.y + @intToFloat(f16, gr.paddle.height);

    // depending on which way it's heading, we only need
    // to check one side for collision.
    if (paddle.anim.current_state == pd.Paddle_states.hit) {
        return false;
    }
    if (ball.y < paddle_bottom_y and ball_bottom_y > paddle.y) {
        if (ball.vx > 0 and ball_right_x >= paddle.x and ball.x < paddle.x) {
            return true;
        }
        else if(ball.vx <= 0 and ball.x <= paddle_right_x and ball_right_x > paddle.x) {
            return true;
        }
    }
    return false;
    
}

export fn start() void {
    // var rnd = std.rand.DefaultPrng.init(@ptrToInt(&bl.ball));
    // const dir = @intToFloat(f16, @mod(rnd.random().int(i32), 360));
    // const mag: f16 = 1.0;
    // bl.ball.vx = @cos(dir) * mag;
    // bl.ball.vy = @sin(dir) * mag;
    // w4.PALETTE.* = .{
    //     0x8e9aaf,0xefd3d7,0xfeeafa,0xdee2ff
    // };
    w4.PALETTE.* = gr.pallete;
    reset_ball_and_paddles();
}

fn reset_ball_and_paddles() void {
    bl.ball.vx = 1.0;
    bl.ball.vy = 0.0;
    bl.ball.x = bl.ball_start_x - @intToFloat(f16, gr.ball.width) / 2;
    bl.ball.y = bl.ball_start_y - @intToFloat(f16, gr.ball.height) / 2;
    pd.p1.y = pd.paddle_start_y - @intToFloat(f16, gr.paddle.height) / 2;
    pd.p2.y = pd.paddle_start_y - @intToFloat(f16, gr.paddle.height) / 2;
    timer = 0;
}

fn move_ball() void {
    // ball off paddle physics
    if (is_colliding(&bl.ball, &pd.p1)) {
        bl.ball.vx *= -1 * gc.BALL_BOUNCEBACK_VX_MULT;
        bl.ball.vy += gc.PADDLE_TRANSFER_VY_MULT * pd.p1.vy;
        bl.ball.spin += gc.BALL_SPIN_VAL_MULT * pd.p1.vy;
        bl.ball.vx -= std.math.fabs(gc.PADDLE_TRANSFER_VY_MULT * gc.PADDLE_TRANSFER_VY_MULT * pd.p1.vy);
        if (pd.p1.anim.anim_timer < gc.PADDLE_LUNGE_CATCHBACK_DURATION) {
            bl.ball.vx *= switch (pd.p1.anim.current_state) {
                pd.Paddle_states.lunge => gc.PADDLE_LUNGE_MULT,
                pd.Paddle_states.catchback => gc.PADDLE_CATCHBACK_MULT,
                else => 1,
            };
        }

        bl.ball.x -= gc.PADDLE_BOUNCEBACK_DIST - 1;
        pd.animate_paddle(&pd.p1, current_p1_dir, current_p1_action_input, true);
    } else if (is_colliding(&bl.ball, &pd.p2)) {
        bl.ball.vx *= -1 * gc.BALL_BOUNCEBACK_VX_MULT;
        bl.ball.vy += gc.PADDLE_TRANSFER_VY_MULT * pd.p2.vy;
        bl.ball.spin += gc.BALL_SPIN_VAL_MULT * pd.p2.vy;
        bl.ball.vx -= std.math.fabs(gc.PADDLE_TRANSFER_VY_MULT * gc.PADDLE_TRANSFER_VY_MULT * pd.p2.vy);
        bl.ball.vx *= switch (pd.p2.anim.current_state) {
            pd.Paddle_states.lunge => gc.PADDLE_LUNGE_MULT,
            pd.Paddle_states.catchback => gc.PADDLE_CATCHBACK_MULT,
            else => 1,
        };
        bl.ball.x += gc.PADDLE_BOUNCEBACK_DIST + 1;
        pd.animate_paddle(&pd.p2, current_p2_dir, current_p2_action_input, true);
    }





    if (bl.ball.y < 0) {
        bl.ball.y = 0;
        bl.ball.vy *= -1;
        bl.ball.spin = 0;
    }
    else if(bl.ball.y > w4.SCREEN_SIZE - gr.ball.height) {
        bl.ball.y = w4.SCREEN_SIZE - gr.ball.height;
        bl.ball.vy *= -1;
        bl.ball.spin = 0;
    }

    if (bl.ball.vx > gc.BALL_MAX_VX) {
        bl.ball.vx = gc.BALL_MAX_VX;
        bl.ball.spin = 0;
    }
    if (bl.ball.vx < -1 * gc.BALL_MAX_VX) {
        bl.ball.vx = -1 * gc.BALL_MAX_VX;
        bl.ball.spin = 0;
    }

    bl.ball.y += bl.ball.spin * gc.BALL_SPIN_ACCEL_MULT;
    bl.ball.spin *= gc.BALL_SPIN_DECAY_MULT;

    bl.ball.x += bl.ball.vx;
    bl.ball.y += bl.ball.vy;

    if (bl.ball.x < 0) {
        reset_ball_and_paddles();
        p2_score += 1;
    }
    else if(bl.ball.x > w4.SCREEN_SIZE - gr.ball.width) {
        reset_ball_and_paddles();
        p1_score += 1;
    }
}

fn main_game_loop() void {
    // w4.DRAW_COLORS.* = 2;
    // w4.text(gc.GAME_NAME, 60, 0);
    w4.DRAW_COLORS.* = gr.ping.draw_colors;
    w4.blit(&gr.ping_img, 60, 0, gr.ping.width, gr.ping.height, gr.ping.flags);

    if (w4.GAMEPAD2.* & w4.BUTTON_UP != 0) {
        current_p1_dir = pd.Paddle_dirs.up;
        is_cpu = false;
    } else if (w4.GAMEPAD2.* & w4.BUTTON_DOWN != 0) {
        current_p1_dir = pd.Paddle_dirs.down;
        is_cpu = false;
    } else {
        if (!is_cpu) {
            current_p1_dir = pd.Paddle_dirs.no_move;
        }
    }
    if (w4.GAMEPAD2.* & w4.BUTTON_1 != 0) {
        current_p1_action_input = pd.Paddle_button_action.lunge;
    } else if (w4.GAMEPAD2.* & w4.BUTTON_2 != 0) {
        current_p1_action_input = pd.Paddle_button_action.catchback;
    } else {
        current_p1_action_input = pd.Paddle_button_action.none;
    }

    if (w4.GAMEPAD1.* & w4.BUTTON_UP != 0) {
        current_p2_dir = pd.Paddle_dirs.up;
    } else if (w4.GAMEPAD1.* & w4.BUTTON_DOWN != 0) {
        current_p2_dir = pd.Paddle_dirs.down;
    } else { 
        current_p2_dir = pd.Paddle_dirs.no_move;
        
    }

    if (w4.GAMEPAD1.* & w4.BUTTON_1 != 0) {
        current_p2_action_input = pd.Paddle_button_action.lunge;
    } else if (w4.GAMEPAD1.* & w4.BUTTON_2 != 0) {
        current_p2_action_input = pd.Paddle_button_action.catchback;
    } else {
        current_p2_action_input = pd.Paddle_button_action.none;
    }

    if (is_cpu) {
        var p1_center = pd.p1.y + @intToFloat(f16, gr.paddle.height) / 2;
        var ball_center = bl.ball.y + @intToFloat(f16,gr.ball.height) / 2;
        if (p1_center < ball_center - gc.CPU_TARGET_SPOT_TOL) {
            current_p1_dir = pd.Paddle_dirs.down;
        } else if(p1_center > ball_center + gc.CPU_TARGET_SPOT_TOL){
            current_p1_dir = pd.Paddle_dirs.up;
        } else {
            current_p1_dir = pd.Paddle_dirs.no_move;
        }
    }
    
    pd.update_paddle(&pd.p1, current_p1_dir);
    pd.update_paddle(&pd.p2, current_p2_dir);

    bl.ball.y_int = @floatToInt(i32, bl.ball.y);
    bl.ball.x_int = @floatToInt(i32, bl.ball.x);

    var p1_score_buf: [32]u8 = undefined;
    _ = std.fmt.bufPrint(&p1_score_buf, "{d}", .{p1_score}) catch undefined;
    var p2_score_buf: [32]u8 = undefined;
    _ = std.fmt.bufPrint(&p2_score_buf, "{d}", .{p2_score}) catch undefined;

    pd.animate_paddle(&pd.p1, current_p1_dir, current_p1_action_input, false);
    pd.animate_paddle(&pd.p2, current_p2_dir, current_p2_action_input, false);

    _ = sm.update_smokes();

    var i: u16 = 0;
    while(i < gc.N_SMOKES_RINGBUFFER) {
        var s: *sm.Smoke = &sm.smokes[i];
        if(s.is_active) {
            w4.DRAW_COLORS.* = s.sprite_data.draw_colors;
            s.x_int = @floatToInt(i32, s.x);
            s.y_int = @floatToInt(i32, s.y);
            w4.blit(s.image, s.x_int, s.y_int, s.sprite_data.width, s.sprite_data.height, s.sprite_data.flags);
        }
        i += 1;
    }

    w4.DRAW_COLORS.* = pd.p1.anim.current_sprite_data.draw_colors; 
    w4.blit(pd.p1.anim.current_image, pd.p1.x_int, pd.p1.y_int, pd.p1.anim.current_sprite_data.width, pd.p1.anim.current_sprite_data.height, pd.p1.anim.current_sprite_data.flags);

    w4.DRAW_COLORS.* = pd.p2.anim.current_sprite_data.draw_colors; 
    w4.blit(pd.p2.anim.current_image, pd.p2.x_int, pd.p2.y_int, pd.p2.anim.current_sprite_data.width, pd.p2.anim.current_sprite_data.height, pd.p2.anim.current_sprite_data.flags);

    w4.DRAW_COLORS.* = gr.ball.draw_colors;
    w4.blit(&gr.ball_image, bl.ball.x_int, bl.ball.y_int, gr.ball.width, gr.ball.height, gr.ball.flags);
    w4.DRAW_COLORS.* = 0x03;
    w4.text(&p1_score_buf, 0, 0);
    w4.text(&p2_score_buf, w4.SCREEN_SIZE - 8, 0);
}

export fn update() void {
    main_game_loop();
    if (timer < gc.RESTART_FRAME_WAIT) {
        timer += 1;
        if (gc.RESTART_FRAME_WAIT / 2 <= timer and timer < gc.RESTART_FRAME_WAIT * 4/6) {
            w4.DRAW_COLORS.* = 2;
            w4.text("Start in 3..", 40, 50);
        }
        else if (gc.RESTART_FRAME_WAIT * 4 / 6 <= timer and timer < gc.RESTART_FRAME_WAIT * 5/6) {
            w4.DRAW_COLORS.* = 2;
            w4.text("Start in 2..", 40, 50);
        } else if (gc.RESTART_FRAME_WAIT * 5 / 6 <= timer) {
            w4.DRAW_COLORS.* = 2;
            w4.text("Start in 1..", 40, 50);
        }
    } else {
        move_ball();
    }
    
}
