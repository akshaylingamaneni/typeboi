import Cocoa

final class KeyboardMonitor {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private let eventMask = CGEventMask(1 << CGEventType.keyDown.rawValue)

    var onKeyEvent: ((KeyEventContext) -> Void)?
    var onTapDisabled: (() -> Void)?

    func start() -> Bool {
        let callback: CGEventTapCallBack = { proxy, type, event, refcon in
            guard let refcon = refcon else { return Unmanaged.passUnretained(event) }
            let monitor = Unmanaged<KeyboardMonitor>.fromOpaque(refcon).takeUnretainedValue()

            // Handle tap being disabled (permission revoked)
            if type == .tapDisabledByUserInput || type == .tapDisabledByTimeout {
                monitor.onTapDisabled?()
                return Unmanaged.passUnretained(event)
            }

            guard type == .keyDown else { return Unmanaged.passUnretained(event) }
            monitor.handle(event: event)
            return Unmanaged.passUnretained(event)
        }

        let refcon = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())

        // Include tap disabled events in the mask
        let fullMask = eventMask | CGEventMask(1 << CGEventType.tapDisabledByUserInput.rawValue) | CGEventMask(1 << CGEventType.tapDisabledByTimeout.rawValue)

        guard let tap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: fullMask,
            callback: callback,
            userInfo: refcon
        ) else {
            return false
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        if let runLoopSource {
            CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        }
        CGEvent.tapEnable(tap: tap, enable: true)
        return true
    }

    func stop() {
        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        }
        if let eventTap {
            CFMachPortInvalidate(eventTap)
        }
        runLoopSource = nil
        eventTap = nil
    }

    private func handle(event: CGEvent) {
        let keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))
        let flags = event.flags
        let app = NSWorkspace.shared.frontmostApplication

        let context = KeyEventContext(
            timestamp: event.timestampSeconds,
            keyCode: keyCode,
            flags: flags,
            isAutoRepeat: event.getIntegerValueField(.keyboardEventAutorepeat) != 0,
            appBundleID: app?.bundleIdentifier,
            appName: app?.localizedName
        )
        onKeyEvent?(context)
    }
}

private extension CGEvent {
    var timestampSeconds: TimeInterval {
        TimeInterval(timestamp) / 1_000_000_000.0
    }
}
