import SwiftUI

struct ResultView: View {
    @Environment(StatusMenuViewStore.self) private var store
    @State private var copiedMessage: String?
    @State private var copiedMessageTask: Task<Void, Never>?

    private var report: Report? {
        store.reports.first { $0.id == store.selectedReportID } ?? store.latestReport
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            content
            Divider()
            footer
        }
        .background(Color(.ivory))
    }

    @ViewBuilder
    private var header: some View {
        @Bindable var store = store
        HStack(spacing: 14) {
            MarkView(size: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text(report.map { title(of: $0) } ?? "Simba")
                    .font(.title3.weight(.semibold))
                if let report {
                    Text("\(timeRange(of: report)) · ^[\(report.entries.count) entry](inflect: true)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if store.reports.count > 1 {
                Picker("Report", selection: $store.selectedReportID) {
                    ForEach(store.reports.reversed()) { report in
                        Text(title(of: report)).tag(Optional(report.id))
                    }
                }
                .labelsHidden()
                .frame(width: 170)
            }
        }
        .padding(16)
    }

    @ViewBuilder
    private var content: some View {
        if let report, !report.entries.isEmpty {
            List {
                ForEach(report.entries) { entry in
                    ResultRowView(entry: entry, onCopy: { copy(entry.text, message: "Copied") })
                        .contextMenu {
                            Button("Copy") { copy(entry.text, message: "Copied") }
                            Button("Copy with Time") { copy(line(of: entry), message: "Copied") }
                            Divider()
                            Button("Delete", role: .destructive) { store.remove(entry.id, from: report.id) }
                        }
                }
            }
            .listStyle(.inset)
            .scrollContentBackground(.hidden)
        } else {
            ContentUnavailableView {
                Label {
                    Text("No entries yet")
                } icon: {
                    MarkView(size: 64)
                }
            } description: {
                Text(report == nil
                     ? "Logging starts with your work hours, or from the menu bar."
                     : "Answers to the hourly prompt will show up here.")
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var footer: some View {
        HStack {
            if let copiedMessage {
                Label(copiedMessage, systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.secondary)
                    .transition(.opacity)
            }
            Spacer()
            Button("Copy All") {
                guard let report else { return }
                let count = report.entries.count
                copy(text(of: report), message: "Copied \(count) \(count == 1 ? "entry" : "entries")")
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(.chestnut))
            .keyboardShortcut("c", modifiers: [.command, .shift])
            .disabled(report?.entries.isEmpty ?? true)
        }
        .padding(12)
        .animation(.default, value: copiedMessage)
    }

    private func copy(_ text: String, message: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        copiedMessage = message
        copiedMessageTask?.cancel()
        copiedMessageTask = Task {
            try? await Task.sleep(for: .seconds(1.8))
            if !Task.isCancelled { copiedMessage = nil }
        }
    }

    private func title(of report: Report) -> String {
        let calendar = Calendar.current
        var style = Date.FormatStyle.dateTime.weekday(.wide).month(.abbreviated).day()
        if !calendar.isDate(report.startedAt, equalTo: .now, toGranularity: .year) {
            style = style.year()
        }
        let title = report.startedAt.formatted(style)
        let sharesDay = store.reports.contains {
            $0.id != report.id && calendar.isDate($0.startedAt, inSameDayAs: report.startedAt)
        }
        return sharesDay ? "\(title) · \(report.startedAt.formatted(date: .omitted, time: .shortened))" : title
    }

    private func timeRange(of report: Report) -> String {
        let start = report.startedAt.formatted(date: .omitted, time: .shortened)
        guard let endedAt = report.endedAt else { return "Started \(start)" }
        return "\(start) – \(endedAt.formatted(date: .omitted, time: .shortened))"
    }

    private func line(of entry: Entry) -> String {
        "\(entry.date.formatted(date: .omitted, time: .shortened)) – \(entry.text)"
    }

    private func text(of report: Report) -> String {
        report.entries.map(line(of:)).joined(separator: "\n")
    }
}

#Preview {
    ResultView()
        .environment(StatusMenuViewStore.preview)
        .frame(width: 520, height: 560)
}
