import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T
import IDS_GIMBAL

// Card with a title; content is laid out in a vertical ColumnLayout.
//   Card { title: "MCU"; subtitle: "Microcontroller details"
//          actions: [ IdsButton { text: "Run BIT"; compact: true } ]
//          InfoRow { label: "Device ID"; value: "0x0451" } }
// flush: true gives a body without padding and a line under the header (3D view / video card).
// Content is top-aligned; set fillContent: true when it should fill the height.
T.Control {
    id: root

    property string title: ""
    property string subtitle: ""
    property bool compact: false
    property bool flush: false
    // true: spare height goes to the content (a child with Layout.fillHeight: true, e.g. VideoViewport)
    property bool fillContent: flush
    default property alias content: body.data
    property alias actions: actionsRow.data

    implicitWidth: Math.max(implicitBackgroundWidth, implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight, implicitContentHeight + topPadding + bottomPadding)
    padding: flush ? 0 : (compact ? 16 : 20)
    spacing: compact ? 12 : 14

    property bool _moving: false
    function _keepSpacerLast() {
        if (_moving) return
        if (body.children.length && body.children[body.children.length - 1] !== spacer) {
            _moving = true
            spacer.parent = null
            spacer.parent = body
            _moving = false
        }
    }
    Component.onCompleted: _keepSpacerLast()

    background: CardBackground {}

    contentItem: ColumnLayout {
        spacing: root.flush ? 0 : root.spacing

        Item {
            id: header
            visible: root.title !== "" || actionsRow.children.length > 0
            Layout.fillWidth: true
            implicitHeight: headerRow.implicitHeight + (root.flush ? 28 : 0)

            RowLayout {
                id: headerRow
                anchors.fill: parent
                anchors.leftMargin: root.flush ? 16 : 0
                anchors.rightMargin: root.flush ? 16 : 0
                anchors.topMargin: root.flush ? 14 : 0
                anchors.bottomMargin: root.flush ? 14 : 0
                spacing: 12

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                    spacing: 2
                    Text {
                        Layout.fillWidth: true
                        text: root.title
                        visible: text !== ""
                        elide: Text.ElideRight
                        font.family: Theme.fontSans
                        font.pixelSize: Theme.fsTitle
                        font.weight: Font.DemiBold
                        color: Theme.text
                        Accessible.role: Accessible.Heading
                        Accessible.name: text
                    }
                    Text {
                        Layout.fillWidth: true
                        text: root.subtitle
                        visible: text !== ""
                        wrapMode: Text.WordWrap
                        font.family: Theme.fontSans
                        font.pixelSize: Theme.fsSmall
                        color: Theme.muted
                    }
                }
                RowLayout {
                    id: actionsRow
                    Layout.alignment: root.flush ? Qt.AlignVCenter : Qt.AlignTop
                    spacing: 8
                }
            }
            Rectangle {
                visible: root.flush
                anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
                height: 1
                color: Theme.line
            }
        }

        ColumnLayout {
            id: body
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: root.spacing
            onChildrenChanged: root._keepSpacerLast()

            // Takes the spare height so the content stays top-aligned.
            Item {
                id: spacer
                Layout.fillHeight: true
                Layout.fillWidth: true
                implicitHeight: 0
                visible: !root.fillContent
            }
        }
    }
}
