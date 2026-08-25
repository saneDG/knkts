import AppKit
import SystemConfiguration

private struct Connection: Equatable {
    let id: String
    let name: String
}

private let networkStoreDidChange: SCDynamicStoreCallBack = { _, _, info in
    guard let info else { return }
    let delegate = Unmanaged<AppDelegate>.fromOpaque(info).takeUnretainedValue()
    MainActor.assumeIsolated {
        delegate.refresh()
    }
}

@MainActor
private final class AppDelegate: NSObject, NSApplicationDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private var store: SCDynamicStore?
    private var runLoopSource: CFRunLoopSource?
    private var connections: [Connection] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        observeNetworkChanges()
        refresh()
    }

    private func observeNetworkChanges() {
        var context = SCDynamicStoreContext(
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil,
            release: nil,
            copyDescription: nil
        )
        guard let store = SCDynamicStoreCreate(nil, "Knkts" as CFString, networkStoreDidChange, &context) else { return }
        self.store = store

        let patterns = [
            "State:/Network/Service/[^/]+/(IPv4|IPv6)",
            "Setup:/Network/Service/.*"
        ] as CFArray
        guard SCDynamicStoreSetNotificationKeys(store, nil, patterns),
              let source = SCDynamicStoreCreateRunLoopSource(nil, store, 0)
        else { return }

        runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
    }

    fileprivate func refresh() {
        let latest = activeWiredConnections()
        guard latest != connections || statusItem.menu == nil else { return }
        connections = latest

        let connected = !connections.isEmpty
        let symbol = connected ? "cable.connector" : "cable.connector.slash"
        statusItem.button?.image = NSImage(systemSymbolName: symbol, accessibilityDescription: connected ? "Wired connection active" : "No wired connection")
        statusItem.button?.toolTip = connected ? "Wired connection active" : "No wired connection"

        let menu = NSMenu()
        if connections.isEmpty {
            let item = NSMenuItem(title: "No Wired Connection", action: nil, keyEquivalent: "")
            item.isEnabled = false
            menu.addItem(item)

            let settingsItem = NSMenuItem(title: "Open Network Settings", action: #selector(openNetworkSettings), keyEquivalent: "")
            settingsItem.target = self
            menu.addItem(settingsItem)
        } else {
            for connection in connections {
                let item = NSMenuItem(title: connection.name, action: #selector(openNetworkSettings), keyEquivalent: "")
                item.target = self
                item.representedObject = connection.id
                let symbol = connection.name.localizedCaseInsensitiveContains("iPhone") ? "cable.connector" : "network"
                item.image = NSImage(systemSymbolName: symbol, accessibilityDescription: connection.name)
                menu.addItem(item)
            }
        }

        menu.addItem(.separator())
        let quitItem = NSMenuItem(title: "Quit Knkts", action: #selector(quit), keyEquivalent: "")
        quitItem.target = self
        menu.addItem(quitItem)
        statusItem.menu = menu
    }

    private func activeWiredConnections() -> [Connection] {
        guard let store,
              let keys = SCDynamicStoreCopyKeyList(store, "State:/Network/Service/[^/]+/(IPv4|IPv6)" as CFString) as? [String]
        else { return [] }

        let activeIDs = Set(keys.compactMap { key -> String? in
            let parts = key.split(separator: "/")
            return parts.count > 3 ? String(parts[3]) : nil
        })

        guard let preferences = SCPreferencesCreate(nil, "Knkts" as CFString, nil) else { return [] }

        return activeIDs.compactMap { id in
            guard let service = SCNetworkServiceCopy(preferences, id as CFString),
                  SCNetworkServiceGetEnabled(service),
                  let interface = SCNetworkServiceGetInterface(service),
                  SCNetworkInterfaceGetInterfaceType(interface) == kSCNetworkInterfaceTypeEthernet
            else { return nil }
            let name = (SCNetworkServiceGetName(service) as String?) ?? (SCNetworkInterfaceGetBSDName(interface) as String?) ?? id
            return Connection(id: id, name: name)
        }.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    @objc private func openNetworkSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.Network-Settings.extension") else { return }
        NSWorkspace.shared.open(url)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}

private let app = NSApplication.shared
private let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
