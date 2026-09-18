# 4. Remote sessions change the scale, not the resolution

- **Status:** accepted
- **Date:** 2026-09-18
- **Scope:** `.config/niri/`, `scripts/`, and the unstowed
  `~/.config/sunshine/sunshine.conf`

## Context

This desktop is reached from a 13" laptop over Moonlight, against a Sunshine
host on the desk machine. Everything on screen is laid out for the desk: one
1920x1080 monitor across 24", about 92 px per inch.

The same frame drawn on a 13.6" laptop panel is a little over half that size —
roughly 166 px per inch of stream, against 92 at the desk. Sitting closer to a
laptop recovers some of it, but not enough: code, the bar and menus all come out
too small to read for a working day.

Three ways out were available:

- **Lower the output mode.** `niri msg output DP-3 mode 1280x720` does make
  everything bigger. It also makes the framebuffer 1280x720, and the stream
  along with it. Every glyph gains size by losing detail — the worst trade of
  the three, given the encoder was never the constraint.
- **Stream at the laptop's native resolution.** Appealing, and impossible. The
  source framebuffer is 1920x1080 because that is the monitor's mode, and the
  panel supports nothing above it. Asking Moonlight for 2560x1664 only makes
  Sunshine upscale 1080p before encoding — more bitrate, not more detail. There
  is no second display to render a bigger desktop into: niri has no runtime
  virtual output, and the only spare connector holds a KVM capture device whose
  EDID also stops at 1080p.
- **Raise the output scale.** Sunshine captures through `wlr-screencopy`, which
  hands over the output's framebuffer. That buffer is the size of the *mode*,
  not of the logical desktop, so scale is invisible to the stream: `grim -o
  DP-3` still produces 1920x1080 at scale 1.5. Windows are laid out in 1280x720
  logical pixels and drawn into the full 1920x1080 — bigger text, same pixels,
  same bitrate.

## Decision

Remote sessions raise the scale of the streamed output and touch nothing else.

- **`.config/niri/scripts/stream-scale.sh`** drives it, symlinked into
  `~/.local/bin/stream-scale` like `alacritty_launcher`. It takes `on [SCALE]`,
  `off`, `toggle`, `up`, `down` and `status`, stepping through
  1 / 1.25 / 1.5 / 1.75 / 2. The default is 1.5: 1280x720 logical, which is
  about the apparent size the desk monitor has, and the largest step that still
  leaves room for two columns.
- **The output is resolved, not hardcoded** — `$STREAM_SCALE_OUTPUT`, else
  Sunshine's `output_name`, else the only enabled output, else the focused one.
  The desk runs one monitor at a time often enough that a hardcoded `DP-3`
  would be wrong on the days it does not.
- **Sunshine's `global_prep_cmd` calls `on` and `off`**, so connecting from the
  laptop scales the desktop up and disconnecting puts it back. A prep command
  that fails aborts the stream, which is why the script resolves the niri socket
  by globbing `$XDG_RUNTIME_DIR` rather than trusting the possibly stale
  `NIRI_SOCKET` that Sunshine's user service inherited at login.
- **`Mod+Ctrl+Equal` / `Mod+Ctrl+Minus` step it by hand**, next to the
  `Mod+Minus` / `Mod+Equal` column-width binds, for tuning mid-session or for
  the times the desk monitor itself wants to be bigger.

Fractional steps are only safe because every client here is a native Wayland
one; `xlsclients` lists nothing but Zoom's webview. An X11 client arriving
through xwayland-satellite would be drawn at 1x and upscaled, and the choice
would collapse back to 1x or 2x.

## Consequences

- The stream never loses resolution to legibility. Bitrate, mode and refresh
  rate are all unchanged by scaling.
- The laptop panel is 16:10 and the stream is 16:9, so Moonlight letterboxes.
  Moonlight should ask for 1920x1080 exactly — matching the source means no
  resampling before the encoder, and the laptop's own scaler does the only
  scaling in the chain.
- A stream that dies without its `undo` running leaves the desk monitor scaled
  up. It is obvious on sight and `stream-scale off` fixes it.
- `sunshine.conf` stays out of the repo, so this one line is not version
  controlled. Sunshine's web UI rewrites that file, and its log, state and
  credentials sit in the same directory.
- If a genuinely laptop-shaped remote desktop is ever wanted — 2560x1600, 16:10,
  independent of the desk monitor — the way there is a dummy plug on a spare
  connector, enabled with a custom mode and named as Sunshine's `output_name`.
  Nothing here forecloses that.
