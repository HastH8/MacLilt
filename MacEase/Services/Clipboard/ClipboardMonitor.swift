import AppKit
import Combine
import CryptoKit
import Foundation

@MainActor
final class ClipboardMonitor: ObservableObject {
    @Published private(set) var entries: [ClipboardEntry] = []
    @Published var isPaused = false
    @Published private(set) var persistentHistory = true
    @Published private(set) var maximumItemCount = 100

    private let pasteboard: NSPasteboard
    private let repository: ClipboardRepository
    private var timer: Timer?
    private var lastChangeCount: Int
    private var unchangedPolls = 0
    private var isLoading = false
    private let maximumBlobBytes = 25 * 1_024 * 1_024
    private var retentionInterval: TimeInterval = 30 * 24 * 60 * 60
    private var maximumStorageBytes = 100 * 1_024 * 1_024
    private var excludedApplications = Set<String>()
    private var hasLoadedPersistence = false

    init(pasteboard: NSPasteboard = .general, repository: ClipboardRepository = ClipboardRepository()) {
        self.pasteboard = pasteboard
        self.repository = repository
        lastChangeCount = pasteboard.changeCount
    }

    func start() {
        guard timer == nil else { return }
        lastChangeCount = pasteboard.changeCount
        scheduleTimer(interval: 0.75)
    }

    func configure(itemLimit: Int, retentionDays: Int, storageLimitMB: Int, persistent: Bool, excludedApplications: String) {
        maximumItemCount = max(10, min(itemLimit, 2_000))
        retentionInterval = TimeInterval(max(1, min(retentionDays, 365))) * 24 * 60 * 60
        maximumStorageBytes = max(10, min(storageLimitMB, 2_048)) * 1_024 * 1_024
        self.excludedApplications = Set(excludedApplications
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { !$0.isEmpty })
        if !hasLoadedPersistence {
            hasLoadedPersistence = true
            if persistent {
                Task { await loadPersistedEntries() }
            } else {
                entries = []
                Task { try? await repository.clear() }
            }
        }
        if persistentHistory != persistent {
            persistentHistory = persistent
            if persistent {
                persistCurrentEntries()
            } else {
                Task { try? await repository.clear() }
            }
        }
        applyRetention()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        unchangedPolls = 0
    }

    func clear() {
        entries.removeAll()
        Task { try? await repository.clear() }
    }

    func delete(_ entry: ClipboardEntry) {
        entries.removeAll { $0.id == entry.id }
        persistCurrentEntries()
    }

    func togglePin(_ entry: ClipboardEntry) {
        guard let index = entries.firstIndex(where: { $0.id == entry.id }) else { return }
        entries[index].isPinned.toggle()
        sortEntries()
        persistCurrentEntries()
    }

    func restore(_ entry: ClipboardEntry) async -> Bool {
        pasteboard.clearContents()
        let succeeded: Bool
        switch entry.kind {
        case .text:
            succeeded = entry.text.map { pasteboard.setString($0, forType: .string) } ?? false
        case .files:
            let urls = entry.filePaths.map { URL(fileURLWithPath: $0) }
            succeeded = pasteboard.writeObjects(urls as [NSURL])
        case .image:
            guard let filename = entry.blobFilename,
                  let typeName = entry.blobType,
                  let data = await repository.blobData(filename: filename) else {
                succeeded = false
                break
            }
            succeeded = pasteboard.setData(data, forType: NSPasteboard.PasteboardType(typeName))
        }
        lastChangeCount = pasteboard.changeCount
        return succeeded
    }

    func imageData(for entry: ClipboardEntry) async -> Data? {
        guard let filename = entry.blobFilename else { return nil }
        return await repository.blobData(filename: filename)
    }

    private func scheduleTimer(interval: TimeInterval) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.poll() }
        }
        timer?.tolerance = interval * 0.25
    }

    private func poll() {
        guard !isPaused, !isLoading else { return }
        let changeCount = pasteboard.changeCount
        guard changeCount != lastChangeCount else {
            unchangedPolls += 1
            if unchangedPolls == 80 { scheduleTimer(interval: 2.0) }
            return
        }

        lastChangeCount = changeCount
        unchangedPolls = 0
        if timer?.timeInterval != 0.75 { scheduleTimer(interval: 0.75) }
        captureCurrentPasteboard()
    }

    private func captureCurrentPasteboard() {
        guard let item = pasteboard.pasteboardItems?.first else { return }
        let rawTypes = Set(item.types.map(\.rawValue))
        guard !rawTypes.contains(where: { $0.localizedCaseInsensitiveContains("concealed") || $0.localizedCaseInsensitiveContains("password") }) else { return }

        let source = NSWorkspace.shared.frontmostApplication?.localizedName
        let sourceIdentifiers = [NSWorkspace.shared.frontmostApplication?.bundleIdentifier, source]
            .compactMap { $0?.lowercased() }
        guard excludedApplications.isDisjoint(with: sourceIdentifiers) else { return }
        var entry: ClipboardEntry?
        var blob: (filename: String, data: Data)?

        if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL], !urls.isEmpty {
            let paths = urls.map(\.path)
            let signature = signature(for: Data(paths.joined(separator: "\0").utf8))
            entry = ClipboardEntry(id: UUID(), kind: .files, createdAt: .now, text: nil, filePaths: paths, blobFilename: nil, blobType: nil, blobByteCount: nil, isPinned: false, signature: signature, sourceApplication: source)
        } else if let data = item.data(forType: .png) ?? item.data(forType: .tiff), data.count <= maximumBlobBytes {
            let type: NSPasteboard.PasteboardType = item.data(forType: .png) != nil ? .png : .tiff
            let signature = signature(for: data)
            let filename = "\(UUID().uuidString).\(type == .png ? "png" : "tiff")"
            entry = ClipboardEntry(id: UUID(), kind: .image, createdAt: .now, text: nil, filePaths: [], blobFilename: filename, blobType: type.rawValue, blobByteCount: data.count, isPinned: false, signature: signature, sourceApplication: source)
            blob = (filename, data)
        } else if let text = item.string(forType: .string), !text.isEmpty {
            let signature = signature(for: Data(text.utf8))
            entry = ClipboardEntry(id: UUID(), kind: .text, createdAt: .now, text: text, filePaths: [], blobFilename: nil, blobType: nil, blobByteCount: nil, isPinned: false, signature: signature, sourceApplication: source)
        }

        guard let entry else { return }
        add(entry, blob: blob)
    }

    private func add(_ entry: ClipboardEntry, blob: (filename: String, data: Data)?) {
        entries = ClipboardHistoryPolicy.merging(entry, into: entries)
        applyRetention()

        guard persistentHistory else { return }
        let current = entries
        Task { try? await repository.persist(entries: current, blob: blob) }
    }

    private func applyRetention() {
        entries = ClipboardHistoryPolicy.retained(
            entries,
            now: .now,
            retentionInterval: retentionInterval,
            itemLimit: maximumItemCount,
            storageLimitBytes: maximumStorageBytes
        )
    }

    private func sortEntries() {
        entries.sort {
            if $0.isPinned != $1.isPinned { return $0.isPinned }
            return $0.createdAt > $1.createdAt
        }
    }

    private func persistCurrentEntries() {
        guard persistentHistory else { return }
        let current = entries
        Task { try? await repository.persist(entries: current) }
    }

    private func loadPersistedEntries() async {
        isLoading = true
        entries = await repository.load()
        applyRetention()
        sortEntries()
        isLoading = false
    }

    private func signature(for data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }
}
