import AppKit
import SwiftUI

final class PromptRoute: NSWindowController {
    convenience init(_ model: AppModel) {
        let panel = PromptPanel(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 120),
            styleMask: [.nonactivatingPanel, .borderless],
            backing: .buffered,
            defer: false)
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.isMovableByWindowBackground = true
        panel.animationBehavior = .utilityWindow
        let host = NSHostingController(rootView: PromptView().environment(model))
        panel.contentViewController = host
        panel.setContentSize(host.view.fittingSize)
        self.init(window: panel)
    }

    override func showWindow(_ sender: Any?) {
        if let window, !window.isVisible { place(window) }
        super.showWindow(sender)
    }

    private func place(_ panel: NSWindow) {
        guard let screen = NSScreen.main else { return }
        let area = screen.visibleFrame
        let size = panel.frame.size
        panel.setFrameOrigin(NSPoint(x: area.maxX - size.width - 16, y: area.maxY - size.height - 16))
    }
}

final class PromptPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
