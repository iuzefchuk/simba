import SwiftUI

struct StatusMenuView: View {
    @Environment(StatusMenuViewStore.self) private var store

    var body: some View {
        @Bindable var store = store
        if let report = store.openReport {
            if let next = store.nextPromptAt {
                Text("^[\(report.entries.count) entry](inflect: true) · next at \(next.formatted(date: .omitted, time: .shortened))")
                Divider()
            }
            Button("Add Entry…") { store.prompt() }
            Button("Finish & Show Result") { store.endLogging() }
        } else {
            Button("Start Logging Manually") { store.startLogging() }
        }
        Button("Show Result…") { store.showResult() }
        Divider()
        Toggle("Launch at Login", isOn: $store.launchesAtLogin)
        Button("Work Hours…") { store.showSetup() }
        Divider()
        Button("Quit Simba") { NSApp.terminate(nil) }
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
