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
    required property bool demoMode

    // Page registry (architecture §11): the only place a page is listed; menu and content are built from it.
    // Titles are bindings and follow language changes. The views use pages.length as their model, so a
    // language change does not recreate the pages.
    // Services (architecture §12): each has its own connection; pages of both may be open side by side.
    readonly property var services: ({ mainControl: qsTr("Main control service") })
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
        { id: "preferences", group: qsTr("Application"), title: qsTr("Preferences"), icon: Icons.gear,
          component: preferencesPage }
    ]
    property string currentPageId: ""
    readonly property int currentIndex: Math.max(0, pages.findIndex(page => page.id === window.currentPageId))
    readonly property string activePageId: pages[currentIndex].id

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
    // Architecture §12, rule 1: without saved settings the connection settings open at startup (real target).
    Component.onCompleted: {
        if (!window.demoMode && !window.mainControl.connection.configured)
            Qt.callLater(window.openConnectionSettings)
    }
    function openConnectionSettings() {
        connectionPopup.prepare(window.mainControl.connection.target(),
                                window.mainControl.connection.availableSerialPorts())
        connectionPopup.open()
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
        id: preferencesPage
        PreferencesPage {
            settings: window.settings
            localization: window.localization
        }
    }

    AppShell {
        anchors.fill: parent

        navigation: NavRail {
            id: navRail
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
        }

        topBar: TopBar {
            objectName: "topBar"
            readonly property var page: window.pages[window.currentIndex]
            crumbs: page.service ? [window.services[page.service], page.title] : [page.title]
            Badge {
                visible: window.demoMode
                kind: "warn"
                text: qsTr("Sample data")
            }
            StatusLabel {
                objectName: "connectionStatus"
                framed: true
                status: window.mainControl.connection.hasError ? "crit"
                      : window.mainControl.connection.connected ? "ok"
                      : window.mainControl.connection.busy ? "warn"
                      : "idle"
                text: window.mainControl.connection.statusText
            }
        }

        statusBar: StatusBar {
            StatusBarSection {
                Layout.fillWidth: true
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 24

                    // Newest notification (row 0) in one line; the model stays the single source.
                    ListView {
                        id: latestNotification
                        objectName: "latestNotification"
                        anchors.fill: parent
                        model: window.notifications
                        interactive: false
                        clip: true
                        delegate: RowLayout {
                            id: latestRow
                            required property string text
                            required property int severity
                            required property int count
                            width: ListView.view.width
                            height: 24
                            spacing: Theme.spacingNormal
                            Badge {
                                kind: latestRow.severity === NotificationModel.Error ? "crit"
                                    : latestRow.severity === NotificationModel.Warning ? "warn"
                                    : "info"
                                text: latestRow.severity === NotificationModel.Error ? qsTr("Error")
                                    : latestRow.severity === NotificationModel.Warning ? qsTr("Warning")
                                    : qsTr("Info")
                            }
                            Text {
                                Layout.fillWidth: true
                                text: latestRow.count > 1 ? latestRow.text + "  ×" + latestRow.count : latestRow.text
                                elide: Text.ElideRight
                                font.family: Theme.fontSans
                                font.pixelSize: Theme.fsSmall
                                color: Theme.text2
                            }
                        }
                    }
                    Text {
                        visible: latestNotification.count === 0
                        anchors.fill: parent
                        verticalAlignment: Text.AlignVCenter
                        text: qsTr("No notifications")
                        font.family: Theme.fontSans
                        font.pixelSize: Theme.fsSmall
                        color: Theme.label
                    }
                }
            }
            StatusBarSection {
                StatusBarButton {
                    id: notificationsButton
                    objectName: "notificationsButton"
                    text: qsTr("Notifications (%1)").arg(latestNotification.count)
                    trailingIconPath: Icons.chevronUp
                    expanded: notificationsPopup.opened
                    onClicked: notificationsPopup.opened ? notificationsPopup.close() : notificationsPopup.open()

                    IdsPopup {
                        id: notificationsPopup
                        objectName: "notificationsPopup"
                        x: notificationsButton.width - width
                        y: -height - 14
                        width: 400
                        NotificationArea {
                            model: window.notifications
                            color: "transparent"
                            border.width: 0
                            Layout.fillWidth: true
                            Layout.preferredHeight: 400
                        }
                    }
                }
            }
            StatusBarSection {
                StatusBarButton {
                    id: connectionButton
                    objectName: "connectionButton"
                    text: window.mainControl.connection.summary
                    trailingIconPath: Icons.chevronUp
                    expanded: connectionPopup.opened
                    onClicked: connectionPopup.opened ? connectionPopup.close() : window.openConnectionSettings()

                    ConnectionPopup {
                        id: connectionPopup
                        objectName: "connectionPopup"
                        x: connectionButton.width - width
                        y: -height - 14
                        width: 400
                        connected: window.mainControl.connection.connected
                        canDisconnect: window.mainControl.connection.connected || window.mainControl.connection.busy
                        onApplyRequested: settings => window.mainControl.connection.apply(settings)
                        onDisconnectRequested: window.mainControl.connection.disconnectDevice()
                    }
                }
            }
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
