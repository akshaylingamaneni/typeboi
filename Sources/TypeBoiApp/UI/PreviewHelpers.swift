import SwiftUI

#if DEBUG
extension StatsEngine {
    static var preview: StatsEngine {
        let store = StatsStore()
        let settings = AppSettings()
        let engine = StatsEngine(store: store, settings: settings)
        return engine
    }
}

extension DailyStats {
    static var preview: DailyStats {
        var stats = DailyStats(date: DateFormatter.isoDay.string(from: Date()))
        stats.global = GlobalStats(
            keystrokesTotal: 12847,
            keystrokesPrintable: 10234,
            backspaceCount: 892,
            shortcutCount: 1721,
            activeSeconds: 7200,
            typingSeconds: 5400,
            typingKeystrokes: 9500
        )
        stats.hourlyGlobal = [
            8: HourlyStats(keystrokesTotal: 500),
            9: HourlyStats(keystrokesTotal: 1200),
            10: HourlyStats(keystrokesTotal: 800),
            11: HourlyStats(keystrokesTotal: 1500),
            12: HourlyStats(keystrokesTotal: 200),
            14: HourlyStats(keystrokesTotal: 1800),
            15: HourlyStats(keystrokesTotal: 2000),
            16: HourlyStats(keystrokesTotal: 1600),
            17: HourlyStats(keystrokesTotal: 1247)
        ]
        stats.apps = [
            "com.apple.dt.Xcode": AppStats(appName: "Xcode", keystrokesTotal: 5000, keystrokesPrintable: 4200, backspaceCount: 300, shortcutCount: 500),
            "com.microsoft.VSCode": AppStats(appName: "VS Code", keystrokesTotal: 3500, keystrokesPrintable: 3000, backspaceCount: 200, shortcutCount: 300),
            "com.apple.Safari": AppStats(appName: "Safari", keystrokesTotal: 2000, keystrokesPrintable: 1500, backspaceCount: 200, shortcutCount: 300),
            "com.apple.Terminal": AppStats(appName: "Terminal", keystrokesTotal: 1500, keystrokesPrintable: 1200, backspaceCount: 100, shortcutCount: 200)
        ]
        return stats
    }
}

extension HourlyStats {
    init(keystrokesTotal: Int) {
        self.keystrokesTotal = keystrokesTotal
        self.keystrokesPrintable = Int(Double(keystrokesTotal) * 0.8)
        self.backspaceCount = Int(Double(keystrokesTotal) * 0.07)
        self.shortcutCount = Int(Double(keystrokesTotal) * 0.13)
        self.activeSeconds = Double(keystrokesTotal) * 0.5
        self.typingSeconds = Double(keystrokesTotal) * 0.4
        self.typingKeystrokes = Int(Double(keystrokesTotal) * 0.75)
    }
}
#endif
