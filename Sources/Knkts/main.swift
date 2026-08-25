import AppKit
import SystemConfiguration

private struct Connection: Equatable {
    let id: String
    let name: String
}

@MainActor
private final class AppDelegate: NSObject, NSApplicationDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let store = SCDynamicStoreCreate(nil, "Knkts" as CFString, nil, nil)
    private var connections: [Connection] = []
    private var timer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        refresh()
        timer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(refresh), userInfo: nil, repeats: true)
    }

    @objc private func refresh() {
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
        } else {
            for connection in connections {
                let item = NSMenuItem(title: connection.name, action: #selector(openNetworkSettings), keyEquivalent: "")
                item.target = self
                item.representedObject = connection.id
                menu.addItem(item)
            }
        }
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
}

private let app = NSApplication.shared
private let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
