const w4 = @import("wasm4.zig");
const gc = @import("game_constants.zig");
const gr = @import("graphics.zig");

pub const Smoke = struct {
    sprite_data: gr.Sprite_Metadata,
    image: *const [8]u8,
    timer: u16,
    is_active: bool,
    x: f16,
    x_int: i32,
    y: f16,
    y_int: i32,
    vx: f16,
    vy: f16 
};

pub var smokes: [gc.N_SMOKES_RINGBUFFER]Smoke = [_]Smoke{Smoke{
            .sprite_data = gr.smoke_trail,
            .image = &gr.smoke_trail_image,
            .timer = 0,
            .is_active = false,
            .x = 0,
            .x_int = 0,
            .y = 0,
            .y_int = 0,
            .vx = 0,
            .vy = 0 
        }} ** gc.N_SMOKES_RINGBUFFER;

pub var smoke_ringbuffer_idx: u8 = 0;

pub fn spawn_smoke(x: f16, y: f16, vx: f16, vy: f16) void {
    var smoke: *Smoke = &smokes[smoke_ringbuffer_idx];
    smoke.x = x;
    smoke.y = y;
    smoke.vx = vx;
    smoke.vy = vy;
    smoke_ringbuffer_idx = @mod(smoke_ringbuffer_idx + 1, 10);
    smoke.timer = 0;
    smoke.is_active = true;
}

pub fn update_smokes() void {
    var i: u8 = 0;
    while(i < gc.N_SMOKES_RINGBUFFER) {
        var smoke: *Smoke = &smokes[i];
        if (smoke.is_active) {
            smoke.x += smoke.vx;
            smoke.y += smoke.vy;
            smoke.vx *= gc.SMOKE_DECEL_MULT;
            smoke.vy *= gc.SMOKE_DECEL_MULT;
            smoke.timer += 1;
            if (smoke.timer >= gc.SMOKE_DURATION) {
                smoke.is_active = false;
            }
        }
        i += 1;
    }
}