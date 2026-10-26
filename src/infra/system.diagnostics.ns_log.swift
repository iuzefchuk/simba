import Foundation

enum NSLogDiagnostics {
    static func note(_ message: String) {
        NSLog("%@", message)
    }
}
