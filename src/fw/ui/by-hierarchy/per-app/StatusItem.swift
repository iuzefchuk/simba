import AppKit
import SwiftUI

@MainActor
final class StatusItem: NSObject {
    private let store: StatusMenuViewStore
    private var item: NSStatusItem?
    private var isHovered = false
    private var isMenuOpen = false

    init(store: StatusMenuViewStore) {
        self.store = store
    }

    func install() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        let menu = NSHostingMenu(rootView: StatusMenuView().environment(store))
        item.menu = menu
        item.button?.imagePosition = .imageTrailing
        item.button?.addTrackingArea(NSTrackingArea(
            rect: .zero,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self))
        NotificationCenter.default.addObserver(
            self, selector: #selector(menuDidBeginTracking), name: NSMenu.didBeginTrackingNotification, object: menu)
        NotificationCenter.default.addObserver(
            self, selector: #selector(menuDidEndTracking), name: NSMenu.didEndTrackingNotification, object: menu)
        self.item = item
        observe()
    }

    @objc func mouseEntered(with event: NSEvent) {
        isHovered = true
        render()
    }

    @objc func mouseExited(with event: NSEvent) {
        isHovered = false
        render()
    }

    @objc private func menuDidBeginTracking() {
        isMenuOpen = true
        render()
    }

    @objc private func menuDidEndTracking() {
        isMenuOpen = false
        render()
    }

    private func observe() {
        withObservationTracking {
            render()
        } onChange: { [weak self] in
            Task { @MainActor in self?.observe() }
        }
    }

    private func render() {
        guard let button = item?.button else { return }
        button.image = NSImage(resource: store.isLogging ? .catMeowing18 : .catCalm18)
        if let report = store.openReport, isHovered || isMenuOpen {
            button.title = "✓\(report.entries.count) ✗\(report.skips.count)"
        } else {
            button.title = ""
        }
    }
}
