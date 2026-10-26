import SwiftUI

@main
struct SimbaApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra {
            StatusMenuView()
                .environment(appDelegate.model)
        } label: {
            Image(appDelegate.model.isLogging ? .menuBarActive : .menuBarIdle)
        }
        .menuBarExtraStyle(.menu)
    }
}
