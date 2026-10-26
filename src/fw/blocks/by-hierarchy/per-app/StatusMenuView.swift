import SwiftUI

struct StatusMenuView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        if let report = model.store.openReport {
            Text("Logging since \(report.startedAt.formatted(date: .omitted, time: .shortened))")
            if let next = model.nextPromptAt {
                Text("^[\(report.entries.count) entry](inflect: true) · next at \(next.formatted(date: .omitted, time: .shortened))")
            }
            Divider()
            Button("Add Entry…") { model.prompt() }
            Button("Finish & Show Result") { model.endLogging() }
        } else {
            Text("Not in Work Focus")
            Divider()
            Button("Start Logging Manually") { model.startLogging() }
        }
        Button("Show Result…") { model.showResult() }
        Divider()
        Toggle("Launch at Login", isOn: $model.launchesAtLogin)
        Button("Set Up Focus Filter…") { model.showSetup() }
        Divider()
        Button("Quit Simba") { NSApp.terminate(nil) }
            .keyboardShortcut("q")
    }
}

#Preview {
    Menu("Simba") {
        StatusMenuView()
    }
    .environment(AppModel.preview)
    .padding()
}
