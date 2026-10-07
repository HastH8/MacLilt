# MacEase

MacEase is a native macOS productivity utility that stays available in both the Dock and menu bar. It includes working screenshot-to-clipboard capture, bounded local clipboard history, an individual-window switcher, keyboard and drag window management, Finder tools, configurable shortcuts, middle-click integration, onboarding, Settings, permissions, and launch at login.

The working name and user-facing copy are centralized in `MacEase/App/AppBrand.swift`. Packaging metadata is in `Packaging/Info.plist` and must be updated as part of a rename.

## Requirements

- macOS 14 Sonoma or newer
- Xcode 26.6 or a compatible Swift 6.3 toolchain

The baseline is macOS 14 because it supports the required SwiftUI/AppKit architecture and all future platform frameworks used by the plan, while avoiding needless exclusion of Sonoma users. The installed environment was Xcode 26.6 with the macOS 26.5 SDK. macOS 26-only Liquid Glass is guarded by availability checks; macOS 14 and 15 use native materials.

## Build and run

Open `Package.swift` in Xcode, or run:

```sh
swift build
swift run MacEase
```

To create a locally ad-hoc-signed app bundle:

```sh
./Scripts/build-app.sh
open artifacts/MacEase.app
```

The script’s signature is for local testing only. It is not a Developer ID signature and has not been notarized.

Run the unit tests with:

```sh
swift test
```

## Current status

### Implemented and build-verified

- Menu-bar application with a compact status panel
- Original glass app icon in Finder, Dock, menu bar, onboarding, Settings, clipboard, and switcher surfaces
- AppKit-owned first-launch onboarding window
- Seven stable onboarding pages with original feature demonstrations
- Back, Continue, Skip, Return, and arrow-key navigation
- Reduce Motion and Reduce Transparency adaptations
- Settings integrated into the main MacEase window with horizontal category navigation
- Persisted feature settings and configurable shortcut recorder with collision warnings
- Permission state checks that do not prompt
- Deliberate Accessibility and Screen Recording request buttons
- Permission refresh when the app becomes active again
- ServiceManagement launch-at-login registration
- Central color, spacing, radius, material, and motion tokens
- macOS 26 Liquid Glass availability path and older-system material fallback
- Screenshot area/window/full-screen capture, cancellation-safe clipboard behavior, optional saving, and confirmation
- Searchable clipboard history for text, images, and file references with pin/delete/clear/pause/restore
- Clipboard item, age, image-storage, persistence, duplicate, sensitive-marker, and application-exclusion controls
- Backdrop-free individual-window switcher with modifier-release activation and bounded on-demand ScreenCaptureKit previews
- Window halves, thirds, quarters, centering, maximize, restore, display movement, and drag snapping
- Finder copy-path, file-reference, reveal, and explicit new-file workflows
- Opt-in middle-click clipboard-history action with application exclusions
- Unit tests for permissions, persistence, window geometry, snapping, shortcuts, and clipboard policy

### Implemented, awaiting hands-on macOS verification

- The visual result in light/dark appearance and all accessibility display settings
- Accessibility and Screen Recording prompt/return flows in a packaged app
- Launch at login after moving a signed build into `/Applications`
- VoiceOver reading order
- Screenshot, window Accessibility, global input-monitoring, Finder Automation, and multi-display behavior across third-party apps

### Release work not falsely claimed complete

- Sparkle integration requires a real signed release feed and update-signing key.
- Performance profiling requires Instruments measurements on release hardware.
- Developer ID signing, notarization, and Gatekeeper testing require release credentials.

### Unsupported

- Changing the window level of arbitrary third-party windows. Public Accessibility APIs do not provide a reliable true always-on-top operation, so MacEase will not fake it by repeatedly raising windows.

See [project status](Documentation/Status.md), [architecture](Documentation/Architecture.md), and [manual verification](Documentation/ManualVerification.md) for detail.

## Permissions and privacy

MacEase is local-first and has no backend requirement. Clipboard content and captured images remain on the Mac.

- **Accessibility** is used for eligible window discovery, focus, movement, resizing, snapping, and global input workflows. Some apps and windows may not expose or accept these operations.
- **Screen Recording** is used for screenshots and window previews. Protected content can appear blank and permission changes may require relaunching the app.
- **Finder Automation** is requested only when a Finder-selection command is invoked.
- Requests occur only after explanatory UI and an explicit action.

Clipboard history uses adaptive pasteboard change-count detection, reads only after a change, stores image blobs outside preferences, and enforces user-configurable bounds. Sensitive-content markers are useful signals but cannot guarantee secret detection.

macOS already supports copying a screenshot to the clipboard with Control added to its screenshot shortcut, and moving copied Finder items with Option-Command-V. MacEase’s intended value is discoverability, configurable workflows, feedback, individual-window switching, and integrated history—not claiming these system abilities do not exist.

## Platform sources checked

- Apple’s [ScreenCaptureKit overview](https://developer.apple.com/documentation/screencapturekit) recommends its system content-sharing picker and documents Screen Recording consent.
- Apple’s [AXUIElement documentation](https://developer.apple.com/documentation/applicationservices/axuielement_h) defines the public Accessibility boundary and its failure modes.
- Apple documents [`SMAppService.mainApp`](https://developer.apple.com/documentation/servicemanagement/smappservice/mainapp) for launch-at-login registration.
- Apple’s [materials guidance](https://developer.apple.com/design/human-interface-guidelines/materials) recommends using Liquid Glass sparingly for controls/navigation while retaining standard materials in the content layer.

## Reference review

The supplied 55.98-second MP4 was inspected at seven points. Its useful qualities—centered hierarchy, a stable rounded window, restrained violet ambience, feature demonstrations, and paced progression—were translated into an original MacEase flow. The later UI screenshots were used to correct switcher-card clipping, feature-control alignment, window persistence, and Settings theme consistency.

## License

No open-source license has been selected. Choose a license before preparing a public release.
