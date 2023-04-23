const w4 = @import("wasm4.zig");
const std = @import("std");
const gr = @import("graphics.zig");
const gc = @import("game_constants.zig");
const pd = @import("paddles.zig");
const bl = @import("ball.zig");
const sm = @import("smoke.zig");

var side1_score: i32 = 0;
var side2_score: i32 = 0;
var timer: u32 = 0;
var is_cpu: bool = true;
var framecount: u16 = 0;

const N_PLAYERS = 4;

const PlayerNum = enum {
    one,
    two,
    three,
    four
};

const Player = struct {
    current_dir_input: pd.Paddle_dirs,
    current_action_input: pd.Paddle_button_action,
    is_cpu_controlled: bool,
    is_active: bool,
    which_side: pd.Side,
    which_gamepad: *const u8,
    paddle: *pd.Paddle,
    num: PlayerNum,
};

var players: [4]Player = [4]Player{
    Player{
        .current_dir_input = pd.Paddle_dirs.no_move,
        .current_action_input = pd.Paddle_button_action.none,
        .is_cpu_controlled = true,
        .is_active = true,
        .which_side = pd.Side.left,
        .which_gamepad = w4.GAMEPAD1,
        .paddle = &pd.p1,
        .num = PlayerNum.one,
    },
    Player{
        .current_dir_input = pd.Paddle_dirs.no_move,
        .current_action_input = pd.Paddle_button_action.none,
        .is_cpu_controlled = true,
        .is_active = true,
        .which_side = pd.Side.right,
        .which_gamepad = w4.GAMEPAD2,
        .paddle = &pd.p2,
        .num = PlayerNum.two,
    },
    Player{
        .current_dir_input = pd.Paddle_dirs.no_move,
        .current_action_input = pd.Paddle_button_action.none,
        .is_cpu_controlled = true,
        .is_active = false,
        .which_side = pd.Side.left,
        .which_gamepad = w4.GAMEPAD3,
        .paddle = &pd.p3,
        .num = PlayerNum.three,
    },
    Player{
        .current_dir_input = pd.Paddle_dirs.no_move,
        .current_action_input = pd.Paddle_button_action.none,
        .is_cpu_controlled = true,
        .is_active = false,
        .which_side = pd.Side.right,
        .which_gamepad = w4.GAMEPAD4,
        .paddle = &pd.p4,
        .num = PlayerNum.four,
    },
};

var current_p1_dir: pd.Paddle_dirs = pd.Paddle_dirs.no_move;
var current_p2_dir: pd.Paddle_dirs = pd.Paddle_dirs.no_move;

var current_p1_action_input: pd.Paddle_button_action = pd.Paddle_button_action.none;
var current_p2_action_input: pd.Paddle_button_action = pd.Paddle_button_action.none;

fn is_colliding(ball: *bl.Ball, paddle: *const pd.Paddle) bool {
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


    w4.PALETTE.* = gr.pallete;
    reset_ball_and_paddles();
}

fn center_paddle_y(y: f16) f16 {
    return y - @intToFloat(f16, gr.paddle.height) / 2;
}

fn get_paddle_start_y(player: *const Player) f16 {
    switch (player.num) {
        .one => {
            return switch(players[2].is_active) {
                true => return center_paddle_y(w4.SCREEN_SIZE / 4),
                false => return center_paddle_y(@intToFloat(f16,w4.SCREEN_SIZE) / 2),
            };
        },
        .two => {
            return switch(players[3].is_active) {
                true => return center_paddle_y(w4.SCREEN_SIZE / 4),
                false => return center_paddle_y(@intToFloat(f16, w4.SCREEN_SIZE) / 2),
            };
        },
        else => return center_paddle_y(3 * @intToFloat(f16, w4.SCREEN_SIZE) / 4)
    }
}

fn reset_ball_and_paddles() void {
    // bl.ball.vx = 1.0;
    // bl.ball.vy = 0.0;

    var rnd = std.rand.DefaultPrng.init(framecount);

    var dir: f16 = 90;
    while (!(360 - gc.SERVE_ANGLE_VARIATION <= dir or dir <= gc.SERVE_ANGLE_VARIATION or (180 - gc.SERVE_ANGLE_VARIATION <= dir and dir <= 180 + gc.SERVE_ANGLE_VARIATION))) {
        dir = @intToFloat(f16, @mod(rnd.random().int(u16), 360));
    }

    const mag: f16 = gc.SERVE_MAGNITUDE;
    bl.ball.vx = @cos(dir * 3.14 / 180) * mag;
    bl.ball.vy = @sin(dir * 3.14 / 180) * mag;

    bl.ball.x = bl.ball_start_x - @intToFloat(f16, gr.ball.width) / 2;
    bl.ball.y = bl.ball_start_y - @intToFloat(f16, gr.ball.height) / 2;

    for (players) |player| {
        player.paddle.y = pd.paddle_start_y - @intToFloat(f16, gr.paddle.height) / 2;
        player.paddle.y = get_paddle_start_y(&player);
    }
    // pd.p1.y = pd.paddle_start_y - @intToFloat(f16, gr.paddle.height) / 2;
    // pd.p2.y = pd.paddle_start_y - @intToFloat(f16, gr.paddle.height) / 2;
    timer = 0;
}

fn handle_ball_colliding_with_paddle(player: *Player) void {
    // ball off paddle physics
    if (is_colliding(&bl.ball, player.paddle)) {
        bl.ball.vx *= -1 * gc.BALL_BOUNCEBACK_VX_MULT;
        bl.ball.vy += gc.PADDLE_TRANSFER_VY_MULT * player.paddle.vy;
        bl.ball.spin += gc.BALL_SPIN_VAL_MULT * player.paddle.vy;
        bl.ball.vx -= std.math.fabs(gc.PADDLE_TRANSFER_VY_MULT * gc.PADDLE_TRANSFER_VY_MULT * player.paddle.vy);
        if (player.paddle.anim.anim_timer < gc.PADDLE_LUNGE_CATCHBACK_DURATION) {
            bl.ball.vx *= switch (player.paddle.anim.current_state) {
                pd.Paddle_states.lunge => gc.PADDLE_LUNGE_MULT,
                pd.Paddle_states.catchback => gc.PADDLE_CATCHBACK_MULT,
                else => 1,
            };
        }

        bl.ball.x += pd.side_mult(player.paddle.side) * (gc.PADDLE_BOUNCEBACK_DIST + 1);
        pd.animate_paddle(player.paddle, player.current_dir_input, player.current_action_input, true);
    }
}

fn move_ball() void {

    for (&players) |*player| {
        if(player.is_active) {
            handle_ball_colliding_with_paddle(player);
        }
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
        side2_score += 1;
    }
    else if(bl.ball.x > w4.SCREEN_SIZE - gr.ball.width) {
        reset_ball_and_paddles();
        side1_score += 1;
    }

    bl.ball.smoke_timer += 1;
    if (bl.ball.smoke_timer >= gc.BALL_SMOKE_INTERVAL) {
        bl.ball.smoke_timer = 0;
        sm.spawn_smoke(bl.ball.x + @intToFloat(f16, gr.ball.width) / 2, bl.ball.y + @intToFloat(f16, gr.ball.width) / 2, -1 * gc.BALL_SMOKE_OUTSPEED_MULT * bl.ball.vx, -1 * gc.BALL_SMOKE_OUTSPEED_MULT * bl.ball.vy);
    }
}

fn gamepad_input(player: *Player) void {

    if (player.which_gamepad.* & w4.BUTTON_UP != 0) {
        player.current_dir_input = pd.Paddle_dirs.up;   
    } else if (player.which_gamepad.* & w4.BUTTON_DOWN != 0) {
        player.current_dir_input = pd.Paddle_dirs.down;
    } else {
        if (!player.is_cpu_controlled) {
            player.current_dir_input = pd.Paddle_dirs.no_move;
        }
    }

    if (player.which_gamepad.* & w4.BUTTON_1 != 0) {
        player.current_action_input = pd.Paddle_button_action.lunge;
    } else if (player.which_gamepad.* & w4.BUTTON_2 != 0) {
        player.current_action_input = pd.Paddle_button_action.catchback;
    } else {
        player.current_action_input = pd.Paddle_button_action.none;
    }

    if (player.is_cpu_controlled) {
        var p_center = player.paddle.y + @intToFloat(f16, gr.paddle.height) / 2;
        var ball_center = bl.ball.y + @intToFloat(f16,gr.ball.height) / 2;
        if (p_center < ball_center - gc.CPU_TARGET_SPOT_TOL) {
            player.current_dir_input = pd.Paddle_dirs.down;
        } else if(p_center > ball_center + gc.CPU_TARGET_SPOT_TOL){
            player.current_dir_input = pd.Paddle_dirs.up;
        } else {
            player.current_dir_input = pd.Paddle_dirs.no_move;
        }
    }
}

fn main_game_loop() void {

    // draw our game title at the top while playing
    w4.DRAW_COLORS.* = 3;
    w4.text(gc.GAME_NAME, gc.TITLE_LOC + 1, 0);
    w4.DRAW_COLORS.* = 2;
    w4.text(gc.GAME_NAME, gc.TITLE_LOC, 0);

    w4.DRAW_COLORS.* = gr.ping.draw_colors;
    // w4.blit(&gr.ping_img, 60, 0, gr.ping.width, gr.ping.height, gr.ping.flags);

    for(&players) |*player| {
        if (player.which_gamepad.* != 0) {
            player.is_cpu_controlled = false;
            player.is_active = true;
        }
        if(player.is_active) {
            gamepad_input(player);
            pd.update_paddle(player.paddle, player.current_dir_input);       
            pd.animate_paddle(player.paddle, player.current_dir_input, player.current_action_input, false);
        }
    }

    
    bl.ball.y_int = @floatToInt(i32, bl.ball.y);
    bl.ball.x_int = @floatToInt(i32, bl.ball.x);


    var side1_score_buf: [2]u8 = .{0x0,0x0};
    _ = std.fmt.bufPrint(&side1_score_buf, "{d}", .{side1_score}) catch undefined;
    var side2_score_buf: [2]u8 = .{0x0,0x0};
    _ = std.fmt.bufPrint(&side2_score_buf, "{d}", .{side2_score}) catch undefined;

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


    for (&players) |*player| {
        if (player.is_active) {
            w4.DRAW_COLORS.* = player.paddle.anim.current_sprite_data.draw_colors; 
            w4.blit(player.paddle.anim.current_image, player.paddle.x_int, player.paddle.y_int, player.paddle.anim.current_sprite_data.width, player.paddle.anim.current_sprite_data.height, player.paddle.anim.current_sprite_data.flags);
        }
       }

    w4.DRAW_COLORS.* = gr.ball.draw_colors;
    w4.blit(&gr.ball_image, bl.ball.x_int, bl.ball.y_int, gr.ball.width, gr.ball.height, gr.ball.flags);
    w4.DRAW_COLORS.* = 0x03;
    w4.text(&side1_score_buf, 0, 0);
    w4.text(&side2_score_buf, w4.SCREEN_SIZE - 16, 0);
}

export fn update() void {
    framecount = @mod(framecount + 1, gc.LARGE_NUM_FOR_SEEDING_MOD);
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
