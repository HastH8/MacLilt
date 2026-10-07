# Manual verification

Build the app bundle with `./Scripts/build-app.sh`, move it to `/Applications`, and use a stable bundle identifier before evaluating persistent permissions or launch at login.

## Application and onboarding

1. Remove the test build’s preferences and launch it as a clean install. Confirm onboarding opens once and MacEase remains visible in the Dock and menu bar.
2. Verify the onboarding window remains 820 × 560 points across every page without content jumps.
3. Navigate with buttons, Return, Left Arrow, and Right Arrow. Confirm Skip and Done persist completion.
4. Reopen onboarding from the menu-bar panel and Settings.
5. Enable Reduce Motion. Confirm page changes use no scale transition.
6. Enable Reduce Transparency. Confirm the background becomes opaque and all text remains legible.
7. Check light and dark system appearances, Increase Contrast, and VoiceOver order.
8. Confirm launch-at-login registration while the app is installed in `/Applications`, then log out and back in.
9. On the permissions page, confirm no prompt appears merely by opening it. Select Review deliberately, grant or deny, return from System Settings, and confirm the displayed state refreshes.
10. Revoke each permission while MacEase is running and confirm the state updates on the next activation.
11. Close the main window, confirm the process remains running, then click the Dock icon and menu-bar icon to confirm the main window reopens.
12. Open Settings from the main window, menu-bar panel, and ⌘, and confirm each route uses the same main window rather than creating another Settings window.

## Feature integration matrix

- Clean installation and upgrade
- Permissions granted, denied, and revoked
- Multiple displays with mixed Retina scaling and arrangements on every side
- Menu bar and Dock on different displays/edges
- Sleep/wake and display reconnect
- Closed, minimized, full-screen, protected, and other-Space windows
- Shortcut collisions and keyboard layouts
- Large clipboard images and missing file references
- Clipboard application exclusions, pause, retention, and duplicate suppression
- Repeated switcher activation and cancellation
- Unsupported or unresponsive applications
- Every feature toggled off while active; verify observers, timers, event taps, streams, and tasks stop

## Performance pass

Use Instruments on a release build for idle CPU, wakeups, memory growth, energy impact, animation hitches, repeated activation, and capture teardown. Record hardware, OS build, sample duration, workflow, and results. Do not infer production performance from unit tests.
