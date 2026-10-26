import Foundation

final class TimerAlarm {
    private let timer: Timer

    init(at date: Date, tolerance: TimeInterval, fire: @escaping @Sendable () -> Void) {
        timer = Timer(fire: date, interval: 0, repeats: false) { _ in fire() }
        timer.tolerance = tolerance
        RunLoop.main.add(timer, forMode: .common)
    }

    func cancel() {
        timer.invalidate()
    }
}
