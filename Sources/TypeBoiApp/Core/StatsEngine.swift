import Foundation

@MainActor
final class StatsEngine: ObservableObject {
    @Published private(set) var stats: DailyStats
    @Published private(set) var currentWPM: Double = 0
    @Published private(set) var displayedWPM: Double = 0

    private let store: StatsStore
    private let settings: AppSettings

    private var lastEventTime: TimeInterval?
    private var burstStartTime: TimeInterval?
    private var burstKeystrokes: Int = 0
    private var lastPrintableTime: TimeInterval?
    private var wpmUpdateTimer: Timer?

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
                let target = self.currentWPM
                let current = self.displayedWPM

                let diff = target - current
                let step = diff * 0.3

                if abs(diff) < 0.5 {
                    if self.displayedWPM != target {
                        self.displayedWPM = target
                    }
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
            burstStartTime = nil
            burstKeystrokes = 0
            lastPrintableTime = nil
            currentWPM = 0
            displayedWPM = 0
        }

        let now = event.timestamp
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

    private func updateCurrentWPM(event: KeyEventContext) {
        guard event.isPrintable, !event.isAutoRepeat else { return }
        let now = event.timestamp
        if let lastPrintableTime {
            if now - lastPrintableTime > settings.burstGap {
                burstStartTime = now
                burstKeystrokes = 0
            }
        } else {
            burstStartTime = now
            burstKeystrokes = 0
        }

        lastPrintableTime = now
        burstKeystrokes += 1

        guard let start = burstStartTime else { return }
        let elapsed = max(0.1, now - start)
        let minutes = elapsed / 60.0
        currentWPM = minutes > 0 ? (Double(burstKeystrokes) / 5.0) / minutes : 0
    }
}
