// paddle

pub const Sprite_Metadata = struct {
    width: u32,
    height: u32,
    flags: u32,
    draw_colors: u16,
};



// pub const paddle_width = 8  ;
// pub const paddle_height = 24;
// pub const paddle_flags = 0; // BLIT_1BPP
pub const paddle_image = [24]u8{
    0b11000111,
    0b10000011,
    0b00000001,
    0b00000001,
    0b00000001,
    0b00000001,
    0b00000001,
    0b00000001,
    0b00000001,
    0b00000001,
    0b00000001,
    0b00000001,
    0b00000001,
    0b00000001,
    0b00000001,
    0b00000001,
    0b00000001,
    0b00000001,
    0b00000001,
    0b00000001,
    0b00000001,
    0b00000001,
    0b10000011,
    0b11000111
};

pub const paddle_up_image = [24]u8{
    0b11000111,
    0b10000011,
    0b00000001,
    0b00000001,
    0b00000001,
    0b00000001,
    0b00000001,
    0b00000001,
    0b00000001,
    0b00000001,
    0b00000001,
    0b00000001,
    0b00000001,
    0b00000001,
    0b00000001,
    0b00000001,
    0b00000001,
    0b00000001,
    0b00000001,
    0b00000001,
    0b00000001,
    0b00010001,
    0b00111001,
    0b01111101
};

pub const paddle_down_image = [24]u8{
    0b01111101,
    0b00111001,
    0b00010001,
    0b00000001,
    0b00000001,
    0b00000001,
    0b00000001,
    0b00000001,
    0b00000001,
    0b00000001,
    0b00000001,
    0b00000001,
    0b00000001,
    0b00000001,
    0b00000001,
    0b00000001,
    0b00000001,
    0b00000001,
    0b00000001,
    0b00000001,
    0b00000001,
    0b00000001,
    0b10000011,
    0b11000111,
};

pub const paddle = Sprite_Metadata {
    .width = 8,
    .height = 24,
    .flags = 0,
    .draw_colors = 0x03,
};

pub const paddle_up = Sprite_Metadata {
    .width = 8,
    .height = 24,
    .flags = 0,
    .draw_colors = 0x03,
};

pub const paddle_down = Sprite_Metadata {
    .width = 8,
    .height = 24,
    .flags = 0,
    .draw_colors = 0x03,
};

pub const paddle_hit = Sprite_Metadata {
    .width = 8,
    .height = 24,
    .flags = 0,
    .draw_colors = 0x04,
};

// pub const ball_width = 8;
// pub const ball_height = 8;
// pub const ball_flags = 0; // BLIT_1BPP
// pub const ball = [8]u8{
//     0b11000011,
//     0b10000001,
//     0b00100100,
//     0b00100100,
//     0b00000000,
//     0b00100100,
//     0b10011001,
//     0b11000011,
// };

// ball
// pub const ball_width = 16;
// pub const ball_height = 16;
// pub const ball_flags = 0; // BLIT_1BPP
pub const ball_image = [32]u8{ 0x07,0xe0,0x1f,0xf8,0x3f,0xfc,0x7f,0xfe,0x7f,0xfe,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0x7f,0xfe,0x7f,0xfe,0x3f,0xfc,0x1f,0xf8,0x07,0xe0 };

pub const ball = Sprite_Metadata{
    .width = 16,
    .height = 16,
    .flags = 0,
    .draw_colors = 0x40,
};

// alltime
pub const alltime_pallete: [4]u32 = .{
    0x95E1D3, // bg: light blue
    0xFCE38A, // alt-text: light yellow
    0xF38181, // paddles: medium red
    0xEAFFD0, // ball/overlay/smoke: white
};

// Neon Palette:
pub const neon_pallete: [4]u32 = .{
    0x20002C, // bg: dark purple
    0xFFEA3C, // alt-text: bright yellow
    0x00E0FF, // paddles: bright blue
    0xFF007F, // ball/overlay/smoke: bright pink
};

// Spring Bloom Palette:
pub const spring_bloom_pallete: [4]u32 = .{
    0xFFF5EE, // bg: light pink
    0xFFCAB1, // alt-text: medium pink-orange
    0xB6E3D8, // paddles: light blue-green
    0xA8DADC, // ball/overlay/smoke: medium blue-green
};


// Electric City Palette:
pub const electric_city_pallete: [4]u32 = .{
    0x03045E, // bg: dark blue
    0xFFD369, // alt-text: bright yellow-orange
    0x29ABE2, // paddles: bright blue
    0xFF2E63, // ball/overlay/smoke: bright pink
};

// Sunrise Bliss Palette:
pub const sunrise_bliss_pallete: [4]u32 = .{
    0xFFF5E5, // bg: light orange
    0xFFD1BA, // alt-text: medium pink-orange
    0xF7BAA6, // paddles: medium pink
    0xF7D1B1, // ball/overlay/smoke: medium orange
};

// Forest Walk Palette:
pub const forest_walk_pallete: [4]u32 = .{
    0xF5F5F5, // bg: light gray
    0x5F5B5B, // alt-text: dark brown-gray
    0x9BC8A9, // paddles: light green
    0xE16639, // ball/overlay/smoke: bright orange
};

// Galactic Dream Palette:
pub const galactic_dream_pallete: [4]u32 = .{
    0x22223B, // bg: dark blue-purple
    0x94618E, // alt-text: medium purple
    0xFFAD6B, // paddles: bright orange
    0xE1E6F9, // ball/overlay/smoke: light blue-gray
};

// Golden Oasis Palette:
pub const golden_oasis_pallete: [4]u32 = .{
    0xFFF9D9, // bg: light yellow
    0xE2C391, // alt-text: medium brown
    0x81C784, // paddles: medium green
    0xFFD6BA, // ball/overlay/smoke: light orange
};

// Minty Sunrise Palette:
pub const minty_sunrise_pallete: [4]u32 = .{
    0xFFF8E7, // bg: light yellow
    0xE6B39A, // alt-text: medium orange-pink
    0x64DD17, // paddles: bright green
    0xFF69B4, // ball/overlay/smoke: bright pink
};

// Minty Sunrise 3 (Dark Brown) Palette:
pub const minty_sunrise_3_dark_pallete: [4]u32 = .{
    0xF6F2E8, // bg: light beige
    0x6C4F3D, // alt-text: dark brown
    0x4CAF50, // paddles: bright green
    0xFF69B4, // ball/overlay/smoke: bright pink
};

pub var pallete: *const [4]u32 = &alltime_pallete;

pub const pallete_list = [_]*const[4]u32{
    &alltime_pallete,&minty_sunrise_3_dark_pallete,&minty_sunrise_pallete,&electric_city_pallete,&forest_walk_pallete,&neon_pallete,&golden_oasis_pallete
};


//0x0b3866, // deep intense blue

// purp

pub const smoke_trail_image = [8]u8 {
    0b00111111,
    0b00011111,
    0b00011111,
    0b00001111,
    0b00000111,
    0b10001111,
    0b11111111,
    0b11111111,
};

pub const smoke_trail = Sprite_Metadata {
    .width = 8,
    .height = 8,
    .flags = 0,
    .draw_colors = 0x04,
};

// ping

pub const ping = Sprite_Metadata {
    .width = 64,
    .height = 33,
    .flags = 1,
    .draw_colors = 0x0230,
};

// ping
pub const ping_img = [528]u8{ 0xaa,0xaa,0xa5,0x0a,0xaa,0xaa,0xaa,0x9a,0xa4,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xaa,0xaa,0xaa,0x4a,0xaa,0xaa,0xaa,0x9a,0xa9,0x00,0xaa,0x90,0x00,0xaa,0xaa,0xa4,0xaa,0xaa,0xaa,0x9a,0xaa,0xaa,0xaa,0x9a,0xa9,0x00,0xaa,0x90,0x02,0xaa,0xaa,0xa9,0xaa,0xaa,0xaa,0xa6,0xaa,0xaa,0xaa,0x9a,0xa9,0x00,0xaa,0x90,0x0a,0xaa,0xaa,0xa9,0xaa,0xaa,0xaa,0xa4,0xaa,0xaa,0xaa,0x4a,0xa9,0x00,0xaa,0x90,0x0a,0xaa,0xaa,0xa9,0xaa,0xaa,0xaa,0xa9,0x2a,0xaa,0xa5,0x0a,0xa9,0x00,0xaa,0x90,0x2a,0xaa,0xaa,0xa9,0xaa,0xaa,0xaa,0xa9,0x2a,0xaa,0x40,0x0a,0xaa,0x40,0xaa,0x90,0x2a,0xaa,0xaa,0xa9,0xaa,0xaa,0xaa,0xa9,0x2a,0xaa,0x40,0x0a,0xaa,0x40,0xaa,0xa4,0xaa,0xaa,0xaa,0xa9,0xaa,0xa0,0xaa,0xa9,0x0a,0xa9,0x00,0x0a,0xaa,0x92,0xaa,0xa4,0xaa,0xaa,0xa4,0x00,0xaa,0xa2,0xaa,0xa9,0x0a,0xa9,0x00,0x0a,0xaa,0x92,0xaa,0xa4,0xaa,0xa4,0x00,0x00,0xaa,0xaa,0xaa,0xa9,0x0a,0xa9,0x00,0x0a,0xaa,0x92,0xaa,0xa4,0xaa,0x90,0x00,0x00,0xaa,0xaa,0xaa,0xa4,0x0a,0xa9,0x00,0x0a,0xaa,0xa6,0xaa,0xa4,0xaa,0x90,0x00,0x00,0xaa,0xaa,0xaa,0xa4,0x0a,0xa9,0x00,0x0a,0xaa,0xa6,0xaa,0xa4,0xaa,0x90,0x00,0x00,0xaa,0xaa,0xaa,0x90,0x0a,0xa9,0x00,0x0a,0xaa,0xaa,0xaa,0xa4,0xaa,0x40,0x00,0x00,0xaa,0xaa,0xaa,0x90,0x0a,0xa9,0x00,0x0a,0xaa,0xaa,0xaa,0xa4,0xaa,0x90,0x00,0x00,0xaa,0xaa,0xaa,0x40,0x0a,0xa9,0x00,0x0a,0xaa,0xaa,0xaa,0xa4,0xaa,0x90,0xaa,0xa9,0xaa,0xaa,0x40,0x00,0x0a,0xa9,0x00,0x0a,0xaa,0xaa,0xaa,0xa6,0xaa,0x92,0xaa,0xa9,0xaa,0xa9,0x00,0x00,0x0a,0xa9,0x00,0x0a,0xaa,0xaa,0xaa,0xa6,0xaa,0x92,0xaa,0xa9,0xaa,0xa9,0x00,0x00,0x0a,0xa9,0x00,0x0a,0xaa,0xaa,0xaa,0xa6,0xaa,0x92,0xaa,0xa9,0xaa,0xa9,0x00,0x00,0x0a,0xa9,0x00,0x0a,0xaa,0xaa,0xaa,0xa6,0xaa,0x92,0xaa,0xa9,0xaa,0xa9,0x00,0x00,0x0a,0xa9,0x00,0x0a,0xaa,0xaa,0xaa,0x92,0xaa,0x92,0xaa,0xa9,0xaa,0xa9,0x00,0x00,0x0a,0xa9,0x00,0x0a,0xaa,0xaa,0xaa,0x92,0xaa,0x90,0xaa,0xa9,0xaa,0xa9,0x00,0x00,0x0a,0xa9,0x00,0x2a,0xaa,0xaa,0xaa,0x92,0xaa,0xa4,0xaa,0xa9,0xaa,0xa9,0x00,0x00,0x0a,0xa9,0x00,0x2a,0xaa,0xaa,0xaa,0x92,0xaa,0xa4,0xaa,0xa9,0xaa,0xa9,0x00,0x00,0x0a,0xa9,0x00,0x2a,0xaa,0x9a,0xaa,0x92,0xaa,0xaa,0xaa,0xa9,0xaa,0xa9,0x00,0x00,0x0a,0xa9,0x00,0x2a,0xaa,0x9a,0xaa,0x42,0xaa,0xaa,0xaa,0xa9,0xaa,0xa9,0x00,0x00,0x2a,0xa9,0x00,0x2a,0xaa,0x9a,0xaa,0x42,0xaa,0xaa,0xaa,0xa9,0xaa,0xa4,0x00,0x00,0x2a,0xa9,0x00,0x2a,0xaa,0x9a,0xaa,0x40,0xaa,0xaa,0xaa,0xa9,0xaa,0xa4,0x00,0x00,0xaa,0xa9,0x00,0x2a,0xaa,0x92,0xaa,0x40,0xaa,0xaa,0xaa,0xa9,0xaa,0xa4,0x00,0x00,0xaa,0xa9,0x00,0x2a,0xaa,0x42,0xaa,0x40,0x2a,0xaa,0xaa,0xa4,0xaa,0xa9,0x00,0xaa,0xaa,0xaa,0xa4,0x2a,0xaa,0x42,0xaa,0x40,0x0a,0xaa,0xaa,0xa4,0xaa,0xa9,0x00,0xaa,0xaa,0xaa,0xa9,0x2a,0xaa,0x40,0xaa,0x40,0x02,0xaa,0xaa,0x90,0xaa,0xa9,0x00,0xaa,0xaa,0xaa,0xa9,0x2a,0xa4,0x00,0x00,0x00,0x00,0x2a,0xaa,0x90 };

// hover display
pub const hover_display_draw_colors = 0x04;