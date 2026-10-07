import AppKit
import SwiftUI

struct ClipboardHistoryView: View {
    @ObservedObject var monitor: ClipboardMonitor
    @State private var search = ""
    @State private var selection: ClipboardEntry.ID?
    @FocusState private var searchFocused: Bool
    let choose: (ClipboardEntry) -> Void

    private var filteredEntries: [ClipboardEntry] {
        guard !search.isEmpty else { return monitor.entries }
        return monitor.entries.filter { $0.searchText.localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        ZStack {
            AmbientBackground()

            VStack(spacing: 0) {
                header
                content
                footer
            }
        }
        .preferredColorScheme(.dark)
        .frame(minWidth: 560, minHeight: 420)
        .onAppear {
            searchFocused = true
            selection = filteredEntries.first?.id
        }
        .onSubmit { restoreSelection() }
        .onDeleteCommand { deleteSelection() }
    }

    private var header: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Clipboard")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                Text("\(monitor.entries.count) saved item\(monitor.entries.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("Search", text: $search)
                    .textFieldStyle(.plain)
                    .focused($searchFocused)
                    .accessibilityLabel("Search clipboard history")
                if !search.isEmpty {
                    Button { search = "" } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 11)
            .frame(width: 230, height: 34)
            .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 10))
            .overlay { RoundedRectangle(cornerRadius: 10).stroke(.white.opacity(0.09)) }
        }
        .padding(.horizontal, 22)
        .padding(.top, 20)
        .padding(.bottom, 14)
    }

    @ViewBuilder
    private var content: some View {
        if filteredEntries.isEmpty {
            VStack(spacing: 10) {
                Image(systemName: search.isEmpty ? "doc.on.clipboard" : "magnifyingglass")
                    .font(.system(size: 30, weight: .light))
                    .foregroundStyle(MacEaseTheme.Colors.cyan)
                Text(search.isEmpty ? "Nothing copied yet" : "No matches")
                    .font(.headline)
                Text(search.isEmpty ? "New clipboard items will appear here." : "Try a different search.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(spacing: 6) {
                    ForEach(filteredEntries) { entry in
                        ClipboardEntryRow(
                            entry: entry,
                            monitor: monitor,
                            isSelected: selection == entry.id,
                            select: { selection = entry.id },
                            restore: { choose(entry) }
                        )
                        .contextMenu {
                            Button(entry.isPinned ? "Unpin" : "Pin") { monitor.togglePin(entry) }
                            Button("Delete", role: .destructive) { monitor.delete(entry) }
                            if entry.kind == .files, let first = entry.filePaths.first {
                                Button("Reveal in Finder") {
                                    NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: first)])
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 4)
            }
        }
    }

    private var footer: some View {
        HStack(spacing: 12) {
            Toggle(isOn: $monitor.isPaused) {
                Label(monitor.isPaused ? "Paused" : "Recording", systemImage: monitor.isPaused ? "pause.fill" : "circle.fill")
            }
            .toggleStyle(.switch)
            .controlSize(.small)
            .font(.caption.weight(.medium))

            Spacer()

            Text("Return to copy")
                .font(.caption2)
                .foregroundStyle(.secondary)

            Button("Clear", role: .destructive) { monitor.clear() }
                .disabled(monitor.entries.isEmpty)
        }
        .padding(.horizontal, 20)
        .frame(height: 52)
        .background(.black.opacity(0.13))
        .overlay(alignment: .top) { Rectangle().fill(.white.opacity(0.07)).frame(height: 1) }
    }

    private func restoreSelection() {
        guard let selection, let entry = filteredEntries.first(where: { $0.id == selection }) else { return }
        choose(entry)
    }

    private func deleteSelection() {
        guard let selection, let entry = filteredEntries.first(where: { $0.id == selection }) else { return }
        monitor.delete(entry)
        self.selection = filteredEntries.first?.id
    }
}

private struct ClipboardEntryRow: View {
    let entry: ClipboardEntry
    @ObservedObject var monitor: ClipboardMonitor
    let isSelected: Bool
    let select: () -> Void
    let restore: () -> Void
    @State private var image: NSImage?
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 12) {
            thumbnail

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.title)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                HStack(spacing: 5) {
                    Text(entry.kind.label)
                    Text("·")
                    Text(entry.createdAt, style: .relative)
                    if let source = entry.sourceApplication {
                        Text("·")
                        Text(source).lineLimit(1)
                    }
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }

            if entry.isPinned {
                Image(systemName: "pin.fill")
                    .font(.caption)
                    .foregroundStyle(MacEaseTheme.Colors.violet)
            }

            if isHovering || isSelected {
                Button(action: restore) {
                    Image(systemName: "arrow.turn.down.left")
                        .font(.caption.weight(.bold))
                        .frame(width: 26, height: 26)
                        .background(MacEaseTheme.Colors.violet.opacity(0.7), in: RoundedRectangle(cornerRadius: 7))
                }
                .buttonStyle(.plain)
                .help("Copy this item")
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, minHeight: 58)
        .background(isSelected ? MacEaseTheme.Colors.violet.opacity(0.17) : (isHovering ? .white.opacity(0.055) : .clear), in: RoundedRectangle(cornerRadius: 11))
        .overlay {
            RoundedRectangle(cornerRadius: 11)
                .stroke(isSelected ? MacEaseTheme.Colors.violet.opacity(0.72) : .clear)
        }
        .contentShape(RoundedRectangle(cornerRadius: 11))
        .onTapGesture(count: 2, perform: restore)
        .onTapGesture(perform: select)
        .onHover { isHovering = $0 }
        .task(id: entry.blobFilename) {
            guard entry.kind == .image, let data = await monitor.imageData(for: entry) else { return }
            image = NSImage(data: data)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var thumbnail: some View {
        Group {
            if let image {
                Image(nsImage: image).resizable().scaledToFill()
            } else {
                Image(systemName: entry.kind.symbol)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(MacEaseTheme.Colors.cyan)
            }
        }
        .frame(width: 40, height: 40)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 9))
        .clipShape(RoundedRectangle(cornerRadius: 9))
    }
}

private extension ClipboardEntryKind {
    var label: String {
        switch self {
        case .text: "Text"
        case .image: "Image"
        case .files: "File"
        }
    }
}
