import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import IDS_GIMBAL

// Infrastructure validation page, not the final telemetry screen.
Item {
    id: page
    required property DeviceViewModel viewModel
    property bool pageActive: false
    property string sampleAge: ""

    ColumnLayout {
        anchors.left: parent.left
        anchors.top: parent.top
        spacing: Theme.spacingNormal

        Label {
            text: qsTr("Connection: %1").arg(page.viewModel.connectionText)
            color: page.viewModel.hasError ? Theme.error
                 : page.viewModel.connected ? Theme.accent
                 : Theme.textPrimary
            font.pixelSize: Theme.fontSizeLarge
        }
        Label {
            visible: page.viewModel.errorDetail.length > 0
            text: page.viewModel.errorDetail
            color: Theme.textSecondary
        }
        Label {
            text: qsTr("Angle: %1").arg(page.viewModel.angleValid
                                        ? page.viewModel.angleDeg.toFixed(2) + " °" : "—")
            color: Theme.textPrimary
        }
        Label {
            text: qsTr("Temperature: %1").arg(page.viewModel.temperatureValid
                                              ? page.viewModel.temperatureC.toFixed(2) + " °C" : "—")
            color: Theme.textPrimary
        }
        Label {
            text: page.sampleAge
            color: Theme.textSecondary
        }

        RowLayout {
            spacing: Theme.spacingNormal
            AppButton {
                text: qsTr("Connect")
                enabled: !page.viewModel.connected && !page.viewModel.busy
                onClicked: page.viewModel.connectDevice()
            }
            AppButton {
                text: qsTr("Disconnect")
                enabled: page.viewModel.connected || page.viewModel.busy
                onClicked: page.viewModel.disconnectDevice()
            }
        }
    }

    // Page-owned activity: runs only while the page is shown; the device session is unaffected.
    Timer {
        interval: 200
        repeat: true
        triggeredOnStart: true
        running: page.pageActive
        onTriggered: {
            const ms = page.viewModel.msSinceLastSample()
            page.sampleAge = ms < 0 ? qsTr("No recent sample") : qsTr("Last sample: %1 ms ago").arg(ms)
        }
    }
}
