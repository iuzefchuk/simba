import Foundation

protocol SchedulingPort {
    func schedule(at date: Date, tolerance: TimeInterval, fire: @escaping @Sendable () -> Void) -> UUID
    func cancel(_ id: UUID)
}
