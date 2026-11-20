import SwiftUI

struct HistoryRowView: View {
    let entry: Entry

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(entry.date.formatted(date: .omitted, time: .standard))
                .font(.body.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 80, alignment: .leading)
            Text(entry.text)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 3)
    }
}

#Preview {
    if let entry = StatusMenuViewStore.preview.latestReport?.entries.first {
        HistoryRowView(entry: entry)
            .padding()
    }
}
