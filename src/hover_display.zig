const w4 = @import("wasm4.zig");
const gc = @import("game_constants.zig");
const gr = @import("graphics.zig");
const std = @import("std");


pub const TextFont = struct {
    primary: u16,
    secondary: u16,
    tertiary: u16,
};


pub const normal_tf = TextFont {
    .primary = 0x04,
    .secondary = 0x00,
    .tertiary = 0x00,
};

pub const title_tf = TextFont {
    .primary = 0x02,
    .secondary = 0x03,
    .tertiary = 0x00,
};

pub const lunge_tf = TextFont {
    .primary = 0x03,
    .secondary = 0x02,
    .tertiary = 0x00,
};

pub const catchback_tf = TextFont {
    .primary = 0x02,
    .secondary = 0x03,
    .tertiary = 0x04,
};


pub const Cursor = struct {
    current_text: [1]u8,
    x_int: i32,
    y_int: i32,
    blink_duration: u16,
    blink_timer: u16,
    blink_state: bool,
    font: *const TextFont,
    current_selection: u8,
};

pub const HoverMessage = struct {
    text: [12]u8,
    duration: u16,
    y: f16,
    y_target: f16,
    y_int: i32,
    is_active: bool,
    timer: u16,
    timestamp: u16,
    text_font: *const TextFont,
};

pub const HoverDisplay = struct {
    message_ringbuffer: [4]HoverMessage,
    message_top_idx: u8,
    is_active: bool,
    cursor: Cursor,
};

pub var hover_display = HoverDisplay{
    .message_ringbuffer = [_]HoverMessage{HoverMessage{
        .text = "Hello there!".*,
        .duration = 10,
        .y = 0,
        .y_int = 0,
        .y_target = 0,
        .is_active = false,
        .timer = 0,
        .timestamp = 0,
        .text_font = &normal_tf
    }} ** 4,
    .message_top_idx = 0,
    .is_active = true,
    .cursor = Cursor{
        .blink_state = false,
        .blink_duration = gc.CURSOR_BLINK_DURATION,
        .blink_timer = 0,
        .current_text = "*".*,
        .x_int = 0,
        .y_int = 0,
        .current_selection = 0,
        .font = &normal_tf,
    }
};

pub const DisplayMessageType = enum {
    rally,
    lunge,
    catchback,
    point,
    starting,
    title_welcome1,
    title_welcome2,
    title_play,
    title_options,
};

pub const NO_DISPLAY_IDX_YET = -1;
pub const INF_DURATION = std.math.maxInt(u16);

pub var rally_count: u16 = 0;
pub var rally_idx: i16 = NO_DISPLAY_IDX_YET;
pub var start_idx: i16 = NO_DISPLAY_IDX_YET;
pub var rally_timestamp: u16 = 0;
pub var starting_count: u8 = 3;

pub fn reset_hover_display() void {
    rally_count = 0;
    rally_idx = NO_DISPLAY_IDX_YET;
    start_idx = NO_DISPLAY_IDX_YET;
    rally_timestamp = 0;
    starting_count = 3;
    for(&hover_display.message_ringbuffer) |*message| {
        message.is_active = false;
    }
}

// pushes current messages up, and 
pub fn display_msg(msg: DisplayMessageType) void{

    var current_bufmsg: *HoverMessage = &hover_display.message_ringbuffer[hover_display.message_top_idx];
    var tookup_new_slot: bool = true;

    switch(msg) {
        .rally => {

            if (rally_idx != NO_DISPLAY_IDX_YET) {
                current_bufmsg = &hover_display.message_ringbuffer[@intCast(usize, rally_idx)];
                tookup_new_slot = false;
            } else {
                rally_idx = hover_display.message_top_idx;
            } 

            rally_count += 1;

            if(rally_count > 4) {
                current_bufmsg.duration = 1000;
                current_bufmsg.text_font = &normal_tf;
                const rally_msg: *const [12]u8 = "  Rally     ";
                var rally_buf: [12]u8 = rally_msg.*;
                _ = std.fmt.bufPrint(rally_buf[9..12], "{d}", .{rally_count}) catch undefined;
                current_bufmsg.text = rally_buf;
            } else {
                tookup_new_slot = false;
                rally_idx = NO_DISPLAY_IDX_YET;
            }
            
            
        },
        .lunge => {
            current_bufmsg.text = "   Lunge!   ".*;
            current_bufmsg.duration = 50;
            current_bufmsg.text_font = &lunge_tf;
        },
        .catchback => {
            current_bufmsg.text = "   Catch!   ".*;
            current_bufmsg.duration = 50;
            current_bufmsg.text_font = &catchback_tf;
        },
        .starting => {
            current_bufmsg.text_font = &title_tf;
            if (start_idx != NO_DISPLAY_IDX_YET) {
                current_bufmsg = &hover_display.message_ringbuffer[@intCast(usize, start_idx)];
                tookup_new_slot = false;
            } else {
                start_idx = hover_display.message_top_idx;
            }
            if (starting_count > 0) {
                current_bufmsg.text = " Start in   ".*;
                _ = std.fmt.bufPrint(current_bufmsg.text[10..12], "{d}", .{starting_count}) catch undefined;
            } else {
                current_bufmsg.text = "    Go!!    ".*;
            }

            current_bufmsg.duration = 60;
            
            starting_count -= 1;
        },
        .title_welcome1 => {
            current_bufmsg.text = "    PING    ".*;
            current_bufmsg.duration = INF_DURATION;
            current_bufmsg.text_font = &title_tf;
        },
        .title_welcome2 => {
            current_bufmsg.text = "------------".*;
            current_bufmsg.duration = INF_DURATION;
            current_bufmsg.text_font = &normal_tf;
        },
        .title_play => {
            current_bufmsg.text = "Play:any key".*;
            current_bufmsg.duration = INF_DURATION;
            current_bufmsg.text_font = &normal_tf;
        },
        .title_options => {
            current_bufmsg.text = "            ".*;
            current_bufmsg.duration = INF_DURATION;
            current_bufmsg.text_font = &normal_tf;
        },
        else => {
            current_bufmsg.text = "NOOP        ".*;
            current_bufmsg.duration = INF_DURATION;
            current_bufmsg.text_font = &normal_tf;
        }
    }

    current_bufmsg.timer = 0;

    // if we take up a new slot in the ringbuffer,
    // existing active messages should shift upwards positionally (not in the ringbuffer idx).
    // the message in the last slot should fade out of existence.
    if(tookup_new_slot) {   
        current_bufmsg.is_active = true;
        for(&hover_display.message_ringbuffer) |*message| {
            message.y_target -= 10;
            message.y_int = @floatToInt(i32, message.y);
        }
        current_bufmsg.timestamp = rally_timestamp;
        rally_timestamp += 1;
        current_bufmsg.y_target = gc.HOVER_DISPLAY_Y;
        current_bufmsg.y = current_bufmsg.y_target + 20;
        current_bufmsg.y_int = @floatToInt(i32, current_bufmsg.y);
        hover_display.message_top_idx = @mod(hover_display.message_top_idx + 1, @intCast(u8, hover_display.message_ringbuffer.len));
    }
}

fn shift_messages_prior_to(timestamp: u16) void {
    for(&hover_display.message_ringbuffer) |*message| {
        if (message.timestamp < timestamp) {
            message.y_target += 10;
            // message.y_int = @floatToInt(i32, message.y);
        }
    }
}

// if messages are older than their timeouts, fade them out, and
// tell any older messages to drop down in position.
pub fn decay_messages()void {
    for(&hover_display.message_ringbuffer) |*message| {
        if(message.is_active) {
            message.y += 0.1 * (message.y_target - message.y);
            message.y_int = @floatToInt(i32, message.y);
            if(message.duration != INF_DURATION and message.timer >= message.duration) {
                message.is_active = false;
                // TODO fade out
                shift_messages_prior_to(message.timestamp);
            }
            message.timer += 1;
        }
    }
}

pub fn blink_cursor() void {
    hover_display.cursor.blink_timer += 1;
    if(hover_display.cursor.blink_timer >= hover_display.cursor.blink_duration) {
        hover_display.cursor.blink_timer = 0;
        hover_display.cursor.blink_state = !hover_display.cursor.blink_state;
    }
}