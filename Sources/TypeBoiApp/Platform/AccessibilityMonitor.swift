import Cocoa

@MainActor
final class AccessibilityMonitor: ObservableObject {
    @Published private(set) var isTrusted: Bool = AXIsProcessTrusted()
    private var pollTimer: Timer?

    init() {
        startPolling()
    }

    func refresh() {
        let wasTrusted = isTrusted
        isTrusted = AXIsProcessTrusted()

        if !wasTrusted && isTrusted {
            NotificationCenter.default.post(name: .accessibilityPermissionGranted, object: nil)
        } else if wasTrusted && !isTrusted {
            NotificationCenter.default.post(name: .accessibilityPermissionRevoked, object: nil)
        }
    }

    func forceRevoked() {
        isTrusted = false
        NotificationCenter.default.post(name: .accessibilityPermissionRevoked, object: nil)
    }

    private func startPolling() {
        pollTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refresh()
            }
        }
    }

    func stopPolling() {
        pollTimer?.invalidate()
        pollTimer = nil
    }
}

extension Notification.Name {
    static let accessibilityPermissionRevoked = Notification.Name("accessibilityPermissionRevoked")
}
