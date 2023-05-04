const w4 = @import("wasm4.zig");

pub const PADDLE_DIST_FROM_SIDES: u8 = 6;

pub const PADDLE_ACCEL: f16 = 0.7;
pub const PADDLE_MAX_VEL: f16 = 4.0;
pub const PADDLE_NO_MOVE_DECAY_RATE: f16 = 0.7;

pub const DAMPEN_BOUNCE: f16 = 0.95;
pub const BALL_BOUNCEBACK_VX_MULT: f16 = 1.1;
pub const PADDLE_TRANSFER_VY_MULT: f16 = 0.12;
pub const BALL_MAX_VX: f16 = 5.5;

pub const CPU_TARGET_SPOT_TOL: f16 = 15;

pub const PADDLE_HIT_ANIM_DURATION = 10;
pub const PADDLE_BOUNCEBACK_DIST = 2;

pub const PADDLE_LUNGE_CATCHBACK_DURATION = 12;

pub const PADDLE_LUNGE_MULT: f16 = 1.4;
pub const PADDLE_CATCHBACK_SPEED_MULT: f16 = 0.7;
pub const PADDLE_CATCHBACK_SPIN_MULT: f16 = 1.5;

pub const SMOKE_START_VEL: f16 = 2;
pub const SMOKE_DECEL_MULT: f16 = 0.8;
pub const N_SMOKES_RINGBUFFER = 30;

pub const SMOKE_DURATION: u16 = 20;
pub const SMOKE_OFFSET_Y: f16 = 0;
pub const BALL_SMOKE_MULT: f16 = 0.3;

pub const GAME_NAME = "PING";

pub const BALL_SPIN_VAL_MULT = 5;
pub const BALL_SPIN_ACCEL_MULT = 0.15;
pub const BALL_SPIN_GROWTH_MULT = 0.03;

pub const BALL_SPIN_OFF_WALL_REDUCTION_MULT = 0.7;
pub const BALL_SPIN_CAP_OFF_WALL_REDUCTION_MULT = 0.3;

pub const BALL_SMOKE_INTERVAL = 10;
pub const BALL_SMOKE_OUTSPEED_MULT = 1;

pub const LARGE_NUM_FOR_SEEDING_MOD: u16 = 50000;

pub const SERVE_ANGLE_VARIATION = 60;
pub const SERVE_MAGNITUDE = 1.3;

pub const TITLE_LOC = 60;

pub const SMOKE_PADDLE_OFFSET_MULT = 0.6;
pub const SMOKE_VX_OFFSET_MULT = 0.3;

pub const HOVER_DISPLAY_X = 30;
pub const HOVER_DISPLAY_Y = 60;

pub const HOVER_DISPLAY_SETTINGS_Y = 90;

pub const HOVER_DISPLAY_Y_DIST_BETWEEN_LINES = 10;

pub const PADDLE_RANDOM_VY_MULT = 0.02;

pub const VERSION = "v0.5.0";

pub const BOOTUP_TIME = 50;

pub const CURSOR_BLINK_DURATION = 20;

pub const MATCH_WIN_COUNT = 2;
pub const GAME_POINT_WIN_COUNT = 5;

pub const SIDE1_SCORE_X = 20;
pub const SIDE2_SCORE_X = w4.SCREEN_SIZE - 16;

pub const SIDE1_MATCH_X = 0;
pub const SIDE2_MATCH_X = w4.SCREEN_SIZE - 16 - 20;

pub const X_OFFSET_DURING_SCORE = 20;
pub const Y_OFFSET_DURING_SCORE = 80;

pub const MATCH_WIN_DURATION = 180;
pub const GAME_WIN_DURATION = 70;
pub const SWITCH_SIDES_DURATION = 110;
pub const POINT_WIN_DURATION = 70;
// pub fn GameSetting(comptime T: type) type {
//     return struct {
//         label: [6]u8,
//         current_v: T,
//         possible_vs: [3]T,
//         debug_only: bool,
//     };
// }

// pub var matchcount = GameSetting(u8){
//     .label = "#GAMES",
//     .current_v = 2,
//     .possible_vs = [3]u8{2, 3, 4},
//     .debug_only = false,
// };

// pub var GameConstants = struct {

// };

pub const MAX_N_FOR_START_RALLY_COUNT = 5;

pub const FLASH_PERCENT = 0.30;

pub const N_DISPLAY_LINES_DURING_NORMAL_PLAY = 4;

pub const INIT_MATCH_DURATION_MSEC = 120;

pub const INIT_GAME_DURATION_MSEC = 70;

pub const COUNTDOWN_DURATION_MSEC: u8 = 70;

pub const ACTION_MSG_DURATION_MSEC = 50;

pub const DifficultySettings = struct {
    cpu_stalling_rate: f16,
    ball_max_vx: f16,
    difficulty_text: [4]u8,
    paddle_max_vel: f16,
};

pub const easy = DifficultySettings {
    .cpu_stalling_rate = 0.2,
    .ball_max_vx = 4.0,
    .difficulty_text = "EASY".*,
    .paddle_max_vel = 3.0,
};

pub const medium = DifficultySettings {
    .cpu_stalling_rate = 0.1,
    .ball_max_vx = 4.5,
    .difficulty_text = "MED.".*,
    .paddle_max_vel = 4.0,
};

pub const hard = DifficultySettings {
    .cpu_stalling_rate = 0.02,
    .ball_max_vx = 5.5,
    .difficulty_text = "HARD".*,
    .paddle_max_vel = 4.5,
};

pub const xhard = DifficultySettings {
    .cpu_stalling_rate = 0.01,
    .ball_max_vx = 6.5,
    .difficulty_text = "X-HD".*,
    .paddle_max_vel = 5.0,
};

pub const MatchCountSettings = struct {
    match_win_count: u8,
    game_point_win_count: u8,
    label: [5]u8,
};

pub const match_count_settings = [_]MatchCountSettings {
    .{
        .match_win_count = 2,
        .game_point_win_count = 3,
        .label = "QUICK".*,
    },
    .{
        .match_win_count = 2,
        .game_point_win_count = 5,
        .label = "NORM.".*,
    },
    .{
        .match_win_count = 3,
        .game_point_win_count = 7,
        .label = "LONG ".*,
    },
    .{
        .match_win_count = 1,
        .game_point_win_count = 21,
        .label = "TO 21".*,
    },
};

pub var current_match_count_idx: u16 = 1;

pub var current_difficulty: *const DifficultySettings = &medium;
pub var difficulty_idx: u16 = 1;
pub const difficulties = [_]*const DifficultySettings{&easy, &medium, &hard, &xhard};