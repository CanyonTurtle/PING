const w4 = @import("wasm4.zig");
const gc = @import("game_constants.zig");
const gr = @import("graphics.zig");
const std = @import("std");
const pd = @import("paddles.zig");
const bl = @import("ball.zig");

pub const CpuState = enum {
    go_towards_ball,
    delay,
    ready_for_new_state,
};

pub const CpuPlayer = struct {
    current_state: CpuState,
    state_timer: u16,
    current_dir_input: pd.Paddle_dirs,
    current_action_input: pd.Paddle_button_action,
    rand_decision_num: u8,
};

pub const defaultCpuPlayer = CpuPlayer{
    .current_dir_input = pd.Paddle_dirs.no_move,
    .current_action_input = pd.Paddle_button_action.none,
    .current_state = CpuState.ready_for_new_state,
    .state_timer = 0,
    .rand_decision_num = 0,
};

const GO_TOWARDS_BALL_DURATION = 20;
const DELAY_DURATION = 40;

pub fn updateCpuDecision(cpu: *CpuPlayer, paddle_center_x: f16, paddle_center_y: f16, ball_center_x: f16, ball_center_y: f16, seed: u16) void {

    switch(cpu.current_state) {
        .ready_for_new_state => {
            // choose what to do next
            var rnd = std.rand.DefaultPrng.init(seed);

            cpu.rand_decision_num = rnd.random().int(u8);
            
            if (cpu.rand_decision_num < 240) {
                cpu.current_state = CpuState.go_towards_ball;
            } else {
                cpu.current_state = CpuState.delay;
            }
            cpu.state_timer = 0;
        },
        .go_towards_ball => {
            if (paddle_center_y < ball_center_y - gc.CPU_TARGET_SPOT_TOL) {
                cpu.current_dir_input = pd.Paddle_dirs.down;
            } else if(paddle_center_y > ball_center_y + gc.CPU_TARGET_SPOT_TOL){
                cpu.current_dir_input = pd.Paddle_dirs.up;
            } else {
                cpu.current_dir_input = pd.Paddle_dirs.no_move;
            }
            if(cpu.state_timer >= GO_TOWARDS_BALL_DURATION) {
                cpu.current_state = CpuState.ready_for_new_state;
            }
        },
        .delay => {
            cpu.current_dir_input = pd.Paddle_dirs.no_move;
            if(cpu.state_timer >= DELAY_DURATION) {
                cpu.current_state = CpuState.ready_for_new_state;
            }
        },
    }
    if (ball_center_y - gc.CPU_TARGET_SPOT_TOL < paddle_center_y and paddle_center_y < ball_center_y + gc.CPU_TARGET_SPOT_TOL and @fabs(ball_center_x - paddle_center_x) < gc.CPU_TARGET_SPOT_TOL) {
        if (@mod(cpu.rand_decision_num + seed, 30) == 0) {
            cpu.current_action_input = pd.Paddle_button_action.lunge;
        } else if (@mod(cpu.rand_decision_num + seed, 30) == 1) {
            cpu.current_action_input = pd.Paddle_button_action.catchback;
        } else {
            cpu.current_action_input = pd.Paddle_button_action.none;
        }
    }
    cpu.state_timer += 1;
}