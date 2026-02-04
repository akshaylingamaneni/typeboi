import Foundation
import Combine

enum MenuBarStyle: String, CaseIterable {
    case text = "Text"
    case icon = "Icon"
    case activity = "Activity"
    case wpm = "WPM"
}

final class AppSettings: ObservableObject {
    @Published var idleThreshold: TimeInterval {
        didSet { UserDefaults.standard.set(idleThreshold, forKey: Keys.idleThreshold) }
    }
    @Published var burstGap: TimeInterval {
        didSet { UserDefaults.standard.set(burstGap, forKey: Keys.burstGap) }
    }
    @Published var excludedBundleIDs: Set<String> {
        didSet { UserDefaults.standard.set(Array(excludedBundleIDs), forKey: Keys.excludedBundleIDs) }
    }
    @Published var menuBarStyle: MenuBarStyle {
        didSet { UserDefaults.standard.set(menuBarStyle.rawValue, forKey: Keys.menuBarStyle) }
    }

    init() {
        let defaults = UserDefaults.standard
        let idle = defaults.double(forKey: Keys.idleThreshold)
        idleThreshold = (idle > 0 && idle <= 10) ? idle : 3
        let burst = defaults.double(forKey: Keys.burstGap)
        burstGap = (burst > 0 && burst <= 5) ? burst : 1.5
        let excluded = defaults.stringArray(forKey: Keys.excludedBundleIDs) ?? []
        excludedBundleIDs = Set(excluded)
        let style = defaults.string(forKey: Keys.menuBarStyle) ?? MenuBarStyle.icon.rawValue
        menuBarStyle = MenuBarStyle(rawValue: style) ?? .icon
    }

    private enum Keys {
        static let idleThreshold = "idleThresholdSeconds"
        static let burstGap = "burstGapSeconds"
        static let excludedBundleIDs = "excludedBundleIDs"
        static let menuBarStyle = "menuBarStyle"
    }
}
