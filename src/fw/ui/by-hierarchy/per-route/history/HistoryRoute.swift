import AppKit
import SwiftUI

final class HistoryRoute: NSWindowController {
    convenience init(_ store: StatusMenuViewStore) {
        let host = NSHostingController(rootView: HistoryView().environment(store).frame(minWidth: 440, minHeight: 320))
        host.sizingOptions = .minSize
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 560),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false)
        window.title = "History"
        window.isReleasedWhenClosed = false
        window.contentViewController = host
        window.setContentSize(NSSize(width: 520, height: 560))
        window.center()
        self.init(window: window)
        windowFrameAutosaveName = "History"
    }
}
