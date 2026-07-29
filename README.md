# zioconsole

Inline live terminal display for Zig — a scrolling log region with a single
status line pinned at the bottom. The `scp` / `cargo` / `apt` pattern.

```zig
const zioconsole = @import("zioconsole");

var live = zioconsole.Live.init(io, .{});
defer live.deinit();

live.set("working... [====>    ] 42%");          // redraw the pinned status line
live.println("✓ deploy/app.js   (2.3 MiB)");      // scrolls above; preserved in scrollback
live.println("✓ deploy/style.css (41 KiB)");
live.finish();                                     // status line stays in scrollback
```

As you `println`, each line is written at the bottom and scrolled up into the
terminal's real history (preserved after exit); the status line is redrawn at the
bottom on every `set`. No alternate screen, no scroll regions — fully portable
VT, and scrollback is preserved.

## Why

The zio fleet splits responsibilities: `zioprogress` does bar math, `zioansi`
emits ANSI codes, `zioterm` formats text. `zioconsole` owns the **terminal
layout** — a pinned live status line plus a scrolling log, the way every
long-running CLI reports progress. Built on the same technique as Rust's
`indicatif` and Python's `rich` (cursor-up + clear + redraw), not DECSTBM.

## Properties

- **Scrollback-preserving.** Printed lines are real terminal output; they scroll
  into history and remain when the program exits.
- **Thread-safe.** A mutex around the redraw, so worker threads can `println`
  while a renderer thread `set`s.
- **TTY-gated.** When the stream is not a TTY, `set` is a no-op and `println`
  writes the line verbatim — pipes and CI get clean per-line logs, no codes.
- **v1 pins a single-line status.** Keep `set`'s status to one visual line.

## Install

```sh
zig fetch --save git+https://github.com/deblasis/zioconsole#v0.1.0
```

```zig
// build.zig
const mod = b.dependency("zioconsole", .{
    .target = target, .optimize = optimize,
}).module("zioconsole");
exe.root_module.addImport("zioconsole", mod);
```

Requires Zig 0.16. Depends on [`zioansi`](https://github.com/deblasis/zioansi).

## License

MIT.
