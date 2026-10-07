import AppKit
import Foundation

enum FinderServiceError: LocalizedError {
    case noSelection
    case automationFailed(String)
    case noFilesOnClipboard
    case couldNotCreateFile

    var errorDescription: String? {
        switch self {
        case .noSelection: "Select a file or folder in Finder first."
        case .automationFailed(let message): "Finder could not provide its selection: \(message)"
        case .noFilesOnClipboard: "The clipboard does not contain file references."
        case .couldNotCreateFile: "The file could not be created."
        }
    }
}

@MainActor
final class FinderService {
    func copySelectedPaths() async throws -> Int {
        let urls = try await selectedURLs()
        let paths = urls.map(\.path).joined(separator: "\n")
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        guard pasteboard.setString(paths, forType: .string) else { throw FinderServiceError.couldNotCreateFile }
        return urls.count
    }

    func copySelectedFileReferences() async throws -> Int {
        let urls = try await selectedURLs()
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        guard pasteboard.writeObjects(urls as [NSURL]) else { throw FinderServiceError.couldNotCreateFile }
        return urls.count
    }

    func createNewFile() async throws -> URL? {
        let selection = try? await selectedURLs()
        let initialDirectory: URL?
        if let first = selection?.first {
            var isDirectory: ObjCBool = false
            FileManager.default.fileExists(atPath: first.path, isDirectory: &isDirectory)
            initialDirectory = isDirectory.boolValue ? first : first.deletingLastPathComponent()
        } else {
            initialDirectory = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first
        }

        let panel = NSSavePanel()
        panel.title = "Create New File"
        panel.prompt = "Create"
        panel.nameFieldStringValue = "Untitled.txt"
        panel.directoryURL = initialDirectory
        panel.canCreateDirectories = true
        guard panel.runModal() == .OK, let url = panel.url else { return nil }
        do {
            try await Task.detached(priority: .userInitiated) {
                try Data().write(to: url, options: [.atomic, .withoutOverwriting])
            }.value
        } catch CocoaError.fileWriteFileExists {
            throw FinderServiceError.couldNotCreateFile
        } catch {
            throw error
        }
        return url
    }

    func revealClipboardFiles() throws -> Int {
        let pasteboard = NSPasteboard.general
        guard let urls = pasteboard.readObjects(
            forClasses: [NSURL.self],
            options: [.urlReadingFileURLsOnly: true]
        ) as? [URL], !urls.isEmpty else {
            throw FinderServiceError.noFilesOnClipboard
        }
        NSWorkspace.shared.activateFileViewerSelecting(urls)
        return urls.count
    }

    private func selectedURLs() async throws -> [URL] {
        let output: String = try await Task.detached(priority: .userInitiated) {
            let source = """
            tell application "Finder"
                set selectedItems to selection
                if (count of selectedItems) is 0 then return ""
                set output to ""
                repeat with selectedItem in selectedItems
                    set output to output & POSIX path of (selectedItem as alias) & linefeed
                end repeat
                return output
            end tell
            """
            guard let script = NSAppleScript(source: source) else {
                throw FinderServiceError.automationFailed("The script could not be created.")
            }
            var details: NSDictionary?
            let descriptor = script.executeAndReturnError(&details)
            if let details {
                let message = details[NSAppleScript.errorMessage] as? String ?? "Unknown automation error"
                throw FinderServiceError.automationFailed(message)
            }
            return descriptor.stringValue ?? ""
        }.value

        let urls = output.split(whereSeparator: \.isNewline).map { URL(fileURLWithPath: String($0)) }
        guard !urls.isEmpty else { throw FinderServiceError.noSelection }
        return urls
    }
}
