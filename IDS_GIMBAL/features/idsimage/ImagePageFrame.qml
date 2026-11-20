pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import IDS_GIMBAL

// Common frame of the IDS Image service pages (final design): video source row and video on the left, the
// STATUS / MODE row and the page's own cards on the right:
//   ImagePageFrame { viewModel: ...; settings: ...; Card {...} }
// Video decoding is deferred: Open only tells so. The RTSP address is an application setting.
Item {
    id: page
    required property ImageViewModel viewModel
    required property AppSettings settings
    // Set by Main.qml: true only while the page is visible (architecture §11; video will stop when false).
    property bool pageActive: false
    default property alias content: pageContent.data

    readonly property imageSample sample: viewModel.sample
    property bool openPressed: false

    function number(m: measurement, decimals: int): string {
        return m.valid ? NumberFormat.fixed(m.value, decimals) : "—"
    }
    function open() {
        page.settings.rtspUrl = urlField.text
        page.openPressed = true
    }

    Flickable {
        id: scroller
        objectName: "pageScroller"
        anchors.fill: parent
        contentWidth: width
        contentHeight: Math.max(height, content.implicitHeight)
        boundsBehavior: Flickable.StopAtBounds
        clip: true
        ScrollBar.vertical: ScrollBar {}

        RowLayout {
            id: content
            width: scroller.width
            height: scroller.contentHeight
            spacing: 12

            Card {
                Layout.fillWidth: true
                Layout.fillHeight: true
                compact: true
                fillContent: true

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    IdsComboBox {
                        objectName: "videoSource"
                        Layout.preferredWidth: 110
                        compact: true
                        model: ["RTSP"] // the only source until video decoding exists
                        Accessible.name: qsTr("Video source")
                    }
                    IdsTextField {
                        id: urlField
                        objectName: "rtspUrl"
                        Layout.fillWidth: true
                        implicitWidth: 60
                        compact: true
                        placeholderText: "rtsp://"
                        Accessible.name: qsTr("RTSP address")
                        onAccepted: page.open()
                        onEditingFinished: page.settings.rtspUrl = text
                        Binding on text { value: page.settings.rtspUrl; when: !urlField.activeFocus }
                    }
                    IdsButton {
                        objectName: "openVideo"
                        compact: true
                        text: qsTr("Open")
                        onClicked: page.open()
                    }
                }
                VideoViewport {
                    objectName: "video"
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    showCrosshair: true
                    placeholderTitle: page.openPressed ? qsTr("Video is not available in this version") : ""

                    OverlayTag {
                        objectName: "tagAttitude"
                        x: 12; y: 12
                        mono: true
                        text: qsTr("PAN %1  TILT %2").arg(page.number(page.sample.panDeg, 1)).arg(page.number(page.sample.tiltDeg, 1))
                    }
                    OverlayTag {
                        objectName: "tagStream"
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        y: 12
                        mono: true
                        text: qsTr("%1 FPS · x%2").arg(page.number(page.sample.fps, 0)).arg(page.number(page.sample.zoom, 1))
                    }
                }
            }

            ColumnLayout {
                Layout.fillHeight: true
                // Fixed side column as in the design (about a quarter of 1536 px); the video takes the rest.
                Layout.preferredWidth: 360
                Layout.maximumWidth: 360
                spacing: 8

                CardBackground {
                    Layout.fillWidth: true
                    implicitHeight: 40
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        spacing: 8
                        Text {
                            text: qsTr("STATUS")
                            font.family: Theme.fontSans
                            font.pixelSize: Theme.fsOverline
                            font.weight: Font.DemiBold
                            font.letterSpacing: Theme.overlineSpacing
                            color: Theme.label
                        }
                        StatusLabel {
                            objectName: "statusValue"
                            status: !page.sample.status.valid ? "idle" : page.sample.status.value === "OK" ? "ok" : "warn"
                            text: page.sample.status.valid ? page.sample.status.value : "—"
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: qsTr("MODE")
                            font.family: Theme.fontSans
                            font.pixelSize: Theme.fsOverline
                            font.weight: Font.DemiBold
                            font.letterSpacing: Theme.overlineSpacing
                            color: Theme.label
                        }
                        StatusLabel {
                            objectName: "modeValue"
                            status: page.sample.mode.valid ? "ok" : "idle"
                            text: page.sample.mode.valid ? page.sample.mode.value : "—"
                        }
                    }
                }
                ColumnLayout {
                    id: pageContent
                    objectName: "imageCards"
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 8
                }
            }
        }
    }
}
