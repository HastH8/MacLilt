import AppKit
import Foundation

enum ScreenshotResult: Equatable {
    case copied
    case cancelled
    case failed(String)
}

enum ScreenshotMode: String, CaseIterable, Sendable {
    case area
    case window
    case fullScreen

    var title: String {
        switch self {
        case .area: "Capture Area"
        case .window: "Capture Window"
        case .fullScreen: "Capture Full Screen"
        }
    }
}

@MainActor
final class ScreenshotService {
    private let pasteboard: NSPasteboard

    init(pasteboard: NSPasteboard = .general) {
        self.pasteboard = pasteboard
    }

    func capture(_ mode: ScreenshotMode = .area) async -> ScreenshotResult {
        let previousChangeCount = pasteboard.changeCount
        let snapshot = PasteboardSnapshot.capture(from: pasteboard)
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        switch mode {
        case .area: process.arguments = ["-i", "-c", "-s"]
        case .window: process.arguments = ["-i", "-c", "-W"]
        case .fullScreen: process.arguments = ["-c"]
        }

        do {
            try process.run()
        } catch {
            return .failed(error.localizedDescription)
        }

        let status: Int32 = await withCheckedContinuation { continuation in
            process.terminationHandler = { completed in
                continuation.resume(returning: completed.terminationStatus)
            }
        }

        guard status == 0 else {
            if pasteboard.changeCount != previousChangeCount {
                snapshot.restore(to: pasteboard)
            }
            return status == 1 ? .cancelled : .failed("The system screenshot tool exited with status \(status).")
        }

        guard pasteboard.canReadItem(withDataConformingToTypes: [NSPasteboard.PasteboardType.png.rawValue, NSPasteboard.PasteboardType.tiff.rawValue]) else {
            snapshot.restore(to: pasteboard)
            return .failed("The capture completed without an image.")
        }
        return .copied
    }

    func saveCurrentClipboardImage() async -> URL? {
        guard let item = pasteboard.pasteboardItems?.first,
              let data = item.data(forType: .png) ?? item.data(forType: .tiff) else { return nil }
        let isPNG = item.data(forType: .png) != nil
        let pictures = FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask)[0]
        let directory = pictures.appendingPathComponent(AppBrand.name, isDirectory: true)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd 'at' HH.mm.ss"
        let filename = "Screenshot \(formatter.string(from: .now)).\(isPNG ? "png" : "tiff")"
        let url = directory.appendingPathComponent(filename)
        return await Task.detached(priority: .utility) {
            do {
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                try data.write(to: url, options: [.atomic, .withoutOverwriting])
                return url
            } catch {
                return nil
            }
        }.value
    }
}

private struct PasteboardSnapshot: @unchecked Sendable {
    let items: [[NSPasteboard.PasteboardType: Data]]

    static func capture(from pasteboard: NSPasteboard) -> PasteboardSnapshot {
        let items = (pasteboard.pasteboardItems ?? []).map { item in
            Dictionary(uniqueKeysWithValues: item.types.compactMap { type in
                item.data(forType: type).map { (type, $0) }
            })
        }
        return PasteboardSnapshot(items: items)
    }

    @MainActor
    func restore(to pasteboard: NSPasteboard) {
        pasteboard.clearContents()
        let restored = items.map { values -> NSPasteboardItem in
            let item = NSPasteboardItem()
            for (type, data) in values { item.setData(data, forType: type) }
            return item
        }
        pasteboard.writeObjects(restored)
    }
}
