pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import IDS_GIMBAL

// Status bar of every screen (final design): TX / RX / HEARTBEAT, data rate, ON TIME | BIT badge, last BIT message
// and time | running operation and progress | connection button | notifications and Debug settings.
// The connection button and the operation belong to `connection`, the service of the visible page.
StatusBar {
    id: root

    required property ServiceConnection connection
    required property MainControlViewModel viewModel
    required property NotificationModel notifications
    required property var services    // key -> display name
    required property var connections // key -> ServiceConnection

    property bool udpOnly: false // the visible service offers IP/UDP only
    signal connectionSettingsRequested() // the owner fills the popup (ConnectionPopup.prepare) and opens it

    readonly property alias connectionPopup: connectionPopup
    readonly property var bit: viewModel.bitReport
    // BitItem.Pass 0, Warning 1, Fail 2; -1 without a report.
    readonly property int bitWorst: bit.valid ? bit.items.reduce((worst, item) => Math.max(worst, item.status), 0) : -1
    readonly property var bitCause: bitWorst > 0 ? bit.items.find(item => item.status === bitWorst) : null
    // A long command of the service, else the script of the Main control service.
    readonly property bool scriptShown: viewModel.script.running && connection === viewModel.connection
    readonly property bool operationShown: connection.progressKind >= 0 || scriptShown
    readonly property int operationPercent: connection.progressKind >= 0 ? connection.progressPercent : viewModel.script.percent

    function operationName(kind: int): string {
        switch (kind) {
        case Command.UpdateFirmware: return qsTr("Updating firmware")
        case Command.StartElectricalAngleCalibration: return qsTr("Calibrating angle")
        case Command.StartCrosstalkCheck: return qsTr("Checking crosstalk")
        case Command.StartImuBiasCalibration: return qsTr("Calibrating IMU")
        default: return qsTr("Working")
        }
    }
    function onTimeText(m: measurement): string {
        if (!m.valid)
            return "—"
        const minutes = Math.floor(m.value / 60)
        return qsTr("%1 h %2 min").arg(Math.floor(minutes / 60)).arg(minutes % 60)
    }

    component Caption: Text {
        font.family: Theme.fontSans
        font.pixelSize: Theme.fsOverline
        font.weight: Font.DemiBold
        font.letterSpacing: 0.66
        font.capitalization: Font.AllUppercase
        color: Theme.label
    }
    component Value: Text {
        font.family: Theme.fontMono
        font.pixelSize: Theme.fsSmall
        color: Theme.text2
    }

    StatusBarSection {
        spacing: 14
        Led { objectName: "txLed"; kind: "tx"; text: "TX"; active: root.connection.txActive }
        Led { objectName: "rxLed"; kind: "rx"; text: "RX"; active: root.connection.rxActive }
        Value {
            objectName: "dataRate"
            text: root.connection.connected ? qsTr("%1 Mbps").arg(NumberFormat.fixed(root.connection.dataRateBps / 1e6, 2)) : "—"
        }
        Led { objectName: "heartbeatLed"; kind: "heartbeat"; text: qsTr("Heartbeat"); active: root.viewModel.heartbeat }
        Caption { text: qsTr("On time") }
        Value { objectName: "onTime"; text: root.onTimeText(root.viewModel.onTime) }
    }

    StatusBarSection {
        objectName: "bitSection"
        Layout.fillWidth: true
        Layout.minimumWidth: 0
        spacing: 10
        Caption { text: "BIT" }
        Badge {
            objectName: "bitBadge"
            visible: root.bit.valid
            kind: root.bitWorst === 2 ? "crit" : root.bitWorst === 1 ? "warn" : "ok"
            text: root.bitWorst === 2 ? qsTr("Fail") : root.bitWorst === 1 ? qsTr("Warning") : qsTr("Pass")
        }
        Text {
            objectName: "bitMessage"
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            text: !root.bit.valid ? "—"
                : root.bitCause ? root.bitCause.name + ": " + root.bitCause.description
                : qsTr("All items passed")
            elide: Text.ElideRight
            font.family: Theme.fontSans
            font.pixelSize: Theme.fsSmall
            color: Theme.text2
        }
        Value { visible: root.bit.valid; text: root.bit.lastRun.split(" ")[0]; color: Theme.muted }
    }

    // Keeps its width when nothing runs, so the bar does not jump.
    StatusBarSection {
        objectName: "operationSection"
        Layout.preferredWidth: 270
        Layout.maximumWidth: 270
        spacing: 10
        Text {
            objectName: "operationName"
            visible: root.operationShown
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            text: root.scriptShown && root.connection.progressKind < 0 ? qsTr("Running script")
                                                                       : root.operationName(root.connection.progressKind)
            elide: Text.ElideRight
            font.family: Theme.fontSans
            font.pixelSize: Theme.fsSmall
            color: Theme.muted
        }
        IdsProgressBar {
            visible: root.operationShown
            implicitWidth: 60
            from: 0
            to: 100
            value: root.operationPercent
            Accessible.name: qsTr("Operation progress")
        }
        Value {
            objectName: "operationPercent"
            visible: root.operationShown
            Layout.minimumWidth: 34
            horizontalAlignment: Text.AlignRight
            text: NumberFormat.fixed(root.operationPercent, 0) + "%"
        }
        Item { visible: !root.operationShown; Layout.fillWidth: true }
    }

    StatusBarSection {
        StatusBarButton {
            id: connectionButton
            objectName: "connectionButton"
            text: root.connection.summary
            trailingIconPath: Icons.chevronUp
            expanded: connectionPopup.opened
            onClicked: connectionPopup.opened ? connectionPopup.close() : root.connectionSettingsRequested()

            ConnectionPopup {
                id: connectionPopup
                objectName: "connectionPopup"
                x: connectionButton.width - width
                y: -height - 14
                width: 400
                udpOnly: root.udpOnly
                connected: root.connection.connected
                canDisconnect: root.connection.connected || root.connection.busy
                onApplyRequested: settings => root.connection.apply(settings)
                onDisconnectRequested: root.connection.disconnectDevice()
            }
        }
    }

    StatusBarSection {
        spacing: 8
        StatusBarButton {
            id: notificationsButton
            objectName: "notificationsButton"
            iconOnly: true
            iconPath: Icons.bell
            expanded: notificationsPopup.opened
            Accessible.name: qsTr("Notifications (%1)").arg(root.notifications.total)
            onClicked: notificationsPopup.opened ? notificationsPopup.close() : notificationsPopup.open()

            Rectangle {
                objectName: "notificationsBadge"
                visible: root.notifications.total > 0
                x: parent.width - width * 0.6
                y: -height * 0.4
                width: Math.max(16, badgeText.implicitWidth + 8)
                height: 16
                radius: 8
                color: Theme.critTx
                Text {
                    id: badgeText
                    anchors.centerIn: parent
                    text: root.notifications.total
                    font.family: Theme.fontSans
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                    color: Theme.card
                }
            }
            IdsPopup {
                id: notificationsPopup
                objectName: "notificationsPopup"
                x: notificationsButton.width + 8 + debugButton.width - width
                y: -height - 14
                width: 400
                NotificationArea {
                    model: root.notifications
                    color: "transparent"
                    border.width: 0
                    Layout.fillWidth: true
                    Layout.preferredHeight: 400
                }
            }
        }
        StatusBarButton {
            id: debugButton
            objectName: "debugButton"
            iconOnly: true
            iconPath: Icons.bug
            expanded: debugPopup.opened
            Accessible.name: qsTr("Debug settings")
            onClicked: debugPopup.opened ? debugPopup.close() : debugPopup.open()

            IdsPopup {
                id: debugPopup
                objectName: "debugPopup"
                property real sampleAgeMs: -1

                x: debugButton.width - width
                y: -height - 14
                width: 400
                title: qsTr("Debug settings")
                onOpened: ageTimer.triggered()

                Timer {
                    id: ageTimer
                    interval: 500
                    repeat: true
                    running: debugPopup.opened
                    onTriggered: debugPopup.sampleAgeMs = root.viewModel.msSinceLastSample()
                }

                Repeater {
                    model: Object.keys(root.services)
                    ColumnLayout {
                        id: serviceRows
                        required property string modelData
                        readonly property ServiceConnection link: root.connections[modelData]
                        Layout.fillWidth: true
                        spacing: 0
                        InfoRow {
                            Layout.fillWidth: true
                            label: root.services[serviceRows.modelData]
                            showDivider: !serviceRows.link.hasError
                            StatusLabel {
                                objectName: "debugStatus-" + serviceRows.modelData
                                status: serviceRows.link.hasError ? "crit" : serviceRows.link.connected ? "ok"
                                      : serviceRows.link.busy ? "warn" : "idle"
                                text: serviceRows.link.statusText
                                fontSize: Theme.fsSmall
                            }
                        }
                        InfoRow {
                            Layout.fillWidth: true
                            visible: serviceRows.link.hasError
                            label: qsTr("Error detail")
                            value: serviceRows.link.errorDetail
                            mono: false
                        }
                    }
                }
                InfoRow {
                    objectName: "debugSampleAge"
                    Layout.fillWidth: true
                    label: qsTr("Last sample age")
                    value: debugPopup.sampleAgeMs < 0 ? "—" : qsTr("%1 ms").arg(NumberFormat.fixed(debugPopup.sampleAgeMs, 0))
                }
                InfoRow {
                    objectName: "debugStale"
                    Layout.fillWidth: true
                    label: qsTr("Stale results dropped")
                    value: NumberFormat.fixed(root.connection.staleDropped, 0)
                }
                InfoRow {
                    objectName: "debugPending"
                    Layout.fillWidth: true
                    label: qsTr("Pending commands")
                    value: root.connection.pendingCommandNames.length > 0 ? root.connection.pendingCommandNames.join(", ") : "—"
                }
                InfoRow {
                    objectName: "debugTraffic"
                    Layout.fillWidth: true
                    showDivider: false
                    label: "TX / RX"
                    value: qsTr("%1 B / %2 B").arg(NumberFormat.fixed(root.connection.txBytes, 0)).arg(NumberFormat.fixed(root.connection.rxBytes, 0))
                }
            }
        }
    }
}
