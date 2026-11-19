pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import QtQuick.Templates as T
import IDS_GIMBAL

ApplicationWindow {
    id: window
    required property AppSettings settings
    required property Localization localization
    required property NotificationModel notifications
    required property MainControlViewModel mainControl
    required property ImageViewModel imageViewModel
    required property bool demoMode

    // Page registry (architecture §11): the only place a page is listed; menu and content are built from it.
    // Titles are bindings and follow language changes. The views use pages.length as their model, so a
    // language change does not recreate the pages.
    // Services (architecture §12): each has its own connection; pages of both may be open side by side.
    readonly property var services: ({ mainControl: qsTr("Main control service"), idsImage: qsTr("IDS Image service") })
    readonly property var connections: ({ mainControl: mainControl.connection, idsImage: imageViewModel.connection })
    readonly property var pages: [
        // service: key of `services`; pages without one (preferences, developer) belong to no connection.
        // designHeight: natural height of the page's (reference) layout, measured; tst_shell fails if the content
        // outgrows it. The tallest one sets the common scale of all pages (page host below).
        { id: "gimbalInfo", service: "mainControl", group: qsTr("Board"), title: qsTr("Gimbal info"),
          icon: Icons.info, component: gimbalInfoPage, designHeight: 890 },
        { id: "motorControl", service: "mainControl", group: qsTr("Control"), title: qsTr("Motor control"),
          icon: Icons.motor, component: motorControlPage, designHeight: 900 },
        { id: "gimbalSettings", service: "mainControl", group: qsTr("Control"), title: qsTr("Gimbal settings"),
          icon: Icons.sliders, component: gimbalSettingsPage, designHeight: 720 },
        { id: "heater", service: "mainControl", group: qsTr("Hardware"), title: qsTr("Heater"),
          icon: Icons.heater, component: heaterPage },
        { id: "viewControl", service: "idsImage", group: "IDS Image", crumb: "IDS Image", title: qsTr("View & control"),
          icon: Icons.eye, component: viewControlPage, designHeight: 914 },
        { id: "alignment", service: "idsImage", group: "IDS Image", crumb: "IDS Image", title: qsTr("Alignment"),
          icon: Icons.target, component: alignmentPage, designHeight: 819 },
        { id: "errors", service: "idsImage", group: "IDS Image", crumb: "IDS Image", title: qsTr("Errors"),
          icon: Icons.warning, component: errorsPage, designHeight: 743 },
        { id: "gimbalState", service: "idsImage", group: "IDS Image", crumb: "IDS Image", title: qsTr("Gimbal state"),
          icon: Icons.list, component: gimbalStatePage, designHeight: 656 },
        { id: "preferences", group: qsTr("Application"), title: qsTr("Preferences"), icon: Icons.gear,
          component: preferencesPage }
    ]
    // Gimbals the user works with (design page 6). The choice changes the display only: top bar and 3D view
    // (`model`: a 3D component, null until one exists); pages, settings and connections stay the same.
    readonly property var gimbals: [
        { id: "g160", name: "G160", versions: ["v1.0", "v2.0"], model: null },
        { id: "g180", name: "G180", versions: ["v1.0", "v2.0", "v3.0"], model: null },
        { id: "kashif700", name: "Kashif700", versions: ["v1.0"], model: null },
        { id: "zr10", name: "ZR10", versions: ["v1.0"], model: zr10Model }
    ]
    Component { id: zr10Model; GimbalZR10 {} }
    // Saved gimbal, or null when the saved id or version is no longer in the list.
    readonly property var currentGimbal: {
        const g = gimbals.find(g => g.id === settings.gimbal)
        return g && g.versions.includes(settings.gimbalVersion) ? g : null
    }
    readonly property real designHeight: Math.max(...pages.map(page => page.designHeight ?? 0))
    // Starts on the page open at last exit; an unknown (e.g. removed) id falls back to the first page via currentIndex.
    property string currentPageId: settings.lastPage
    onCurrentPageIdChanged: settings.lastPage = currentPageId
    readonly property int currentIndex: Math.max(0, pages.findIndex(page => page.id === window.currentPageId))
    readonly property string activePageId: pages[currentIndex].id
    // Connection of the visible page's service; pages without one (preferences) show the Main control service.
    readonly property string activeService: pages[currentIndex].service ?? "mainControl"
    readonly property ServiceConnection activeConnection: connections[activeService]

    width: 1280
    height: 800
    minimumWidth: 800
    minimumHeight: 560
    visibility: Window.Maximized // a fixed 1280x800 window does not fit 1080p at 125 %
    visible: true
    title: qsTr("IDS Gimbal")
    color: Theme.bg

    Binding {
        target: Theme
        property: "mode"
        value: window.settings.theme
    }
    // Architecture §12, rule 1: without saved settings the connection settings open at startup (real target)
    // and whenever a page of such a service becomes visible. The popup belongs to the visible page's service,
    // so a popup left open for the previous service is closed.
    // The gimbal selection comes first at startup; the connection settings wait until it is closed.
    // askingGimbal: the popup is not visible yet while the window is being completed. The check runs deferred,
    // so a call made while the window is created sees askingGimbal set in Component.onCompleted.
    property bool askingGimbal: false
    function openSettingsIfNotConfigured() {
        Qt.callLater(() => {
            if (!window.demoMode && !window.activeConnection.configured && !window.askingGimbal && !gimbalDialog.visible)
                window.openConnectionSettings()
        })
    }
    Component.onCompleted: {
        if (!currentGimbal || !settings.gimbalOnStart) {
            askingGimbal = true
            gimbalDialog.open()
        }
        openSettingsIfNotConfigured()
    }
    onActiveConnectionChanged: {
        statusBar.connectionPopup.close()
        openSettingsIfNotConfigured()
    }
    function openConnectionSettings() {
        statusBar.connectionPopup.prepare(window.activeConnection.target(), window.activeConnection.availableSerialPorts())
        statusBar.connectionPopup.open()
    }

    Binding {
        target: NumberFormat
        property: "language"
        value: window.localization.language
    }

    Component {
        id: gimbalInfoPage
        GimbalInfoPage {
            viewModel: window.mainControl
        }
    }
    Component {
        id: motorControlPage
        MotorControlPage {
            viewModel: window.mainControl
        }
    }
    Component {
        id: gimbalSettingsPage
        GimbalSettingsPage {
            viewModel: window.mainControl
        }
    }
    Component {
        id: heaterPage
        HeaterPage {
            viewModel: window.mainControl
        }
    }
    Component {
        id: viewControlPage
        ViewControlPage {
            viewModel: window.imageViewModel
            settings: window.settings
        }
    }
    Component {
        id: alignmentPage
        AlignmentPage {
            viewModel: window.imageViewModel
            settings: window.settings
        }
    }
    Component {
        id: errorsPage
        ErrorsPage {
            viewModel: window.imageViewModel
            settings: window.settings
        }
    }
    Component {
        id: gimbalStatePage
        GimbalStatePage {
            viewModel: window.imageViewModel
            settings: window.settings
        }
    }
    Component {
        id: preferencesPage
        PreferencesPage {
            settings: window.settings
            localization: window.localization
        }
    }

    // Exit guard (T23): work that would be lost. Closing asks first; a confirmed exit sets exitConfirmed so the
    // window is not asked twice.
    property bool exitConfirmed: false
    property var exitLosses: []
    function currentLosses(): var {
        const losses = []
        const unsaved = mainControl.parameters.unsavedCount
        if (unsaved > 0)
            losses.push(qsTr("%1 unsaved parameter change(s) will be lost.").arg(unsaved))
        if (mainControl.connection.pendingCommands.includes(Command.UpdateFirmware))
            losses.push(qsTr("The firmware update in progress will be interrupted."))
        if (mainControl.script.running)
            losses.push(qsTr("The script that is playing will stop."))
        if (mainControl.recorder.recording)
            losses.push(qsTr("The CSV recording in progress will be closed."))
        return losses
    }
    onClosing: close => {
        if (exitConfirmed)
            return
        exitLosses = currentLosses()
        if (exitLosses.length === 0)
            return
        close.accepted = false
        exitDialog.open()
    }
    ConfirmDialog {
        id: exitDialog
        objectName: "exitDialog"
        title: qsTr("Exit the application?")
        text: qsTr("If you exit now:") + "\n" + window.exitLosses.map(loss => "• " + loss).join("\n")
        cancelText: qsTr("Stay")
        acceptText: qsTr("Exit")
        danger: true
        onConfirmed: { window.exitConfirmed = true; window.close() }
    }

    GimbalSelectDialog {
        id: gimbalDialog
        objectName: "gimbalDialog"
        gimbals: window.gimbals
        currentId: window.currentGimbal ? window.currentGimbal.id : ""
        currentVersion: window.currentGimbal ? window.settings.gimbalVersion : ""
        onStart: window.settings.gimbalOnStart
        onAccepted: (id, version, onStart) => {
            window.settings.gimbal = id
            window.settings.gimbalVersion = version
            window.settings.gimbalOnStart = onStart
        }
        onClosed: {
            window.askingGimbal = false
            window.openSettingsIfNotConfigured()
        }
    }

    RealtimeWindow {
        id: realtimeWindow
        objectName: "realtimeWindow"
        transientParent: window // closes with the main window
        viewModel: window.mainControl
        notifications: window.notifications
    }

    AppShell {
        anchors.fill: parent

        navigation: NavRail {
            id: navRail
            // Start of the IDS Image group: a line, then the service's logo and connection dot.
            Component {
                id: imageBrand
                Column {
                    width: navRail.expandedWidth - 24
                    Rectangle { x: 6; width: parent.width - 12; height: 1; color: Theme.line }
                    Item { width: 1; height: 12 }
                    RailBrand {
                        objectName: "railBrandImage"
                        rail: navRail
                        logoSource: Qt.resolvedUrl("../assets/icons/ids_logo.png")
                        title: "IDS Image"
                        subtitle: window.services.idsImage
                        connected: window.imageViewModel.connection.connected
                        connectionLabel: window.imageViewModel.connection.statusText
                    }
                }
            }
            RailBrand {
                logoSource: Qt.resolvedUrl("../assets/icons/ids_logo.png")
                title: "IDS Control"
                subtitle: qsTr("Main control service")
                connected: window.mainControl.connection.connected
                connectionLabel: window.mainControl.connection.statusText
            }
            Repeater {
                model: window.pages.length
                Column {
                    id: navEntry
                    required property int index
                    readonly property var page: window.pages[index]
                    width: navRail.expandedWidth - 24
                    Loader {
                        active: navEntry.page.service === "idsImage"
                                && (navEntry.index === 0 || window.pages[navEntry.index - 1].service !== "idsImage")
                        visible: active
                        sourceComponent: imageBrand
                    }
                    NavSection {
                        rail: navRail
                        visible: navEntry.index === 0
                                 || window.pages[navEntry.index - 1].group !== navEntry.page.group
                        text: navEntry.page.group
                    }
                    NavItem {
                        objectName: "nav-" + navEntry.page.id
                        rail: navRail
                        text: navEntry.page.title
                        iconPath: navEntry.page.icon
                        current: window.currentIndex === navEntry.index
                        onClicked: window.currentPageId = navEntry.page.id
                    }
                }
            }
            Loader { // no IDS Image pages yet: the group shows its logo only
                active: !window.pages.some(page => page.service === "idsImage")
                visible: active
                sourceComponent: imageBrand
            }
        }

        topBar: TopBar {
            objectName: "topBar"
            readonly property var page: window.pages[window.currentIndex]
            crumbs: page.service ? [page.crumb ?? window.services[page.service], page.title] : [page.title]
            Badge {
                visible: window.demoMode
                kind: "warn"
                text: qsTr("Sample data")
            }
            IdsButton {
                objectName: "realtimeButton"
                iconPath: Icons.chart
                text: qsTr("Realtime graph and logger")
                onClicked: realtimeWindow.show()
            }
            ThemeSwitcher {
                objectName: "themeSwitcher"
                settings: window.settings
            }
            // Both services at a glance: green when all are connected, amber when some are or one is connecting,
            // red when none is or one has an error. Opens the panel of both connections.
            T.AbstractButton {
                id: connectionChip
                readonly property var links: Object.values(window.connections)
                readonly property int connectedCount: links.filter(link => link.connected).length
                readonly property bool anyBusy: links.some(link => link.busy)
                objectName: "connectionStatus"
                text: connectedCount === links.length ? qsTr("Connected")
                    : connectedCount > 0 ? qsTr("%1/%2 connected").arg(connectedCount).arg(links.length)
                    : anyBusy ? qsTr("Connecting")
                    : qsTr("Not connected")
                implicitWidth: chipLabel.implicitWidth
                implicitHeight: chipLabel.implicitHeight
                focusPolicy: Qt.StrongFocus
                hoverEnabled: true
                Accessible.name: qsTr("Connections: %1").arg(text)
                onClicked: connectionsPanel.opened ? connectionsPanel.close() : connectionsPanel.open()
                background: StatusLabel {
                    id: chipLabel
                    framed: true
                    status: connectionChip.links.some(link => link.hasError) || connectionChip.connectedCount === 0 && !connectionChip.anyBusy ? "crit"
                          : connectionChip.connectedCount === connectionChip.links.length ? "ok"
                          : "warn"
                    text: connectionChip.text
                    opacity: connectionChip.down ? 0.85 : 1
                    FocusRing { visible: connectionChip.visualFocus }
                }

                ConnectionsPanel {
                    id: connectionsPanel
                    objectName: "connectionsPanel"
                    x: connectionChip.width - width
                    y: connectionChip.height + 8
                    services: window.services
                    connections: window.connections
                    order: ["mainControl", "idsImage"]
                    udpOnlyServices: ["idsImage"] // 17 Nov: IDS Image is UDP only
                }
            }
            IdsButton {
                id: gimbalButton
                objectName: "gimbalButton"
                text: window.currentGimbal ? window.currentGimbal.name + " · " + window.settings.gimbalVersion
                                           : qsTr("Select gimbal")
                Accessible.name: qsTr("Gimbal: %1").arg(text)
                onClicked: gimbalDialog.open()
                contentItem: Row { // design: gimbal icon, small "GIMBAL" label, name · version, arrow
                    spacing: 8
                    Icon {
                        width: 15; height: 15
                        anchors.verticalCenter: parent.verticalCenter
                        path: Icons.gimbal
                        color: Theme.muted
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: qsTr("Gimbal")
                        font.family: Theme.fontSans
                        font.pixelSize: Theme.fsOverline
                        font.weight: Font.DemiBold
                        font.letterSpacing: Theme.overlineSpacing
                        font.capitalization: Font.AllUppercase
                        color: Theme.label
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: gimbalButton.text
                        font: gimbalButton.font
                        color: Theme.text
                    }
                    Icon {
                        width: 15; height: 15
                        anchors.verticalCenter: parent.verticalCenter
                        path: Icons.chevronDown
                        color: Theme.muted
                        strokeWidth: 2.2
                    }
                }
            }
        }

        statusBar: MainStatusBar {
            id: statusBar
            objectName: "statusBar"
            connection: window.activeConnection
            udpOnly: window.activeService === "idsImage" // 17 Nov: IDS Image is UDP only
            viewModel: window.mainControl
            notifications: window.notifications
            services: window.services
            connections: window.connections
            onConnectionSettingsRequested: window.openConnectionSettings()
        }

        StackLayout {
            anchors.fill: parent
            currentIndex: window.currentIndex
            Repeater {
                model: window.pages.length
                // Every page keeps the reference layout and has the same scale, so a card or button does not
                // change size between pages: laid out at least as tall as the tallest page and, when the area
                // is shorter, shrunk uniformly (never enlarged). The scale depends only on the height, so the
                // wider layout it causes cannot feed back into it.
                Item {
                    id: pageSlot
                    required property int index
                    readonly property real fit: height > 0 ? Math.min(1, height / window.designHeight) : 1

                    // Only the visible page is active (architecture §11): pages with `pageActive` stop their
                    // heavy work when hidden; data reception and connections are not affected.
                    Binding {
                        target: pageLoader.item
                        property: "pageActive"
                        value: window.activePageId === window.pages[pageSlot.index].id
                        when: pageLoader.item !== null && "pageActive" in pageLoader.item
                    }
                    Binding {
                        target: pageLoader.item
                        property: "gimbalModel"
                        value: window.currentGimbal ? window.currentGimbal.model : null
                        when: pageLoader.item !== null && "gimbalModel" in pageLoader.item
                    }

                    Loader {
                        id: pageLoader
                        objectName: "page-" + window.pages[pageSlot.index].id
                        width: pageSlot.width / pageSlot.fit
                        height: pageSlot.height / pageSlot.fit
                        scale: pageSlot.fit
                        transformOrigin: Item.TopLeft
                        sourceComponent: window.pages[pageSlot.index].component
                    }
                }
            }
        }
    }
}
