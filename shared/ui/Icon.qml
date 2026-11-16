import QtQuick
import QtQuick.Shapes
import IDS_GIMBAL

// Stroke icon from SVG path data; the color follows the text color by default.
Item {
    id: root
    property string path: ""
    property color color: Theme.text
    property real strokeWidth: 2          // in the 24 px viewBox
    readonly property real _s: Math.min(width, height) / 24

    implicitWidth: 20
    implicitHeight: 20
    visible: path !== ""
    Accessible.ignored: true

    Shape {
        anchors.fill: parent
        // Antialiased on the GPU without a 4x multisampled layer per icon.
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            scale: Qt.size(root._s, root._s)
            strokeColor: root.color
            strokeWidth: root.strokeWidth * root._s
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathSvg { path: root.path }
        }
    }
}
