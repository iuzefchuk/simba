import AppKit
import SwiftUI

final class ResultRoute: NSWindowController {
    convenience init(_ store: StatusMenuViewStore) {
        let host = NSHostingController(rootView: ResultView().environment(store).frame(minWidth: 440, minHeight: 320))
        host.sizingOptions = .minSize
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 560),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false)
        window.title = "Simba"
        window.isReleasedWhenClosed = false
        window.contentViewController = host
        window.setContentSize(NSSize(width: 520, height: 560))
        window.center()
        self.init(window: window)
        windowFrameAutosaveName = "Result"
    }
}
