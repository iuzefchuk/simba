import Foundation

enum UserDefaultsPreferences {
    static var didShowSetup: Bool {
        get { UserDefaults.standard.bool(forKey: "didShowSetup") }
        set { UserDefaults.standard.set(newValue, forKey: "didShowSetup") }
    }

    static var promptInterval: TimeInterval? {
        let interval = UserDefaults.standard.double(forKey: "promptInterval")
        return interval > 0 ? interval : nil
    }
}
