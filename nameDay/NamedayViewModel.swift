@preconcurrency import Foundation
import AppKit
import ServiceManagement
import SwiftUI

// MARK: - Calendar & Date helpers (Prague TZ)
private extension Calendar {
    static let prague: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Europe/Prague")!
        return cal
    }()
}

private enum PragueDateKey {
    static func key(for date: Date) -> String {
        let comps = Calendar.prague.dateComponents([.month, .day], from: date)
        return String(format: "%02d-%02d", comps.month ?? 1, comps.day ?? 1)
    }
    static var todayKey: String { key(for: Date()) }
    static func tomorrow(from date: Date) -> Date {
        Calendar.prague.date(byAdding: .day, value: 1, to: date) ?? date.addingTimeInterval(86_400)
    }
    static func nextMidnight(after date: Date) -> Date {
        let startOfToday = Calendar.prague.startOfDay(for: date)
        return Calendar.prague.date(byAdding: .day, value: 1, to: startOfToday) ?? date.addingTimeInterval(86_400)
    }
}

// MARK: - Nameday data
private enum NamedayValue: Decodable {
    case string(String)
    case array([String])

    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let s = try? c.decode(String.self) { self = .string(s) }
        else if let a = try? c.decode([String].self) { self = .array(a) }
        else {
            throw DecodingError.typeMismatch(
                NamedayValue.self,
                .init(codingPath: decoder.codingPath, debugDescription: "Expected String or [String]")
            )
        }
    }

    var displayText: String {
        switch self {
        case .string(let s): return s
        case .array(let names): return names.joined(separator: ", ")
        }
    }
}

private enum NamedayStore {
    private static let fileName = "data.json"

    static func loadMap() throws -> [String: NamedayValue] {
        if let url = appSupportFileURL(), FileManager.default.fileExists(atPath: url.path) {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([String: NamedayValue].self, from: data)
        }
        if let url = Bundle.main.url(forResource: fileName.replacingOccurrences(of: ".json", with: ""), withExtension: "json") {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([String: NamedayValue].self, from: data)
        }
        throw NSError(domain: "Nameday", code: 1, userInfo: [NSLocalizedDescriptionKey: "\(fileName) nenalezen"])
    }

    private static func appSupportFileURL() -> URL? {
        let fm = FileManager.default
        guard var base = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return nil }
        let bundleID = Bundle.main.bundleIdentifier ?? "MenuBarJSONApp"
        base.appendPathComponent(bundleID, isDirectory: true)
        try? fm.createDirectory(at: base, withIntermediateDirectories: true)
        return base.appendingPathComponent(fileName)
    }
}

// MARK: - ViewModel
@MainActor
final class NamedayViewModel: ObservableObject {
    @Published var displayText: String = "Načítám…"
    @Published var tomorrowText: String = "Načítám…"
    @Published var launchAtLoginEnabled: Bool = false

    private var midnightTask: Task<Void, Never>?
    private var lastShownKey: String?

    private var wcObserver: NSObjectProtocol?
    private var ncObservers: [NSObjectProtocol] = []

    deinit {
        midnightTask?.cancel()
        if let wcObserver { NSWorkspace.shared.notificationCenter.removeObserver(wcObserver) }
        for t in ncObservers { NotificationCenter.default.removeObserver(t) }
    }

    // MARK: - Public API
    func start() {
        setupNotificationsIfNeeded()
        rescheduleSleepToMidnight()
        Task { await refreshFromLocal() }
    }

    func syncLaunchAtLoginState() {
        launchAtLoginEnabled = (SMAppService.mainApp.status == .enabled)
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled { try SMAppService.mainApp.register() }
            else { try SMAppService.mainApp.unregister() }
        } catch {
            print("LaunchAtLogin error:", error)
        }
        syncLaunchAtLoginState()
    }

    // MARK: - Data
    func refreshFromLocal() async {
        do {
            let map = try NamedayStore.loadMap()
            let now = Date()
            let todayKey = PragueDateKey.key(for: now)
            let tomorrowKey = PragueDateKey.key(for: PragueDateKey.tomorrow(from: now))

            if let val = map[todayKey] {
                displayText = Self.clean(val.displayText)
            } else {
                displayText = "–"
            }

            if let val = map[tomorrowKey] {
                tomorrowText = Self.clean(val.displayText)
            } else {
                tomorrowText = "–"
            }

            lastShownKey = todayKey
        } catch {
            displayText = "Chyba čtení"
            tomorrowText = "Chyba čtení"
            print("Nameday read error:", error)
        }
    }

    private static func clean(_ s: String) -> String {
        let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
        let oneLine = t.replacingOccurrences(of: "\n", with: " ")
        return oneLine.isEmpty ? "–" : oneLine
    }

    // MARK: - Scheduling
    private func rescheduleSleepToMidnight() {
        midnightTask?.cancel()
        midnightTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                let now = Date()
                let next = PragueDateKey.nextMidnight(after: now)
                let seconds = max(1, next.timeIntervalSince(now))
                do {
                    try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                } catch { break }
                await self.refreshFromLocal()
            }
        }
    }

    private func setupNotificationsIfNeeded() {
        guard wcObserver == nil && ncObservers.isEmpty else { return }

        wcObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task { await self.handleWakeOrClockChange() }
        }

        let dayChanged = NotificationCenter.default.addObserver(
            forName: .NSCalendarDayChanged, object: nil, queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task { await self.refreshFromLocal() }
        }

        ncObservers = [dayChanged]
    }

    private func handleWakeOrClockChange() async {
        if PragueDateKey.todayKey != lastShownKey { await refreshFromLocal() }
        rescheduleSleepToMidnight()
    }
}
