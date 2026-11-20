import SwiftUI

struct ResultRowView: View {
    let entry: Entry
    var onCopy: () -> Void

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(entry.date.formatted(date: .omitted, time: .shortened))
                .font(.body.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 64, alignment: .leading)
            Text(entry.text)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button(action: onCopy) {
                Image(systemName: "doc.on.doc")
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)
            .help("Copy")
        }
        .padding(.vertical, 3)
    }
}

#Preview {
    if let entry = StatusMenuViewStore.preview.latestReport?.entries.first {
        ResultRowView(entry: entry, onCopy: {})
            .padding()
    }
}
