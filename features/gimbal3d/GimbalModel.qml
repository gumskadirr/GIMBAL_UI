import QtQuick
import QtQuick3D

// A pan-tilt gimbal in 3D (from the ZR10_3D sample): a fixed base, the pan part turning on the base and the tilt
// part carried by it. Each gimbal is one small file setting the meshes, axes and camera framing:
//   GimbalModel { baseMesh: "meshes/x_base.mesh"; panMesh: ...; tiltMesh: ...; tiltPosition: ...; tiltSign: -1 }
// pan and tilt are degrees from telemetry; GimbalView sets them. Scene unit: 1 mm, Y up.
Node {
    id: gimbal

    property real pan: 0
    property real tilt: 0

    property url baseMesh
    property url panMesh
    property vector3d panPosition: Qt.vector3d(0, 0, 0)   // relative to the base
    property vector3d panAxis: Qt.vector3d(0, 1, 0)
    property real panSign: 1                               // -1 when the device counts the other way
    property url tiltMesh
    property vector3d tiltPosition: Qt.vector3d(0, 0, 0)  // relative to the pan part
    property vector3d tiltAxis: Qt.vector3d(1, 0, 0)
    property real tiltSign: 1

    // Camera framing for GimbalView: the point it orbits and its distance.
    property vector3d viewCenter: Qt.vector3d(0, 0, 0)
    property real viewDistance: 230

    property alias panPart: panNode   // for tests
    property alias tiltPart: tiltNode

    Model {
        source: gimbal.baseMesh
        materials: PrincipledMaterial { baseColor: "#3a3a3d"; roughness: 0.6 }
    }
    Node {
        id: panNode
        position: gimbal.panPosition
        rotation: Quaternion.fromAxisAndAngle(gimbal.panAxis, gimbal.panSign * gimbal.pan)
        Model {
            source: gimbal.panMesh
            materials: PrincipledMaterial { baseColor: "#2b2b2e"; roughness: 0.45 }
        }
        Node {
            id: tiltNode
            position: gimbal.tiltPosition
            rotation: Quaternion.fromAxisAndAngle(gimbal.tiltAxis, gimbal.tiltSign * gimbal.tilt)
            Model {
                source: gimbal.tiltMesh
                materials: PrincipledMaterial { baseColor: "#1c1c1f"; roughness: 0.3 }
            }
        }
    }
}
