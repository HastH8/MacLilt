# Delivery status

Last updated: 2026-10-07

| Area | Status | Evidence or limitation |
|---|---|---|
| Package foundation | Implemented and verified | `swift build` succeeds with Xcode 26.6 / macOS 26.5 SDK |
| Unit tests | Implemented and verified | Swift Testing suites cover permissions, persistence, shortcuts, geometry, snapping, and clipboard policy |
| Dock and menu bar lifecycle | Implemented and locally verified | Regular Dock app plus native `MenuBarExtra`; closing and reopening the main window was exercised from `/Applications` |
| Settings | Implemented and visually checked | Integrated main-window route with horizontal category navigation and aligned cards |
| Onboarding | Implemented; manual visual check pending | AppKit window, seven pages, keyboard navigation, reduced-effects paths |
| Preference persistence | Implemented and verified | Unit-tested with isolated UserDefaults suites |
| Permission model | Implemented and verified at unit boundary | Real system prompt/return behavior still needs packaged-app testing |
| Launch at login | Implemented; system verification pending | Uses `SMAppService.mainApp`; test from `/Applications` |
| Screenshot → Paste | Implemented; system verification pending | Area/window/full-screen, safe cancellation, clipboard, optional Pictures saving, confirmation |
| Clipboard history | Implemented, visually checked, and policy-tested | Compact text/images/files list, search, restore, pin/delete/clear/pause, adaptive monitor, local bounded persistence |
| Window switcher | Implemented; cross-app verification pending | Backdrop-free AX-window previews, cycling/cancel/activation, icons, bounded on-demand capture |
| Resize and snapping | Implemented and geometry-tested | Halves, quarters, thirds, center, maximize, restore, next display, edge preview, bypass modifier |
| Custom shortcuts | Implemented and validator-tested | Recording, persistence, duplicate/reserved warnings, defaults, lifecycle cleanup |
| Mouse and Finder improvements | Implemented; system verification pending | Opt-in middle click with exclusions; Finder paths/references/new file/reveal |
| Always on top | Unsupported for arbitrary third-party windows | No reliable public API to change their window level |
| Performance budgets | Provisional only | No Instruments measurements have been made |

## Provisional budgets

These are targets, not measured claims:

- Idle CPU: below 0.5% on a representative Apple silicon Mac
- Idle wakeups: no feature-owned repeating work except the adaptive clipboard monitor when enabled
- Baseline memory: below 80 MB after onboarding is closed
- Switcher preview cache: bounded by item count and decoded byte cost
- Clipboard storage: user-configurable item, age, and disk-size caps
- Drag preview updates: throttled to at most one layout update per display refresh

The project must be profiled with Instruments before any budget is described as met.

## Known limitations

- The main window and integrated Settings were visually inspected from the packaged build; third-party and multi-display workflows still need hands-on coverage.
- Swift Package Manager verifies compilation and tests; release identity, hardened runtime, notarization, and Sparkle are not configured.
- The generated raster icon is integrated; a hand-tuned vector source could improve future tiny-size exports.
- The bundle identifier is a placeholder and must be changed before signing or requesting stable permissions.
