pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import IDS_GIMBAL

// Functional notification list; final visual design comes later.
Rectangle {
    id: area
    required property NotificationModel model

    color: Theme.card
    border.color: Theme.line2
    radius: Theme.rSmall

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacingNormal
        spacing: Theme.spacingNormal

        RowLayout {
            Layout.fillWidth: true
            Label {
                text: qsTr("Notifications")
                color: Theme.text
                font.pixelSize: Theme.fsBody
                Layout.fillWidth: true
            }
            AppButton {
                text: qsTr("Clear")
                enabled: list.count > 0
                onClicked: area.model.clear()
            }
        }

        ListView {
            id: list
            model: area.model
            clip: true
            spacing: Theme.spacingSmall
            Layout.fillWidth: true
            Layout.fillHeight: true

            delegate: Rectangle {
                id: row
                required property int index
                required property string text
                required property string detail
                required property int severity
                required property date timestamp
                required property int count

                width: ListView.view.width
                implicitHeight: content.implicitHeight + 2 * Theme.spacingNormal
                color: Theme.bg
                radius: Theme.rSmall
                border.color: row.severity === NotificationModel.Error ? Theme.critTx
                            : row.severity === NotificationModel.Warning ? Theme.warnTx
                            : Theme.line2

                RowLayout {
                    id: content
                    anchors.fill: parent
                    anchors.margins: Theme.spacingNormal

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Label {
                            text: row.count > 1 ? row.text + "  ×" + row.count : row.text
                            color: Theme.text
                            wrapMode: Text.Wrap
                            Layout.fillWidth: true
                        }
                        Label {
                            text: row.detail
                            visible: row.detail.length > 0
                            color: Theme.muted
                            font.pixelSize: Theme.fsSmall
                            wrapMode: Text.Wrap
                            Layout.fillWidth: true
                        }
                        Label {
                            text: Qt.formatTime(row.timestamp, "HH:mm:ss")
                            color: Theme.muted
                            font.pixelSize: Theme.fsSmall
                        }
                    }
                    AppButton {
                        text: "×"
                        Accessible.name: qsTr("Dismiss")
                        implicitWidth: Theme.controlHeight
                        leftPadding: 0
                        rightPadding: 0
                        onClicked: area.model.dismiss(row.index)
                    }
                }
            }
        }
    }
}
