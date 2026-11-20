import Foundation

final class TimerScheduling: SchedulingPort {
    private var timers: [UUID: DispatchSourceTimer] = [:]

    func schedule(at date: Date, tolerance: TimeInterval, fire: @escaping @Sendable () -> Void) -> UUID {
        let id = UUID()
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(wallDeadline: .now() + date.timeIntervalSinceNow, leeway: .milliseconds(Int(tolerance * 1000)))
        timer.setEventHandler { [weak self] in
            self?.cancel(id)
            fire()
        }
        timer.resume()
        timers[id] = timer
        return id
    }

    func cancel(_ id: UUID) {
        timers.removeValue(forKey: id)?.cancel()
    }
}
