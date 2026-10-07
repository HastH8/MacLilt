import AppKit
import SwiftUI

struct BrandIcon: View {
    let size: CGFloat
    var showsGlow = true

    var body: some View {
        Group {
            if let image = BrandAssets.icon {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
            } else {
                Image(systemName: AppBrand.menuBarSymbol)
                    .resizable()
                    .scaledToFit()
                    .padding(size * 0.22)
                    .background(MacEaseTheme.Colors.darkBase, in: RoundedRectangle(cornerRadius: size * 0.23))
            }
        }
        .frame(width: size, height: size)
        .shadow(color: showsGlow ? MacEaseTheme.Colors.violet.opacity(0.38) : .clear, radius: size * 0.22)
        .accessibilityHidden(true)
    }
}

private enum BrandAssets {
    static let icon: NSImage? = {
        if let url = Bundle.main.url(forResource: "BrandIcon", withExtension: "png"),
           let image = NSImage(contentsOf: url) {
            return image
        }
        let sourceURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Resources/BrandIcon.png")
        return NSImage(contentsOf: sourceURL)
    }()
}
