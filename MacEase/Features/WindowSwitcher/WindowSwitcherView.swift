import SwiftUI

struct WindowSwitcherView: View {
    @ObservedObject var model: WindowSwitcherModel
    let choose: (SwitchableWindow) -> Void

    var body: some View {
        Group {
            if model.windows.isEmpty {
                Label("No available windows", systemImage: "rectangle.3.group")
                    .font(.callout.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 14)
                    .background(.ultraThinMaterial, in: Capsule())
            } else {
                ScrollView(.horizontal) {
                    HStack(alignment: .top, spacing: 14) {
                        ForEach(Array(model.windows.prefix(10).enumerated()), id: \.element.id) { index, window in
                            WindowPreview(window: window, isSelected: index == model.selectedIndex)
                                .onTapGesture {
                                    model.select(window.id)
                                    choose(window)
                                }
                        }
                    }
                    .padding(12)
                }
                .scrollIndicators(.hidden)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .preferredColorScheme(.dark)
    }
}

private struct WindowPreview: View {
    let window: SwitchableWindow
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 8) {
            Group {
                if let preview = window.preview {
                    Image(nsImage: preview)
                        .resizable()
                        .scaledToFill()
                } else {
                    ZStack {
                        LinearGradient(
                            colors: [Color(red: 0.11, green: 0.12, blue: 0.19), Color(red: 0.05, green: 0.05, blue: 0.09)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        Image(nsImage: window.applicationIcon)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 46, height: 46)
                    }
                }
            }
            .frame(width: 194, height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? MacEaseTheme.Colors.violet : .white.opacity(0.18), lineWidth: isSelected ? 3 : 1)
            }
            .shadow(color: isSelected ? MacEaseTheme.Colors.violet.opacity(0.5) : .black.opacity(0.35), radius: isSelected ? 13 : 8, y: 5)

            HStack(spacing: 7) {
                Image(nsImage: window.applicationIcon)
                    .resizable()
                    .frame(width: 18, height: 18)
                Text(window.title)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
            }
            .foregroundStyle(.white)
            .frame(width: 194)
            .shadow(color: .black, radius: 3)
        }
        .scaleEffect(isSelected ? 1 : 0.96)
        .opacity(isSelected ? 1 : 0.86)
        .animation(MacEaseTheme.Motion.quick, value: isSelected)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
