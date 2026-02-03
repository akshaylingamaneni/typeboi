import Foundation

protocol KeyClassifier {
    var isBackspace: Bool { get }
    var isModifierOnly: Bool { get }
    var isShortcut: Bool { get }
    var isPrintable: Bool { get }
}

struct KeyEvent: KeyClassifier {
    let timestamp: TimeInterval
    let isBackspace: Bool
    let isModifierOnly: Bool
    let isShortcut: Bool
    let isPrintable: Bool
    let isAutoRepeat: Bool
    let appBundleID: String?
    let appName: String?
}
