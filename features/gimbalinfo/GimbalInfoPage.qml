pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import IDS_GIMBAL

// Gimbal info page of the final design. So far only the summary strip; display only, no commands.
// No "NORMAL" badges: temperature and voltage limits are not known yet and are not invented.
Item {
    id: page
    required property DeviceViewModel viewModel

    function degrees(m: measurement): string {
        return m.valid ? m.value.toFixed(3) + "°" : "—"
    }
    function radians(m: measurement): string {
        return m.valid ? (m.value * Math.PI / 180).toFixed(4) + " rad" : ""
    }
    function reference(m: measurement): string {
        return m.valid ? qsTr("REF %1 · %2").arg(page.degrees(m)).arg(page.radians(m)) : ""
    }
    function celsius(m: measurement): string {
        return m.valid ? m.value.toFixed(1) + " °C" : "—"
    }

    ColumnLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: 14

        StatStrip {
            Layout.fillWidth: true

            StatCell {
                objectName: "cell-safeControl"
                label: qsTr("Safe control")
                value: !page.viewModel.safeControl.valid ? "—"
                     : page.viewModel.safeControl.value ? qsTr("Locked") : qsTr("Unlocked")
                valueStatus: !page.viewModel.safeControl.valid ? ""
                           : page.viewModel.safeControl.value ? "warn" : "idle"
            }
            StatCell {
                objectName: "cell-temperature"
                label: qsTr("Gimbal / IMU temp.")
                value: page.celsius(page.viewModel.gimbalTemp)
                secondary: page.viewModel.imuTemp.valid ? qsTr("IMU %1").arg(page.celsius(page.viewModel.imuTemp)) : ""
            }
            StatCell {
                objectName: "cell-supply"
                label: qsTr("Supply voltage")
                value: page.viewModel.supplyVoltage.valid ? page.viewModel.supplyVoltage.value.toFixed(1) + " V" : "—"
            }
            StatCell {
                objectName: "cell-pan"
                label: qsTr("Pan angle")
                value: page.degrees(page.viewModel.pan)
                monoValue: true
                secondary: page.radians(page.viewModel.pan)
                note: page.reference(page.viewModel.panRef)
                leading: ArcGauge {
                    from: -180
                    to: 180
                    value: page.viewModel.pan.value
                    fillColor: page.viewModel.pan.valid ? Theme.gauge : "transparent"
                }
            }
            StatCell {
                objectName: "cell-tilt"
                label: qsTr("Tilt angle")
                value: page.degrees(page.viewModel.tilt)
                monoValue: true
                secondary: page.radians(page.viewModel.tilt)
                note: page.reference(page.viewModel.tiltRef)
                leading: ArcGauge {
                    from: -90
                    to: 90
                    value: page.viewModel.tilt.value
                    fillColor: page.viewModel.tilt.valid ? Theme.gauge : "transparent"
                }
            }
        }
    }
}
