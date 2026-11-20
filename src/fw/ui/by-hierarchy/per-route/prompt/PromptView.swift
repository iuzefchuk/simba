import SwiftUI

struct PromptView: View {
    @Environment(StatusMenuViewStore.self) private var store
    @FocusState private var isFieldFocused: Bool

    private var canLog: Bool { Entry.normalized(store.draft) != nil }

    var body: some View {
        @Bindable var store = store
        HStack(alignment: .top, spacing: 12) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 40, height: 40)
            VStack(alignment: .leading, spacing: 10) {
                TextField("What are you doing right now?", text: $store.draft)
                    .textFieldStyle(.roundedBorder)
                    .focused($isFieldFocused)
                    .onSubmit { if canLog { store.answerPrompt() } }
                HStack {
                    Spacer()
                    Button("Skip") { store.skipPrompt() }
                        .keyboardShortcut(.cancelAction)
                    Button("Log") { store.answerPrompt() }
                        .buttonStyle(.borderedProminent)
                        .disabled(!canLog)
                }
            }
        }
        .padding(16)
        .frame(width: 420)
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
        .onAppear { isFieldFocused = true }
        .onChange(of: store.promptedAt) { _, _ in isFieldFocused = true }
    }
}

#Preview {
    PromptView()
        .environment(StatusMenuViewStore.preview)
}
