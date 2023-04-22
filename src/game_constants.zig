pub const PADDLE_DIST_FROM_SIDES: u8 = 6;

pub const PADDLE_ACCEL: f16 = 0.7;
pub const PADDLE_MAX_VEL: f16 = 3.6;
pub const PADDLE_NO_MOVE_DECAY_RATE: f16 = 0.7;

pub const DAMPEN_BOUNCE: f16 = 0.95;
pub const BALL_BOUNCEBACK_VX_MULT: f16 = 1.1;
pub const PADDLE_TRANSFER_VY_MULT: f16 = 0.12;
pub const BALL_MAX_VX: f16 = 5;

pub const RESTART_FRAME_WAIT: u32 = 120;

pub const CPU_TARGET_SPOT_TOL: f16 = 15;

pub const PADDLE_HIT_ANIM_DURATION = 10;
pub const PADDLE_BOUNCEBACK_DIST = 2;

pub const PADDLE_LUNGE_CATCHBACK_DURATION = 12;

pub const PADDLE_LUNGE_MULT: f16 = 1.4;
pub const PADDLE_CATCHBACK_MULT: f16 = 0.7;

pub const SMOKE_START_VEL: f16 = 2;
pub const SMOKE_DECEL_MULT: f16 = 0.8;
pub const N_SMOKES_RINGBUFFER = 20;

pub const SMOKE_DURATION: u16 = 20;
pub const SMOKE_OFFSET_Y: f16 = 0;
pub const BALL_SMOKE_MULT: f16 = 0.3;

pub const GAME_NAME = "PING";

pub const BALL_SPIN_VAL_MULT = 3;
pub const BALL_SPIN_ACCEL_MULT = 0.15;
pub const BALL_SPIN_DECAY_MULT = 0.98;