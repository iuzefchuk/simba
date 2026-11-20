import SwiftUI

struct PromptView: View {
    @Environment(StatusMenuViewStore.self) private var store
    @FocusState private var isFieldFocused: Bool

    private var canSave: Bool { Entry.normalized(store.draft) != nil }

    var body: some View {
        @Bindable var store = store
        HStack(alignment: .top, spacing: 14) {
            MarkView(size: 46)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 8) {
                TextField("What are you doing right now?", text: $store.draft)
                    .textFieldStyle(.roundedBorder)
                    .focused($isFieldFocused)
                    .onSubmit { if canSave { store.answerPrompt() } }
                HStack {
                    Spacer()
                    Button("Skip") { store.skipPrompt() }
                        .keyboardShortcut(.cancelAction)
                    Button("Save") { store.answerPrompt() }
                        .buttonStyle(.borderedProminent)
                        .tint(Color(.chestnut))
                        .disabled(!canSave)
                }
                .controlSize(.small)
            }
        }
        .padding(16)
        .frame(width: 420)
        .background(Color(.cream), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
            .strokeBorder(Color(.chestnut).opacity(0.25)))
        .onAppear { isFieldFocused = true }
        .onChange(of: store.promptedAt) { _, _ in isFieldFocused = true }
    }
}

#Preview {
    PromptView()
        .environment(StatusMenuViewStore.preview)
}
