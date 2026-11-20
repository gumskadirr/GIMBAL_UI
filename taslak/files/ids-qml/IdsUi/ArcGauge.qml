import QtQuick
import QtQuick.Shapes
import IdsUi

// 270° yay gösterge (pan / tilt açısı). Ortasına çocuk öğe konabilir.
//   ArcGauge { width: 40; height: 40; from: -180; to: 180; value: 124.5 }
Item {
    id: root

    property real from: 0
    property real to: 1
    property real value: 0
    property real sweep: 270
    property real thickness: Math.max(3, Math.min(width, height) * 0.107)
    property color trackColor: Theme.track
    property color fillColor: Theme.gauge
    default property alias content: center.data

    readonly property real progress: to === from ? 0
                                   : Math.max(0, Math.min(1, (value - from) / (to - from)))
    readonly property real _r: (Math.min(width, height) - thickness) / 2

    implicitWidth: 40
    implicitHeight: 40
    Accessible.role: Accessible.Indicator
    Accessible.name: value.toString()

    Shape {
        anchors.fill: parent
        layer.enabled: true
        layer.samples: 4
        ShapePath {
            fillColor: "transparent"
            strokeColor: root.trackColor
            strokeWidth: root.thickness
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: root.width / 2; centerY: root.height / 2
                radiusX: root._r; radiusY: root._r
                startAngle: 90 + (360 - root.sweep) / 2
                sweepAngle: root.sweep
            }
        }
        ShapePath {
            fillColor: "transparent"
            strokeColor: root.progress > 0 ? root.fillColor : "transparent"
            strokeWidth: root.thickness
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: root.width / 2; centerY: root.height / 2
                radiusX: root._r; radiusY: root._r
                startAngle: 90 + (360 - root.sweep) / 2
                sweepAngle: root.sweep * root.progress
            }
        }
    }
    Item { id: center; anchors.fill: parent }
}
