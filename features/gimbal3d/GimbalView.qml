pragma ComponentBehavior: Bound
import QtQuick
import QtQuick3D
import QtQuick3D.Helpers
import IDS_GIMBAL

// 3D view of a gimbal (GimbalModel component) on a transparent background, put inside a VideoViewport.
// Display only: dragging turns the camera, never the gimbal. pan / tilt in degrees; with valid false the model
// keeps its last angles and "No telemetry" shows. Nothing is built where Qt Quick 3D cannot draw (software
// renderer, offscreen tests): `shown` is false and the owner shows its placeholder.
Item {
    id: root

    property Component model: null
    property real pan: 0
    property real tilt: 0
    property bool valid: true
    property bool interactive: true // orbit, zoom and Reset view

    readonly property bool available: GraphicsInfo.api !== GraphicsInfo.Software && GraphicsInfo.api !== GraphicsInfo.OpenVG
    readonly property bool shown: model !== null && available
    property GimbalModel gimbal: null // set by the 3D view; for tests
    signal resetView()

    Loader {
        id: viewLoader
        anchors.fill: parent
        active: root.shown
        sourceComponent: View3D {
            id: view
            readonly property GimbalModel gimbal: modelLoader.item as GimbalModel
            readonly property vector3d startRotation: Qt.vector3d(-12, 25, 0)

            Binding { target: root; property: "gimbal"; value: view.gimbal }
            Connections {
                target: root
                function onResetView() {
                    orbitOrigin.eulerRotation = view.startRotation
                    orbitCamera.position = Qt.vector3d(0, 0, view.gimbal ? view.gimbal.viewDistance : 230)
                }
            }

            environment: SceneEnvironment {
                backgroundMode: SceneEnvironment.Transparent
                antialiasingMode: SceneEnvironment.MSAA
                antialiasingQuality: SceneEnvironment.Medium
            }

            Node {
                id: orbitOrigin
                position: view.gimbal ? view.gimbal.viewCenter : Qt.vector3d(0, 0, 0)
                eulerRotation: view.startRotation
                PerspectiveCamera {
                    id: orbitCamera
                    z: view.gimbal ? view.gimbal.viewDistance : 230
                    clipNear: 1
                    clipFar: 5000
                }
            }
            DirectionalLight { eulerRotation: Qt.vector3d(-40, 30, 0); brightness: 1.6 }
            DirectionalLight { eulerRotation: Qt.vector3d(-10, 200, 0); brightness: 0.7 }
            DirectionalLight { eulerRotation: Qt.vector3d(60, 0, 0); brightness: 0.3 }

            Loader3D {
                id: modelLoader
                sourceComponent: root.model
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
