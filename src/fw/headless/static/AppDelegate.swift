import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    var onLaunch: () -> Void = {}

    func applicationDidFinishLaunching(_ notification: Notification) {
        onLaunch()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
