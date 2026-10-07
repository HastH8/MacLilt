import CoreGraphics

enum SnapTargetResolver {
    static func layout(at point: CGPoint, in visibleFrame: CGRect, edgeThreshold: CGFloat = 24, cornerZone: CGFloat = 110) -> WindowLayout? {
        let nearLeft = point.x <= visibleFrame.minX + edgeThreshold
        let nearRight = point.x >= visibleFrame.maxX - edgeThreshold
        let nearTop = point.y >= visibleFrame.maxY - edgeThreshold
        if nearLeft && point.y >= visibleFrame.maxY - cornerZone { return .topLeftQuarter }
        if nearRight && point.y >= visibleFrame.maxY - cornerZone { return .topRightQuarter }
        if nearLeft && point.y <= visibleFrame.minY + cornerZone { return .bottomLeftQuarter }
        if nearRight && point.y <= visibleFrame.minY + cornerZone { return .bottomRightQuarter }
        if nearLeft { return .leftHalf }
        if nearRight { return .rightHalf }
        if nearTop { return .maximize }
        return nil
    }
}
