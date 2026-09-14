# Meyuro Glass visual QA

## Capture context

- Source visual truth: `C:\Users\sasha\Downloads\Window.png`
- Source viewport: 1586 x 992 px
- Source state: active MeyuroOS System Settings window, Quick Settings page
- Previous implementation reference: `C:\Users\sasha\AppData\Local\Temp\codex-clipboard-971aae27-94ab-4135-a435-79caf4c1ee31.png` (1155 x 705 px)
- Implementation capture: unavailable
- Implementation viewport and density: unavailable
- Reason: this workspace is Windows-only and has no Podman, Docker, installed WSL distribution, or running KDE Plasma/KWin session. Local browser access to the theme SVG was also denied by the browser security policy.

## Comparison status

No valid side-by-side pixel comparison can be made until the image is built and booted in a KDE Plasma session. The implementation has therefore not been visually signed off.

Structural validation completed:

- Plasma 6 global-theme and desktop-theme metadata parse successfully.
- Aurorae decoration and button SVG files parse successfully and expose all required active, inactive, hover, pressed, mask, and nine-slice frame IDs.
- Qt 5/6 Kvantum, GTK 3/4, KDE color-scheme, KWin blur, and first-login activation paths are present.
- Shell syntax validation passes for the image build and login activation scripts.
- Main text on the primary dark surface is 12.49:1; white text on the selected blue surface is 4.63:1.

## Fidelity surfaces to verify after boot

- Rounded 16 px glass frame and soft blue/pink luminous edge.
- Blue-to-purple translucent title bar and window background with KWin blur.
- 34 px rounded minimize, maximize, and close controls in active, inactive, hover, and pressed states.
- Consistent glass controls, menus, dialogs, sidebars, inputs, and selection states in Qt 5, Qt 6, GTK 3, and GTK 4 applications.
- Legibility over both bright and dark wallpaper regions.
- Maximized and fullscreen windows, multi-monitor scaling, inactive windows, and sandboxed/client-side-decorated applications.

## Interaction and runtime checks

- Interactions exercised: none; Plasma/KWin runtime unavailable.
- Browser console errors: not applicable; this is a native desktop theme, not a browser prototype.
- Visual comparison iterations: 0 of 3; blocked before the first implementation capture.

## Task Manager addition

The MeyuroOS Task Manager integration was added after the original theme QA.
Static validation covers its Plasma containment-actions plugin, panel migration,
localized launcher actions, overview/applications/history/process pages, and
Ctrl+Shift+Esc shortcut. Runtime checks still require a booted Plasma session:
right-click an empty area of every panel, launch the manager, switch all pages,
inspect CPU/RAM/GPU/disk/network graphs, and end a disposable test process.

final result: blocked
