// Main.qml — ZR10 görüntüleme + test slider'ları
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick3D
import QtQuick3D.Helpers

Window {
    width: 1100
    height: 720
    visible: true
    color: "#1b1d21"
    title: "Gimbal 3D"

    View3D {
        id: view
        anchors.fill: parent
        environment: SceneEnvironment {
            backgroundMode: SceneEnvironment.Color
            clearColor: "#1b1d21"
            antialiasingMode: SceneEnvironment.MSAA
            antialiasingQuality: SceneEnvironment.High
        }

        // Kamera, gimbalin ortasına bakan bir yörünge noktasının içinde
        Node {
            id: orbitOrigin
            position: Qt.vector3d(0, -30, 0)
            eulerRotation: Qt.vector3d(-12, 25, 0)
            PerspectiveCamera {
                id: camera
                position: Qt.vector3d(0, 0, 230)
                clipNear: 1
                clipFar: 5000
            }
        }

        DirectionalLight { eulerRotation: Qt.vector3d(-40, 30, 0);   brightness: 1.6 }
        DirectionalLight { eulerRotation: Qt.vector3d(-10, 200, 0);  brightness: 0.7 }
        DirectionalLight { eulerRotation: Qt.vector3d(60, 0, 0);     brightness: 0.3 }

        GimbalZR10 {
            id: gimbal
            yaw: yawSlider.value
            pitch: pitchSlider.value
        }
    }

    OrbitCameraController {
        anchors.fill: parent
        origin: orbitOrigin
        camera: camera
    }

    // Sağ tık + sürükle: model üzerinde başlarsa yaw/pitch'i slider'lar üzerinden değiştirir
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        property point last
        onPressed: (mouse) => {
            mouse.accepted = view.pick(mouse.x, mouse.y).objectHit !== null
            last = Qt.point(mouse.x, mouse.y)
        }
        onPositionChanged: (mouse) => {
            yawSlider.value += (mouse.x - last.x) * 0.5
            pitchSlider.value -= (mouse.y - last.y) * 0.5
            last = Qt.point(mouse.x, mouse.y)
        }
    }

    Pane {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: 16
        opacity: 0.9
        GridLayout {
            columns: 3
            Label { text: "Yaw" }
            // Aralıkları kendi gimbalinin datasheet değerlerine göre ayarla
            Slider { id: yawSlider; from: -135; to: 135; value: 0; Layout.preferredWidth: 220 }
            Label { text: yawSlider.value.toFixed(1) + "°" }
            Label { text: "Pitch" }
            Slider { id: pitchSlider; from: -90; to: 25; value: 0; Layout.preferredWidth: 220 }
            Label { text: pitchSlider.value.toFixed(1) + "°" }
        }
    }
}
