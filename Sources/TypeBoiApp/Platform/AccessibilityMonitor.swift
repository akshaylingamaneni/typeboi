import Cocoa

@MainActor
final class AccessibilityMonitor: ObservableObject {
    @Published private(set) var isTrusted: Bool = AXIsProcessTrusted()

    func refresh() {
        isTrusted = AXIsProcessTrusted()
    }
}
