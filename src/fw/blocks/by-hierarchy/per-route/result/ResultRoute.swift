import AppKit
import SwiftUI

final class ResultRoute: NSWindowController {
    convenience init(_ model: AppModel) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 560),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false)
        window.title = "Simba"
        window.isReleasedWhenClosed = false
        window.minSize = NSSize(width: 440, height: 320)
        window.contentViewController = NSHostingController(rootView: ResultView().environment(model))
        window.setContentSize(NSSize(width: 520, height: 560))
        window.center()
        self.init(window: window)
        windowFrameAutosaveName = "Result"
    }
}
