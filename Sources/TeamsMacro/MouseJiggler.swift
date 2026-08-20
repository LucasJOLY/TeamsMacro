import CoreGraphics
import Foundation

enum MouseJiggler {
    static func jiggle(by delta: Int) {
        guard delta > 0, let current = CGEvent(source: nil) else { return }
        let origin = current.location
        let offset = CGPoint(x: origin.x + CGFloat(delta), y: origin.y)
        postMouseMove(to: offset)
        postMouseMove(to: origin)
    }

    private static func postMouseMove(to point: CGPoint) {
        guard let event = CGEvent(
            mouseEventSource: nil,
            mouseType: .mouseMoved,
            mouseCursorPosition: point,
            mouseButton: .left
        ) else { return }
        event.post(tap: .cghidEventTap)
    }
}
