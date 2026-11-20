// GimbalZR10.qml — SIYI ZR10 ayarları
// Parçalar SolidWorks montajındaki haliyle, değiştirilmeden kullanıldı:
//   zr10_base  : plakalar, kontrolcü, sönümleyiciler, vidalar (sabit)
//   zr10_yaw   : "gimbal motors" parçası (tek parça)
//   zr10_pitch : "camera" parçası
// Sahne birimi: 1 birim = 1 mm. Y yukarı, kamera lensi +Z yönüne bakıyor.
import QtQuick
import QtQuick3D

GimbalModel {
    id: zr10

    property alias yaw: zr10.angle1
    property alias pitch: zr10.angle2

    baseMesh: "meshes/zr10_base.mesh"

    // Yaw: üstteki motorun ekseni (Y) etrafında
    axis1Mesh: "meshes/zr10_yaw.mesh"
    axis1Position: Qt.vector3d(0, 0, 0)
    axis1Direction: Qt.vector3d(0, 1, 0)

    // Pitch: kameranın yan göbeklerinden geçen yatay eksen (X)
    // axis2Sign: -1 ile pitch'te aşağı = negatif (ör. -90 = tam aşağı).
    // Gimbalinden gelen işaret tersse axis2Sign: 1 yap.
    axis2Mesh: "meshes/zr10_pitch.mesh"
    axis2Position: Qt.vector3d(-4.1, -53.1, 13.94)
    axis2Direction: Qt.vector3d(1, 0, 0)
    axis2Sign: -1
    axis2Material: PrincipledMaterial { baseColor: "#1c1c1f"; roughness: 0.3 }

    // Üçüncü eksen kullanılmıyor
}
