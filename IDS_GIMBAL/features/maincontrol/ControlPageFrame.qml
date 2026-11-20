pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import IDS_GIMBAL

// Common frame of the Main control service pages (final design): summary strip on top, the 3D gimbal card on
// the left and the page's own content in the right column:
//   ControlPageFrame { viewModel: ...; Card {...} }
// Display only. No "NORMAL" badges: temperature and voltage limits are not known yet and are not invented.
Item {
    id: page
    required property MainControlViewModel viewModel
    // Set by Main.qml: true only while the page is visible. Rule for every page: timers, charts, video and other
    // heavy redraws stop while it is false; data reception and connections continue (architecture §11).
    property bool pageActive: false
    property var gimbalModel: null // 3D model of the selected gimbal (GimbalLibrary, set by Main.qml) or null
    default property alias content: pageContent.data

    function degrees(m: measurement): string {
        return m.valid ? NumberFormat.fixed(m.value, 3) + "°" : "—"
    }
    function radians(m: measurement): string {
        return m.valid ? NumberFormat.fixed(m.value * Math.PI / 180, 4) + " rad" : ""
    }
    function reference(m: measurement): string {
        return m.valid ? qsTr("REF %1 · %2").arg(page.degrees(m)).arg(page.radians(m)) : ""
    }
    function celsius(m: measurement): string {
        return m.valid ? NumberFormat.fixed(m.value, 1) + " °C" : "—"
    }

    // Scrolls when the window is shorter than the content; otherwise the 3D area takes the spare height.
    Flickable {
        id: scroller
        objectName: "pageScroller"
        anchors.fill: parent
        contentWidth: width
        contentHeight: Math.max(height, content.implicitHeight)
        boundsBehavior: Flickable.StopAtBounds
        clip: true
        ScrollBar.vertical: ScrollBar {}

        ColumnLayout {
            id: content
            width: scroller.width
            height: scroller.contentHeight
            spacing: 10

            StatStrip {
                Layout.fillWidth: true

                StatCell {
                    objectName: "cell-safeControl"
                    share: 2
                    label: qsTr("Safe control")
                    value: !page.viewModel.safeControl.valid ? "—"
                         : page.viewModel.safeControl.value ? qsTr("Locked") : qsTr("Unlocked")
                    valueStatus: !page.viewModel.safeControl.valid ? ""
                               : page.viewModel.safeControl.value ? "warn" : "idle"
                }
                StatCell {
                    objectName: "cell-temperature"
                    share: 3
                    label: qsTr("Gimbal / IMU temp.")
                    value: page.celsius(page.viewModel.gimbalTemp)
                    secondary: page.viewModel.imuTemp.valid ? qsTr("IMU %1").arg(page.celsius(page.viewModel.imuTemp)) : ""
                }
                StatCell {
                    objectName: "cell-supply"
                    share: 2
                    label: qsTr("Supply voltage")
                    value: page.viewModel.supplyVoltage.valid ? NumberFormat.fixed(page.viewModel.supplyVoltage.value, 1) + " V" : "—"
                }
                StatCell {
                    objectName: "cell-pan"
                    share: 4
                    valueSample: NumberFormat.fixed(-180, 3) + "°" // the widest angle
                    label: qsTr("Pan angle")
                    value: page.degrees(page.viewModel.pan)
                    monoValue: true
                    secondary: page.radians(page.viewModel.pan)
                    note: page.reference(page.viewModel.panRef)
                    leading: ArcGauge {
                        from: -180
                        to: 180
                        value: page.viewModel.pan.value
                        valid: page.viewModel.pan.valid
                    }
                }
                StatCell {
                    objectName: "cell-tilt"
                    share: 4
                    valueSample: NumberFormat.fixed(-180, 3) + "°" // the widest angle
                    label: qsTr("Tilt angle")
                    value: page.degrees(page.viewModel.tilt)
                    monoValue: true
                    secondary: page.radians(page.viewModel.tilt)
                    note: page.reference(page.viewModel.tiltRef)
                    leading: ArcGauge {
                        from: -90
                        to: 90
                        value: page.viewModel.tilt.value
                        valid: page.viewModel.tilt.valid
                    }
                }
            }
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 12

                Card {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredWidth: 1
                    flush: true
                    title: qsTr("Gimbal")
                    subtitle: qsTr("3D model, follows live pan and tilt")

                    VideoViewport {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        topRadius: 0
                        bottomRadius: Theme.rCard - 1
                        placeholderIcon: gimbalView.shown ? "" : Icons.cube
                        placeholderTitle: gimbalView.shown ? "" : qsTr("3D gimbal model")
                        placeholderText: !page.gimbalModel ? qsTr("No 3D model for this gimbal yet")
                                                                   : qsTr("The 3D view needs a 3D graphics driver")

                        GimbalView {
                            id: gimbalView
                            objectName: "gimbalView"
                            anchors.fill: parent
                            model: page.gimbalModel
                            pan: page.viewModel.pan.value
                            tilt: page.viewModel.tilt.value
                            valid: page.viewModel.pan.valid && page.viewModel.tilt.valid
                        }
                    }
                }

                ColumnLayout {
                    id: pageContent
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredWidth: 2
                    spacing: 8
                }
            }
        }
    }
}
