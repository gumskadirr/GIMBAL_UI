pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
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
        // outgrows it. Used by the page host below to scale the page to fit.
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
        { id: "preferences", group: qsTr("Application"), title: qsTr("Preferences"), icon: Icons.gear,
          component: preferencesPage }
    ]
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
    function openSettingsIfNotConfigured() {
        if (!window.demoMode && !window.activeConnection.configured)
            Qt.callLater(window.openConnectionSettings)
    }
    Component.onCompleted: openSettingsIfNotConfigured()
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
        id: preferencesPage
        PreferencesPage {
            settings: window.settings
            localization: window.localization
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
            StatusLabel {
                objectName: "connectionStatus"
                framed: true
                status: window.activeConnection.hasError ? "crit"
                      : window.activeConnection.connected ? "ok"
                      : window.activeConnection.busy ? "warn"
                      : "idle"
                text: window.activeConnection.statusText
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
                // A page with designHeight keeps the reference layout: it is laid out at least that tall and,
                // when the area is shorter, shrunk uniformly (never enlarged). The scale depends only on the
                // height, so the wider layout it causes cannot feed back into it.
                Item {
                    id: pageSlot
                    required property int index
                    readonly property real designHeight: window.pages[index].designHeight ?? 0
                    readonly property real fit: designHeight > 0 && height > 0 ? Math.min(1, height / designHeight) : 1

                    // Only the visible page is active (architecture §11): pages with `pageActive` stop their
                    // heavy work when hidden; data reception and connections are not affected.
                    Binding {
                        target: pageLoader.item
                        property: "pageActive"
                        value: window.activePageId === window.pages[pageSlot.index].id
                        when: pageLoader.item !== null && "pageActive" in pageLoader.item
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
