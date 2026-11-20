import AppKit
import SwiftUI

final class SetupRoute: NSWindowController {
    convenience init(_ store: StatusMenuViewStore) {
        let host = NSHostingController(rootView: SetupView().environment(store))
        let window = NSWindow(contentViewController: host)
        window.styleMask = [.titled, .closable]
        window.title = "Set Up Simba"
        window.isReleasedWhenClosed = false
        window.setContentSize(host.view.fittingSize)
        window.center()
        self.init(window: window)
    }
}
