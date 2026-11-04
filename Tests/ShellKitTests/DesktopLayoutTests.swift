import XCTest
@testable import ShellKit

/// The tiling map's geometry: which side of the free area an edge-attached strip is trimmed from.
@MainActor
final class DesktopLayoutTests: XCTestCase {
    private let screen = NSRect(x: 0, y: 0, width: 1000, height: 800)
    private var gap: CGFloat { DesktopLayout.gap }

    func testZoneOutsideTheAreaChangesNothing() {
        let far = NSRect(x: 2000, y: 0, width: 100, height: 100)
        XCTAssertEqual(DesktopLayout.cut(far, from: screen), screen)
    }

    func testTaskbarAlongTheBottomTrimsTheBottom() {
        let taskbar = NSRect(x: 0, y: 0, width: 1000, height: 30)
        let free = DesktopLayout.cut(taskbar, from: screen)
        XCTAssertEqual(free, NSRect(x: 0, y: 30 + gap, width: 1000, height: 800 - 30 - gap))
    }

    func testWidgetColumnOnTheRightTrimsTheRight() {
        let column = NSRect(x: 780, y: 0, width: 220, height: 800)
        let free = DesktopLayout.cut(column, from: screen)
        XCTAssertEqual(free, NSRect(x: 0, y: 0, width: 780 - gap, height: 800))
    }

    func testFolderColumnOnTheLeftTrimsTheLeft() {
        let column = NSRect(x: 0, y: 0, width: 220, height: 800)
        let free = DesktopLayout.cut(column, from: screen)
        XCTAssertEqual(free, NSRect(x: 220 + gap, y: 0, width: 1000 - 220 - gap, height: 800))
    }

    func testStripAlongTheTopTrimsTheTop() {
        let strip = NSRect(x: 0, y: 700, width: 1000, height: 100)
        let free = DesktopLayout.cut(strip, from: screen)
        XCTAssertEqual(free, NSRect(x: 0, y: 0, width: 1000, height: 700 - gap))
    }

    func testTrimmingKeepsTheLargerRemainder() {
        // A small block in the bottom-left corner: trimming its height (cheaper) beats trimming its width.
        let block = NSRect(x: 0, y: 0, width: 300, height: 40)
        let free = DesktopLayout.cut(block, from: screen)
        XCTAssertEqual(free.width, 1000)
        XCTAssertEqual(free.minY, 40 + gap)
    }

    func testToTopLeftFlipsOnlyTheVerticalAxis() {
        let main = NSScreen.screens.first?.frame.height ?? 0
        let flipped = DesktopLayout.toTopLeft(NSRect(x: 10, y: 20, width: 100, height: 50))
        XCTAssertEqual(flipped.minX, 10)
        XCTAssertEqual(flipped.size, CGSize(width: 100, height: 50))
        XCTAssertEqual(flipped.minY, main - 70)
    }
}

final class WidgetEdgeTests: XCTestCase {
    func testLeftAndRightAreColumns() {
        XCTAssertTrue(WidgetEdge.left.isVertical)
        XCTAssertTrue(WidgetEdge.right.isVertical)
        XCTAssertFalse(WidgetEdge.top.isVertical)
        XCTAssertFalse(WidgetEdge.bottom.isVertical)
    }

    func testRawValuesAreWhatTheSettingsStore() {
        XCTAssertEqual(WidgetEdge.allCases.map(\.rawValue), ["Right", "Left", "Top", "Bottom"])
        XCTAssertEqual(WidgetEdge(rawValue: "Left"), .left)
        XCTAssertNil(WidgetEdge(rawValue: "left"))
    }
}
