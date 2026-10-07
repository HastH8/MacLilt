import SwiftUI

enum MacEaseTheme {
    enum Colors {
        static let violet = Color(red: 0.56, green: 0.30, blue: 0.98)
        static let blue = Color(red: 0.20, green: 0.54, blue: 1.00)
        static let cyan = Color(red: 0.22, green: 0.80, blue: 0.94)
        static let darkBase = Color(red: 0.045, green: 0.045, blue: 0.075)
        static let panelStroke = Color.white.opacity(0.13)
        static let secondaryText = Color.white.opacity(0.68)
    }

    enum Spacing {
        static let xs: CGFloat = 6
        static let sm: CGFloat = 10
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 36
    }

    enum Radius {
        static let control: CGFloat = 10
        static let card: CGFloat = 16
        static let window: CGFloat = 24
    }

    enum Motion {
        static let quick = Animation.easeOut(duration: 0.18)
        static let page = Animation.spring(duration: 0.42, bounce: 0.12)
    }
}

struct AmbientBackground: View {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        ZStack {
            MacEaseTheme.Colors.darkBase
            if !reduceTransparency {
                RadialGradient(
                    colors: [MacEaseTheme.Colors.violet.opacity(0.38), .clear],
                    center: UnitPoint(x: 0.28, y: 0.38),
                    startRadius: 8,
                    endRadius: 360
                )
                RadialGradient(
                    colors: [MacEaseTheme.Colors.blue.opacity(0.24), .clear],
                    center: UnitPoint(x: 0.78, y: 0.25),
                    startRadius: 4,
                    endRadius: 330
                )
            }
            LinearGradient(
                colors: [.white.opacity(reduceTransparency ? 0.04 : 0.08), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
    }
}

extension View {
    @ViewBuilder
    func macEaseGlass(cornerRadius: CGFloat = MacEaseTheme.Radius.card) -> some View {
        if #available(macOS 26.0, *) {
            self.glassEffect(.regular, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        } else {
            self.background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(MacEaseTheme.Colors.panelStroke, lineWidth: 1)
                }
        }
    }
}
