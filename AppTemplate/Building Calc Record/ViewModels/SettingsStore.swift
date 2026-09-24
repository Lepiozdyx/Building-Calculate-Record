import Foundation
import Observation
import UIKit
import UserNotifications

@Observable
final class SettingsStore {
    var displayName: String {
        didSet { UserDefaults.standard.set(displayName, forKey: Keys.displayName) }
    }

    var occupation: String {
        didSet { UserDefaults.standard.set(occupation, forKey: Keys.occupation) }
    }

    var currencyCode: String {
        didSet { UserDefaults.standard.set(currencyCode, forKey: Keys.currencyCode) }
    }

    var unitSystem: UnitSystem {
        didSet { UserDefaults.standard.set(unitSystem.rawValue, forKey: Keys.unitSystem) }
    }

    var defaultWastePercent: Double {
        didSet { UserDefaults.standard.set(defaultWastePercent, forKey: Keys.defaultWaste) }
    }

    var hasCompletedOnboarding: Bool {
        didSet { UserDefaults.standard.set(hasCompletedOnboarding, forKey: Keys.onboardingDone) }
    }

    var calculationReminders: Bool {
        didSet { UserDefaults.standard.set(calculationReminders, forKey: Keys.calcReminders) }
    }

    var tipOfTheDay: Bool {
        didSet {
            UserDefaults.standard.set(tipOfTheDay, forKey: Keys.tipOfDay)
            let enabled = tipOfTheDay
            Task { await NotificationScheduler.shared.updateTipSchedule(enabled: enabled) }
        }
    }

    var projectReminders: Bool {
        didSet { UserDefaults.standard.set(projectReminders, forKey: Keys.projectReminders) }
    }

    var appUpdates: Bool {
        didSet { UserDefaults.standard.set(appUpdates, forKey: Keys.appUpdates) }
    }

    var favoriteTipIDs: Set<String> {
        didSet { UserDefaults.standard.set(Array(favoriteTipIDs), forKey: Keys.favoriteTips) }
    }

    var profilePhotoFilename: String? {
        didSet { UserDefaults.standard.set(profilePhotoFilename, forKey: Keys.profilePhoto) }
    }

    init() {
        let defaults = UserDefaults.standard
        displayName = defaults.string(forKey: Keys.displayName) ?? "Guest"
        occupation = defaults.string(forKey: Keys.occupation) ?? "DIY Builder"
        currencyCode = defaults.string(forKey: Keys.currencyCode) ?? "USD"
        unitSystem = UnitSystem(rawValue: defaults.string(forKey: Keys.unitSystem) ?? "") ?? .metric
        if defaults.object(forKey: Keys.defaultWaste) == nil {
            defaultWastePercent = 10
        } else {
            defaultWastePercent = defaults.double(forKey: Keys.defaultWaste)
        }
        hasCompletedOnboarding = defaults.bool(forKey: Keys.onboardingDone)
        calculationReminders = Self.storedBool(Keys.calcReminders, default: true)
        tipOfTheDay = Self.storedBool(Keys.tipOfDay, default: true)
        projectReminders = Self.storedBool(Keys.projectReminders, default: false)
        appUpdates = Self.storedBool(Keys.appUpdates, default: true)
        favoriteTipIDs = Set(defaults.stringArray(forKey: Keys.favoriteTips) ?? [])
        profilePhotoFilename = defaults.string(forKey: Keys.profilePhoto)
    }

    private static func storedBool(_ key: String, default defaultValue: Bool) -> Bool {
        guard UserDefaults.standard.object(forKey: key) != nil else { return defaultValue }
        return UserDefaults.standard.bool(forKey: key)
    }

    func toggleFavorite(tipID: String) {
        var set = favoriteTipIDs
        if set.contains(tipID) {
            set.remove(tipID)
        } else {
            set.insert(tipID)
        }
        favoriteTipIDs = set
    }

    func isFavorite(tipID: String) -> Bool {
        favoriteTipIDs.contains(tipID)
    }

    func formatMoney(_ amount: Double, currencyCode: String? = nil) -> String {
        let code = currencyCode ?? self.currencyCode
        let option = CurrencyCatalog.option(for: code)
        if amount == amount.rounded() {
            return "\(option.symbol)\(Int(amount))"
        }
        return String(format: "%@%.2f", option.symbol, amount)
    }

    func profilePhotoURL() -> URL? {
        guard let name = profilePhotoFilename else { return nil }
        return Self.profilePhotosDirectory.appendingPathComponent(name)
    }

    func saveProfilePhoto(data: Data) throws {
        try FileManager.default.createDirectory(at: Self.profilePhotosDirectory, withIntermediateDirectories: true)
        let filename = "profile-\(UUID().uuidString).jpg"
        let url = Self.profilePhotosDirectory.appendingPathComponent(filename)
        let jpeg = UIImage(data: data)?.jpegData(compressionQuality: 0.85) ?? data
        try jpeg.write(to: url)
        if let old = profilePhotoFilename {
            try? FileManager.default.removeItem(at: Self.profilePhotosDirectory.appendingPathComponent(old))
        }
        profilePhotoFilename = filename
    }

    private enum Keys {
        static let displayName = "displayName"
        static let occupation = "occupation"
        static let currencyCode = "currencyCode"
        static let unitSystem = "unitSystem"
        static let defaultWaste = "defaultWaste"
        static let onboardingDone = "onboardingDone"
        static let calcReminders = "calcReminders"
        static let tipOfDay = "tipOfDay"
        static let projectReminders = "projectReminders"
        static let appUpdates = "appUpdates"
        static let favoriteTips = "favoriteTips"
        static let profilePhoto = "profilePhoto"
    }

    private static var profilePhotosDirectory: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ProfilePhotos", isDirectory: true)
    }
}

@MainActor
final class NotificationScheduler {
    static let shared = NotificationScheduler()

    func updateTipSchedule(enabled: Bool) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["tipOfDay"])
        guard enabled else { return }
        let granted = try? await center.requestAuthorization(options: [.alert, .sound])
        guard granted == true else { return }
        let content = UNMutableNotificationContent()
        content.title = "Tip of the Day"
        content.body = Catalog.tipOfTheDay().title
        var date = DateComponents()
        date.hour = 9
        date.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
        let request = UNNotificationRequest(identifier: "tipOfDay", content: content, trigger: trigger)
        try? await center.add(request)
    }
}
