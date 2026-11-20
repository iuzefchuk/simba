import SwiftUI

struct StatusMenuView: View {
    @Environment(StatusMenuViewStore.self) private var store

    var body: some View {
        if store.isLogging {
            Button("Trigger prompt") { store.prompt() }
        } else {
            Button("Start logging") { store.startLogging() }
        }
        Button("Show result") { store.showResult() }
        Divider()
        Button("Setup") { store.showSetup() }
        Divider()
        Button("Quit") { NSApp.terminate(nil) }
            .keyboardShortcut("q")
    }
}

#Preview {
    Menu("Simba") {
        StatusMenuView()
    }
    .environment(StatusMenuViewStore.preview)
    .padding()
}
