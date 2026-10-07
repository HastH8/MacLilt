import CoreGraphics
import Foundation

enum WindowLayout: String, CaseIterable, Identifiable, Sendable {
    case leftHalf
    case rightHalf
    case topLeftQuarter
    case topRightQuarter
    case bottomLeftQuarter
    case bottomRightQuarter
    case leftThird
    case centerThird
    case rightThird
    case center
    case maximize
    case restore
    case nextDisplay

    var id: String { rawValue }

    var title: String {
        switch self {
        case .leftHalf: "Left Half"
        case .rightHalf: "Right Half"
        case .topLeftQuarter: "Top Left Quarter"
        case .topRightQuarter: "Top Right Quarter"
        case .bottomLeftQuarter: "Bottom Left Quarter"
        case .bottomRightQuarter: "Bottom Right Quarter"
        case .leftThird: "Left Third"
        case .centerThird: "Center Third"
        case .rightThird: "Right Third"
        case .center: "Center"
        case .maximize: "Maximize"
        case .restore: "Restore Previous Bounds"
        case .nextDisplay: "Move to Next Display"
        }
    }

    var symbol: String {
        switch self {
        case .leftHalf: "rectangle.lefthalf.inset.filled"
        case .rightHalf: "rectangle.righthalf.inset.filled"
        case .topLeftQuarter: "rectangle.inset.topleft.filled"
        case .topRightQuarter: "rectangle.inset.topright.filled"
        case .bottomLeftQuarter: "rectangle.inset.bottomleft.filled"
        case .bottomRightQuarter: "rectangle.inset.bottomright.filled"
        case .leftThird, .centerThird, .rightThird: "rectangle.split.3x1"
        case .center: "arrow.up.left.and.arrow.down.right"
        case .maximize: "arrow.up.left.and.arrow.down.right"
        case .restore: "arrow.uturn.backward"
        case .nextDisplay: "rectangle.on.rectangle"
        }
    }
}

enum WindowGeometry {
    static func frame(for layout: WindowLayout, in visibleFrame: CGRect, currentFrame: CGRect) -> CGRect? {
        let halfWidth = floor(visibleFrame.width / 2)
        let halfHeight = floor(visibleFrame.height / 2)
        let thirdWidth = floor(visibleFrame.width / 3)

        switch layout {
        case .leftHalf:
            return CGRect(x: visibleFrame.minX, y: visibleFrame.minY, width: halfWidth, height: visibleFrame.height)
        case .rightHalf:
            return CGRect(x: visibleFrame.minX + halfWidth, y: visibleFrame.minY, width: visibleFrame.width - halfWidth, height: visibleFrame.height)
        case .topLeftQuarter:
            return CGRect(x: visibleFrame.minX, y: visibleFrame.minY + halfHeight, width: halfWidth, height: visibleFrame.height - halfHeight)
        case .topRightQuarter:
            return CGRect(x: visibleFrame.minX + halfWidth, y: visibleFrame.minY + halfHeight, width: visibleFrame.width - halfWidth, height: visibleFrame.height - halfHeight)
        case .bottomLeftQuarter:
            return CGRect(x: visibleFrame.minX, y: visibleFrame.minY, width: halfWidth, height: halfHeight)
        case .bottomRightQuarter:
            return CGRect(x: visibleFrame.minX + halfWidth, y: visibleFrame.minY, width: visibleFrame.width - halfWidth, height: halfHeight)
        case .leftThird:
            return CGRect(x: visibleFrame.minX, y: visibleFrame.minY, width: thirdWidth, height: visibleFrame.height)
        case .centerThird:
            return CGRect(x: visibleFrame.minX + thirdWidth, y: visibleFrame.minY, width: thirdWidth, height: visibleFrame.height)
        case .rightThird:
            return CGRect(x: visibleFrame.minX + thirdWidth * 2, y: visibleFrame.minY, width: visibleFrame.width - thirdWidth * 2, height: visibleFrame.height)
        case .center:
            let width = min(currentFrame.width, visibleFrame.width)
            let height = min(currentFrame.height, visibleFrame.height)
            return CGRect(x: visibleFrame.midX - width / 2, y: visibleFrame.midY - height / 2, width: width, height: height)
        case .maximize:
            return visibleFrame
        case .restore, .nextDisplay:
            return nil
        }
    }

    static func translatedFrame(_ frame: CGRect, from source: CGRect, to destination: CGRect) -> CGRect {
        guard source.width > 0, source.height > 0 else { return destination }
        let relativeX = (frame.minX - source.minX) / source.width
        let relativeY = (frame.minY - source.minY) / source.height
        let widthRatio = min(frame.width / source.width, 1)
        let heightRatio = min(frame.height / source.height, 1)
        let width = destination.width * widthRatio
        let height = destination.height * heightRatio
        let proposed = CGRect(
            x: destination.minX + destination.width * relativeX,
            y: destination.minY + destination.height * relativeY,
            width: width,
            height: height
        )
        return proposed.clamped(to: destination)
    }
}

private extension CGRect {
    func clamped(to bounds: CGRect) -> CGRect {
        let width = min(width, bounds.width)
        let height = min(height, bounds.height)
        return CGRect(
            x: min(max(minX, bounds.minX), bounds.maxX - width),
            y: min(max(minY, bounds.minY), bounds.maxY - height),
            width: width,
            height: height
        )
    }
}
