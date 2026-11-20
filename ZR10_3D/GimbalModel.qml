// GimbalModel.qml
// Genel gimbal bileşeni: taban + en fazla 3 eksen (eksen1 → eksen2 → eksen3).
// 2 eksenli gimbalde eksen1 ve eksen2'yi kullan, eksen3'ü boş bırak.
import QtQuick
import QtQuick3D

Node {
    id: gimbal

    // ---- Taban (sabit kısım) ----
    property url baseMesh
    property Material baseMaterial: PrincipledMaterial { objectName: ""; baseColor: "#3a3a3d"; roughness: 0.6 }

    // ---- Eksen 1 (tabana bağlı motor) ----
    property url axis1Mesh
    property vector3d axis1Position: Qt.vector3d(0, 0, 0)    // tabana göre konum
    property vector3d axis1Direction: Qt.vector3d(0, 1, 0)   // dönme ekseni
    property real angle1: 0
    property real axis1Sign: 1                               // motor yönü ters ise -1
    property real axis1Offset: 0
    property real axis1Min: -360
    property real axis1Max: 360
    property Material axis1Material: PrincipledMaterial { objectName: ""; baseColor: "#2b2b2e"; roughness: 0.45 }

    // ---- Eksen 2 (eksen 1'in taşıdığı motor) — kullanılmıyorsa boş bırak ----
    property url axis2Mesh
    property vector3d axis2Position: Qt.vector3d(0, 0, 0)    // eksen 1'e göre konum
    property vector3d axis2Direction: Qt.vector3d(0, 0, 1)
    property real angle2: 0
    property real axis2Sign: 1
    property real axis2Offset: 0
    property real axis2Min: -360
    property real axis2Max: 360
    property Material axis2Material: PrincipledMaterial { objectName: ""; baseColor: "#2b2b2e"; roughness: 0.45 }

    // ---- Eksen 3 (en uçtaki, genelde kamera) ----
    property url axis3Mesh
    property vector3d axis3Position: Qt.vector3d(0, 0, 0)    // eksen 2'ye göre konum
    property vector3d axis3Direction: Qt.vector3d(1, 0, 0)
    property real angle3: 0
    property real axis3Sign: 1
    property real axis3Offset: 0
    property real axis3Min: -360
    property real axis3Max: 360
    property Material axis3Material: PrincipledMaterial { objectName: ""; baseColor: "#1c1c1f"; roughness: 0.3 }

    function _clamp(v, lo, hi) { return Math.max(lo, Math.min(hi, v)) }

    Model {
        source: gimbal.baseMesh
        pickable: true
        visible: gimbal.baseMesh != ""
        materials: [gimbal.baseMaterial]
    }

    Node {
        id: axis1Node
        position: gimbal.axis1Position
        rotation: Quaternion.fromAxisAndAngle(gimbal.axis1Direction,
                      gimbal.axis1Sign * gimbal._clamp(gimbal.angle1, gimbal.axis1Min, gimbal.axis1Max) + gimbal.axis1Offset)
        Model {
            source: gimbal.axis1Mesh
            pickable: true
            visible: gimbal.axis1Mesh != ""
            materials: [gimbal.axis1Material]
        }

        Node {
            id: axis2Node
            position: gimbal.axis2Position
            rotation: Quaternion.fromAxisAndAngle(gimbal.axis2Direction,
                          gimbal.axis2Sign * gimbal._clamp(gimbal.angle2, gimbal.axis2Min, gimbal.axis2Max) + gimbal.axis2Offset)
            Model {
                source: gimbal.axis2Mesh
                pickable: true
                visible: gimbal.axis2Mesh != ""
                materials: [gimbal.axis2Material]
            }

            Node {
                id: axis3Node
                position: gimbal.axis3Position
                rotation: Quaternion.fromAxisAndAngle(gimbal.axis3Direction,
                              gimbal.axis3Sign * gimbal._clamp(gimbal.angle3, gimbal.axis3Min, gimbal.axis3Max) + gimbal.axis3Offset)
                Model {
                    source: gimbal.axis3Mesh
                    pickable: true
                    visible: gimbal.axis3Mesh != ""
                    materials: [gimbal.axis3Material]
                }
            }
        }
    }

    Node {
        id: __materialLibrary__
    }
}
