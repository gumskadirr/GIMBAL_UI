pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Dialogs
import QtQuick.Templates as T
import IDS_GIMBAL

// Adds or edits a gimbal of the library: name, versions and an optional 3D model (three .glb files and their
// axes). The preview on the right shows the model as entered; its sliders turn the preview only. Save writes
// through GimbalLibrary.save() and stays open with the error when it fails; Cancel / Esc change nothing.
IdsPopup {
    id: dialog

    required property GimbalLibrary library
    property var gimbal: null           // the entry being edited, null for a new gimbal
    property var files: ({})            // newly chosen files: { base, pan, tilt } URLs
    property string error: ""
    readonly property var parts: [{ key: "base", label: qsTr("Base") }, { key: "pan", label: qsTr("Pan part") },
                                  { key: "tilt", label: qsTr("Tilt part") }]
    readonly property var axes: ["x", "y", "z"]
    signal saved(string id)

    function openFor(entry: var) {
        gimbal = entry
        const model = entry ? entry.model : null
        nameField.text = entry ? entry.name : ""
        versionsField.text = entry ? entry.versions.join(", ") : "v1.0"
        modelSwitch.checked = !!model || !entry
        files = ({})
        panAxis.currentIndex = axes.indexOf(model ? model.panAxis : "y")
        panSign.currentIndex = model && model.panSign < 0 ? 1 : 0
        tiltAxis.currentIndex = axes.indexOf(model ? model.tiltAxis : "x")
        tiltSign.currentIndex = model && model.tiltSign < 0 ? 1 : 0
        const pivot = (field, values) => field.forEach((f, i) => f.text = NumberFormat.fixed(values ? values[i] : 0, 2))
        pivot([panPivotRow.fieldX, panPivotRow.fieldY, panPivotRow.fieldZ], model ? model.panPivot : null)
        pivot([tiltPivotRow.fieldX, tiltPivotRow.fieldY, tiltPivotRow.fieldZ], model ? model.tiltPivot : null)
        inPlaceSwitch.checked = model ? model.inPlace : true
        previewPan.value = 0
        previewTilt.value = 0
        error = ""
        open()
    }
    function fileOf(part: string): string { // chosen or stored file URL, "" when none
        return files[part] ?? (gimbal && gimbal.model ? gimbal.model[part] : "")
    }
    function numbers(fields: var): var {
        return fields.map(f => NumberFormat.parse(f.text))
    }
    readonly property var pivotsValid: [panPivotRow.fieldX, panPivotRow.fieldY, panPivotRow.fieldZ, tiltPivotRow.fieldX, tiltPivotRow.fieldY, tiltPivotRow.fieldZ].every(f => !isNaN(NumberFormat.parse(f.text)))
    // The model as entered, for the preview and for save(); null without a model.
    readonly property var model: {
        if (!modelSwitch.checked)
            return null
        return {
            base: fileOf("base"), pan: fileOf("pan"), tilt: fileOf("tilt"),
            panAxis: axes[panAxis.currentIndex], panSign: panSign.currentIndex === 1 ? -1 : 1,
            panPivot: numbers([panPivotRow.fieldX, panPivotRow.fieldY, panPivotRow.fieldZ]).map(v => isNaN(v) ? 0 : v),
            tiltAxis: axes[tiltAxis.currentIndex], tiltSign: tiltSign.currentIndex === 1 ? -1 : 1,
            tiltPivot: numbers([tiltPivotRow.fieldX, tiltPivotRow.fieldY, tiltPivotRow.fieldZ]).map(v => isNaN(v) ? 0 : v),
            inPlace: inPlaceSwitch.checked
        }
    }
    readonly property bool previewReady: model !== null && parts.every(p => fileOf(p.key) !== "")

    function save() {
        if (modelSwitch.checked && !pivotsValid) {
            error = qsTr("Enter the axis positions as numbers.")
            return
        }
        const versions = versionsField.text.split(",").map(v => v.trim()).filter(v => v !== "")
        const result = library.save({ id: gimbal ? gimbal.id : "", name: nameField.text, versions: versions, model: model },
                                    files)
        if (result !== "") {
            error = result
            return
        }
        const saved = library.gimbals.find(g => g.name === nameField.text.trim())
        close()
        dialog.saved(saved ? saved.id : "")
    }

    parent: T.Overlay.overlay
    anchors.centerIn: parent
    modal: true
    width: Math.min(parent ? parent.width - 64 : 960, 960)
    padding: 28
    onOpened: nameField.forceActiveFocus()

    component PivotRow: RowLayout {
        property alias label: rowLabel.text
        property alias fieldX: xField
        property alias fieldY: yField
        property alias fieldZ: zField
        spacing: 8
        Text {
            id: rowLabel
            Layout.preferredWidth: 80
            font.family: Theme.fontSans
            font.pixelSize: Theme.fsBody
            color: Theme.text2
        }
        IdsTextField { id: xField; Layout.fillWidth: true; suffix: "x"; Accessible.name: rowLabel.text + " x" }
        IdsTextField { id: yField; Layout.fillWidth: true; suffix: "y"; Accessible.name: rowLabel.text + " y" }
        IdsTextField { id: zField; Layout.fillWidth: true; suffix: "z"; Accessible.name: rowLabel.text + " z" }
    }

    FileDialog {
        id: fileDialog
        property string part: ""
        title: qsTr("Choose a 3D model file")
        nameFilters: [qsTr("3D models (*.glb)")]
        onAccepted: {
            const chosen = Object.assign({}, dialog.files)
            chosen[part] = selectedFile.toString()
            dialog.files = chosen
        }
    }

    Text {
        Layout.fillWidth: true
        text: dialog.gimbal ? qsTr("Edit %1").arg(dialog.gimbal.name) : qsTr("New gimbal")
        font.family: Theme.fontSans
        font.pixelSize: 24
        font.weight: Font.Bold
        color: Theme.text
        Accessible.role: Accessible.Heading
        Accessible.name: text
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 24

        ColumnLayout { // form
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            Layout.alignment: Qt.AlignTop
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                FormField {
                    Layout.fillWidth: true
                    label: qsTr("Name")
                    IdsTextField { id: nameField; objectName: "edit-name"; mono: false; Accessible.name: qsTr("Name") }
                }
                FormField {
                    Layout.fillWidth: true
                    label: qsTr("Versions, comma separated")
                    IdsTextField {
                        id: versionsField
                        objectName: "edit-versions"
                        placeholderText: "v1.0, v2.0"
                        Accessible.name: qsTr("Versions")
                    }
                }
            }

            ToggleRow { id: modelSwitch; objectName: "edit-hasModel"; Layout.fillWidth: true; text: qsTr("3D model") }

            ColumnLayout {
                Layout.fillWidth: true
                visible: modelSwitch.checked
                spacing: 12

                Repeater {
                    model: dialog.parts
                    RowLayout {
                        id: fileRow
                        required property var modelData
                        readonly property string chosen: dialog.files[modelData.key] ?? ""
                        Layout.fillWidth: true
                        spacing: 10
                        Text {
                            Layout.preferredWidth: 80
                            text: fileRow.modelData.label
                            font.family: Theme.fontSans
                            font.pixelSize: Theme.fsBody
                            color: Theme.text2
                        }
                        Text {
                            objectName: "edit-fileName-" + fileRow.modelData.key
                            Layout.fillWidth: true
                            elide: Text.ElideMiddle
                            text: fileRow.chosen !== "" ? decodeURIComponent(fileRow.chosen.split("/").pop())
                                : dialog.fileOf(fileRow.modelData.key) !== "" ? qsTr("Current file")
                                : qsTr("No file")
                            font.family: Theme.fontMono
                            font.pixelSize: Theme.fsSmall
                            color: dialog.fileOf(fileRow.modelData.key) !== "" ? Theme.text : Theme.muted
                        }
                        IdsButton {
                            objectName: "edit-file-" + fileRow.modelData.key
                            compact: true
                            text: qsTr("Choose…")
                            Accessible.name: qsTr("Choose %1 file").arg(fileRow.modelData.label)
                            onClicked: {
                                fileDialog.part = fileRow.modelData.key
                                fileDialog.open()
                            }
                        }
                    }
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 3
                    columnSpacing: 10
                    rowSpacing: 10
                    FormField {
                        label: qsTr("Pan axis")
                        SegmentedControl { id: panAxis; objectName: "edit-panAxis"; model: ["X", "Y", "Z"] }
                    }
                    FormField {
                        label: qsTr("Pan direction")
                        SegmentedControl { id: panSign; model: ["+", "−"] }
                    }
                    Item { Layout.fillWidth: true }
                    FormField {
                        label: qsTr("Tilt axis")
                        SegmentedControl { id: tiltAxis; objectName: "edit-tiltAxis"; model: ["X", "Y", "Z"] }
                    }
                    FormField {
                        label: qsTr("Tilt direction")
                        SegmentedControl { id: tiltSign; objectName: "edit-tiltSign"; model: ["+", "−"] }
                    }
                }

                PivotRow { id: panPivotRow; Layout.fillWidth: true; label: qsTr("Pan centre") }
                PivotRow { id: tiltPivotRow; objectName: "edit-tiltPivot"; Layout.fillWidth: true; label: qsTr("Tilt centre") }
                ToggleRow {
                    id: inPlaceSwitch
                    objectName: "edit-inPlace"
                    Layout.fillWidth: true
                    text: qsTr("Parts exported in their assembly position")
                }
                Text {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    text: inPlaceSwitch.checked
                          ? qsTr("Centres are points of the assembly, in the unit of the files.")
                          : qsTr("Each file is centred on its axis: the pan centre is relative to the base, the tilt centre to the pan part.")
                    font.family: Theme.fontSans
                    font.pixelSize: Theme.fsSmall
                    color: Theme.muted
                }
            }
        }

        ColumnLayout { // preview
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            Layout.alignment: Qt.AlignTop
            spacing: 10
            VideoViewport {
                Layout.fillWidth: true
                Layout.preferredHeight: 300
                placeholderIcon: preview.shown ? "" : Icons.cube
                placeholderTitle: preview.shown ? "" : qsTr("Preview")
                placeholderText: !modelSwitch.checked ? qsTr("No 3D model")
                               : !dialog.previewReady ? qsTr("Choose the three files to see the model")
                               : qsTr("The 3D view needs a 3D graphics driver")
                GimbalView {
                    id: preview
                    objectName: "editPreview"
                    anchors.fill: parent
                    model: dialog.previewReady ? dialog.model : null
                    pan: previewPan.value
                    tilt: previewTilt.value
                }
            }
            RowLayout {
                Layout.fillWidth: true
                visible: dialog.previewReady
                Text { text: qsTr("Pan"); Layout.preferredWidth: 40; color: Theme.text2; font.family: Theme.fontSans; font.pixelSize: Theme.fsSmall }
                IdsSlider { id: previewPan; Layout.fillWidth: true; from: -180; to: 180; Accessible.name: qsTr("Preview pan") }
                Text { text: NumberFormat.fixed(previewPan.value, 0) + "°"; Layout.preferredWidth: 44; color: Theme.text2; font.family: Theme.fontMono; font.pixelSize: Theme.fsSmall }
            }
            RowLayout {
                Layout.fillWidth: true
                visible: dialog.previewReady
                Text { text: qsTr("Tilt"); Layout.preferredWidth: 40; color: Theme.text2; font.family: Theme.fontSans; font.pixelSize: Theme.fsSmall }
                IdsSlider { id: previewTilt; Layout.fillWidth: true; from: -90; to: 90; Accessible.name: qsTr("Preview tilt") }
                Text { text: NumberFormat.fixed(previewTilt.value, 0) + "°"; Layout.preferredWidth: 44; color: Theme.text2; font.family: Theme.fontMono; font.pixelSize: Theme.fsSmall }
            }
            Text {
                Layout.fillWidth: true
                visible: dialog.previewReady
                wrapMode: Text.WordWrap
                text: qsTr("The sliders turn the preview only.")
                font.family: Theme.fontSans
                font.pixelSize: Theme.fsSmall
                color: Theme.muted
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 1
        color: Theme.line
    }
    RowLayout {
        Layout.fillWidth: true
        spacing: 12
        Text {
            objectName: "edit-error"
            Layout.fillWidth: true
            text: dialog.error
            wrapMode: Text.WordWrap
            font.family: Theme.fontSans
            font.pixelSize: Theme.fsBody
            color: Theme.critTx
        }
        IdsButton {
            objectName: "edit-cancel"
            variant: "quiet"
            text: qsTr("Cancel")
            onClicked: dialog.close()
        }
        IdsButton {
            objectName: "edit-save"
            variant: "primary"
            text: qsTr("Save")
            onClicked: dialog.save()
        }
    }
}
