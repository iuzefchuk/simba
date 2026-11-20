import SwiftUI

struct StatusMenuView: View {
    @Environment(StatusMenuViewStore.self) private var store

    var body: some View {
        if store.isLogging {
            Button("Log") { store.prompt() }
            Button("Sleep") { store.endLogging() }
        } else {
            Button("Wake & log") {
                store.startLogging()
                store.prompt()
            }
        }
        Divider()
        Button("History") { store.showHistory() }
        Button("Settings") { store.showSetup() }
        Divider()
        Button("Quit") { NSApp.terminate(nil) }
    }
}

#Preview {
    Menu("Simba") {
        StatusMenuView()
    }
    .environment(StatusMenuViewStore.preview)
    .padding()
}
