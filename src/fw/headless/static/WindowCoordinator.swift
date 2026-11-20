import AppKit

@MainActor
final class WindowCoordinator {
    enum Destination {
        case prompt
        case history
        case setup
    }

    private var routes: [Destination: () -> NSWindowController] = [:]
    private var windowControllers: [Destination: NSWindowController] = [:]

    func register(_ destination: Destination, route: @escaping () -> NSWindowController) {
        routes[destination] = route
    }

    func open(_ destination: Destination) {
        guard let windowController = windowController(for: destination) else { return }
        if destination != .prompt {
            NSApp.activate()
        }
        windowController.showWindow(nil)
        if destination != .prompt {
            windowController.window?.orderFrontRegardless()
        }
    }

    func close(_ destination: Destination) {
        windowControllers[destination]?.close()
    }

    private func windowController(for destination: Destination) -> NSWindowController? {
        if let windowController = windowControllers[destination] { return windowController }
        let windowController = routes[destination]?()
        windowControllers[destination] = windowController
        return windowController
    }
}
