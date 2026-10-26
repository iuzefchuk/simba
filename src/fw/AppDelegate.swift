import AppIntents
import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let model: AppModel
    private let windowCoordinator: WindowCoordinator

    override init() {
        let model = AppModel(store: ReportStore(fileURL: ReportStore.defaultFileURL))
        self.model = model
        windowCoordinator = WindowCoordinator(model)
        super.init()
        AppDependencyManager.shared.add(dependency: model)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        if !UserDefaultsPreferences.didShowSetup {
            UserDefaultsPreferences.didShowSetup = true
            model.showSetup()
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
