import Foundation

struct GlobalStats: Codable {
    var keystrokesTotal: Int = 0
    var keystrokesPrintable: Int = 0
    var backspaceCount: Int = 0
    var shortcutCount: Int = 0
    var activeSeconds: TimeInterval = 0
    var typingSeconds: TimeInterval = 0
    var typingKeystrokes: Int = 0

    var wpmActive: Double {
        guard activeSeconds >= 10, typingKeystrokes >= 10 else { return 0 }
        let minutes = activeSeconds / 60.0
        return minutes > 0 ? (Double(typingKeystrokes) / 5.0) / minutes : 0
    }
}

struct HourlyStats: Codable {
    var keystrokesTotal: Int = 0
    var keystrokesPrintable: Int = 0
    var backspaceCount: Int = 0
    var shortcutCount: Int = 0
    var activeSeconds: TimeInterval = 0
    var typingSeconds: TimeInterval = 0
    var typingKeystrokes: Int = 0

    var wpmActive: Double {
        guard activeSeconds >= 10, typingKeystrokes >= 10 else { return 0 }
        let minutes = activeSeconds / 60.0
        return minutes > 0 ? (Double(typingKeystrokes) / 5.0) / minutes : 0
    }
}

struct AppStats: Codable {
    var appName: String
    var keystrokesTotal: Int = 0
    var keystrokesPrintable: Int = 0
    var backspaceCount: Int = 0
    var shortcutCount: Int = 0
}

struct DailyStats: Codable {
    var date: String
    var global: GlobalStats = GlobalStats()
    var hourlyGlobal: [Int: HourlyStats] = [:]
    var apps: [String: AppStats] = [:]
}

struct StatsIndex: Codable {
    var days: [String] = []
}
