import SwiftUI

final class HistoryViewModel: ObservableObject {
    @Published var dailyStats: [DailyStats] = []

    private let store: StatsStore

    init(store: StatsStore) {
        self.store = store
    }

    func load() {
        dailyStats = store.loadAllStats()
    }
}

struct HistoryView: View {
    enum RangeSelection: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
    }

    @StateObject private var viewModel: HistoryViewModel
    @State private var selection: RangeSelection = .month

    init(store: StatsStore) {
        _viewModel = StateObject(wrappedValue: HistoryViewModel(store: store))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            header
            rangePicker
            heatmapSection
            summaryCards
            Spacer()
        }
        .onAppear {
            viewModel.load()
        }
    }

    private var header: some View {
        HStack {
            Text("Activity History")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            Spacer()
            Text("\(filteredStats.count) days")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }

    private var rangePicker: some View {
        Picker("Range", selection: $selection) {
            ForEach(RangeSelection.allCases, id: \.self) { range in
                Text(range.rawValue).tag(range)
            }
        }
        .pickerStyle(.segmented)
    }

    private var heatmapSection: some View {
        GitHubHeatmap(
            dailyStats: viewModel.dailyStats,
            weeksToShow: weeksForSelection
        )
        .frame(height: heatmapHeight)
        .glassCard()
    }

    private var weeksForSelection: Int {
        switch selection {
        case .week: return 2
        case .month: return 5
        case .year: return 52
        }
    }

    private var heatmapHeight: CGFloat {
        switch selection {
        case .week: return 140
        case .month: return 160
        case .year: return 180
        }
    }

    private var filteredStats: [DailyStats] {
        let today = Date()
        let calendar = Calendar.current
        let daysBack: Int
        switch selection {
        case .week: daysBack = 6
        case .month: daysBack = 29
        case .year: daysBack = 364
        }
        let startDate = calendar.date(byAdding: .day, value: -daysBack, to: today) ?? today
        let allowed = Set(dateRange(from: startDate, to: today).map { DateFormatter.isoDay.string(from: $0) })
        let lookup = Dictionary(uniqueKeysWithValues: viewModel.dailyStats.map { ($0.date, $0) })
        return allowed.sorted().compactMap { lookup[$0] }
    }

    private var summaryCards: some View {
        let total = filteredStats.reduce(0) { $0 + $1.global.keystrokesTotal }
        let printable = filteredStats.reduce(0) { $0 + $1.global.keystrokesPrintable }
        let backspace = filteredStats.reduce(0) { $0 + $1.global.backspaceCount }
        let shortcuts = filteredStats.reduce(0) { $0 + $1.global.shortcutCount }

        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.sm) {
            StatCard("Total", value: formatted(total), icon: "keyboard")
            StatCard("Printable", value: formatted(printable), icon: "character")
            StatCard("Backspace", value: formatted(backspace), icon: "delete.left")
            StatCard("Shortcuts", value: formatted(shortcuts), icon: "command")
        }
    }

    private func formatted(_ value: Int) -> String {
        if value >= 1000000 {
            return String(format: "%.1fM", Double(value) / 1000000)
        } else if value >= 1000 {
            return String(format: "%.1fk", Double(value) / 1000)
        }
        return "\(value)"
    }

    private func dateRange(from start: Date, to end: Date) -> [Date] {
        var dates: [Date] = []
        var current = Calendar.current.startOfDay(for: start)
        let endDay = Calendar.current.startOfDay(for: end)
        while current <= endDay {
            dates.append(current)
            guard let next = Calendar.current.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }
        return dates
    }
}

struct HeatmapData {
    let weeks: [[DayCell]]
    let maxValue: Int
    let monthLabels: [(String, Int)]
}

struct GitHubHeatmap: View {
    let dailyStats: [DailyStats]
    let weeksToShow: Int

    @State private var hoveredDay: DayCell?
    @State private var cachedData: HeatmapData?

    private let dayLabels = ["S", "M", "T", "W", "T", "F", "S"]

    private var heatmapData: HeatmapData {
        cachedData ?? computeHeatmapData()
    }

    private var cellSize: CGFloat {
        weeksToShow > 20 ? 10 : 12
    }

    private var cellSpacing: CGFloat {
        weeksToShow > 20 ? 2 : 3
    }

    private func computeHeatmapData() -> HeatmapData {
        let statsLookup = Dictionary(uniqueKeysWithValues: dailyStats.map { ($0.date, $0) })
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        guard let startDate = calendar.date(byAdding: .day, value: -(weeksToShow * 7 - 1), to: today) else {
            return HeatmapData(weeks: [], maxValue: 1, monthLabels: [])
        }

        var weeks: [[DayCell]] = []
        var currentWeek: [DayCell] = []

        let startWeekday = calendar.component(.weekday, from: startDate)
        for _ in 1..<startWeekday {
            currentWeek.append(DayCell(date: nil, value: 0))
        }

        var current = startDate
        while current <= today {
            let dateStr = DateFormatter.isoDay.string(from: current)
            let value = statsLookup[dateStr]?.global.keystrokesTotal ?? 0
            currentWeek.append(DayCell(date: current, value: value))

            if currentWeek.count == 7 {
                weeks.append(currentWeek)
                currentWeek = []
            }
            current = calendar.date(byAdding: .day, value: 1, to: current) ?? current
        }

        if !currentWeek.isEmpty {
            while currentWeek.count < 7 {
                currentWeek.append(DayCell(date: nil, value: 0))
            }
            weeks.append(currentWeek)
        }

        let maxValue = weeks.flatMap { $0 }.map(\.value).max() ?? 1

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        var labels: [(String, Int)] = []
        var lastMonth = -1
        for (weekIndex, week) in weeks.enumerated() {
            if let firstValidDay = week.first(where: { $0.date != nil }),
               let date = firstValidDay.date {
                let month = calendar.component(.month, from: date)
                if month != lastMonth {
                    labels.append((formatter.string(from: date), weekIndex))
                    lastMonth = month
                }
            }
        }

        return HeatmapData(weeks: weeks, maxValue: maxValue, monthLabels: labels)
    }

    var body: some View {
        let data = heatmapData
        VStack(alignment: .leading, spacing: Spacing.sm) {
            hoverInfo

            HStack(alignment: .top, spacing: Spacing.xs) {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("")
                        .font(.caption2)
                        .frame(height: 14)
                    dayLabelsColumn
                }

                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: weeksToShow > 20) {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            monthLabelsRow(data: data)
                            weeksGrid(data: data)
                        }
                        .padding(.trailing, Spacing.md)
                        .id("heatmapEnd")
                    }
                    .onAppear {
                        proxy.scrollTo("heatmapEnd", anchor: .trailing)
                    }
                    .onChange(of: weeksToShow) {
                        proxy.scrollTo("heatmapEnd", anchor: .trailing)
                    }
                }
            }

            HStack {
                Spacer()
                legendView
            }
        }
        .onAppear {
            cachedData = computeHeatmapData()
        }
        .onChange(of: dailyStats.count) {
            cachedData = computeHeatmapData()
        }
        .onChange(of: weeksToShow) {
            cachedData = computeHeatmapData()
        }
    }

    @ViewBuilder
    private var hoverInfo: some View {
        if let day = hoveredDay, let date = day.date {
            HStack {
                Text(tooltipText(date: date, value: day.value))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .transition(.opacity)
        } else {
            Text(" ")
                .font(.caption)
        }
    }

    private func monthLabelsRow(data: HeatmapData) -> some View {
        HStack(spacing: cellSpacing) {
            ForEach(Array(data.weeks.enumerated()), id: \.offset) { weekIndex, _ in
                let label = data.monthLabels.first { $0.1 == weekIndex }?.0
                Text(label ?? "")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(width: cellSize, alignment: .leading)
            }
        }
        .frame(height: 14)
    }

    private var dayLabelsColumn: some View {
        VStack(spacing: cellSpacing) {
            ForEach(0..<7, id: \.self) { day in
                Text(dayLabels[day])
                    .font(.system(size: 8))
                    .foregroundStyle(.tertiary)
                    .frame(width: 12, height: cellSize)
            }
        }
    }

    private func weeksGrid(data: HeatmapData) -> some View {
        HStack(alignment: .top, spacing: cellSpacing) {
            ForEach(Array(data.weeks.enumerated()), id: \.offset) { _, week in
                VStack(spacing: cellSpacing) {
                    ForEach(Array(week.enumerated()), id: \.offset) { _, day in
                        cellView(for: day, maxValue: data.maxValue)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func cellView(for day: DayCell, maxValue: Int) -> some View {
        if day.date != nil {
            let isHovered = hoveredDay == day
            RoundedRectangle(cornerRadius: 2)
                .fill(colorFor(value: day.value, maxValue: maxValue, isHovered: isHovered))
                .frame(width: cellSize, height: cellSize)
                .scaleEffect(isHovered ? 1.3 : 1.0)
                .animation(.easeOut(duration: 0.1), value: isHovered)
                .onHover { hovering in
                    hoveredDay = hovering ? day : nil
                }
        } else {
            Color.clear
                .frame(width: cellSize, height: cellSize)
        }
    }

    private func tooltipText(date: Date, value: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "\(formatter.string(from: date)) • \(value) keystrokes"
    }

    private func colorFor(value: Int, maxValue: Int, isHovered: Bool = false) -> Color {
        guard maxValue > 0 else { return Color.secondary.opacity(0.1) }
        let intensity = Double(value) / Double(maxValue)
        let color = HeatmapIntensity.color(for: intensity)
        return isHovered ? color.opacity(1.0) : color
    }

    private var legendView: some View {
        HStack(spacing: 4) {
            Text("Less")
                .font(.caption2)
                .foregroundStyle(.tertiary)

            ForEach([0.0, 0.25, 0.5, 0.75, 1.0], id: \.self) { intensity in
                RoundedRectangle(cornerRadius: 2)
                    .fill(HeatmapIntensity.color(for: intensity))
                    .frame(width: 10, height: 10)
            }

            Text("More")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }
}

struct DayCell: Equatable {
    let date: Date?
    let value: Int
}

#Preview {
    HistoryView(store: StatsStore())
        .frame(width: 360, height: 500)
        .padding()
}
