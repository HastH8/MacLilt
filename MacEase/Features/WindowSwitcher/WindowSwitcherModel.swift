import Combine

@MainActor
final class WindowSwitcherModel: ObservableObject {
    @Published private(set) var windows: [SwitchableWindow] = []
    @Published private(set) var selectedIndex = 0
    @Published private(set) var isLoading = false

    private let catalog: WindowCatalog
    private var previewTask: Task<Void, Never>?

    init(catalog: WindowCatalog = WindowCatalog()) {
        self.catalog = catalog
    }

    var selection: SwitchableWindow? {
        windows.indices.contains(selectedIndex) ? windows[selectedIndex] : nil
    }

    func reload(reverse: Bool = false) {
        previewTask?.cancel()
        windows = catalog.windows()
        selectedIndex = reverse ? max(0, windows.count - 1) : (windows.count > 1 ? 1 : 0)
        isLoading = windows.isEmpty
        let snapshot = windows
        previewTask = Task { [weak self] in
            guard let self else { return }
            let previews = await catalog.loadPreviews(for: snapshot)
            guard !Task.isCancelled else { return }
            for index in windows.indices {
                windows[index].preview = previews[windows[index].id]
            }
            isLoading = false
        }
    }

    func move(by offset: Int) {
        guard !windows.isEmpty else { return }
        selectedIndex = (selectedIndex + offset + windows.count) % windows.count
    }

    func select(_ id: SwitchableWindow.ID) {
        guard let index = windows.firstIndex(where: { $0.id == id }) else { return }
        selectedIndex = index
    }

    func activateSelection() {
        guard let selection else { return }
        catalog.activate(selection)
        close()
    }

    func activate(_ window: SwitchableWindow) {
        catalog.activate(window)
        close()
    }

    func close() {
        previewTask?.cancel()
        previewTask = nil
        windows = []
        selectedIndex = 0
        isLoading = false
    }
}
