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
    required property DeviceViewModel deviceViewModel
    required property bool demoMode

    // Page registry (architecture §11): the only place a page is listed; menu and content are built from it.
    // Titles are bindings and follow language changes. The views use pages.length as their model, so a
    // language change does not recreate the pages.
    readonly property var pages: [
        { id: "diagnostics", group: qsTr("Developer"), title: qsTr("Diagnostics"), icon: Icons.bug,
          component: diagnosticsPage, demoOnly: true },
        { id: "preferences", group: qsTr("Application"), title: qsTr("Preferences"), icon: Icons.sliders,
          component: preferencesPage }
    ].filter(page => window.demoMode || !page.demoOnly)
    property string currentPageId: ""
    readonly property int currentIndex: Math.max(0, pages.findIndex(page => page.id === window.currentPageId))
    readonly property string activePageId: pages[currentIndex].id

    width: 1280
    height: 800
    minimumWidth: 800
    minimumHeight: 560
    visible: true
    title: qsTr("IDS Gimbal")
    color: Theme.bg

    Binding {
        target: Theme
        property: "mode"
        value: window.settings.theme
    }

    Component {
        id: diagnosticsPage
        DiagnosticsPage {
            viewModel: window.deviceViewModel
            pageActive: window.activePageId === "diagnostics"
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
                connected: window.deviceViewModel.connected
                connectionLabel: window.deviceViewModel.connectionText
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
            crumbs: [qsTr("Main control service"), window.pages[window.currentIndex].title]
            Badge {
                visible: window.demoMode
                kind: "warn"
                text: qsTr("Sample data")
            }
            StatusLabel {
                objectName: "connectionStatus"
                framed: true
                status: window.deviceViewModel.hasError ? "crit"
                      : window.deviceViewModel.connected ? "ok"
                      : window.deviceViewModel.busy ? "warn"
                      : "idle"
                text: window.deviceViewModel.connectionText
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
        }

        StackLayout {
            anchors.fill: parent
            currentIndex: window.currentIndex
            Repeater {
                model: window.pages.length
                Loader {
                    required property int index
                    objectName: "page-" + window.pages[index].id
                    sourceComponent: window.pages[index].component
                }
            }
        }
    }
}
