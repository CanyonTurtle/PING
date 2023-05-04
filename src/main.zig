const w4 = @import("wasm4.zig");
const std = @import("std");
const gr = @import("graphics.zig");
const gc = @import("game_constants.zig");
const pd = @import("paddles.zig");
const bl = @import("ball.zig");
const sm = @import("smoke.zig");
const hd = @import("hover_display.zig");
const cpus = @import("cpu_player.zig");

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
    switch_sides,
};

const Match = struct {
    num: u8 = 1,
    side1_match_score: u8 = 0,
    side1_game_score: u8 = 0,
    side2_match_score: u8 = 0,
    side2_game_score: u8 = 0,
    did_side1_win: bool = false,
};

var match = Match {};

var game_state: GameStates = GameStates.bootup;
var round_state: SingleRoundState = SingleRoundState.init_game;
var game_timer: u32 = 0;
var round_timer: u32 = 0;

var framecount: u16 = 0;


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
    current_dir_input: pd.Paddle_dirs = .no_move,
    current_action_input: pd.Paddle_button_action = .none,
    is_cpu_controlled: bool = true,
    is_active: bool = false,
    which_side: pd.Side,
    which_gamepad: *const u8,
    paddle: pd.Paddle = pd.init_paddle(.left),
    num: PlayerNum,
    cpu: cpus.CpuPlayer = cpus.defaultCpuPlayer,
};

var players = [_]Player{
    Player{
        .is_active = true,
        .which_side = pd.Side.left,
        .which_gamepad = w4.GAMEPAD1,
        .num = PlayerNum.one,
    },
    Player{
        .is_active = true,
        .which_side = pd.Side.right,
        .which_gamepad = w4.GAMEPAD2,
        .num = PlayerNum.two,
    },
    Player{
        .which_side = pd.Side.left,
        .which_gamepad = w4.GAMEPAD3,
        .num = PlayerNum.three,
    },
    Player{
        .which_side = pd.Side.right,
        .which_gamepad = w4.GAMEPAD4,
        .num = PlayerNum.four,
    },
};

fn set_paddle_positions_according_to_sides() void {
    for (&players) |*player| {
        player.paddle = pd.init_paddle(player.which_side);
    }
}

fn is_colliding(ball: *bl.Ball, paddle: *const pd.Paddle) bool {

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

fn reset_point() void {

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

    for (&players) |*player| {
        player.paddle.y = pd.paddle_start_y - @intToFloat(f16, gr.paddle.height) / 2;
        player.paddle.y = get_paddle_start_y(player);
        player.paddle.y_int = @floatToInt(i32, player.paddle.y);
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


// text handles for the menu options
// (we need these to persist between frames).
var color_handle: u16 = hd.NOIDX;
var starting_handle: u16 = hd.NOIDX;
var rally_handle: u16 = hd.NOIDX;
var match_win_handle: u16 = hd.NOIDX;
var difficulty_handle: u16 = hd.NOIDX;
var match_len_handle: u16 = hd.NOIDX;

var rally_count: u16 = 0;

pub fn reset_text_handles() void {
    color_handle = hd.NOIDX;
    starting_handle = hd.NOIDX;
    rally_handle = hd.NOIDX;
    match_win_handle = hd.NOIDX;
    difficulty_handle = hd.NOIDX;
    match_len_handle = hd.NOIDX;
}

fn handle_ball_colliding_with_paddle(player: *Player) void {
    // ball off paddle physics
    if (is_colliding(&bl.ball, &player.paddle)) {

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
                        _ = hd.display_msg(hd.NOIDX, "   Lunge!   ".*, gc.ACTION_MSG_DURATION_MSEC, &hd.lunge_tf);
                    },
                    .catchback => {
                        _ = hd.display_msg(hd.NOIDX, "   Catch!   ".*, gc.ACTION_MSG_DURATION_MSEC, &hd.catchback_tf);
                    },
                    else => {},
                }
            }
        }

        bl.ball.x += pd.side_mult(player.paddle.side) * (gc.PADDLE_BOUNCEBACK_DIST + 1);
        pd.animate_paddle(&player.paddle, player.current_dir_input, player.current_action_input, true);

        // no action messages on title sequence
        if (game_state == GameStates.main_game) {
            rally_count += 1;
            if (rally_count >= gc.MAX_N_FOR_START_RALLY_COUNT) {
                rally_handle = hd.display_msg(rally_handle, "   Rally X  ".*, hd.INF_DURATION, &hd.normal_tf);
                _ = std.fmt.bufPrint(hd.hover_display.message_ringbuffer[rally_handle].text[9..12], "{d}", .{rally_count}) catch undefined;
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

    if (bl.ball.vx > gc.current_difficulty.ball_max_vx) {
        bl.ball.vx = gc.current_difficulty.ball_max_vx;
    }
    if (bl.ball.vx < -1 * gc.current_difficulty.ball_max_vx) {
        bl.ball.vx = -1 * gc.current_difficulty.ball_max_vx;
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

// draws text with layers.
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

        var side1_game_buf: [2]u8 = .{ 0x0, 0x0 };
        _ = std.fmt.bufPrint(&side1_game_buf, "{d}", .{match.side1_match_score}) catch undefined;
        var side2_game_buf: [2]u8 = .{ 0x0, 0x0 };
        _ = std.fmt.bufPrint(&side2_game_buf, "{d}", .{match.side2_match_score}) catch undefined;



        if (round_state == SingleRoundState.someone_won_game or round_state == SingleRoundState.someone_won_match) {
            if (@mod(round_timer / 2, 10) < 10 * gc.FLASH_PERCENT) {
                if (bl.ball.x < w4.SCREEN_SIZE / 2) {  
                    w4.text(&side1_game_buf, gc.SIDE1_MATCH_X, 0);
                } else {
                    w4.text(&side2_game_buf, gc.SIDE2_MATCH_X, 0);
                }
                
            } else {
                w4.text(&side1_game_buf, gc.SIDE1_MATCH_X, 0);
                w4.text(&side2_game_buf, gc.SIDE2_MATCH_X, 0);
            }

        } else {
            w4.text(&side1_game_buf, gc.SIDE1_MATCH_X, 0);
            w4.text(&side2_game_buf, gc.SIDE2_MATCH_X, 0);
        }

        if (round_state == SingleRoundState.someone_scored) {
            if (@mod(round_timer / 2, 10) < 10 * gc.FLASH_PERCENT) {
                if (bl.ball.x < w4.SCREEN_SIZE / 2) {  
                    w4.text(&side1_score_buf, gc.SIDE1_SCORE_X, 0);
                } else {
                    w4.text(&side2_score_buf, gc.SIDE2_SCORE_X, 0);
                }
                
            } else {
                w4.text(&side1_score_buf, gc.SIDE1_SCORE_X, 0);
                w4.text(&side2_score_buf, gc.SIDE2_SCORE_X, 0);
            }

        } else {
            w4.text(&side1_score_buf, gc.SIDE1_SCORE_X, 0);
            w4.text(&side2_score_buf, gc.SIDE2_SCORE_X, 0);
        }

        if (round_state == SingleRoundState.switch_sides or round_state == SingleRoundState.init_match) {
            for (&players) |player| {
                if (player.is_active) {
                    var player_label: [2]u8 = "PX".*;
                    _ = std.fmt.bufPrint(player_label[1..2], "{d}", .{get_pnum_as_int(player.num)}) catch undefined;
                    if (@mod(round_timer / 2, 10) < 10 * gc.FLASH_PERCENT) {
                        
                    } else {
                        w4.text(&player_label, player.paddle.x_int - 4, player.paddle.y_int - 10);
                    }
                }
            }
            

        }
        // else if (round_state == SingleRoundState.countdown or round_state == .init_game or round_state == .someone_won_game) {
        //     for (&players) |player| {
        //         if (player.is_active) {
        //             var player_label: [2]u8 = "PX".*;
        //             _ = std.fmt.bufPrint(player_label[1..2], "{d}", .{get_pnum_as_int(player.num)}) catch undefined;
        //             w4.text(&player_label, player.paddle.x_int - 4, player.paddle.y_int - 10);
        //         }
        //     }
        // }
    }

    if (hd.hover_display.is_active) {
        for (&hd.hover_display.message_ringbuffer) |*message| {
            if (message.is_active) {
                draw_font(&message.text, gc.HOVER_DISPLAY_X, message.y_int, message.text_font);
            }
        }

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


var menu_input: u8 = 0;
var prev_menu_input: u8 = 0;
const MENU_NOTHING_SELECTED = 255;

// handles moving the cursor,
// and if a menu option is pressed,
// it will return the new game state.
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

const divide_line_text = "------------";
const back_text = "<-- Back    ";

const COLOR_CYCLE_DONE = 10000;
var color_cycle_timer: u16 = 0;
var last_color_idx: u16 = 0;

// The game is expressed as as two concurrent state machines:
// 1. the game state - whether we're on the title screen, playing, options screen, etc...
// 2. the round state - which phase of a specific round of ping we're in.

// If the game state is in the "main game" state, then the round state takes on its full
// functionality. Otherwise, the round state is just the CPU paddles playing eachother endlessly.

// Each state machine has a timer that is used to handle timing of entry / exit between states.
export fn update() void {
    switch (game_state) {
        .bootup => {
            // The reason this is here is because of a
            // workaround to avoid https://github.com/aduros/wasm4/issues/542
            w4.PALETTE.* = [_]u32{0,0,0,0};// gr.pallete.*;
            set_paddle_positions_according_to_sides();
            game_state = GameStates.title_screen;
            round_state = SingleRoundState.init_game;
            round_timer = 0;
        },
        .title_screen => {

            if(color_cycle_timer <= 60) {
                var rratio = @intToFloat(f16, color_cycle_timer) / 60;
                w4.PALETTE.* = [4]u32{
                    gr.transitionBetweenColors(0, gr.pallete_list[gr.pallete_idx][0], rratio),
                    gr.transitionBetweenColors(0, gr.pallete_list[gr.pallete_idx][1], rratio),
                    gr.transitionBetweenColors(0, gr.pallete_list[gr.pallete_idx][2], rratio),
                    gr.transitionBetweenColors(0, gr.pallete_list[gr.pallete_idx][3], rratio),
                };
                color_cycle_timer += 1;
            } else {
                color_cycle_timer = COLOR_CYCLE_DONE;
            }


            if (game_timer < gc.BOOTUP_TIME) {    
                game_timer += 1;
            } else if (game_timer == gc.BOOTUP_TIME) {
                reset_text_handles();
                hd.reset_hover_display(4, true);
                _ = hd.display_msg(hd.NOIDX, gc.GAME_NAME.* ++ "        ".*, hd.INF_DURATION, &hd.title_tf);
                _ = hd.display_msg(hd.NOIDX, divide_line_text.*, hd.INF_DURATION, &hd.normal_tf);
                _ = hd.display_msg(hd.NOIDX, "Play        ".*, hd.INF_DURATION, &hd.normal_tf);
                _ = hd.display_msg(hd.NOIDX, "Options     ".*, hd.INF_DURATION, &hd.normal_tf);

                for (&players) |*player| {
                    player.is_cpu_controlled = true;
                }

                game_timer += 1;
                
            } else if (game_timer > gc.BOOTUP_TIME and game_timer < gc.BOOTUP_TIME + 30) {
                game_timer += 1;
                // mu.start_song(&mu.song_1);
            } else {
                game_timer += 1;
                hd.blink_cursor();
                

                

                var option_selected: u8 = get_menu_option();

                const BEGIN_MATCH = 0;
                const SEE_OPTIONS = 1;


                switch (option_selected) {
                    BEGIN_MATCH => {
                        players[0].is_cpu_controlled = false;
                        players[0].is_active = true;
                        game_state = GameStates.main_game;
                        round_state = SingleRoundState.init_match;
                        round_timer = 0;
                    },
                    SEE_OPTIONS => {
                        game_state = GameStates.options;
                        game_timer = 0;
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
            if (game_timer == 0) {
                reset_text_handles();
                game_timer += 1;
                hd.reset_hover_display(7, true);
                _ = hd.display_msg(hd.NOIDX, "Options     ".*, hd.INF_DURATION, &hd.title_tf);
                _ = hd.display_msg(hd.NOIDX, divide_line_text.*, hd.INF_DURATION, &hd.normal_tf);

                // one-digit version
                // color_handle = hd.display_msg(hd.NOIDX, "Color (x/x) ".*, hd.INF_DURATION, &hd.normal_tf);
                // _ = std.fmt.bufPrint(hd.hover_display.message_ringbuffer[color_handle].text[7..8], "{d}", .{gr.pallete_idx + 1}) catch undefined;
                // _ = std.fmt.bufPrint(hd.hover_display.message_ringbuffer[color_handle].text[9..10], "{d}", .{gr.pallete_list.len}) catch undefined;

                // double-digit version
                color_handle = hd.display_msg(hd.NOIDX, "Color:   /  ".*, hd.INF_DURATION, &hd.normal_tf);
                _ = std.fmt.bufPrint(hd.hover_display.message_ringbuffer[color_handle].text[7..9], "{d}", .{gr.pallete_idx + 1}) catch undefined;
                _ = std.fmt.bufPrint(hd.hover_display.message_ringbuffer[color_handle].text[10..12], "{d}", .{gr.pallete_list.len}) catch undefined;
        

                difficulty_handle = hd.display_msg(hd.NOIDX, "Level: XXXX ".*, hd.INF_DURATION, &hd.normal_tf);
                _ = std.fmt.bufPrint(hd.hover_display.message_ringbuffer[difficulty_handle].text[7..11], "{s}", .{gc.current_difficulty.difficulty_text}) catch undefined;
                  
                match_len_handle = hd.display_msg(hd.NOIDX, "Match: XXXXX".*, hd.INF_DURATION, &hd.normal_tf);
                _ = std.fmt.bufPrint(hd.hover_display.message_ringbuffer[match_len_handle].text[7..12], "{s}", .{gc.match_count_settings[gc.current_match_count_idx].label}) catch undefined;
                 

                _ = hd.display_msg(hd.NOIDX, "About       ".*, hd.INF_DURATION, &hd.normal_tf);
                _ = hd.display_msg(hd.NOIDX, back_text.*, hd.INF_DURATION, &hd.normal_tf);

            } else {
                hd.blink_cursor();

                var option_selected: u8 = get_menu_option();

                const CYCLE_COLORS = 0;
                const CYCLE_DIFFICULTY_LEVEL = 1;
                const CYCLE_MATCH_LEN = 2;
                const SEE_ABOUT = 3;
                const BACK = 4;

                // a little gimmick to smoothly transition between color palettes.
                if (color_cycle_timer <= 5) {

                    var rratio = @intToFloat(f16, color_cycle_timer) / 5;
                    w4.PALETTE.* = [4]u32{
                        gr.transitionBetweenColors(gr.pallete_list[last_color_idx][0], gr.pallete_list[gr.pallete_idx][0], rratio),
                        gr.transitionBetweenColors(gr.pallete_list[last_color_idx][1], gr.pallete_list[gr.pallete_idx][1], rratio),
                        gr.transitionBetweenColors(gr.pallete_list[last_color_idx][2], gr.pallete_list[gr.pallete_idx][2], rratio),
                        gr.transitionBetweenColors(gr.pallete_list[last_color_idx][3], gr.pallete_list[gr.pallete_idx][3], rratio),
                    };
                    color_cycle_timer += 1;
                } else {
                    color_cycle_timer = COLOR_CYCLE_DONE;
                }
                switch (option_selected) {
                    CYCLE_COLORS => {
                        last_color_idx = gr.pallete_idx;
                        gr.pallete_idx = @mod(gr.pallete_idx + 1, @intCast(u16, gr.pallete_list.len));
                        // w4.PALETTE.* = gr.pallete_list[gr.pallete_idx];
                        _ = std.fmt.bufPrint(hd.hover_display.message_ringbuffer[color_handle].text[7..9], "  ", .{}) catch undefined;
                        _ = std.fmt.bufPrint(hd.hover_display.message_ringbuffer[color_handle].text[7..9], "{d}", .{gr.pallete_idx + 1}) catch undefined;
                        _ = std.fmt.bufPrint(hd.hover_display.message_ringbuffer[color_handle].text[10..12], "{d}", .{gr.pallete_list.len}) catch undefined;
                        color_cycle_timer = 0;
                    },
                    CYCLE_DIFFICULTY_LEVEL => {
                        gc.difficulty_idx = @mod(gc.difficulty_idx + 1, @intCast(u16, gc.difficulties.len));
                        gc.current_difficulty = gc.difficulties[gc.difficulty_idx];

                        _ = std.fmt.bufPrint(hd.hover_display.message_ringbuffer[difficulty_handle].text[7..11], "{s}", .{gc.current_difficulty.difficulty_text}) catch undefined;
                    },
                    CYCLE_MATCH_LEN => {
                        gc.current_match_count_idx = @mod(gc.current_match_count_idx + 1, @intCast(u16, gc.match_count_settings.len));
                        _ = std.fmt.bufPrint(hd.hover_display.message_ringbuffer[match_len_handle].text[7..12], "{s}", .{gc.match_count_settings[gc.current_match_count_idx].label}) catch undefined;
                    },
                    SEE_ABOUT => {
                        game_state = GameStates.about;
                        game_timer = 0;
                    },
                    BACK => {
                        game_state = GameStates.title_screen;
                        game_timer = gc.BOOTUP_TIME;
                    },
                    else => {
                        
                    },
                }
            }
        },
        .about => {   
            if (game_timer == 0) {
                reset_text_handles();
                game_timer += 1;
                hd.reset_hover_display(7, true);

                _ = hd.display_msg(hd.NOIDX, "About       ".*, hd.INF_DURATION, &hd.title_tf);
                _ = hd.display_msg(hd.NOIDX, divide_line_text.*, hd.INF_DURATION, &hd.normal_tf);
                _ = hd.display_msg(hd.NOIDX, "github.com/ ".*, hd.INF_DURATION, &hd.normal_tf);
                _ = hd.display_msg(hd.NOIDX, "CanyonTurtle".*, hd.INF_DURATION, &hd.normal_tf);
                _ = hd.display_msg(hd.NOIDX, "/PING       ".*, hd.INF_DURATION, &hd.normal_tf);
                _ = hd.display_msg(hd.NOIDX, gc.VERSION.* ++ "      ".*, hd.INF_DURATION, &hd.normal_tf);
                _ = hd.display_msg(hd.NOIDX, back_text.*, hd.INF_DURATION, &hd.normal_tf);
            } else {
                hd.blink_cursor();

                var option_selected: u8 = get_menu_option();

                const BACK = 4;

                switch (option_selected) {
                    BACK => {
                        game_state = GameStates.title_screen;
                        game_timer = gc.BOOTUP_TIME;
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
                        match.side1_match_score = 0;
                        match.side2_match_score = 0;
                        match.side1_game_score = 0;
                        match.side2_game_score = 0;
                        reset_text_handles();
                        reset_point();
                        hd.reset_hover_display(gc.N_DISPLAY_LINES_DURING_NORMAL_PLAY, false);
                        _ = hd.display_msg(hd.NOIDX, "Match Start!".*, gc.INIT_MATCH_DURATION_MSEC, &hd.title_tf);
                        var h1 = hd.display_msg(hd.NOIDX, "- best of X ".*, gc.INIT_MATCH_DURATION_MSEC, &hd.normal_tf);
                        var h2 = hd.display_msg(hd.NOIDX, "- play to X ".*, gc.INIT_MATCH_DURATION_MSEC, &hd.normal_tf);

                        _ = std.fmt.bufPrint(hd.hover_display.message_ringbuffer[h1].text[10..12], "{d}", .{gc.match_count_settings[gc.current_match_count_idx].match_win_count * 2 - 1}) catch undefined;
                        _ = std.fmt.bufPrint(hd.hover_display.message_ringbuffer[h2].text[10..12], "{d}", .{gc.match_count_settings[gc.current_match_count_idx].game_point_win_count}) catch undefined;

                        round_timer += 1;
                    }
                    else if(round_timer >= gc.INIT_MATCH_DURATION_MSEC) {
                        round_state = SingleRoundState.init_game;
                        round_timer = 0;
                    } else {
                        round_timer += 1;
                    }  
                },
                .init_game => {
                    
                    if (round_timer == 0) {
                        match.side1_game_score = 0;
                        match.side2_game_score = 0;
                        reset_text_handles();
                        reset_point();
                        hd.reset_hover_display(gc.N_DISPLAY_LINES_DURING_NORMAL_PLAY, false);
                        var handle = hd.display_msg(hd.NOIDX, "   GAME X   ".*, gc.INIT_GAME_DURATION_MSEC, &hd.title_tf);
                        _ = std.fmt.bufPrint(hd.hover_display.message_ringbuffer[handle].text[8..9], "{d}", .{match.num}) catch undefined;

                        round_timer += 1;
                    }
                    else if(round_timer >= gc.INIT_GAME_DURATION_MSEC) {
                        round_state = SingleRoundState.countdown;
                        round_timer = 0;
                    } else {
                        round_timer += 1;
                    }    
                },
                .countdown => {
                    
                    if (round_timer == 0) {
                        reset_text_handles();
                        reset_point();
                        round_timer += 1;
                    } else if (round_timer < gc.COUNTDOWN_DURATION_MSEC) {
                        round_timer += 1;
                        if (round_timer == gc.COUNTDOWN_DURATION_MSEC / 4 or round_timer == gc.COUNTDOWN_DURATION_MSEC / 2 or round_timer == gc.COUNTDOWN_DURATION_MSEC / 4 * 3 or round_timer == gc.COUNTDOWN_DURATION_MSEC) {

                            starting_handle = hd.display_msg(starting_handle, "Start in X..".*, 50, &hd.title_tf);
                            _ = std.fmt.bufPrint(hd.hover_display.message_ringbuffer[starting_handle].text[9..10], "{d}", .{@as(u8, (gc.COUNTDOWN_DURATION_MSEC - @intCast(u8, round_timer)) / (gc.COUNTDOWN_DURATION_MSEC / 4))}) catch undefined;
                            if (round_timer == gc.COUNTDOWN_DURATION_MSEC) {
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
                        if (match.side1_game_score >= gc.match_count_settings[gc.current_match_count_idx].game_point_win_count) {
                            match.side1_match_score += 1;
                            round_state = SingleRoundState.someone_won_game;
                            round_timer = 0;
                        } else if (match.side2_game_score >= gc.match_count_settings[gc.current_match_count_idx].game_point_win_count) {
                            match.side2_match_score += 1;
                            round_state = SingleRoundState.someone_won_game;
                            round_timer = 0;
                        } else {
                            _ = hd.display_msg(hd.NOIDX, "   POINT!   ".*, gc.POINT_WIN_DURATION, &hd.title_tf);
                            round_timer += 1;    
                        }  
                    } else if (round_timer < gc.POINT_WIN_DURATION) {
                        round_timer += 1;
                    } else {
                        round_timer = 0;
                        round_state = SingleRoundState.countdown;
                    }
                },
                .someone_won_game => {
                    if(round_timer == 0) {
                        match.num += 1;
                        if (match.side1_match_score >= gc.match_count_settings[gc.current_match_count_idx].match_win_count) {
                            match.did_side1_win = true;
                            round_state = SingleRoundState.someone_won_match;
                            round_timer = 0;
                        } else if (match.side2_match_score >= gc.match_count_settings[gc.current_match_count_idx].match_win_count) {
                            match.did_side1_win = false;
                            round_state = SingleRoundState.someone_won_match;
                            round_timer = 0;
                        } else {
                            _ = hd.display_msg(hd.NOIDX, "   GAME!    ".*,60, &hd.title_tf);
                            round_timer += 1;    
                        }  

                    } else if (round_timer < gc.GAME_WIN_DURATION) {
                        round_timer += 1;
                    } else {
                        round_timer = 0;
                        round_state = SingleRoundState.switch_sides;
                    } 
                },
                .switch_sides => {
                    if(round_timer == 0) {

                        for(&players) |*player| {
                            player.which_side = if(player.which_side == pd.Side.left) pd.Side.right else pd.Side.left;
                        }

                        var temp = match.side1_match_score;
                        match.side1_match_score = match.side2_match_score;
                        match.side2_match_score = temp;

                        match.side1_game_score = 0;
                        match.side2_game_score = 0;

                        set_paddle_positions_according_to_sides();
                                                
                        reset_text_handles();
                        reset_point();
                        hd.reset_hover_display(4, false);
                        _ = hd.display_msg(hd.NOIDX, "SWITCH SIDES".*, hd.INF_DURATION, &hd.normal_tf);
                        _ = hd.display_msg(hd.NOIDX, "<--      -->".*, hd.INF_DURATION, &hd.normal_tf);
                        round_timer += 1;


                        

                    } else if (round_timer < gc.SWITCH_SIDES_DURATION) {
                        round_timer += 1;
                    } else {
                        round_timer = 0;
                        round_state = SingleRoundState.init_game;
                    } 
                },
                .someone_won_match => {
                    if(round_timer == 0) {
                        hd.reset_hover_display(3, false);
                        match_win_handle = hd.display_msg(match_win_handle, "SIDE X WINS!".*, hd.INF_DURATION, &hd.title_tf);
                        var arrow_text = "   <--      ".*;
                        if (match.side1_match_score < match.side2_match_score) {
                            arrow_text = "      -->   ".*;
                        }
                         _ = hd.display_msg(hd.NOIDX, arrow_text, hd.INF_DURATION, &hd.title_tf);
                        
                        round_timer += 1;

                        _ = std.fmt.bufPrint(hd.hover_display.message_ringbuffer[match_win_handle].text[5..6], "{d}", .{if (match.did_side1_win) @as(u8, 1) else @as(u8, 2)}) catch undefined;


                    } else if (round_timer < gc.MATCH_WIN_DURATION) {
                        round_timer += 1;
                    } else {
                        // round_timer = 0;
                        // round_state = SingleRoundState.init_game;
                        game_state = GameStates.title_screen;
                        game_timer = gc.BOOTUP_TIME;
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
                        reset_point();
                        round_timer += 1;
                    } else if (round_timer < gc.COUNTDOWN_DURATION_MSEC) {
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
            pd.update_paddle(&player.paddle, player.current_dir_input);
            pd.animate_paddle(&player.paddle, player.current_dir_input, player.current_action_input, false);
        }
    }

    // update ui elements
    hd.decay_messages();
    sm.update_smokes();

    draw_screen();
}
