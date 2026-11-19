pragma ComponentBehavior: Bound
import QtQuick
import QtQuick3D
import QtQuick3D.Helpers
import IDS_GIMBAL
import "framing.js" as Framing

// 3D view of a gimbal on a transparent background, put inside a VideoViewport. model: the GimbalLibrary model
// object (GimbalModel.spec) or null. Display only: dragging turns the camera, never the gimbal. The camera frames
// the model from its bounds. pan / tilt in degrees; with valid false the model keeps its last angles and
// "No telemetry" shows. Nothing is built where Qt Quick 3D cannot draw (software
// renderer, offscreen tests): `shown` is false and the owner shows its placeholder.
Item {
    id: root

    property var model: null
    property real pan: 0
    property real tilt: 0
    property bool valid: true
    property bool interactive: true // orbit, zoom and Reset view

    readonly property bool available: GraphicsInfo.api !== GraphicsInfo.Software && GraphicsInfo.api !== GraphicsInfo.OpenVG
    readonly property bool shown: !!model && available
    readonly property string loadError: gimbal ? gimbal.errorString : ""
    property GimbalModel gimbal: null // set by the 3D view; for tests
    signal resetView()

    Loader {
        id: viewLoader
        anchors.fill: parent
        // Built only while visible: a View3D created hidden draws the model wrongly once shown, and a hidden page
        // should not render anyway. The framing cache makes the rebuild instant.
        active: root.shown && root.visible
        sourceComponent: View3D {
            id: view
            readonly property GimbalModel gimbal: modelLoader.item as GimbalModel
            readonly property vector3d startRotation: Qt.vector3d(-12, 25, 0)
            property vector3d center: Qt.vector3d(0, 0, 0)
            property real distance: 1
            property string framedFor: ""

            property int polls: 0

            // Frames the camera once per model, when all three parts are measured (bounds come after the first
            // render, part by part, without a reliable change signal: polled until then). Another view's framing
            // of the same model is reused; after 2 s the measured parts are enough.
            function frame() {
                const key = JSON.stringify(root.model)
                const bounds = gimbal ? gimbal.measuredBounds(++polls > 20) : null
                if (bounds)
                    Framing.cache[key] = { center: bounds.minimum.plus(bounds.maximum).times(0.5),
                                           distance: bounds.maximum.minus(bounds.minimum).length() * 1.1 } // fits 60°
                const framing = Framing.cache[key]
                if (!framing)
                    return
                framedFor = key
                polls = 0
                center = framing.center
                distance = framing.distance
                root.resetView()
            }
            Timer {
                interval: 100
                repeat: true
                running: view.gimbal !== null && view.framedFor !== JSON.stringify(root.model)
                onTriggered: view.frame()
            }

            Binding { target: root; property: "gimbal"; value: view.gimbal }
            Connections {
                target: root
                function onResetView() {
                    orbitOrigin.eulerRotation = view.startRotation
                    orbitCamera.position = Qt.vector3d(0, 0, view.distance)
                }
            }

            environment: SceneEnvironment {
                backgroundMode: SceneEnvironment.Transparent
                antialiasingMode: SceneEnvironment.MSAA
                antialiasingQuality: SceneEnvironment.Medium
            }

            Node {
                id: orbitOrigin
                position: view.center
                eulerRotation: view.startRotation
                PerspectiveCamera {
                    id: orbitCamera
                    z: view.distance
                    clipNear: view.distance / 100
                    clipFar: view.distance * 20
                }
            }
            DirectionalLight { eulerRotation: Qt.vector3d(-40, 30, 0); brightness: 1.6 }
            DirectionalLight { eulerRotation: Qt.vector3d(-10, 200, 0); brightness: 0.7 }
            DirectionalLight { eulerRotation: Qt.vector3d(60, 0, 0); brightness: 0.3 }

            Loader3D {
                id: modelLoader
                sourceComponent: GimbalModel { spec: root.model }
            }
            Binding { target: view.gimbal; property: "pan"; value: root.pan; when: view.gimbal !== null }
            Binding { target: view.gimbal; property: "tilt"; value: root.tilt; when: view.gimbal !== null }

            OrbitCameraController {
                anchors.fill: parent
                enabled: root.interactive
                origin: orbitOrigin
                camera: orbitCamera
                panEnabled: false
            }
        }
    }

    Text {
        objectName: "loadError"
        anchors.centerIn: parent
        width: Math.min(parent.width - 48, 320)
        visible: root.loadError !== ""
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        text: qsTr("The 3D model could not be loaded.") + "
" + root.loadError
        font.family: Theme.fontSans
        font.pixelSize: Theme.fsSmall
        color: "#FFFFFF"
    }
    OverlayTag {
        objectName: "noTelemetry"
        x: 12
        y: 12
        visible: root.shown && !root.valid
        text: qsTr("No telemetry")
    }
    Loader { // only with a 3D view: a hidden button would still count as a control of the page
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 12
        active: root.shown && root.interactive
        sourceComponent: IdsButton {
            objectName: "resetView"
            compact: true
            iconPath: Icons.resetView
            text: qsTr("Reset view")
            onClicked: root.resetView()
        }
    }
}
