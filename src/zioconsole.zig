//! Inline live terminal display for Zig.
//!
//! A scrolling log region with a single status line pinned at the bottom — the
//! `scp`/`cargo`/`apt` pattern. As you `println` log lines they scroll up into
//! the terminal's real scrollback history (preserved after exit); the status
//! line stays pinned at the bottom and is redrawn on every `set`.
//!
//! Technique (same as Rust's `indicatif` and Python's `rich`): each `println`
//! writes the log line at the bottom then a newline, so the terminal scrolls
//! that line up into history naturally; the status is then redrawn on the
//! bottom line. No alternate screen, no DECSTBM scroll regions — fully portable
//! VT, and scrollback is preserved.
//!
//! Thread-safe (a mutex around the redraw) so worker threads can `println` while
//! a renderer thread `set`s. When the stream is not a TTY, `set` is a no-op and
//! `println` writes the line verbatim, so pipes/CI get clean per-line logs and
//! no control codes.
//!
//! v1 pins a single-line status. Keep `set`'s status to one visual line (it is
//! rendered as-is; if it wraps the layout breaks). ANSI styling in the status is
//! fine (written byte-for-byte).

const std = @import("std");
const builtin = @import("builtin");
const zioansi = @import("zioansi");

/// Which standard stream to render to.
pub const Stream = enum { stdout, stderr };

pub const Options = struct {
    stream: Stream = .stderr,
};

// libc ioctl with the correct macOS/BSD signature (request is `unsigned long`).
// std.c.ioctl declares request as c_int, which corrupts the value passed
// variadically on 64-bit BSD-derived systems, so we declare our own.
extern "c" fn ioctl(fd: c_int, request: c_ulong, ...) c_int;

/// Query the terminal's column count for the given fd, or null if unknown.
/// Linux: `ioctl(TIOCGWINSZ)` via std.os.linux. macOS/BSD: libc `ioctl`.
/// Windows/other: null (use a default). Useful for sizing/truncating output.
pub fn termCols(fd: std.posix.fd_t) ?u16 {
    switch (builtin.os.tag) {
        .linux => {
            var ws: std.posix.winsize = undefined;
            const rc = std.os.linux.ioctl(fd, std.os.linux.T.IOCGWINSZ, @intFromPtr(&ws));
            if (std.os.linux.E.init(rc) != .SUCCESS) return null;
            if (ws.ws_col == 0) return null;
            return ws.ws_col;
        },
        .macos, .ios, .freebsd, .netbsd, .openbsd, .dragonfly => {
            // TIOCGWINSZ = _IOR('t', 104, winsize) on BSD-derived systems.
            const TIOCGWINSZ: c_ulong = 0x40087468;
            var ws: std.posix.winsize = undefined;
            if (ioctl(@intCast(fd), TIOCGWINSZ, &ws) != 0) return null;
            if (ws.ws_col == 0) return null;
            return ws.ws_col;
        },
        else => return null,
    }
}

/// Concatenate `slices` into `buf`, truncating to fit. Returns the written slice.
fn cat(buf: []u8, slices: []const []const u8) []const u8 {
    var n: usize = 0;
    for (slices) |s| {
        const m = @min(s.len, buf.len - n);
        @memcpy(buf[n..][0..m], s[0..m]);
        n += m;
    }
    return buf[0..n];
}

/// Bytes to redraw the status line: carriage return + clear-line + status.
/// Pure: testable without a TTY.
pub fn renderStatus(buf: []u8, status: []const u8) []const u8 {
    return cat(buf, &.{ "\r", zioansi.screen.clearLine, status });
}

/// Bytes for a log line. If a status is currently drawn, the log line is written
/// at the bottom then scrolled up (newline), and the status redrawn below it —
/// preserving scrollback and keeping the status pinned. Otherwise the line is
/// emitted plainly. Pure: testable without a TTY.
pub fn renderPrintln(buf: []u8, text: []const u8, status: []const u8, drawn: bool) []const u8 {
    if (!drawn) return cat(buf, &.{ text, "\n" });
    return cat(buf, &.{
        "\r", zioansi.screen.clearLine, text, "\n",
        "\r", zioansi.screen.clearLine, status,
    });
}

/// Bytes to clear the drawn status line.
pub fn renderClear(buf: []u8) []const u8 {
    return cat(buf, &.{ "\r", zioansi.screen.clearLine });
}

/// An inline live display: scrolling log + a single pinned status line.
pub const Live = struct {
    io: std.Io,
    file: std.Io.File,
    is_tty: bool,
    drawn: bool,
    status: [512]u8 = undefined,
    status_len: u32 = 0,
    mutex: std.Thread.Mutex = .{},
    out: [4096]u8 = undefined, // render* output (the sequence to emit)
    wbuf: [4096]u8 = undefined, // writer's own buffer (distinct from `out`)

    pub fn init(io: std.Io, opts: Options) Live {
        const file = switch (opts.stream) {
            .stderr => std.Io.File.stderr(),
            .stdout => std.Io.File.stdout(),
        };
        return .{
            .io = io,
            .file = file,
            .is_tty = file.isTty(io) catch false,
            .drawn = false,
        };
    }

    /// Write `bytes` through one buffered writer + a single flush.
    fn emit(self: *Live, bytes: []const u8) void {
        var fw = self.file.writer(self.io, &self.wbuf);
        const w = &fw.interface;
        w.writeAll(bytes) catch {};
        w.flush() catch {};
    }

    /// Redraw the pinned status line at the bottom. No-op when not a TTY.
    pub fn set(self: *Live, status: []const u8) void {
        if (!self.is_tty) return;
        self.mutex.lock();
        defer self.mutex.unlock();
        const m = @min(status.len, self.status.len);
        @memcpy(self.status[0..m], status[0..m]);
        self.status_len = @intCast(m);
        const s = renderStatus(&self.out, self.status[0..self.status_len]);
        self.emit(s);
        self.drawn = true;
    }

    /// Print a log line above the status; preserved in scrollback. When not a
    /// TTY, writes the line verbatim (no control codes) so pipes stay clean.
    pub fn println(self: *Live, text: []const u8) void {
        self.mutex.lock();
        defer self.mutex.unlock();
        if (!self.is_tty) {
            self.emit(cat(&self.out, &.{ text, "\n" }));
            return;
        }
        const status = self.status[0..self.status_len];
        const s = renderPrintln(&self.out, text, status, self.drawn);
        self.emit(s);
    }

    /// Wipe the status line.
    pub fn clear(self: *Live) void {
        self.mutex.lock();
        defer self.mutex.unlock();
        if (!self.is_tty or !self.drawn) return;
        self.emit(renderClear(&self.out));
        self.drawn = false;
        self.status_len = 0;
    }

    /// Leave the last status line in scrollback and advance to a fresh line.
    pub fn finish(self: *Live) void {
        self.mutex.lock();
        defer self.mutex.unlock();
        if (!self.is_tty or !self.drawn) return;
        self.emit("\n");
        self.drawn = false;
    }

    /// Tidy up: clear the status line if still drawn.
    pub fn deinit(self: *Live) void {
        if (self.drawn) self.clear();
    }
};

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

const testing = std.testing;

test "renderStatus emits CR + clearLine + status" {
    var buf: [64]u8 = undefined;
    const s = renderStatus(&buf, "bar");
    try testing.expect(std.mem.startsWith(u8, s, "\r"));
    try testing.expect(std.mem.indexOf(u8, s, "\x1b[2K") != null);
    try testing.expect(std.mem.endsWith(u8, s, "bar"));
}

test "renderPrintln plain when no status drawn" {
    var buf: [64]u8 = undefined;
    const s = renderPrintln(&buf, "hello", "", false);
    try testing.expectEqualStrings("hello\n", s);
}

test "renderPrintln scrolls the line and redraws the status when drawn" {
    var buf: [128]u8 = undefined;
    const s = renderPrintln(&buf, "f1", "BAR", true);
    // Sequence: CR+clear, log line, newline (scroll), CR+clear, status redrawn.
    try testing.expect(std.mem.startsWith(u8, s, "\r\x1b[2K"));
    try testing.expect(std.mem.indexOf(u8, s, "f1\n") != null);
    try testing.expect(std.mem.endsWith(u8, s, "BAR"));
}

test "renderClear emits CR + clearLine only" {
    var buf: [16]u8 = undefined;
    const s = renderClear(&buf);
    try testing.expectEqualStrings("\r\x1b[2K", s);
}

test "cat truncates to buffer length" {
    var buf: [5]u8 = undefined;
    const s = cat(&buf, &.{ "abc", "defg" });
    try testing.expectEqual(@as(usize, 5), s.len);
    try testing.expectEqualStrings("abcde", s);
}
