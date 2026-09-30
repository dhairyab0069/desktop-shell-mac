import AppKit

/// Everything the user can change, shared by every Desktop Shell process (the
/// folders, widgets, taskbar and hotkeys background services).
///
/// All of them read and write one preferences domain. After a change, call
/// `Settings.broadcastChange()`; every process listening with
/// `Settings.onChange` then re-reads and re-draws.
public final class Settings {
    public static let shared = Settings()
    public static let domain = "local.dhairyabhatia.desktop"
    private static let changed = Notification.Name("local.dhairyabhatia.desktop.changed")

    private let defaults: UserDefaults

    private init() {
        defaults = Bundle.main.bundleIdentifier == Self.domain ? .standard : UserDefaults(suiteName: Self.domain)!
        defaults.register(defaults: [
            "showWidgets": true,
            "showFolders": true,
            "foldersIncludeDownloads": false,
            "widgetsCollapsed": false,
            "widgetEdge": WidgetEdge.right.rawValue,
            "keepWindowsClear": true,
            "showTaskbar": true,
            "ghosttyHotkey": true,
            "optionOpensStart": true,
            "showNowPlaying": true,
            "youtubeLoops": true,
        ])
    }

    // MARK: - Telling the other processes

    /// Tell every Desktop Shell process that settings or the layout changed.
    public static func broadcastChange() {
        DistributedNotificationCenter.default().postNotificationName(changed, object: nil, userInfo: nil,
                                                                    deliverImmediately: true)
    }

    /// Run `block` on the main thread whenever any Desktop Shell process broadcasts a change
    /// (bursts are coalesced into one call).
    @MainActor
    public static func onChange(_ block: @escaping @MainActor () -> Void) {
        let debounce = Debounce()
        DistributedNotificationCenter.default().addObserver(forName: changed, object: nil, queue: .main) { _ in
            onMainActor {
                debounce.pending?.cancel()
                let work = DispatchWorkItem { onMainActor { block() } }
                debounce.pending = work
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: work)
            }
        }
    }

    /// Ask the taskbar service to open (or close) the Start menu.
    public static func requestStartMenu() {
        DistributedNotificationCenter.default().postNotificationName(startMenu, object: nil, userInfo: nil, deliverImmediately: true)
    }

    @MainActor
    public static func onStartMenuRequest(_ block: @escaping @MainActor () -> Void) {
        DistributedNotificationCenter.default().addObserver(forName: startMenu, object: nil, queue: .main) { _ in
            onMainActor { block() }
        }
    }

    private static let startMenu = Notification.Name("local.dhairyabhatia.desktop.startMenu")

    // MARK: - Raw access (for values other processes write)

    public func string(_ key: String) -> String? {
        defaults.synchronize() // pick up what another process just wrote
        return defaults.string(forKey: key)
    }

    public func set(_ value: Any?, for key: String) { defaults.set(value, forKey: key) }

    public func stringArray(_ key: String) -> [String]? {
        defaults.synchronize()
        return defaults.stringArray(forKey: key)
    }

    public func counts(_ key: String) -> [String: Int] {
        defaults.synchronize()
        return defaults.dictionary(forKey: key) as? [String: Int] ?? [:]
    }

    private func bool(_ key: String) -> Bool {
        defaults.synchronize()
        return defaults.bool(forKey: key)
    }

    // MARK: - Widgets

    public var showWidgets: Bool {
        get { bool("showWidgets") }
        set { defaults.set(newValue, forKey: "showWidgets") }
    }

    public var widgetsCollapsed: Bool {
        get { bool("widgetsCollapsed") }
        set { defaults.set(newValue, forKey: "widgetsCollapsed") }
    }

    public var widgetEdge: WidgetEdge {
        get { WidgetEdge(rawValue: string("widgetEdge") ?? "") ?? .right }
        set { defaults.set(newValue.rawValue, forKey: "widgetEdge") }
    }

    /// The Now Playing widget (Apple Music, with its looping motion artwork).
    public var showNowPlaying: Bool {
        get { bool("showNowPlaying") }
        set { defaults.set(newValue, forKey: "showNowPlaying") }
    }

    /// No Apple Music motion artwork? Loop the middle of the song's YouTube video instead.
    public var youtubeLoops: Bool {
        get { bool("youtubeLoops") }
        set { defaults.set(newValue, forKey: "youtubeLoops") }
    }

    // MARK: - Folders service

    public var showFolders: Bool {
        get { bool("showFolders") }
        set { defaults.set(newValue, forKey: "showFolders") }
    }

    public var foldersIncludeDownloads: Bool {
        get { bool("foldersIncludeDownloads") }
        set { defaults.set(newValue, forKey: "foldersIncludeDownloads") }
    }

    // MARK: - Taskbar service

    /// The Windows XP taskbar in place of the Dock.
    public var showTaskbar: Bool {
        get { bool("showTaskbar") }
        set { defaults.set(newValue, forKey: "showTaskbar") }
    }

    /// ⌃T opens Ghostty from anywhere.
    public var ghosttyHotkey: Bool {
        get { bool("ghosttyHotkey") }
        set { defaults.set(newValue, forKey: "ghosttyHotkey") }
    }

    /// Tapping ⌥ Option on its own opens the Start menu, like the Windows key.
    public var optionOpensStart: Bool {
        get { bool("optionOpensStart") }
        set { defaults.set(newValue, forKey: "optionOpensStart") }
    }

    /// Tile app windows so they never overlap the widgets, folders or taskbar (needs Accessibility).
    public var keepWindowsClear: Bool {
        get { bool("keepWindowsClear") }
        set { defaults.set(newValue, forKey: "keepWindowsClear") }
    }
}

/// Holds the pending coalesced callback. Only ever touched on the main thread.
private final class Debounce: @unchecked Sendable {
    var pending: DispatchWorkItem?
}

/// Which screen edge the widget panel is docked to. Left/right = a vertical
/// column; top/bottom = a horizontal strip.
public enum WidgetEdge: String, CaseIterable {
    case right = "Right", left = "Left", top = "Top", bottom = "Bottom"
    public var isVertical: Bool { self == .left || self == .right }
}
