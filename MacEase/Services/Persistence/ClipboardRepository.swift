import Foundation

actor ClipboardRepository {
    private let rootURL: URL
    private let blobsURL: URL
    private let indexURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(rootURL: URL? = nil) {
        let base = rootURL ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(AppBrand.bundleIdentifier, isDirectory: true)
            .appendingPathComponent("Clipboard", isDirectory: true)
        self.rootURL = base
        blobsURL = base.appendingPathComponent("Blobs", isDirectory: true)
        indexURL = base.appendingPathComponent("history.json")
        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }

    func load() -> [ClipboardEntry] {
        guard let data = try? Data(contentsOf: indexURL),
              let entries = try? decoder.decode([ClipboardEntry].self, from: data) else {
            return []
        }
        return entries
    }

    func persist(entries: [ClipboardEntry], blob: (filename: String, data: Data)? = nil) throws {
        try FileManager.default.createDirectory(at: blobsURL, withIntermediateDirectories: true)
        if let blob {
            try blob.data.write(to: blobsURL.appendingPathComponent(blob.filename), options: .atomic)
        }
        let data = try encoder.encode(entries)
        try data.write(to: indexURL, options: .atomic)
        removeOrphanedBlobs(keeping: Set(entries.compactMap(\.blobFilename)))
    }

    func blobData(filename: String) -> Data? {
        try? Data(contentsOf: blobsURL.appendingPathComponent(filename))
    }

    func clear() throws {
        try persist(entries: [])
    }

    private func removeOrphanedBlobs(keeping filenames: Set<String>) {
        guard let urls = try? FileManager.default.contentsOfDirectory(at: blobsURL, includingPropertiesForKeys: nil) else { return }
        for url in urls where !filenames.contains(url.lastPathComponent) {
            try? FileManager.default.removeItem(at: url)
        }
    }
}
