pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import IDS_GIMBAL

// Functional notification list; final visual design comes later.
Rectangle {
    id: area
    required property NotificationModel model

    color: Theme.surface
    border.color: Theme.border
    radius: Theme.radius

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacingNormal
        spacing: Theme.spacingNormal

        RowLayout {
            Layout.fillWidth: true
            Label {
                text: qsTr("Notifications")
                color: Theme.textPrimary
                font.pixelSize: Theme.fontSizeNormal
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
                color: Theme.background
                radius: Theme.radius
                border.color: row.severity === NotificationModel.Error ? Theme.error
                            : row.severity === NotificationModel.Warning ? Theme.warning
                            : Theme.border

                RowLayout {
                    id: content
                    anchors.fill: parent
                    anchors.margins: Theme.spacingNormal

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Label {
                            text: row.count > 1 ? row.text + "  ×" + row.count : row.text
                            color: Theme.textPrimary
                            wrapMode: Text.Wrap
                            Layout.fillWidth: true
                        }
                        Label {
                            text: row.detail
                            visible: row.detail.length > 0
                            color: Theme.textSecondary
                            font.pixelSize: Theme.fontSizeSmall
                            wrapMode: Text.Wrap
                            Layout.fillWidth: true
                        }
                        Label {
                            text: Qt.formatTime(row.timestamp, "HH:mm:ss")
                            color: Theme.textSecondary
                            font.pixelSize: Theme.fontSizeSmall
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
