import Foundation
import Testing
@testable import MacEase

@Suite("Clipboard history policy")
struct ClipboardHistoryPolicyTests {
    @Test("Duplicate content moves to the front without multiplying")
    func duplicateSuppression() {
        let old = entry(signature: "same", age: 100, pinned: true)
        let other = entry(signature: "other", age: 50)
        let fresh = entry(signature: "same", age: 0)
        let result = ClipboardHistoryPolicy.merging(fresh, into: [other, old])
        #expect(result.count == 2)
        #expect(result[0].signature == "same")
        #expect(result[0].isPinned)
    }

    @Test("Age, count, and blob budget are enforced")
    func retention() {
        let now = Date()
        let old = entry(signature: "old", age: 10_000)
        let pinnedOld = entry(signature: "pinned", age: 10_000, pinned: true)
        let imageA = entry(signature: "a", age: 20, bytes: 80)
        let imageB = entry(signature: "b", age: 10, bytes: 80)
        let result = ClipboardHistoryPolicy.retained(
            [old, pinnedOld, imageA, imageB],
            now: now,
            retentionInterval: 1_000,
            itemLimit: 3,
            storageLimitBytes: 100
        )
        #expect(result.contains(where: { $0.signature == "pinned" }))
        #expect(!result.contains(where: { $0.signature == "old" }))
        #expect(result.filter { $0.blobByteCount != nil }.count == 1)
    }

    private func entry(signature: String, age: TimeInterval, pinned: Bool = false, bytes: Int? = nil) -> ClipboardEntry {
        ClipboardEntry(
            id: UUID(),
            kind: bytes == nil ? .text : .image,
            createdAt: Date().addingTimeInterval(-age),
            text: signature,
            filePaths: [],
            blobFilename: bytes == nil ? nil : "\(signature).png",
            blobType: bytes == nil ? nil : "public.png",
            blobByteCount: bytes,
            isPinned: pinned,
            signature: signature,
            sourceApplication: nil
        )
    }
}
