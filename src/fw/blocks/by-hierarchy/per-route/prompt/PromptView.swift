import SwiftUI

struct PromptView: View {
    @Environment(AppModel.self) private var model
    @FocusState private var isFieldFocused: Bool

    private var canSave: Bool { Entry.normalized(model.draft) != nil }

    var body: some View {
        @Bindable var model = model
        HStack(alignment: .top, spacing: 14) {
            MarkView(size: 46)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Entry")
                        .font(.headline)
                    Spacer()
                    Text(model.promptedAt ?? .now, format: .dateTime.hour().minute())
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                TextField("What are you doing right now?", text: $model.draft)
                    .textFieldStyle(.roundedBorder)
                    .focused($isFieldFocused)
                    .onSubmit { if canSave { model.answerPrompt() } }
                HStack {
                    Text("Return to save · Esc to skip")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    Spacer()
                    Button("Skip") { model.skipPrompt() }
                        .keyboardShortcut(.cancelAction)
                    Button("Save") { model.answerPrompt() }
                        .buttonStyle(.borderedProminent)
                        .tint(Color(.accent))
                        .disabled(!canSave)
                }
                .controlSize(.small)
            }
        }
        .padding(16)
        .frame(width: 420)
        .background(Color(.panelBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
            .strokeBorder(Color(.accent).opacity(0.25)))
        .onAppear { isFieldFocused = true }
        .onChange(of: model.promptedAt) { _, _ in isFieldFocused = true }
    }
}

#Preview {
    PromptView()
        .environment(AppModel.preview)
}
