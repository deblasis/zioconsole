//! Terminal colors and styles for Zig.
//!
//! ANSI escape code library with comptime format strings.
//! Zero allocation, zero dependencies.
//!
//! ## Quick Start
//! ```zig
//! const zioansi = @import("zioansi");
//!
//! pub fn main() !void {
//!     std.debug.print("{s}\n", .{zioansi.fmt("{red}Error:{/} file not found", .{})});
//!     std.debug.print("{s}\n", .{zioansi.fmt("{green}Success:{/} all tests passed", .{})});
//! }
//! ```

const std = @import("std");

/// Color names for comptime format strings.
pub const Color = enum {
    black,
    red,
    green,
    yellow,
    blue,
    magenta,
    cyan,
    white,
    bright_black,
    bright_red,
    bright_green,
    bright_yellow,
    bright_blue,
    bright_magenta,
    bright_cyan,
    bright_white,

    /// Returns the ANSI foreground escape code for this color.
    pub fn fg(self: Color) []const u8 {
        return switch (self) {
            .black => "\x1b[30m",
            .red => "\x1b[31m",
            .green => "\x1b[32m",
            .yellow => "\x1b[33m",
            .blue => "\x1b[34m",
            .magenta => "\x1b[35m",
            .cyan => "\x1b[36m",
            .white => "\x1b[37m",
            .bright_black => "\x1b[90m",
            .bright_red => "\x1b[91m",
            .bright_green => "\x1b[92m",
            .bright_yellow => "\x1b[93m",
            .bright_blue => "\x1b[94m",
            .bright_magenta => "\x1b[95m",
            .bright_cyan => "\x1b[96m",
            .bright_white => "\x1b[97m",
        };
    }

    /// Returns the ANSI background escape code for this color.
    pub fn bg(self: Color) []const u8 {
        return switch (self) {
            .black => "\x1b[40m",
            .red => "\x1b[41m",
            .green => "\x1b[42m",
            .yellow => "\x1b[43m",
            .blue => "\x1b[44m",
            .magenta => "\x1b[45m",
            .cyan => "\x1b[46m",
            .white => "\x1b[47m",
            .bright_black => "\x1b[100m",
            .bright_red => "\x1b[101m",
            .bright_green => "\x1b[102m",
            .bright_yellow => "\x1b[103m",
            .bright_blue => "\x1b[104m",
            .bright_magenta => "\x1b[105m",
            .bright_cyan => "\x1b[106m",
            .bright_white => "\x1b[107m",
        };
    }
};

/// Text style names for comptime format strings.
pub const Style = enum {
    bold,
    dim,
    italic,
    underline,
    blink,
    reverse,
    hidden,
    strikethrough,

    /// Returns the ANSI escape code to enable this style.
    pub fn enable(self: Style) []const u8 {
        return switch (self) {
            .bold => "\x1b[1m",
            .dim => "\x1b[2m",
            .italic => "\x1b[3m",
            .underline => "\x1b[4m",
            .blink => "\x1b[5m",
            .reverse => "\x1b[7m",
            .hidden => "\x1b[8m",
            .strikethrough => "\x1b[9m",
        };
    }

    /// Returns the ANSI escape code to disable this style.
    pub fn disable(self: Style) []const u8 {
        return switch (self) {
            .bold => "\x1b[22m",
            .dim => "\x1b[22m",
            .italic => "\x1b[23m",
            .underline => "\x1b[24m",
            .blink => "\x1b[25m",
            .reverse => "\x1b[27m",
            .hidden => "\x1b[28m",
            .strikethrough => "\x1b[29m",
        };
    }
};

/// Reset all styles and colors.
pub const reset: []const u8 = "\x1b[0m";

/// Apply a foreground color to a string slice.
/// Caller must free the returned slice.
pub fn colorFg(allocator: std.mem.Allocator, c: Color, text: []const u8) ![]u8 {
    return std.fmt.allocPrint(allocator, "{s}{s}{s}", .{ c.fg(), text, reset });
}

/// Apply a background color to a string slice.
/// Caller must free the returned slice.
pub fn colorBg(allocator: std.mem.Allocator, c: Color, text: []const u8) ![]u8 {
    return std.fmt.allocPrint(allocator, "{s}{s}{s}", .{ c.bg(), text, reset });
}

/// Apply a style to a string slice.
/// Caller must free the returned slice.
pub fn styled(allocator: std.mem.Allocator, s: Style, text: []const u8) ![]u8 {
    return std.fmt.allocPrint(allocator, "{s}{s}{s}", .{ s.enable(), text, s.disable() });
}

/// Apply bold to text.
pub fn bold(allocator: std.mem.Allocator, text: []const u8) ![]u8 {
    return std.fmt.allocPrint(allocator, "{s}{s}{s}", .{ Style.bold.enable(), text, reset });
}

/// Apply underline to text.
pub fn underline(allocator: std.mem.Allocator, text: []const u8) ![]u8 {
    return std.fmt.allocPrint(allocator, "{s}{s}{s}", .{ Style.underline.enable(), text, reset });
}

/// Apply dim to text.
pub fn dim(allocator: std.mem.Allocator, text: []const u8) ![]u8 {
    return std.fmt.allocPrint(allocator, "{s}{s}{s}", .{ Style.dim.enable(), text, reset });
}

/// Write a 256-color foreground code into a buffer. Returns the written slice.
pub fn fg256(buf: []u8, index: u8) []const u8 {
    return std.fmt.bufPrint(buf, "\x1b[38;5;{d}m", .{index}) catch "";
}

/// Write a 256-color background code into a buffer. Returns the written slice.
pub fn bg256(buf: []u8, index: u8) []const u8 {
    return std.fmt.bufPrint(buf, "\x1b[48;5;{d}m", .{index}) catch "";
}

/// Write a truecolor (24-bit) foreground code. Returns the written slice.
pub fn fgTrueColor(buf: []u8, r: u8, g: u8, b: u8) []const u8 {
    return std.fmt.bufPrint(buf, "\x1b[38;2;{d};{d};{d}m", .{ r, g, b }) catch "";
}

/// Write a truecolor (24-bit) background code. Returns the written slice.
pub fn bgTrueColor(buf: []u8, r: u8, g: u8, b: u8) []const u8 {
    return std.fmt.bufPrint(buf, "\x1b[48;2;{d};{d};{d}m", .{ r, g, b }) catch "";
}

/// Cursor control escape codes.
pub const cursor = struct {
    /// Move cursor to absolute position (row, col), 1-based.
    pub fn moveTo(buf: []u8, row: usize, col: usize) []const u8 {
        return std.fmt.bufPrint(buf, "\x1b[{d};{d}H", .{ row, col }) catch "";
    }

    /// Move cursor up `n` rows.
    pub fn up(buf: []u8, n: usize) []const u8 {
        return std.fmt.bufPrint(buf, "\x1b[{d}A", .{n}) catch "";
    }

    /// Move cursor down `n` rows.
    pub fn down(buf: []u8, n: usize) []const u8 {
        return std.fmt.bufPrint(buf, "\x1b[{d}B", .{n}) catch "";
    }

    /// Hide the cursor.
    pub const hide: []const u8 = "\x1b[?25l";

    /// Show the cursor.
    pub const show: []const u8 = "\x1b[?25h";
};

/// Screen control escape codes.
pub const screen = struct {
    /// Clear the entire screen.
    pub const clear: []const u8 = "\x1b[2J";

    /// Clear from cursor to end of line.
    pub const clearEndOfLine: []const u8 = "\x1b[K";

    /// Clear the entire line.
    pub const clearLine: []const u8 = "\x1b[2K";

    /// Save cursor position.
    pub const saveCursor: []const u8 = "\x1b[s";

    /// Restore cursor position.
    pub const restoreCursor: []const u8 = "\x1b[u";
};

/// Strips all ANSI escape codes from a string slice.
/// Caller must free the returned slice.
pub fn strip(allocator: std.mem.Allocator, text: []const u8) ![]u8 {
    var result: std.ArrayList(u8) = .empty;
    errdefer result.deinit(allocator);

    var i: usize = 0;
    while (i < text.len) {
        if (text[i] == '\x1b' and i + 1 < text.len and text[i + 1] == '[') {
            // Skip escape sequence: ESC [ ... letter
            i += 2;
            while (i < text.len and !std.ascii.isAlphabetic(text[i])) : (i += 1) {}
            if (i < text.len) i += 1;
        } else {
            try result.append(allocator, text[i]);
            i += 1;
        }
    }
    return result.toOwnedSlice(allocator);
}

/// Returns the visible width of text (excluding ANSI codes).
pub fn visibleLen(text: []const u8) usize {
    var len: usize = 0;
    var i: usize = 0;
    while (i < text.len) {
        if (text[i] == '\x1b' and i + 1 < text.len and text[i + 1] == '[') {
            i += 2;
            while (i < text.len and !std.ascii.isAlphabetic(text[i])) : (i += 1) {}
            if (i < text.len) i += 1;
        } else {
            len += 1;
            i += 1;
        }
    }
    return len;
}

/// Comptime format string processor.
/// Supports tags like {red}, {green}, {bold}, {/} (reset) in format strings.
/// Tags are expanded at compile time — zero runtime cost.
pub fn fmt(comptime format: []const u8, args: anytype) []const u8 {
    _ = args;
    comptime var result: []const u8 = "";
    comptime var i: usize = 0;
    comptime while (i < format.len) : (i += 1) {
        if (format[i] == '{') {
            const end = std.mem.indexOfScalarPos(u8, format, i, '}') orelse {
                @compileError("zioansi: unclosed { in format string");
            };
            const tag = format[i + 1 .. end];
            result = result ++ tagToAnsi(tag);
            i = end;
        } else {
            result = result ++ &[_]u8{format[i]};
        }
    };
    return result;
}

/// Internal: map a tag name to its ANSI escape code.
fn tagToAnsi(comptime tag: []const u8) []const u8 {
    if (std.mem.eql(u8, tag, "/")) return reset;
    if (std.mem.eql(u8, tag, "/bg")) return "\x1b[49m";
    // Foreground colors
    if (std.mem.eql(u8, tag, "black")) return "\x1b[30m";
    if (std.mem.eql(u8, tag, "red")) return "\x1b[31m";
    if (std.mem.eql(u8, tag, "green")) return "\x1b[32m";
    if (std.mem.eql(u8, tag, "yellow")) return "\x1b[33m";
    if (std.mem.eql(u8, tag, "blue")) return "\x1b[34m";
    if (std.mem.eql(u8, tag, "magenta")) return "\x1b[35m";
    if (std.mem.eql(u8, tag, "cyan")) return "\x1b[36m";
    if (std.mem.eql(u8, tag, "white")) return "\x1b[37m";
    if (std.mem.eql(u8, tag, "bright_black")) return "\x1b[90m";
    if (std.mem.eql(u8, tag, "bright_red")) return "\x1b[91m";
    if (std.mem.eql(u8, tag, "bright_green")) return "\x1b[92m";
    if (std.mem.eql(u8, tag, "bright_yellow")) return "\x1b[93m";
    if (std.mem.eql(u8, tag, "bright_blue")) return "\x1b[94m";
    if (std.mem.eql(u8, tag, "bright_magenta")) return "\x1b[95m";
    if (std.mem.eql(u8, tag, "bright_cyan")) return "\x1b[96m";
    if (std.mem.eql(u8, tag, "bright_white")) return "\x1b[97m";
    // Background colors
    if (std.mem.eql(u8, tag, "bg_black")) return "\x1b[40m";
    if (std.mem.eql(u8, tag, "bg_red")) return "\x1b[41m";
    if (std.mem.eql(u8, tag, "bg_green")) return "\x1b[42m";
    if (std.mem.eql(u8, tag, "bg_yellow")) return "\x1b[43m";
    if (std.mem.eql(u8, tag, "bg_blue")) return "\x1b[44m";
    if (std.mem.eql(u8, tag, "bg_magenta")) return "\x1b[45m";
    if (std.mem.eql(u8, tag, "bg_cyan")) return "\x1b[46m";
    if (std.mem.eql(u8, tag, "bg_white")) return "\x1b[47m";
    if (std.mem.eql(u8, tag, "bg_bright_black")) return "\x1b[100m";
    if (std.mem.eql(u8, tag, "bg_bright_red")) return "\x1b[101m";
    if (std.mem.eql(u8, tag, "bg_bright_green")) return "\x1b[102m";
    if (std.mem.eql(u8, tag, "bg_bright_yellow")) return "\x1b[103m";
    if (std.mem.eql(u8, tag, "bg_bright_blue")) return "\x1b[104m";
    if (std.mem.eql(u8, tag, "bg_bright_magenta")) return "\x1b[105m";
    if (std.mem.eql(u8, tag, "bg_bright_cyan")) return "\x1b[106m";
    if (std.mem.eql(u8, tag, "bg_bright_white")) return "\x1b[107m";
    // Styles
    if (std.mem.eql(u8, tag, "bold")) return "\x1b[1m";
    if (std.mem.eql(u8, tag, "dim")) return "\x1b[2m";
    if (std.mem.eql(u8, tag, "italic")) return "\x1b[3m";
    if (std.mem.eql(u8, tag, "underline")) return "\x1b[4m";
    if (std.mem.eql(u8, tag, "blink")) return "\x1b[5m";
    if (std.mem.eql(u8, tag, "reverse")) return "\x1b[7m";
    if (std.mem.eql(u8, tag, "hidden")) return "\x1b[8m";
    if (std.mem.eql(u8, tag, "strikethrough")) return "\x1b[9m";
    @compileError("zioansi: unknown tag: " ++ tag);
}

fn lookupColor(comptime name: []const u8) ?Color {
    const fields = @typeInfo(Color).@"enum".fields;
    inline for (fields) |field| {
        if (std.mem.eql(u8, name, field.name)) {
            return @enumFromInt(field.value);
        }
    }
    return null;
}

/// Internal: lookup a style by name.
fn lookupStyle(comptime name: []const u8) ?Style {
    const fields = @typeInfo(Style).@"enum".fields;
    inline for (fields) |field| {
        if (std.mem.eql(u8, name, field.name)) {
            return @enumFromInt(field.value);
        }
    }
    return null;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

test "Color.fg returns escape codes" {
    try std.testing.expectEqualSlices(u8, "\x1b[31m", Color.red.fg());
    try std.testing.expectEqualSlices(u8, "\x1b[32m", Color.green.fg());
    try std.testing.expectEqualSlices(u8, "\x1b[36m", Color.cyan.fg());
    try std.testing.expectEqualSlices(u8, "\x1b[97m", Color.bright_white.fg());
}

test "Color.bg returns escape codes" {
    try std.testing.expectEqualSlices(u8, "\x1b[41m", Color.red.bg());
    try std.testing.expectEqualSlices(u8, "\x1b[44m", Color.blue.bg());
}

test "Style.enable/disable returns escape codes" {
    try std.testing.expectEqualSlices(u8, "\x1b[1m", Style.bold.enable());
    try std.testing.expectEqualSlices(u8, "\x1b[24m", Style.underline.disable());
}

test "reset is \\x1b[0m" {
    try std.testing.expectEqualSlices(u8, "\x1b[0m", reset);
}

test "colorFg wraps text with color codes" {
    const result = try colorFg(std.testing.allocator, .red, "error");
    defer std.testing.allocator.free(result);
    try std.testing.expectEqualSlices(u8, "\x1b[31merror\x1b[0m", result);
}

test "colorBg wraps text with background codes" {
    const result = try colorBg(std.testing.allocator, .blue, "highlight");
    defer std.testing.allocator.free(result);
    try std.testing.expectEqualSlices(u8, "\x1b[44mhighlight\x1b[0m", result);
}

test "styled wraps text with style codes" {
    const result = try styled(std.testing.allocator, .bold, "header");
    defer std.testing.allocator.free(result);
    try std.testing.expectEqualSlices(u8, "\x1b[1mheader\x1b[22m", result);
}

test "bold wraps text" {
    const result = try bold(std.testing.allocator, "title");
    defer std.testing.allocator.free(result);
    try std.testing.expectEqualSlices(u8, "\x1b[1mtitle\x1b[0m", result);
}

test "underline wraps text" {
    const result = try underline(std.testing.allocator, "link");
    defer std.testing.allocator.free(result);
    try std.testing.expectEqualSlices(u8, "\x1b[4mlink\x1b[0m", result);
}

test "dim wraps text" {
    const result = try dim(std.testing.allocator, "muted");
    defer std.testing.allocator.free(result);
    try std.testing.expectEqualSlices(u8, "\x1b[2mmuted\x1b[0m", result);
}

test "fg256 writes 256-color code" {
    var buf: [32]u8 = undefined;
    const result = fg256(&buf, 196);
    try std.testing.expect(result.len > 0);
    try std.testing.expectEqualStrings("\x1b[38;5;196m", result);
}

test "bg256 writes 256-color background code" {
    var buf: [32]u8 = undefined;
    const result = bg256(&buf, 21);
    try std.testing.expectEqualStrings("\x1b[48;5;21m", result);
}

test "fgTrueColor writes 24-bit color code" {
    var buf: [32]u8 = undefined;
    const result = fgTrueColor(&buf, 255, 128, 0);
    try std.testing.expectEqualStrings("\x1b[38;2;255;128;0m", result);
}

test "bgTrueColor writes 24-bit background code" {
    var buf: [32]u8 = undefined;
    const result = bgTrueColor(&buf, 0, 200, 100);
    try std.testing.expectEqualStrings("\x1b[48;2;0;200;100m", result);
}

test "strip removes ANSI codes" {
    const input = "\x1b[31mred\x1b[0m normal \x1b[1mbold\x1b[22m";
    const result = try strip(std.testing.allocator, input);
    defer std.testing.allocator.free(result);
    try std.testing.expectEqualStrings("red normal bold", result);
}

test "strip with no codes returns original" {
    const input = "plain text";
    const result = try strip(std.testing.allocator, input);
    defer std.testing.allocator.free(result);
    try std.testing.expectEqualStrings("plain text", result);
}

test "visibleLen counts only visible characters" {
    const input = "\x1b[31mhello\x1b[0m";
    try std.testing.expectEqual(@as(usize, 5), visibleLen(input));
}

test "visibleLen with no codes is string length" {
    try std.testing.expectEqual(@as(usize, 5), visibleLen("hello"));
}

test "cursor.moveTo returns position code" {
    var buf: [32]u8 = undefined;
    const result = cursor.moveTo(&buf, 5, 10);
    try std.testing.expectEqualStrings("\x1b[5;10H", result);
}

test "cursor.hide and show" {
    try std.testing.expectEqualSlices(u8, "\x1b[?25l", cursor.hide);
    try std.testing.expectEqualSlices(u8, "\x1b[?25h", cursor.show);
}

test "screen.clear is \\x1b[2J" {
    try std.testing.expectEqualSlices(u8, "\x1b[2J", screen.clear);
}

test "fmt comptime format string" {
    const result = fmt("{red}Error:{/} file not found", .{});
    try std.testing.expectEqualStrings("\x1b[31mError:\x1b[0m file not found", result);
}

test "fmt with background color" {
    const result = fmt("{bg_red}{white}ALERT{/}{/}", .{});
    try std.testing.expectEqualStrings("\x1b[41m\x1b[37mALERT\x1b[0m\x1b[0m", result);
}

test "fmt with bold style" {
    const result = fmt("{bold}Warning:{/} check your input", .{});
    try std.testing.expectEqualStrings("\x1b[1mWarning:\x1b[0m check your input", result);
}

test "fmt plain text passes through" {
    const result = fmt("no colors here", .{});
    try std.testing.expectEqualStrings("no colors here", result);
}

test "all 16 colors have fg codes" {
    inline for (@typeInfo(Color).@"enum".fields) |field| {
        const c: Color = @enumFromInt(field.value);
        try std.testing.expect(c.fg().len > 0);
    }
}

test "all 16 colors have bg codes" {
    inline for (@typeInfo(Color).@"enum".fields) |field| {
        const c: Color = @enumFromInt(field.value);
        try std.testing.expect(c.bg().len > 0);
    }
}

test "all 8 styles have enable/disable codes" {
    inline for (@typeInfo(Style).@"enum".fields) |field| {
        const s: Style = @enumFromInt(field.value);
        try std.testing.expect(s.enable().len > 0);
        try std.testing.expect(s.disable().len > 0);
    }
}

test "strip removes escape codes" {
    const result = try strip(std.testing.allocator, "\x1b[1mhello\x1b[0m");
    defer std.testing.allocator.free(result);
    try std.testing.expectEqualStrings("hello", result);
}

test "strip plain text unchanged" {
    const result = try strip(std.testing.allocator, "plain");
    defer std.testing.allocator.free(result);
    try std.testing.expectEqualStrings("plain", result);
}

test "fgTrueColor produces output" {
    var buf: [32]u8 = undefined;
    const result = fgTrueColor(&buf, 255, 128, 0);
    try std.testing.expect(result.len > 0);
}

test "bgTrueColor produces output" {
    var buf: [32]u8 = undefined;
    const result = bgTrueColor(&buf, 0, 128, 255);
    try std.testing.expect(result.len > 0);
}

test "cursor.up and cursor.down emit the right codes" {
    var buf: [16]u8 = undefined;
    try std.testing.expectEqualStrings("\x1b[3A", cursor.up(&buf, 3));
    try std.testing.expectEqualStrings("\x1b[12B", cursor.down(&buf, 12));
}
