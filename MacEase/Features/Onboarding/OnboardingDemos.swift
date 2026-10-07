import SwiftUI

struct ScreenshotDemo: View {
    var body: some View {
        ZStack {
            DemoDesktop()
            RoundedRectangle(cornerRadius: 12)
                .stroke(style: StrokeStyle(lineWidth: 2, dash: [7, 5]))
                .foregroundStyle(MacEaseTheme.Colors.cyan)
                .frame(width: 210, height: 108)
                .overlay(alignment: .bottomTrailing) {
                    Image(systemName: "cursorarrow.motionlines")
                        .font(.title2)
                        .offset(x: 13, y: 13)
                }
            Label("Copied", systemImage: "checkmark.circle.fill")
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(.black.opacity(0.72), in: Capsule())
                .offset(y: 78)
        }
    }
}

struct SwitcherDemo: View {
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            DemoWindow(symbol: "safari", title: "Research", selected: false)
            DemoWindow(symbol: "doc.text.fill", title: "Draft", selected: true)
            DemoWindow(symbol: "bubble.left.and.bubble.right.fill", title: "Messages", selected: false)
        }
        .padding(18)
        .background(.black.opacity(0.44), in: RoundedRectangle(cornerRadius: 18))
        .overlay { RoundedRectangle(cornerRadius: 18).stroke(.white.opacity(0.1)) }
    }
}

struct ClipboardDemo: View {
    var body: some View {
        VStack(spacing: 9) {
            DemoClipboardRow(symbol: "text.quote", title: "Project notes", subtitle: "Copied just now", tint: .blue)
            DemoClipboardRow(symbol: "photo.fill", title: "Design reference.png", subtitle: "Image · 1420 × 900", tint: .purple)
            DemoClipboardRow(symbol: "doc.fill", title: "Release checklist.md", subtitle: "File reference", tint: .orange)
        }
        .padding(14)
        .background(.black.opacity(0.34), in: RoundedRectangle(cornerRadius: 18))
        .overlay { RoundedRectangle(cornerRadius: 18).stroke(.white.opacity(0.1)) }
    }
}

private struct DemoDesktop: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 18)
            .fill(LinearGradient(colors: [.indigo.opacity(0.9), .blue.opacity(0.45)], startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay(alignment: .top) {
                HStack {
                    Circle().fill(.red.opacity(0.9)); Circle().fill(.yellow.opacity(0.9)); Circle().fill(.green.opacity(0.9)); Spacer()
                }
                .frame(height: 9)
                .padding(12)
            }
            .overlay {
                VStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 6).fill(.white.opacity(0.18)).frame(width: 250, height: 16)
                    RoundedRectangle(cornerRadius: 6).fill(.white.opacity(0.10)).frame(width: 190, height: 10)
                }
            }
            .frame(width: 390, height: 220)
            .shadow(color: .black.opacity(0.35), radius: 20, y: 12)
    }
}

private struct DemoWindow: View {
    let symbol: String
    let title: String
    let selected: Bool

    var body: some View {
        VStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 9)
                .fill(LinearGradient(colors: [.white.opacity(0.18), .white.opacity(0.06)], startPoint: .top, endPoint: .bottom))
                .frame(maxWidth: .infinity)
                .frame(height: 82)
                .overlay { Image(systemName: symbol).font(.title).foregroundStyle(.white.opacity(0.8)) }
            Text(title)
                .font(.caption.weight(.medium))
                .lineLimit(1)
                .frame(maxWidth: .infinity)
        }
        .frame(width: 112)
        .padding(8)
        .background(selected ? MacEaseTheme.Colors.violet.opacity(0.26) : .clear, in: RoundedRectangle(cornerRadius: 13))
        .overlay { RoundedRectangle(cornerRadius: 13).stroke(selected ? MacEaseTheme.Colors.violet : .clear, lineWidth: 2) }
    }
}

private struct DemoClipboardRow: View {
    let symbol: String
    let title: String
    let subtitle: String
    let tint: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol).foregroundStyle(tint).frame(width: 32, height: 32).background(tint.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.caption.weight(.semibold))
                Text(subtitle).font(.caption2).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "pin").foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .frame(width: 390, height: 52)
        .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 12))
    }
}
