import QtQuick
import QtQuick.Shapes
import IdsUi

// SVG path verisinden çizgi ikon. Renk varsayılan olarak metin rengini izler.
Item {
    id: root
    property string path: ""
    property color color: Theme.text
    property real strokeWidth: 2          // 24px viewBox içindeki kalınlık
    readonly property real _s: Math.min(width, height) / 24

    implicitWidth: 20
    implicitHeight: 20
    visible: path !== ""
    Accessible.ignored: true

    Shape {
        anchors.fill: parent
        layer.enabled: true
        layer.samples: 4
        layer.smooth: true
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
