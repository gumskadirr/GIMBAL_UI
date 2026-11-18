pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import IDS_GIMBAL

// Time chart of a SeriesBuffer: legend (solid = measurement, dashed = reference), a fixed Y axis from +yMax to
// -yMax with a grid, and one line per series. The newest sample is at the right edge, the window is the buffer's.
// The lines are re-read from the buffer at 30 Hz, only while `active`; the data keeps arriving regardless.
//   LineChart { buffer: vm.scope; active: pageActive; yMax: 10
//               series: [{index: SeriesBuffer.PanRate, name: "panRate", dashed: false, color: "#3B3FB0"}] }
Item {
    id: root

    property SeriesBuffer buffer
    property var series: []    // [{index, name, dashed, color}]
    property real yMax: 10
    property bool active: false
    property int version: 0    // counts the redraws; stays put while inactive
    property bool hasData: false
    property var linePaths: [] // per series: list of pixel polylines
    property string emptyText: ""

    implicitHeight: 160

    function refresh() {
        if (!buffer)
            return
        const w = plot.width, h = plot.height
        let any = false
        const all = []
        for (let i = 0; i < root.series.length; ++i) {
            const out = []
            for (const segment of buffer.points(root.series[i].index, Math.max(2, Math.round(w)))) {
                const pts = []
                for (const p of segment)
                    pts.push(Qt.point((1 + p.x / buffer.windowSeconds) * w, h / 2 * (1 - p.y / root.yMax)))
                out.push(pts)
                any = true
            }
            all.push(out)
        }
        linePaths = all
        hasData = any
        version++
    }

    onActiveChanged: if (active) refresh()
    onSeriesChanged: if (active) Qt.callLater(refresh)
    onYMaxChanged: if (active) Qt.callLater(refresh)

    Timer {
        interval: 33
        repeat: true
        running: root.active
        onTriggered: root.refresh()
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        RowLayout {
            spacing: 16
            Repeater {
                model: root.series
                delegate: RowLayout {
                    id: entry
                    required property var modelData
                    spacing: 6
                    Shape {
                        implicitWidth: 22
                        implicitHeight: 10
                        ShapePath {
                            strokeColor: entry.modelData.color
                            strokeWidth: 2
                            fillColor: "transparent"
                            strokeStyle: entry.modelData.dashed ? ShapePath.DashLine : ShapePath.SolidLine
                            dashPattern: [4, 3]
                            startX: 0; startY: 5
                            PathLine { x: 22; y: 5 }
                        }
                    }
                    Text {
                        text: entry.modelData.name
                        font.family: Theme.fontSans
                        font.pixelSize: Theme.fsSmall
                        color: Theme.text2
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 6

            Item { // Y axis values
                Layout.preferredWidth: 30
                Layout.fillHeight: true
                Repeater {
                    model: 5
                    delegate: Text {
                        required property int index
                        readonly property real tick: root.yMax * (1 - index / 2)
                        anchors.right: parent.right
                        y: index * (parent.height - height) / 4
                        text: NumberFormat.fixed(tick, 0)
                        font.family: Theme.fontMono
                        font.pixelSize: Theme.fsOverline
                        color: Theme.muted
                    }
                }
            }

            Rectangle {
                id: plot
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Theme.rSmall
                color: Theme.input
                border.width: 1
                border.color: Theme.line
                clip: true
                onWidthChanged: if (root.active) Qt.callLater(root.refresh)
                onHeightChanged: if (root.active) Qt.callLater(root.refresh)

                Repeater { // horizontal grid
                    model: 3
                    delegate: Rectangle {
                        required property int index
                        width: plot.width; height: 1
                        y: (index + 1) * plot.height / 4
                        color: Theme.line
                    }
                }
                Repeater { // vertical grid
                    model: 3
                    delegate: Rectangle {
                        required property int index
                        height: plot.height; width: 1
                        x: (index + 1) * plot.width / 4
                        color: Theme.line
                    }
                }

                Repeater {
                    model: root.series
                    delegate: Shape {
                        id: line
                        required property var modelData
                        required property int index
                        property var paths: root.linePaths[index] || []
                        anchors.fill: parent
                        ShapePath {
                            strokeColor: line.modelData.color
                            strokeWidth: 2
                            fillColor: "transparent"
                            strokeStyle: line.modelData.dashed ? ShapePath.DashLine : ShapePath.SolidLine
                            dashPattern: [4, 3]
                            joinStyle: ShapePath.RoundJoin
                            PathMultiline { paths: line.paths }
                        }
                    }
                }

                Text {
                    objectName: "value-scopeEmpty"
                    anchors.centerIn: parent
                    visible: !root.hasData
                    text: root.emptyText
                    font.family: Theme.fontSans
                    font.pixelSize: Theme.fsBody
                    color: Theme.muted
                }
            }
        }
    }
}
