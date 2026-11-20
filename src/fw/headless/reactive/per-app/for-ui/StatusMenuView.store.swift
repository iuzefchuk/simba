import Foundation
import Observation
import ServiceManagement

@MainActor
@Observable
final class StatusMenuViewStore {
    private static let reportsKey = "reports"
    private static let workHoursKey = "work-hours"

    private(set) var reports: [Report]
    private(set) var promptedAt: Date?
    var draft = ""
    var selectedReportID: Report.ID?
    var workHours: WorkHours {
        didSet {
            saveWorkHours()
            followWorkHours()
        }
    }
    @ObservationIgnored private let storage: any StoragePort
    @ObservationIgnored private let scheduling: any SchedulingPort
    @ObservationIgnored private let windows: WindowCoordinator
    @ObservationIgnored private var isFirstLaunch: Bool
    @ObservationIgnored private var promptScheduleID: UUID?
    @ObservationIgnored private var workHoursScheduleID: UUID?

    init(storage: any StoragePort, scheduling: any SchedulingPort, windows: WindowCoordinator) {
        self.storage = storage
        self.scheduling = scheduling
        self.windows = windows
        var reports = storage.load([Report].self, key: Self.reportsKey, version: Report.schemaVersion) ?? []
        if let violation = reports.violation {
            NSLog("%@", "the saved reports violate \(violation)")
            storage.setAside(key: Self.reportsKey)
            reports = []
        }
        let endedStale = reports.endStale(now: .now) != nil
        self.reports = reports
        let savedWorkHours = storage.load(WorkHours.self, key: Self.workHoursKey, version: WorkHours.schemaVersion)
        workHours = savedWorkHours ?? .standard
        isFirstLaunch = savedWorkHours == nil
        if endedStale { saveReports() }
        if isLogging { scheduleNextPrompt() }
    }

    var openReport: Report? { reports.openReport }
    var latestReport: Report? { reports.last }
    var isLogging: Bool { openReport != nil }

    var launchesAtLogin: Bool {
        get { SMAppService.mainApp.status == .enabled }
        set {
            do {
                if newValue {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                NSLog("%@", "launch at login change failed: \(error)")
            }
        }
    }

    func appDidLaunch() {
        if isFirstLaunch {
            isFirstLaunch = false
            saveWorkHours()
            launchesAtLogin = true
            showSetup()
        }
        followWorkHours()
    }

    func startLogging() {
        change { try $0.start(at: .now) }
        scheduleNextPrompt()
    }

    func endLogging(at date: Date = .now) {
        if promptedAt != nil { answerPrompt() }
        guard let report = change({ try $0.end(at: date) }) else { return }
        cancelNextPrompt()
        showResult(report.id)
    }

    func prompt(at date: Date = .now) {
        promptedAt = date
        windows.open(.prompt)
    }

    func answerPrompt() {
        guard promptedAt != nil else { return }
        guard let entry = Entry(date: .now, text: draft) else { return skipPrompt() }
        change { try $0.add(entry) }
        closePrompt()
    }

    func skipPrompt() {
        if promptedAt != nil { change { try $0.skip(at: .now) } }
        closePrompt()
    }

    private func closePrompt() {
        promptedAt = nil
        draft = ""
        windows.close(.prompt)
    }

    func remove(_ entryID: Entry.ID, from reportID: Report.ID) {
        change { try $0.remove(entryID, from: reportID) }
    }

    func showResult(_ reportID: Report.ID? = nil) {
        selectedReportID = reportID ?? latestReport?.id
        windows.open(.result)
    }

    func showSetup() {
        windows.open(.setup)
    }

    func loadSample() {
        let tenAM = Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: .now) ?? .now
        change { try $0.start(at: tenAM.addingTimeInterval(-1800)) }
        let texts = ["Reviewing the payments PR", "Investigating flaky CI on main", "Design sync, then writing up the API proposal"]
        for (hour, text) in texts.enumerated() {
            if let entry = Entry(date: tenAM.addingTimeInterval(Double(hour) * 3600), text: text) {
                change { try $0.add(entry) }
            }
        }
        prompt(at: tenAM.addingTimeInterval(10800))
    }

    private func followWorkHours() {
        let now = Date.now
        if let end = reports.endDue(during: workHours, at: now, in: .current) {
            endLogging(at: end)
        }
        if reports.isStartDue(during: workHours, at: now, in: .current) {
            startLogging()
        }
        if let workHoursScheduleID { scheduling.cancel(workHoursScheduleID) }
        workHoursScheduleID = workHours.nextChange(after: now, in: .current).map { date in
            scheduling.schedule(at: date, tolerance: 15) { [weak self] in
                Task { @MainActor in self?.followWorkHours() }
            }
        }
    }

    private func scheduleNextPrompt() {
        if let promptScheduleID { scheduling.cancel(promptScheduleID) }
        let fireDate = Self.nextPrompt(after: .now)
        promptScheduleID = scheduling.schedule(at: fireDate, tolerance: 15) { [weak self] in
            Task { @MainActor in self?.promptFired(scheduledFor: fireDate) }
        }
    }

    private func promptFired(scheduledFor date: Date) {
        guard isLogging else { return }
        if promptedAt != nil { change { try $0.skip(at: date) } }
        prompt(at: date)
        scheduleNextPrompt()
    }

    private func cancelNextPrompt() {
        if let promptScheduleID { scheduling.cancel(promptScheduleID) }
        promptScheduleID = nil
    }

    @discardableResult
    private func change(_ apply: (inout [Report]) throws -> Report) -> Report? {
        do {
            let report = try apply(&reports)
            saveReports()
            return report
        } catch {
            NSLog("%@", "the change was rejected: \(error)")
            return nil
        }
    }

    private func saveReports() {
        storage.save(reports, key: Self.reportsKey, version: Report.schemaVersion)
    }

    private func saveWorkHours() {
        storage.save(workHours, key: Self.workHoursKey, version: WorkHours.schemaVersion)
    }

    private static func nextPrompt(after date: Date) -> Date {
        if let interval = promptInterval {
            return date.addingTimeInterval(interval)
        }
        return Logging.nextPrompt(after: date, in: .current)
    }

    private static let promptInterval: TimeInterval? = {
        let arguments = ProcessInfo.processInfo.arguments
        guard let flag = arguments.firstIndex(of: "-promptInterval"), arguments.indices.contains(flag + 1),
              let interval = TimeInterval(arguments[flag + 1]), interval > 0 else { return nil }
        return interval
    }()
}

extension StatusMenuViewStore {
    static var preview: StatusMenuViewStore {
        let store = StatusMenuViewStore(storage: JSONStorage.temporary("Previews"), scheduling: TimerScheduling(), windows: WindowCoordinator())
        store.loadSample()
        return store
    }
}
