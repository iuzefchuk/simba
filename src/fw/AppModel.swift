import Foundation
import Observation

@MainActor
@Observable
final class AppModel {
    let store: ReportStore
    private(set) var nextPromptAt: Date?
    private(set) var promptedAt: Date?
    var draft = ""
    var selectedReportID: Report.ID?
    var destination: Destination?
    @ObservationIgnored private var alarm: TimerAlarm?

    enum Destination {
        case result
        case setup
    }

    init(store: ReportStore) {
        self.store = store
        store.endStaleReport()
        if isLogging { scheduleNextPrompt() }
    }

    var isLogging: Bool { store.openReport != nil }

    var launchesAtLogin: Bool {
        get { ServiceManagementLaunchAtLogin.isEnabled }
        set {
            do {
                try ServiceManagementLaunchAtLogin.setEnabled(newValue)
            } catch {
                NSLogDiagnostics.note("launch at login change failed: \(error)")
            }
        }
    }

    func startLogging() {
        store.startReport()
        scheduleNextPrompt()
    }

    func endLogging() {
        if promptedAt != nil { answerPrompt() }
        guard let report = store.endReport() else { return }
        cancelNextPrompt()
        showResult(report.id)
    }

    func prompt(at date: Date = .now) {
        promptedAt = date
    }

    func answerPrompt() {
        if let promptedAt, let entry = Entry(date: promptedAt, text: draft) {
            store.add(entry)
        }
        skipPrompt()
    }

    func skipPrompt() {
        promptedAt = nil
        draft = ""
    }

    func showResult(_ reportID: Report.ID? = nil) {
        selectedReportID = reportID ?? store.latestReport?.id
        destination = .result
    }

    func showSetup() {
        destination = .setup
    }

    func loadSample() {
        let tenAM = Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: .now) ?? .now
        store.startReport(at: tenAM.addingTimeInterval(-1800))
        let texts = ["Reviewing the payments PR", "Investigating flaky CI on main", "Design sync, then writing up the API proposal"]
        for (hour, text) in texts.enumerated() {
            if let entry = Entry(date: tenAM.addingTimeInterval(Double(hour) * 3600), text: text) {
                store.add(entry)
            }
        }
        prompt(at: tenAM.addingTimeInterval(10800))
    }

    private func scheduleNextPrompt() {
        alarm?.cancel()
        let fireDate = Self.nextPrompt(after: .now)
        nextPromptAt = fireDate
        alarm = TimerAlarm(at: fireDate, tolerance: 15) { [weak self] in
            Task { @MainActor in self?.promptAlarmFired(scheduledFor: fireDate) }
        }
    }

    private func promptAlarmFired(scheduledFor date: Date) {
        guard isLogging else { return }
        prompt(at: date)
        scheduleNextPrompt()
    }

    private func cancelNextPrompt() {
        alarm?.cancel()
        alarm = nil
        nextPromptAt = nil
    }

    private static func nextPrompt(after date: Date) -> Date {
        if let interval = UserDefaultsPreferences.promptInterval {
            return date.addingTimeInterval(interval)
        }
        return Logging.nextPrompt(after: date, in: .current)
    }
}

extension AppModel {
    static var preview: AppModel {
        let folder = FileManagerAppFolder.temporary("Previews")
        try? FileManagerAppFolder.empty(folder)
        let model = AppModel(store: ReportStore(fileURL: folder.appending(path: "reports.json")))
        model.loadSample()
        return model
    }
}
