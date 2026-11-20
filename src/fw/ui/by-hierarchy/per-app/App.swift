import SwiftUI

@main
struct SimbaApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    private let store: StatusMenuViewStore

    init() {
        let windows = WindowCoordinator()
        let store = StatusMenuViewStore(storage: JSONStorage.applicationSupport, scheduling: TimerScheduling(), windows: windows)
        windows.register(.prompt) { PromptRoute(store) }
        windows.register(.result) { ResultRoute(store) }
        windows.register(.setup) { SetupRoute(store) }
        self.store = store
        appDelegate.onLaunch = { store.appDidLaunch() }
    }

    var body: some Scene {
        MenuBarExtra {
            StatusMenuView()
                .environment(store)
        } label: {
            Image(store.isLogging ? .catMeowing18 : .catCalm18)
        }
        .menuBarExtraStyle(.menu)
    }
}
