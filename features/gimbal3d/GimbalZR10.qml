import QtQuick
import QtQuick3D

// SIYI ZR10 (meshes from its SolidWorks assembly, unchanged): base = plates, controller, dampers; pan = the
// motor part; tilt = the camera, lens towards +Z.
// shortcut: tilt down is negative as in the sample (tiltSign -1); flip the sign if the device reports the other way.
GimbalModel {
    baseMesh: "meshes/zr10_base.mesh"
    panMesh: "meshes/zr10_yaw.mesh"
    tiltMesh: "meshes/zr10_pitch.mesh"
    tiltPosition: Qt.vector3d(-4.1, -53.1, 13.94)
    tiltSign: -1
    viewCenter: Qt.vector3d(0, -30, 0)
    viewDistance: 230
}
