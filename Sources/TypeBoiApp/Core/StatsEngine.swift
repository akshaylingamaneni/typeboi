import Foundation

@MainActor
final class StatsEngine: ObservableObject {
    @Published private(set) var stats: DailyStats
    @Published private(set) var currentWPM: Double = 0
    @Published private(set) var displayedWPM: Double = 0
    @Published private(set) var lastBurstWPM: Double = 0

    private let store: StatsStore
    private let settings: AppSettings

    private var lastEventTime: TimeInterval?
    private var wpmUpdateTimer: Timer?
    private var peakBurstWPM: Double = 0
    private var wasIdle: Bool = true

    init(store: StatsStore, settings: AppSettings) {
        self.store = store
        self.settings = settings
        self.stats = store.todayStats
        startWPMSmoothing()
    }

    func stopTimers() {
        wpmUpdateTimer?.invalidate()
        wpmUpdateTimer = nil
    }

    private func startWPMSmoothing() {
        wpmUpdateTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }

                // If idle past threshold, decay to 0 faster
                let idleTime = self.wpmLastKeystroke.map { Date().timeIntervalSince($0) } ?? 100
                let isIdle = idleTime > self.settings.idleThreshold

                // Track peak during active typing
                if !isIdle && self.displayedWPM > self.peakBurstWPM {
                    self.peakBurstWPM = self.displayedWPM
                }

                // Save peak when transitioning to idle
                if isIdle && !self.wasIdle && self.peakBurstWPM >= 10 {
                    self.lastBurstWPM = self.peakBurstWPM
                    self.peakBurstWPM = 0
                }
                self.wasIdle = isIdle

                let target = isIdle ? 0.0 : self.currentWPM
                let current = self.displayedWPM
                let diff = target - current

                // Fast rise, medium decay, fast decay when idle
                let factor: Double
                if diff > 0 {
                    factor = 0.3
                } else if isIdle {
                    factor = 0.4
                } else {
                    factor = 0.15
                }

                let step = diff * factor
                if abs(diff) < 1.0 {
                    self.displayedWPM = target
                } else {
                    self.displayedWPM = current + step
                }
            }
        }
    }

    func refresh() {
        stats = store.todayStats
    }

    func handle(event: KeyEventContext) {
        if let bundleID = event.appBundleID, settings.excludedBundleIDs.contains(bundleID) {
            return
        }

        let previousDate = stats.date
        store.rollToNewDayIfNeeded()
        stats = store.todayStats
        if previousDate != stats.date {
            lastEventTime = nil
            wpmWindowStart = nil
            wpmKeystrokeCount = 0
            wpmLastKeystroke = nil
            currentWPM = 0
            displayedWPM = 0
            peakBurstWPM = 0
            lastBurstWPM = 0
        }

        let now = Date().timeIntervalSinceReferenceDate
        var delta: TimeInterval?
        if let last = lastEventTime {
            delta = max(0, now - last)
        }
        lastEventTime = now

        updateGlobal(event: event, delta: delta)
        updateHourly(event: event, delta: delta)
        updatePerApp(event: event)
        updateCurrentWPM(event: event)

        store.todayStats = stats
        store.markDirty()
    }

    private func updateGlobal(event: KeyEventContext, delta: TimeInterval?) {
        var global = stats.global
        global.keystrokesTotal += 1
        if event.isPrintable { global.keystrokesPrintable += 1 }
        if event.isBackspace { global.backspaceCount += 1 }
        if event.isShortcut { global.shortcutCount += 1 }

        if let delta {
            if delta <= settings.idleThreshold {
                global.activeSeconds += delta
            }
            if delta <= settings.idleThreshold, event.isPrintable, !event.isAutoRepeat {
                global.typingSeconds += delta
            }
        }
        if event.isPrintable, !event.isAutoRepeat {
            global.typingKeystrokes += 1
        }

        stats.global = global
    }

    private func updateHourly(event: KeyEventContext, delta: TimeInterval?) {
        let hour = Calendar.current.component(.hour, from: Date())
        var hourly = stats.hourlyGlobal[hour] ?? HourlyStats()
        hourly.keystrokesTotal += 1
        if event.isPrintable { hourly.keystrokesPrintable += 1 }
        if event.isBackspace { hourly.backspaceCount += 1 }
        if event.isShortcut { hourly.shortcutCount += 1 }

        if let delta {
            if delta <= settings.idleThreshold {
                hourly.activeSeconds += delta
            }
            if delta <= settings.idleThreshold, event.isPrintable, !event.isAutoRepeat {
                hourly.typingSeconds += delta
            }
        }
        if event.isPrintable, !event.isAutoRepeat {
            hourly.typingKeystrokes += 1
        }

        stats.hourlyGlobal[hour] = hourly
    }

    private func updatePerApp(event: KeyEventContext) {
        guard let bundleID = event.appBundleID else { return }
        let name = event.appName ?? bundleID
        var appStats = stats.apps[bundleID] ?? AppStats(appName: name)
        appStats.keystrokesTotal += 1
        if event.isPrintable { appStats.keystrokesPrintable += 1 }
        if event.isBackspace { appStats.backspaceCount += 1 }
        if event.isShortcut { appStats.shortcutCount += 1 }
        stats.apps[bundleID] = appStats
    }

    private var wpmKeystrokeCount: Int = 0
    private var wpmWindowStart: Date?
    private var wpmLastKeystroke: Date?

    private func updateCurrentWPM(event: KeyEventContext) {
        guard event.isPrintable, !event.isAutoRepeat, !event.isShortcut else { return }

        let now = Date()
        let windowSize: TimeInterval = 10.0

        // Reset window if pause detected (thinking time shouldn't count)
        // Keep last WPM displayed - don't zero it on pause
        if let lastKey = wpmLastKeystroke, now.timeIntervalSince(lastKey) > settings.burstGap {
            wpmWindowStart = now
            wpmKeystrokeCount = 1
            wpmLastKeystroke = now
            return
        }
        wpmLastKeystroke = now

        if let start = wpmWindowStart {
            let elapsed = now.timeIntervalSince(start)
            if elapsed > windowSize {
                wpmWindowStart = now
                wpmKeystrokeCount = 1
                currentWPM = 0
                return
            }
            wpmKeystrokeCount += 1

            guard wpmKeystrokeCount >= 10, elapsed >= 2.0 else {
                currentWPM = 0
                return
            }

            let minutes = elapsed / 60.0
            currentWPM = (Double(wpmKeystrokeCount) / 5.0) / minutes
        } else {
            wpmWindowStart = now
            wpmKeystrokeCount = 1
            currentWPM = 0
        }
    }

}
