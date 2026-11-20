pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Dialogs
import IDS_GIMBAL

// "Realtime graph and logger" window of the top bar. The design has no content for it, so: the scope chart with
// selectable series (the SeriesBuffer of the view model), manual CSV recording (the CsvRecorder of the Gimbal
// settings page) and the notification list. The chart draws only while the window is visible.
Window {
    id: root

    required property MainControlViewModel viewModel
    required property NotificationModel notifications

    readonly property alias chart: chart
    readonly property CsvRecorder recorder: viewModel.recorder
    property int view: 0 // Speed, Position, Torque: one unit per chart, the Y range is fixed per unit
    // Series per view; the colors alternate Pan / Tilt as on the Gimbal settings page. yMax as in T12 (shortcut there).
    readonly property var views: [
        { name: qsTr("Speed"), yMax: 10, series: [
            {index: SeriesBuffer.PanRate, name: "panRate", dashed: false, color: Theme.acc},
            {index: SeriesBuffer.PanRateRef, name: "panRateRef", dashed: true, color: Theme.acc},
            {index: SeriesBuffer.TiltRate, name: "tiltRate", dashed: false, color: Theme.series2},
            {index: SeriesBuffer.TiltRateRef, name: "tiltRateRef", dashed: true, color: Theme.series2}] },
        { name: qsTr("Position"), yMax: 180, series: [
            {index: SeriesBuffer.PanPosition, name: "panPos", dashed: false, color: Theme.acc},
            {index: SeriesBuffer.PanPositionRef, name: "panPosRef", dashed: true, color: Theme.acc},
            {index: SeriesBuffer.TiltPosition, name: "tiltPos", dashed: false, color: Theme.series2},
            {index: SeriesBuffer.TiltPositionRef, name: "tiltPosRef", dashed: true, color: Theme.series2}] },
        { name: qsTr("Torque"), yMax: 10, series: [
            {index: SeriesBuffer.PanTorque, name: "panIq", dashed: false, color: Theme.acc},
            {index: SeriesBuffer.TiltTorque, name: "tiltIq", dashed: false, color: Theme.series2}] }
    ]
    property var hidden: ({}) // series index -> true when switched off
    readonly property var shown: views[view].series.filter(s => !hidden[s.index])

    title: qsTr("Realtime graph and logger")
    width: 960
    height: 640
    minimumWidth: 640
    minimumHeight: 480
    color: Theme.bg

    function toggle(index: int, on: bool) {
        const next = Object.assign({}, hidden)
        next[index] = !on
        hidden = next
    }

    FileDialog {
        id: csvDialog
        title: qsTr("Record CSV")
        fileMode: FileDialog.SaveFile
        defaultSuffix: "csv"
        nameFilters: [qsTr("CSV file (*.csv)")]
        onAccepted: root.recorder.start(selectedFile)
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            SegmentedControl {
                objectName: "realtime-view"
                model: root.views.map(v => v.name)
                currentIndex: root.view
                Accessible.name: qsTr("Scope view")
                onActivated: index => root.view = index
            }
            Repeater {
                model: root.views[root.view].series
                delegate: IdsButton {
                    required property var modelData
                    objectName: "realtime-series-" + modelData.name
                    compact: true
                    checkable: true
                    checked: !root.hidden[modelData.index]
                    text: modelData.name
                    Accessible.name: modelData.name
                    onToggled: root.toggle(modelData.index, checked)
                }
            }
            Item { Layout.fillWidth: true }
        }

        LineChart {
            id: chart
            objectName: "chart-realtime"
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 160
            buffer: root.viewModel.scope
            series: root.shown
            yMax: root.views[root.view].yMax
            active: root.visible
            emptyText: qsTr("No stream data")
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            IdsButton {
                objectName: "realtime-record"
                iconPath: Icons.record
                busy: root.recorder.recording
                enabled: root.viewModel.connection.connected && !root.recorder.recording
                text: qsTr("Record CSV")
                onClicked: csvDialog.open()
            }
            IdsButton {
                objectName: "realtime-save"
                variant: "quiet"
                enabled: root.recorder.recording
                text: qsTr("Save CSV")
                onClicked: root.recorder.stop()
            }
            Text {
                objectName: "realtime-rows"
                visible: root.recorder.recording
                text: qsTr("%1 rows").arg(NumberFormat.fixed(root.recorder.rowCount, 0))
                font.family: Theme.fontMono
                font.pixelSize: Theme.fsSmall
                color: Theme.text2
            }
            Item { Layout.fillWidth: true }
        }

        NotificationArea {
            Layout.fillWidth: true
            Layout.preferredHeight: 180
            model: root.notifications
        }
    }
}
