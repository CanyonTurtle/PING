const w4 = @import("wasm4.zig");
const std = @import("std");
const gr = @import("graphics.zig");
const gc = @import("game_constants.zig");
const pd = @import("paddles.zig");
const bl = @import("ball.zig");
const sm = @import("smoke.zig");
const hd = @import("hover_display.zig");
const cpus = @import("cpu_player.zig");

var side1_score: i32 = 0;
var side2_score: i32 = 0;
var round_timer: u32 = 0;
var is_cpu: bool = true;
var framecount: u16 = 0;

const N_PLAYERS = 4;

const GameStates = enum {
    bootup,
    title_screen,
    main_game,
    options,
    about,
};

const SingleRoundState = enum {
    init_match,
    init_game,
    countdown,
    playing,
    someone_scored,
    someone_won_game,
    someone_won_match,
};

const Match = struct {
    num: u8,
    side1_match_score: u8,
    side1_game_score: u8,
    side2_match_score: u8,
    side2_game_score: u8,
    did_side1_win: bool,
};

var match = Match {
    .num = 1,
    .side1_match_score = 0,
    .side1_game_score = 0,
    .side2_match_score = 0,
    .side2_game_score = 0,
    .did_side1_win = false,
};

var game_state: GameStates = GameStates.bootup;
var round_state: SingleRoundState = SingleRoundState.init_game;

const PlayerNum = enum { one, two, three, four };

fn get_pnum_as_int(player_num: PlayerNum) u16 {
    return switch (player_num) {
        .one => 1,
        .two => 2,
        .three => 3,
        .four => 4,
    };
}

const Player = struct {
    current_dir_input: pd.Paddle_dirs,
    current_action_input: pd.Paddle_button_action,
    is_cpu_controlled: bool,
    is_active: bool,
    which_side: pd.Side,
    which_gamepad: *const u8,
    paddle: *pd.Paddle,
    num: PlayerNum,
    cpu: cpus.CpuPlayer,
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
        .cpu = cpus.defaultCpuPlayer,
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
        .cpu = cpus.defaultCpuPlayer,
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
        .cpu = cpus.defaultCpuPlayer,
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
        .cpu = cpus.defaultCpuPlayer,
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
        } else if (ball.vx <= 0 and ball.x <= paddle_right_x and ball_right_x > paddle.x) {
            return true;
        }
    }
    return false;
}

fn my_start() void {}

fn center_paddle_y(y: f16) f16 {
    return y - @intToFloat(f16, gr.paddle.height) / 2;
}

fn get_paddle_start_y(player: *const Player) f16 {
    switch (player.num) {
        .one => {
            return switch (players[2].is_active) {
                true => return center_paddle_y(w4.SCREEN_SIZE / 4),
                false => return center_paddle_y(@intToFloat(f16, w4.SCREEN_SIZE) / 2),
            };
        },
        .two => {
            return switch (players[3].is_active) {
                true => return center_paddle_y(w4.SCREEN_SIZE / 4),
                false => return center_paddle_y(@intToFloat(f16, w4.SCREEN_SIZE) / 2),
            };
        },
        else => return center_paddle_y(3 * @intToFloat(f16, w4.SCREEN_SIZE) / 4),
    }
}

fn reset_and_start_new_round() void {

    // bl.ball.vx = 1.0;
    // bl.ball.vy = 0.0;
    rally_count = 0;
    var rnd = std.rand.DefaultPrng.init(framecount);
    var rint: u16 = 0;
    var dir: f16 = 90;
    while (!(360 - gc.SERVE_ANGLE_VARIATION <= dir or dir <= gc.SERVE_ANGLE_VARIATION or (180 - gc.SERVE_ANGLE_VARIATION <= dir and dir <= 180 + gc.SERVE_ANGLE_VARIATION))) {
        rint = rnd.random().int(u16);
        dir = @intToFloat(f16, @mod(rint, 360));
    }

    const mag: f16 = gc.SERVE_MAGNITUDE;
    bl.ball.vx = @cos(dir * 3.14 / 180) * mag;
    bl.ball.vy = @sin(dir * 3.14 / 180) * mag;

    bl.ball.x = bl.ball_start_x - @intToFloat(f16, gr.ball.width) / 2;
    bl.ball.y = bl.ball_start_y - @intToFloat(f16, gr.ball.height) / 2;
    bl.ball.x_int = @floatToInt(i32, bl.ball.x);
    bl.ball.y_int = @floatToInt(i32, bl.ball.y);

    for (players) |player| {
        player.paddle.y = pd.paddle_start_y - @intToFloat(f16, gr.paddle.height) / 2;
        player.paddle.y = get_paddle_start_y(&player);
    }
    // pd.p1.y = pd.paddle_start_y - @intToFloat(f16, gr.paddle.height) / 2;
    // pd.p2.y = pd.paddle_start_y - @intToFloat(f16, gr.paddle.height) / 2;

    bl.ball.spin_cap = 0;
    bl.ball.spin = 0;

    if (game_state == GameStates.main_game) {
        hd.reset_hover_display(4, false);
    }

    // gr.pallete = gr.pallete_list[@mod(rint, gr.pallete_list.len - 1)];
    // w4.PALETTE.* = gr.pallete.*;
}

var color_handle: u16 = hd.NOIDX;
var starting_handle: u16 = hd.NOIDX;
var rally_handle: u16 = hd.NOIDX;
var match_win_handle: u16 = hd.NOIDX;

var rally_count: u16 = 0;

pub fn reset_text_handles() void {
    color_handle = hd.NOIDX;
    starting_handle = hd.NOIDX;
    rally_handle = hd.NOIDX;
    match_win_handle = hd.NOIDX;

}



fn handle_ball_colliding_with_paddle(player: *Player) void {
    // ball off paddle physics
    if (is_colliding(&bl.ball, player.paddle)) {

        // add some rng to the y vel. for preventing standstills
        var rnd = std.rand.DefaultPrng.init(framecount);

        var rand_vy_add = @intToFloat(f16, @mod(rnd.random().int(i16), 10) - 5);
        bl.ball.vy += rand_vy_add * gc.PADDLE_RANDOM_VY_MULT;

        bl.ball.vx *= -1 * gc.BALL_BOUNCEBACK_VX_MULT;
        bl.ball.vy += gc.PADDLE_TRANSFER_VY_MULT * player.paddle.vy;
        bl.ball.spin_cap = gc.BALL_SPIN_VAL_MULT * player.paddle.vy;
        bl.ball.vx -= std.math.fabs(gc.PADDLE_TRANSFER_VY_MULT * gc.PADDLE_TRANSFER_VY_MULT * player.paddle.vy);
        if (player.paddle.anim.anim_timer < gc.PADDLE_LUNGE_CATCHBACK_DURATION) {
            bl.ball.vx *= switch (player.paddle.anim.current_state) {
                pd.Paddle_states.lunge => gc.PADDLE_LUNGE_MULT,
                pd.Paddle_states.catchback => gc.PADDLE_CATCHBACK_SPEED_MULT,
                else => 1,
            };
            bl.ball.spin_cap *= switch (player.paddle.anim.current_state) {
                pd.Paddle_states.catchback => gc.PADDLE_CATCHBACK_SPIN_MULT,
                else => 1,
            };
            // no action messages on title sequence
            if (game_state == GameStates.main_game) {
                switch (player.paddle.anim.current_state) {
                    .lunge => {
                        // hd.display_msg(hd.DisplayMessageType.lunge);
                        _ = hd.display_msg(hd.NOIDX, "Lunge!      ".*, 50, &hd.lunge_tf);
                    },
                    .catchback => {
                        _ = hd.display_msg(hd.NOIDX, "Catch!      ".*, 50, &hd.catchback_tf);
                    },
                    else => {},
                }
            }
        }

        bl.ball.x += pd.side_mult(player.paddle.side) * (gc.PADDLE_BOUNCEBACK_DIST + 1);
        pd.animate_paddle(player.paddle, player.current_dir_input, player.current_action_input, true);
        // no action messages on title sequence
        if (game_state == GameStates.main_game) {
            // hd.display_msg(hd.DisplayMessageType.rally);
            rally_count += 1;
            if (rally_count >= 5) {
                rally_handle = hd.display_msg(rally_handle, "   Rally X  ".*, hd.INF_DURATION, &hd.normal_tf);
                _ = std.fmt.bufPrint(hd.hover_display.message_ringbuffer[rally_handle].text[9..10], "{d}", .{rally_count}) catch undefined;
            }
            
        }

        // mu.play_paddle_hit();
    }
}

fn move_ball() void {
    for (&players) |*player| {
        if (player.is_active) {
            handle_ball_colliding_with_paddle(player);
        }
    }

    if (bl.ball.y < 0) {
        bl.ball.y = 0;
        bl.ball.vy *= -1;
        bl.ball.spin_cap *= -1 * gc.BALL_SPIN_CAP_OFF_WALL_REDUCTION_MULT;
        bl.ball.spin *= -1 * gc.BALL_SPIN_OFF_WALL_REDUCTION_MULT;
    } else if (bl.ball.y > w4.SCREEN_SIZE - gr.ball.height) {
        bl.ball.y = w4.SCREEN_SIZE - gr.ball.height;
        bl.ball.vy *= -1;
        bl.ball.spin_cap *= -1 * gc.BALL_SPIN_CAP_OFF_WALL_REDUCTION_MULT;
        bl.ball.spin *= -1 * gc.BALL_SPIN_OFF_WALL_REDUCTION_MULT;
    }

    if (bl.ball.vx > gc.BALL_MAX_VX) {
        bl.ball.vx = gc.BALL_MAX_VX;
    }
    if (bl.ball.vx < -1 * gc.BALL_MAX_VX) {
        bl.ball.vx = -1 * gc.BALL_MAX_VX;
        bl.ball.spin_cap = 0;
        bl.ball.spin = 0;
    }

    bl.ball.y += bl.ball.spin * gc.BALL_SPIN_ACCEL_MULT;

    if (std.math.fabs(bl.ball.spin) < std.math.fabs(bl.ball.spin_cap)) {
        bl.ball.spin += (bl.ball.spin_cap - bl.ball.spin) * gc.BALL_SPIN_GROWTH_MULT;
    }

    bl.ball.x += bl.ball.vx;
    bl.ball.y += bl.ball.vy;

    if (bl.ball.x < 0) {
        round_state = SingleRoundState.someone_scored;
        if(game_state == GameStates.main_game) {
            round_timer = 0;
            match.side2_game_score += 1;
        }

    } else if (bl.ball.x > w4.SCREEN_SIZE - gr.ball.width) {
        round_state = SingleRoundState.someone_scored;
        if(game_state == GameStates.main_game) {
            round_timer = 0;
            match.side1_game_score += 1;
        }
    }

    bl.ball.smoke_timer += 1;
    if (bl.ball.smoke_timer >= gc.BALL_SMOKE_INTERVAL) {
        bl.ball.smoke_timer = 0;
        sm.spawn_smoke(bl.ball.x + @intToFloat(f16, gr.ball.width) / 2, bl.ball.y + @intToFloat(f16, gr.ball.width) / 2, -1 * gc.BALL_SMOKE_OUTSPEED_MULT * bl.ball.vx, -1 * gc.BALL_SMOKE_OUTSPEED_MULT * bl.ball.vy);
    }

    bl.ball.y_int = @floatToInt(i32, bl.ball.y);
    bl.ball.x_int = @floatToInt(i32, bl.ball.x);
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
        var paddle_center_x = player.paddle.x + @intToFloat(f16, gr.paddle.width) / 2;
        var paddle_center_y = player.paddle.y + @intToFloat(f16, gr.paddle.height) / 2;
        var ball_center_x = bl.ball.x + @intToFloat(f16, gr.ball.width) / 2;
        var ball_center_y = bl.ball.y + @intToFloat(f16, gr.ball.height) / 2;

        cpus.updateCpuDecision(&player.cpu, paddle_center_x, paddle_center_y, ball_center_x, ball_center_y, framecount + get_pnum_as_int(player.num) * 1000);

        player.current_action_input = player.cpu.current_action_input;
        player.current_dir_input = player.cpu.current_dir_input;
    }
}

fn draw_font(text: []const u8, x: i32, y: i32, font: *const hd.TextFont) void {
    if (font.tertiary != 0) {
        w4.DRAW_COLORS.* = font.tertiary;
        w4.text(text, x + 2, y + 2);
    }
    if (font.secondary != 0) {
        w4.DRAW_COLORS.* = font.secondary;
        w4.text(text, x + 1, y + 1);
    }
    w4.DRAW_COLORS.* = font.primary;
    w4.text(text, x, y);
}

fn draw_screen() void {
    var i: u16 = 0;
    while (i < gc.N_SMOKES_RINGBUFFER) {
        var s: *sm.Smoke = &sm.smokes[i];
        if (s.is_active) {
            w4.DRAW_COLORS.* = s.sprite_data.draw_colors;
            s.x_int = @floatToInt(i32, s.x);
            s.y_int = @floatToInt(i32, s.y);
            w4.blit(s.image, s.x_int, s.y_int, s.sprite_data.width, s.sprite_data.height, s.sprite_data.flags);
        }
        i += 1;
    }

    if (game_state == GameStates.main_game) {
        // draw our game title at the top while playing
        w4.DRAW_COLORS.* = 3;
        w4.text(gc.GAME_NAME, gc.TITLE_LOC + 1, 1);
        w4.DRAW_COLORS.* = 2;
        w4.text(gc.GAME_NAME, gc.TITLE_LOC, 0);

        w4.DRAW_COLORS.* = gr.hover_display_draw_colors;
        // w4.text(gc.VERSION, gc.TITLE_LOC + 8 * 5, 0);

        var side1_score_buf: [2]u8 = .{ 0x0, 0x0 };
        _ = std.fmt.bufPrint(&side1_score_buf, "{d}", .{match.side1_game_score}) catch undefined;
        var side2_score_buf: [2]u8 = .{ 0x0, 0x0 };
        _ = std.fmt.bufPrint(&side2_score_buf, "{d}", .{match.side2_game_score}) catch undefined;

        if (round_state == SingleRoundState.someone_scored) {
            if (@mod(round_timer / 2, 10) < 3) {
                if (bl.ball.x < 60) {  
                    w4.text(&side1_score_buf, 0, 0);
                } else {
                    w4.text(&side2_score_buf, w4.SCREEN_SIZE - 16, 0);
                }
                
            } else {
                w4.text(&side1_score_buf, 0, 0);
                w4.text(&side2_score_buf, w4.SCREEN_SIZE - 16, 0);
            }

        } else {
            w4.text(&side1_score_buf, 0, 0);
            w4.text(&side2_score_buf, w4.SCREEN_SIZE - 16, 0);
        }
        
    }

    // w4.text(gc.VERSION, w4.SCREEN_SIZE - 8 * 5, w4.SCREEN_SIZE - 8);

    if (hd.hover_display.is_active) {
        for (&hd.hover_display.message_ringbuffer) |*message| {
            if (message.is_active) {
                draw_font(&message.text, gc.HOVER_DISPLAY_X, message.y_int, message.text_font);
                // w4.text(&message.text, gc.HOVER_DISPLAY_X, message.y_int);
            }
        }
        // speed meter

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

    if (hd.hover_display.cursor.menumode_enabled) {
        if (hd.hover_display.cursor.blink_state) {
            draw_font(&hd.hover_display.cursor.current_text, hd.hover_display.cursor.x_int, hd.hover_display.cursor.y_int + hd.hover_display.cursor.current_selection * gc.HOVER_DISPLAY_Y_DIST_BETWEEN_LINES, hd.hover_display.cursor.font);
        }
    }
}

// handles moving the cursor,
// and if a menu option is pressed,
// it will return the new game state.
var menu_input: u8 = 0;
var prev_menu_input: u8 = 0;
const MENU_NOTHING_SELECTED = 255;

fn get_menu_option() u8 {
    menu_input = w4.GAMEPAD1.*;
    var menu_input_this_frame: u8 = menu_input & (menu_input ^ prev_menu_input);
    prev_menu_input = menu_input;

    var offs: i8 = 0;
    if (menu_input_this_frame & w4.BUTTON_DOWN != 0) {
        offs = 1;

    } else if (menu_input_this_frame & w4.BUTTON_UP != 0) {
        offs = -1;
    } else if (menu_input_this_frame & (w4.BUTTON_1 | w4.BUTTON_2) != 0) {
        return hd.hover_display.cursor.current_selection;
    }

    // 2 options will be used up by the menu name
    hd.hover_display.cursor.current_selection = @intCast(u8, @mod(@intCast(i16, hd.hover_display.cursor.current_selection) + offs, @intCast(i16, hd.hover_display.effective_length) - 2));
    if (offs != 0) {
        hd.hover_display.cursor.blink_state = true;
        hd.hover_display.cursor.blink_timer = 0;
    }
    return MENU_NOTHING_SELECTED;
    // return GameStates.main_game;
}

var bootup_timer: u32 = 0;
var options_timer: u32 = 0;

const divide_line_text = "------------";
const back_text = "<-- Back    ";


export fn update() void {
    switch (game_state) {
        .bootup => {
            // The reason this is here is because of a
            // workaround to avoid https://github.com/aduros/wasm4/issues/542
            w4.PALETTE.* = gr.pallete.*;

            game_state = GameStates.title_screen;
            round_state = SingleRoundState.init_game;
            round_timer = 0;
        },
        .title_screen => {
            if (bootup_timer < gc.BOOTUP_TIME) {    
                bootup_timer += 1;
            } else if (bootup_timer == gc.BOOTUP_TIME) {
                reset_text_handles();
                hd.reset_hover_display(4, true);
                _ = hd.display_msg(hd.NOIDX, gc.GAME_NAME.* ++ "        ".*, hd.INF_DURATION, &hd.title_tf);
                _ = hd.display_msg(hd.NOIDX, divide_line_text.*, hd.INF_DURATION, &hd.normal_tf);
                _ = hd.display_msg(hd.NOIDX, "Play        ".*, hd.INF_DURATION, &hd.normal_tf);
                _ = hd.display_msg(hd.NOIDX, "Options     ".*, hd.INF_DURATION, &hd.normal_tf);
                // hd.display_msg(hd.DisplayMessageType.title_title);
                // hd.display_msg(hd.DisplayMessageType.divider_line);
                // hd.display_msg(hd.DisplayMessageType.title_play);
                // hd.display_msg(hd.DisplayMessageType.title_options);

                bootup_timer += 1;
                
            } else if (bootup_timer > gc.BOOTUP_TIME and bootup_timer < gc.BOOTUP_TIME + 30) {
                bootup_timer += 1;
                // mu.start_song(&mu.song_1);
            } else {
                hd.blink_cursor();

                var option_selected: u8 = get_menu_option();

                switch (option_selected) {
                    0 => {
                        players[0].is_cpu_controlled = false;
                        players[0].is_active = true;
                        game_state = GameStates.main_game;
                        round_state = SingleRoundState.init_match;
                        round_timer = 0;
                    },
                    1 => {
                        game_state = GameStates.options;
                        options_timer = 0;
                    },
                    else => {
                        
                    },
                }
            }
        },
        .main_game => {
            for (&players) |*player| {
                if (player.which_gamepad.* != 0) {
                    player.is_cpu_controlled = false;
                    player.is_active = true;
                }
            }
        },
        .options => {  
            if (options_timer == 0) {
                reset_text_handles();
                options_timer += 1;
                hd.reset_hover_display(5, true);
                _ = hd.display_msg(hd.NOIDX, "Options     ".*, hd.INF_DURATION, &hd.title_tf);
                _ = hd.display_msg(hd.NOIDX, divide_line_text.*, hd.INF_DURATION, &hd.normal_tf);
                color_handle = hd.display_msg(hd.NOIDX, "Color (x/x) ".*, hd.INF_DURATION, &hd.normal_tf);
                _ = hd.display_msg(hd.NOIDX, "About       ".*, hd.INF_DURATION, &hd.normal_tf);
                _ = hd.display_msg(hd.NOIDX, back_text.*, hd.INF_DURATION, &hd.normal_tf);

                // hd.display_msg(hd.DisplayMessageType.options_options);
                // hd.display_msg(hd.DisplayMessageType.divider_line);
                // hd.display_msg(hd.DisplayMessageType.options_pallete_rotate);
                // hd.display_msg(hd.DisplayMessageType.options_about);
                // hd.display_msg(hd.DisplayMessageType.back);

            } else {
                hd.blink_cursor();

                var option_selected: u8 = get_menu_option();

                switch (option_selected) {
                    0 => {
                        gr.pallete_idx = @mod(gr.pallete_idx + 1, @intCast(u16, gr.pallete_list.len));
                        w4.PALETTE.* = gr.pallete_list[gr.pallete_idx].*;
                        _ = std.fmt.bufPrint(hd.hover_display.message_ringbuffer[color_handle].text[7..8], "{d}", .{gr.pallete_idx + 1}) catch undefined;
                        _ = std.fmt.bufPrint(hd.hover_display.message_ringbuffer[color_handle].text[9..10], "{d}", .{gr.pallete_list.len}) catch undefined;
                    },
                    1 => {
                        game_state = GameStates.about;
                        options_timer = 0;
                    },
                    2 => {
                        game_state = GameStates.title_screen;
                        bootup_timer = gc.BOOTUP_TIME;
                    },
                    else => {
                        
                    },
                }
            }
        },
        .about => {
            
            if (options_timer == 0) {
                reset_text_handles();
                options_timer += 1;
                hd.reset_hover_display(6, true);

                _ = hd.display_msg(hd.NOIDX, "About       ".*, hd.INF_DURATION, &hd.title_tf);
                _ = hd.display_msg(hd.NOIDX, divide_line_text.*, hd.INF_DURATION, &hd.normal_tf);
                _ = hd.display_msg(hd.NOIDX, "Author:     ".*, hd.INF_DURATION, &hd.normal_tf);
                _ = hd.display_msg(hd.NOIDX, "CanyonTurtle".*, hd.INF_DURATION, &hd.normal_tf);
                _ = hd.display_msg(hd.NOIDX, gc.VERSION.* ++ "      ".*, hd.INF_DURATION, &hd.normal_tf);
                _ = hd.display_msg(hd.NOIDX, back_text.*, hd.INF_DURATION, &hd.normal_tf);


                // hd.display_msg(hd.DisplayMessageType.about_about);
                // hd.display_msg(hd.DisplayMessageType.divider_line);
                // hd.display_msg(hd.DisplayMessageType.about_author_label);
                // hd.display_msg(hd.DisplayMessageType.about_author);
                // hd.display_msg(hd.DisplayMessageType.about_version);
                // hd.display_msg(hd.DisplayMessageType.back);

            } else {
                hd.blink_cursor();

                var option_selected: u8 = get_menu_option();

                switch (option_selected) {
                    3 => {
                        game_state = GameStates.title_screen;
                        bootup_timer = gc.BOOTUP_TIME;
                    },
                    else => {
                        
                    },
                }
            }
        },
    }

    // controls for the main player
    switch (game_state) {
        .main_game => {
            switch (round_state) {
                .init_match => {
                    
                    if (round_timer == 0) {
                        match.num = 1;
                        reset_text_handles();
                        reset_and_start_new_round();
                        hd.reset_hover_display(4, false);
                        _ = hd.display_msg(hd.NOIDX, "Match Start!".*, 120, &hd.title_tf);
                        var h1 = hd.display_msg(hd.NOIDX, "- best of X ".*, 120, &hd.normal_tf);
                        var h2 = hd.display_msg(hd.NOIDX, "- play to X ".*, 120, &hd.normal_tf);

                        _ = std.fmt.bufPrint(hd.hover_display.message_ringbuffer[h1].text[10..11], "{d}", .{gc.MATCH_WIN_COUNT * 2 - 1}) catch undefined;
                        _ = std.fmt.bufPrint(hd.hover_display.message_ringbuffer[h2].text[10..11], "{d}", .{gc.GAME_POINT_WIN_COUNT}) catch undefined;
                        // hd.display_msg(hd.DisplayMessageType.match_start);
                        round_timer += 1;
                    }
                    else if(round_timer >= 120) {
                        round_state = SingleRoundState.init_game;
                        round_timer = 0;
                    } else {
                        round_timer += 1;
                    }  
                },
                .init_game => {
                    
                    if (round_timer == 0) {
                        reset_text_handles();
                        reset_and_start_new_round();
                        hd.reset_hover_display(4, false);
                        var handle = hd.display_msg(hd.NOIDX, "   GAME X   ".*, 50, &hd.title_tf);
                        _ = std.fmt.bufPrint(hd.hover_display.message_ringbuffer[handle].text[8..9], "{d}", .{match.num}) catch undefined;
                        // hd.display_msg(hd.DisplayMessageType.game_start);
                        round_timer += 1;
                    }
                    else if(round_timer >= 70) {
                        round_state = SingleRoundState.countdown;
                        round_timer = 0;
                    } else {
                        round_timer += 1;
                    }    
                },
                .countdown => {
                    
                    if (round_timer == 0) {
                        reset_text_handles();
                        reset_and_start_new_round();
                        round_timer += 1;
                    } else if (round_timer < gc.RESTART_FRAME_WAIT) {
                        round_timer += 1;
                        if (round_timer == 30 or round_timer == 60 or round_timer == 90 or round_timer == 120) {
                            // hd.display_msg(hd.DisplayMessageType.starting);
                            starting_handle = hd.display_msg(starting_handle, "Start in X..".*, 50, &hd.title_tf);
                            _ = std.fmt.bufPrint(hd.hover_display.message_ringbuffer[starting_handle].text[9..10], "{d}", .{@as(u8, (120 - @intCast(u8, round_timer)) / 30)}) catch undefined;
                            if (round_timer == 120) {
                                _ = std.fmt.bufPrint(hd.hover_display.message_ringbuffer[starting_handle].text[0..12], "   Go!!!    ", .{}) catch undefined;
                            }
                        }
                    } else {
                        round_state = SingleRoundState.playing;
                    }
                },
                .playing => {
                    move_ball();
                },

                // when a score is detected, we will transition to here
                .someone_scored => {
                    if(round_timer == 0) {
                        if (match.side1_game_score >= gc.GAME_POINT_WIN_COUNT) {
                            match.side1_match_score += 1;
                            round_state = SingleRoundState.someone_won_game;
                            round_timer = 0;
                        } else if (match.side2_game_score >= gc.GAME_POINT_WIN_COUNT) {
                            match.side2_match_score += 1;
                            round_state = SingleRoundState.someone_won_game;
                            round_timer = 0;
                        } else {
                            // hd.display_msg(hd.DisplayMessageType.point);   
                            _ = hd.display_msg(hd.NOIDX, "POINT!      ".*, 60, &hd.title_tf);
                            round_timer += 1;    
                        }  
                    } else if (round_timer < 70) {
                        round_timer += 1;
                    } else {
                        round_timer = 0;
                        round_state = SingleRoundState.countdown;
                    }
                },
                .someone_won_game => {
                    if(round_timer == 0) {
                        match.num += 1;
                        if (match.side1_match_score >= gc.MATCH_WIN_COUNT) {
                            match.did_side1_win = true;
                            round_state = SingleRoundState.someone_won_match;
                            round_timer = 0;
                        } else if (match.side2_game_score >= gc.MATCH_WIN_COUNT) {
                            match.did_side1_win = false;
                            round_state = SingleRoundState.someone_won_match;
                            round_timer = 0;
                        } else {
                            // hd.display_msg(hd.DisplayMessageType.game_end);   
                            _ = hd.display_msg(hd.NOIDX, "   GAME!    ".*,60, &hd.title_tf);
                            round_timer += 1;    
                        }  

                    } else if (round_timer < 70) {
                        round_timer += 1;
                    } else {
                        round_timer = 0;
                        round_state = SingleRoundState.init_game;
                    } 
                },
                .someone_won_match => {
                    if(round_timer == 0) {
                        hd.reset_hover_display(3, true);
                        match_win_handle = hd.display_msg(match_win_handle, "SIDE X WINS!".*, hd.INF_DURATION, &hd.title_tf);
                        // hd.display_msg(hd.DisplayMessageType.match_end);
                        // hd.display_msg(hd.DisplayMessageType.divider_line);
                        // hd.display_msg(hd.DisplayMessageType.to_title);
                        round_timer += 1;

                        _ = std.fmt.bufPrint(hd.hover_display.message_ringbuffer[0].text[5..6], "{d}", .{if (match.did_side1_win) @as(u8, 1) else @as(u8, 2)}) catch undefined;


                    } else if (round_timer < 120) {
                        round_timer += 1;
                    } else {
                        // round_timer = 0;
                        // round_state = SingleRoundState.init_game;
                        game_state = GameStates.title_screen;
                        bootup_timer = gc.BOOTUP_TIME;
                    } 
                }   
            }
        },
        // When the CPUs are playing on the title screen
        else => {
            switch (round_state) {
                .init_game => {
                    round_state = SingleRoundState.countdown;
                    round_timer = 0;    
                },
                .countdown => {
                    if (round_timer == 0) {
                        reset_and_start_new_round();
                        round_timer += 1;
                    } else if (round_timer < gc.RESTART_FRAME_WAIT) {
                        round_timer += 1;
                    } else {
                        round_state = SingleRoundState.playing;
                    }
                },
                .playing => {
                    move_ball();
                },
                else => {
                    round_state = SingleRoundState.countdown;
                    round_timer = 0;
                }
            }   
        }
    }

    

    framecount = @mod(framecount + 1, gc.LARGE_NUM_FOR_SEEDING_MOD);

    // update the players.
    for (&players) |*player| {
        if (player.is_active) {
            gamepad_input(player);
            pd.update_paddle(player.paddle, player.current_dir_input);
            pd.animate_paddle(player.paddle, player.current_dir_input, player.current_action_input, false);
        }
    }

    // update ui elements
    hd.decay_messages();
    sm.update_smokes();

    draw_screen();
}
