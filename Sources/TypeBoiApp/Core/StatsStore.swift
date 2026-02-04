import Foundation

final class StatsStore {
    private let fileManager = FileManager.default
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private var dirty = false

    var todayStats: DailyStats

    init() {
        encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        decoder = JSONDecoder()

        let today = DateFormatter.isoDay.string(from: Date())
        todayStats = DailyStats(date: today)
        if let loaded = try? loadStats(for: today) {
            todayStats = loaded
        }
    }

    func markDirty() {
        dirty = true
    }

    func saveIfNeeded() {
        guard dirty else { return }
        do {
            try save(stats: todayStats)
            dirty = false
        } catch {
            // Best effort save; failures will retry on next tick.
        }
    }

    func exportYearJSON(to url: URL) throws {
        saveIfNeeded()
        let index = try loadIndex()
        var export: [DailyStats] = []
        for day in index.days.sorted() {
            if let stats = try? loadStats(for: day) {
                export.append(stats)
            }
        }
        let data = try encoder.encode(export)
        try data.write(to: url, options: [.atomic])
    }

    func loadAllStats() -> [DailyStats] {
        let index = (try? loadIndex()) ?? StatsIndex()
        var results: [DailyStats] = []
        for day in index.days.sorted() {
            if let stats = try? loadStats(for: day) {
                results.append(stats)
            }
        }
        return results
    }

    func rollToNewDayIfNeeded() {
        let today = DateFormatter.isoDay.string(from: Date())
        if todayStats.date != today {
            saveIfNeeded()
            todayStats = DailyStats(date: today)
            dirty = true
        }
    }

    func resetAllData() throws {
        let dir = try ensureDataDirectory()
        if fileManager.fileExists(atPath: dir.path) {
            try fileManager.removeItem(at: dir)
        }
        todayStats = DailyStats(date: DateFormatter.isoDay.string(from: Date()))
        dirty = true
    }

    var dataDirectoryURL: URL? {
        try? dataDirectory()
    }

    private func dataDirectory() throws -> URL {
        let appSupport = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return appSupport.appendingPathComponent("TypeBoi", isDirectory: true)
    }

    private func ensureDataDirectory() throws -> URL {
        let dir = try dataDirectory()
        if !fileManager.fileExists(atPath: dir.path) {
            try fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    private func statsURL(for day: String) throws -> URL {
        let dir = try ensureDataDirectory()
        return dir.appendingPathComponent("\(day).json")
    }

    private func indexURL() throws -> URL {
        let dir = try ensureDataDirectory()
        return dir.appendingPathComponent("index.json")
    }

    private func save(stats: DailyStats) throws {
        let url = try statsURL(for: stats.date)
        let data = try encoder.encode(stats)
        try data.write(to: url, options: [.atomic])

        var index = (try? loadIndex()) ?? StatsIndex()
        if !index.days.contains(stats.date) {
            index.days.append(stats.date)
            let indexData = try encoder.encode(index)
            let indexURL = try indexURL()
            try indexData.write(to: indexURL, options: [.atomic])
        }
    }

    private func loadStats(for day: String) throws -> DailyStats {
        let url = try statsURL(for: day)
        let data = try Data(contentsOf: url)
        return try decoder.decode(DailyStats.self, from: data)
    }

    private func loadIndex() throws -> StatsIndex {
        let url = try indexURL()
        if !fileManager.fileExists(atPath: url.path) {
            return StatsIndex()
        }
        let data = try Data(contentsOf: url)
        return try decoder.decode(StatsIndex.self, from: data)
    }
}
