# Architecture

MacEase is a Swift Package with a native executable target. SwiftUI owns ordinary interface composition; AppKit owns lifecycle and window behavior. System frameworks sit behind small service objects so their state transitions can be tested without prompting or manipulating the host Mac.

```text
MacEaseApp
├── AppDelegate
│   └── OnboardingWindowCoordinator (AppKit window ownership)
├── AppModel (@MainActor composition root)
│   ├── PreferenceStore
│   ├── PermissionCenter
│   ├── ScreenshotService + ClipboardMonitor/Repository
│   ├── WindowSwitcher + WindowManagement + WindowSnap
│   ├── GlobalShortcutMonitor + MiddleClickService
│   ├── FinderService
│   └── LaunchAtLoginService
├── MenuBarPanel
├── SettingsView
└── OnboardingView
```

## Ownership rules

- `AppDelegate` owns observers and the onboarding coordinator and removes its observer at termination.
- `AppModel` is the main-actor composition root and owns injected feature services plus their UI coordinators.
- `syncFeatureLifecycles()` starts and stops clipboard timers, shortcut monitors, snapping monitors, middle-click monitors, and switcher work from persisted feature toggles.
- Permission status checks are separate from request methods. `refresh()` cannot produce a system prompt.
- Capture processes, image-blob persistence, and file I/O leave the main actor; UI and pasteboard access remain main-actor isolated. Preview work is bounded and cancellable.

## Service boundaries

```text
Shortcuts ──> feature command handlers
Screenshot ─> native interactive capture ─> NSPasteboard ─> optional history/file
Clipboard ──> change-count monitor ─> bounded local store
Switcher ───> AX window catalog + on-demand ScreenCaptureKit previews
Snapping ───> AX window control + shared layout calculator
```

The screenshot and switcher share capture permission state but never keep a permanent capture stream. The switcher’s preview task exists only while the overlay is open. Snapping and keyboard resize share pure geometry calculations and one Accessibility window-control boundary. Clipboard image blobs live in Application Support while index metadata remains a bounded JSON file; neither is placed in UserDefaults.

## Distribution direction

Direct distribution is the primary target. A release build will be placed in an `.app` bundle, signed with Developer ID Application, notarized, stapled, and packaged for download. Sparkle will only be enabled once an HTTPS appcast, signing key, and release process exist. The current build script creates an ad-hoc signature solely for local testing.
