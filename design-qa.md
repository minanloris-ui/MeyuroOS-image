# Meyuro Glass window-only visual QA

## Comparison target

- Source visual truth: `C:\Users\sasha\Downloads\Window.png`
- Source pixels: 1586 x 992
- Baseline implementation screenshot: `C:\Users\sasha\AppData\Local\Temp\codex-clipboard-e0fc04fd-b814-43cb-932c-cdd7d3ef6e5a.png`
- Baseline pixels: 1252 x 725
- Revised implementation screenshot: unavailable
- CSS viewport and device scale: not applicable/unknown; both artifacts are native desktop captures at different screen sizes
- State: active KDE System Settings window on Quick Settings
- Scope: application windows only; Plasma panel, launcher, desktop, and wallpaper are explicitly excluded

## Full-view comparison evidence

The source uses a visibly translucent blue-to-violet window, a luminous rounded
outer frame, roomy rounded controls, and softened backdrop detail. The baseline
implementation remains visually identifiable as opaque Breeze: charcoal content,
gray rectangular controls, a thin square frame, and standard title-bar buttons.
The differing screenshot sizes prevent pixel-level spacing measurements, but the
missing material, color, radius, and elevation are unambiguous at full-view scale.

## Focused-region comparison evidence

The title bar and right-side window controls were inspected closely because they
are the most toolkit-independent fidelity surface. The source has 10-16 px corner
radii, translucent blue/purple fill, a light edge, and rounded 34 px controls. The
baseline has square corners and flat monochrome controls. The content controls
show the same mismatch: the source uses blue glass fills and cyan focus borders,
while the baseline uses opaque gray Breeze buttons.

## Findings and fixes

- [P1] Window style was not reliably activated.
  - Evidence: the baseline uses Breeze for both the frame and application controls.
  - Fix applied: added system defaults, a systemd-user activation unit, an XDG
    autostart fallback, a versioned migration, explicit `kvantummanager --set`,
    and a Breeze-to-Kvantum live style reload.
- [P1] Aurorae blur declaration used the wrong element structure.
  - Evidence: the previous SVG contained nine `mask-*` slices, while Aurorae
    requires one element with the exact ID `mask`; without it decoration blur is
    disabled.
  - Fix applied: replaced the slices with one rounded `mask` and retained the
    active/inactive nine-slice decoration frames.
- [P1] Earlier activation could also replace the Plasma shell theme.
  - Evidence: the helper wrote `plasmarc/Theme/name=MeyuroGlass` and applied a
    Look-and-Feel package.
  - Fix applied: removed the Plasma desktop/global theme packages and global KDE
    color-scheme application. The helper now restores the old Meyuro-owned shell
    values only when present.
- [P2] The one-pixel side/bottom frame could not show the intended rounded glass
  silhouette.
  - Fix applied: increased side borders to 7 px and the bottom border to 10 px;
    normal, dialog, and utility windows receive 94%/88% active/inactive opacity.
    The KWin type mask is `289`, which excludes Dock/panel and Desktop surfaces.

## Required fidelity surfaces

- Fonts and typography: unchanged intentionally; the source and baseline use a
  compatible KDE UI sans-serif hierarchy.
- Spacing and layout rhythm: application-owned layouts are preserved; only frame
  depth, control skin, and radius are changed.
- Colors and visual tokens: blue `#122d5e`, cyan `#2baeff`, violet edge tint,
  translucent control fills, and white foregrounds are encoded in Kvantum,
  Aurorae, and GTK window styles.
- Image quality and asset fidelity: no raster imagery belongs to the window-only
  scope. Wallpaper and shell assets are intentionally unchanged.
- Copy and content: application text is unchanged.

## Comparison history

1. Baseline: P1 material, radius, and activation mismatch visible in the supplied
   System Settings screenshot.
2. Code fixes: reliable window-only activation, correct Aurorae blur mask, wider
   rounded frame, KWin window-type filter, and removal of shell-theme mutation.
3. Post-fix capture: blocked until the new bootable image is built and opened in
   a KDE Plasma/KWin session.

## Verification blocker

This Windows workspace has no Docker, Podman, installed WSL distribution, or
running KDE Plasma/KWin session. The native theme cannot be rendered or captured
here, so the revised image cannot yet be visually compared against the source.
Static SVG/XML, shell syntax, window-scope, and integration checks pass, but they
do not substitute for a post-boot visual capture.

final result: blocked
