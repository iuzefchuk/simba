import AppKit

@MainActor
final class WindowCoordinator {
    private let model: AppModel
    private lazy var prompt = PromptRoute(model)
    private lazy var result = ResultRoute(model)
    private lazy var setup = SetupRoute(model)
    private var shownPromptedAt: Date?

    init(_ model: AppModel) {
        self.model = model
        observe()
    }

    private func observe() {
        withObservationTracking {
            _ = model.destination
            _ = model.promptedAt
        } onChange: {
            Task { @MainActor in
                self.update()
                self.observe()
            }
        }
    }

    private func update() {
        if let destination = model.destination {
            model.destination = nil
            switch destination {
            case .result: open(result)
            case .setup: open(setup)
            }
        }
        if model.promptedAt != shownPromptedAt {
            shownPromptedAt = model.promptedAt
            if shownPromptedAt != nil {
                prompt.showWindow(nil)
            } else {
                prompt.close()
            }
        }
    }

    private func open(_ windowController: NSWindowController) {
        NSApp.activate()
        windowController.showWindow(nil)
        windowController.window?.orderFrontRegardless()
    }
}
