import Foundation

enum ClipboardEntryKind: String, Codable, Sendable {
    case text
    case image
    case files

    var symbol: String {
        switch self {
        case .text: "text.quote"
        case .image: "photo"
        case .files: "doc.on.doc"
        }
    }
}

struct ClipboardEntry: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let kind: ClipboardEntryKind
    let createdAt: Date
    var text: String?
    var filePaths: [String]
    var blobFilename: String?
    var blobType: String?
    var blobByteCount: Int?
    var isPinned: Bool
    let signature: String
    let sourceApplication: String?

    var title: String {
        switch kind {
        case .text:
            text?.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: "\n").first.map(String.init) ?? "Text"
        case .image:
            "Image"
        case .files:
            filePaths.count == 1 ? URL(fileURLWithPath: filePaths[0]).lastPathComponent : "\(filePaths.count) files"
        }
    }

    var searchText: String {
        ([text ?? ""] + filePaths + [sourceApplication ?? ""]).joined(separator: " ")
    }
}
