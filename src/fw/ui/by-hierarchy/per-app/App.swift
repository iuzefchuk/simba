import SwiftUI

@main
struct SimbaApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    private let statusItem: StatusItem

    init() {
        let windows = WindowCoordinator()
        let store = StatusMenuViewStore(storage: JSONStorage.applicationSupport, scheduling: TimerScheduling(), windows: windows)
        windows.register(.prompt) { PromptRoute(store) }
        windows.register(.history) { HistoryRoute(store) }
        windows.register(.setup) { SetupRoute(store) }
        let statusItem = StatusItem(store: store)
        self.statusItem = statusItem
        appDelegate.onLaunch = {
            statusItem.install()
            store.appDidLaunch()
        }
    }

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
