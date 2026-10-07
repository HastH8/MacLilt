# Release checklist

Nothing in this file asserts that signing or notarization has happened.

## Before release engineering

- Choose an open-source license with the project owner.
- Replace the placeholder bundle identifier and keep it stable.
- Add original app and menu-bar artwork in all required variants.
- Verify privacy strings against the features that actually ship.
- Decide whether the release is sandboxed; test Accessibility and capture implications before changing entitlements.
- Remove or hide every unfinished control and update `Documentation/Status.md`.
- Run unit, integration, accessibility, manual, and Instruments checks on supported macOS versions.

## Signing and notarization

1. Build a Release app with a clean environment.
2. Enable hardened runtime and sign nested code, then the app, with a **Developer ID Application** certificate.
3. Verify with `codesign --verify --deep --strict --verbose=2`.
4. Create the distribution archive (ZIP or DMG) without mutating the signed app.
5. Submit it with `xcrun notarytool submit ... --wait` using credentials stored in Keychain or CI secrets.
6. Staple the ticket with `xcrun stapler staple` and validate it.
7. Test Gatekeeper from a fresh download on a clean user account.

## Updates

- Add Sparkle through Swift Package Manager only after release hosting exists.
- Generate and protect a Sparkle EdDSA key.
- Publish an HTTPS appcast with signed archives and correct version metadata.
- Test update, cancellation, rollback behavior, and a skipped version on a disposable installation.
- Never embed notarization credentials or update private keys in the repository.

## Publication

- Publish checksums, release notes, supported versions, permission explanations, privacy notes, and known limitations.
- Confirm the website download is the same notarized artifact that was tested.
- Tag the exact source commit used for the build.
