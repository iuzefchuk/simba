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
            if report != nil {
                header
                Divider()
            }
            content
            Divider()
            footer
        }
    }

    private var header: some View {
        @Bindable var store = store
        return HStack {
            Picker("Report", selection: $store.selectedReportID) {
                ForEach(store.reports.reversed()) { report in
                    Text(title(of: report)).tag(Optional(report.id))
                }
            }
            .labelsHidden()
            .fixedSize()
            Spacer()
        }
        .padding(12)
    }

    @ViewBuilder
    private var content: some View {
        if let report, !report.entries.isEmpty {
            List {
                ForEach(report.entries) { entry in
                    ResultRowView(entry: entry)
                        .contextMenu {
                            Button("Copy") { copy(entry.text, message: "Copied") }
                            Button("Delete", role: .destructive) { store.remove(entry.id, from: report.id) }
                        }
                }
            }
            .listStyle(.inset)
        } else {
            ContentUnavailableView(
                "No entries yet",
                systemImage: "tray",
                description: Text("Answers to the hourly prompt will show up here."))
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
