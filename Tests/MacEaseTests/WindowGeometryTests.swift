import CoreGraphics
import Testing
@testable import MacEase

@Suite("Window geometry")
struct WindowGeometryTests {
    private let visible = CGRect(x: -1_440, y: 25, width: 1_440, height: 875)

    @Test("Halves tile without gaps")
    func halves() throws {
        let current = CGRect(x: -1_200, y: 100, width: 800, height: 600)
        let left = try #require(WindowGeometry.frame(for: .leftHalf, in: visible, currentFrame: current))
        let right = try #require(WindowGeometry.frame(for: .rightHalf, in: visible, currentFrame: current))
        #expect(left.minX == visible.minX)
        #expect(right.maxX == visible.maxX)
        #expect(left.maxX == right.minX)
        #expect(left.height == visible.height)
    }

    @Test("Quarters respect nonzero display origins")
    func quarters() throws {
        let current = CGRect(x: -1_200, y: 100, width: 800, height: 600)
        let topRight = try #require(WindowGeometry.frame(for: .topRightQuarter, in: visible, currentFrame: current))
        #expect(topRight.maxX == visible.maxX)
        #expect(topRight.maxY == visible.maxY)
        #expect(topRight.width == 720)
    }

    @Test("Moving displays preserves relative size and clamps")
    func displayTranslation() {
        let source = CGRect(x: 0, y: 0, width: 1_000, height: 800)
        let destination = CGRect(x: -1_920, y: 40, width: 1_920, height: 1_040)
        let frame = CGRect(x: 750, y: 600, width: 500, height: 400)
        let result = WindowGeometry.translatedFrame(frame, from: source, to: destination)
        #expect(destination.contains(result))
        #expect(result.width == 960)
        #expect(result.height == 520)
    }

    @Test("Snap targets prefer corners over edges")
    func snapTargets() {
        let screen = CGRect(x: 0, y: 25, width: 1_440, height: 875)
        #expect(SnapTargetResolver.layout(at: CGPoint(x: 2, y: 898), in: screen) == .topLeftQuarter)
        #expect(SnapTargetResolver.layout(at: CGPoint(x: 2, y: 450), in: screen) == .leftHalf)
        #expect(SnapTargetResolver.layout(at: CGPoint(x: 720, y: 899), in: screen) == .maximize)
        #expect(SnapTargetResolver.layout(at: CGPoint(x: 720, y: 450), in: screen) == nil)
    }
}
