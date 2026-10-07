import Foundation

enum ClipboardHistoryPolicy {
    static func merging(_ newEntry: ClipboardEntry, into entries: [ClipboardEntry]) -> [ClipboardEntry] {
        var result = entries
        if let duplicateIndex = result.firstIndex(where: { $0.signature == newEntry.signature }) {
            let old = result.remove(at: duplicateIndex)
            var refreshed = newEntry
            refreshed.isPinned = old.isPinned
            if refreshed.blobFilename == nil {
                refreshed.blobFilename = old.blobFilename
                refreshed.blobType = old.blobType
                refreshed.blobByteCount = old.blobByteCount
            }
            result.insert(refreshed, at: 0)
        } else {
            result.insert(newEntry, at: 0)
        }
        return result
    }

    static func retained(
        _ entries: [ClipboardEntry],
        now: Date,
        retentionInterval: TimeInterval,
        itemLimit: Int,
        storageLimitBytes: Int
    ) -> [ClipboardEntry] {
        let cutoff = now.addingTimeInterval(-retentionInterval)
        var result = entries.filter { $0.isPinned || $0.createdAt >= cutoff }
        result.sort {
            if $0.isPinned != $1.isPinned { return $0.isPinned }
            return $0.createdAt > $1.createdAt
        }
        if result.count > itemLimit {
            let pinned = result.filter(\.isPinned)
            let recent = result.filter { !$0.isPinned }.prefix(max(0, itemLimit - pinned.count))
            result = pinned + recent
        }
        while result.reduce(0, { $0 + ($1.blobByteCount ?? 0) }) > storageLimitBytes, !result.isEmpty {
            if let index = result.lastIndex(where: { !$0.isPinned && $0.blobByteCount != nil }) {
                result.remove(at: index)
            } else if let index = result.lastIndex(where: { $0.blobByteCount != nil }) {
                result.remove(at: index)
            } else {
                break
            }
        }
        return result
    }
}
