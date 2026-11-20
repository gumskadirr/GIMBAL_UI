import QtQuick
import QtQuick3D
import QtQuick3D.AssetUtils

// A pan-tilt gimbal in 3D from three .glb files (GimbalLibrary model): a fixed base, the pan part turning on the
// base and the tilt part carried by it. pan / tilt in degrees; GimbalView sets them.
// spec: { base, pan, tilt (URLs), panAxis "x|y|z", panSign, panPivot [x,y,z], tiltAxis, tiltSign, tiltPivot, inPlace }
// inPlace false: each part file is centred on its own axis; panPivot is relative to the base, tiltPivot to the pan
// part (the ZR10 files). inPlace true: all parts were exported in their assembly position and both pivots are
// assembly points; each part is shifted back by its pivot so it turns about it.
Node {
    id: gimbal

    required property var spec
    property real pan: 0
    property real tilt: 0

    readonly property vector3d panPivot: vec(spec.panPivot)
    readonly property vector3d tiltPivot: vec(spec.tiltPivot)
    readonly property vector3d panOffset: spec.inPlace ? panPivot.times(-1) : Qt.vector3d(0, 0, 0)
    readonly property vector3d tiltPosition: spec.inPlace ? tiltPivot.minus(panPivot) : tiltPivot
    readonly property vector3d tiltOffset: spec.inPlace ? tiltPivot.times(-1) : Qt.vector3d(0, 0, 0)

    readonly property bool loaded: [baseLoader, panLoader, tiltLoader].every(l => l.status === RuntimeLoader.Success)
    readonly property string errorString: [baseLoader, panLoader, tiltLoader]
        .filter(l => l.status === RuntimeLoader.Error).map(l => l.errorString).join("\n")
    property alias panPart: panNode // for tests
    property alias tiltPart: tiltNode
    property alias panLoader: panLoader
    property alias tiltLoader: tiltLoader

    function vec(a: var): vector3d {
        return a && a.length === 3 ? Qt.vector3d(a[0], a[1], a[2]) : Qt.vector3d(0, 0, 0)
    }
    function axis(name: string): vector3d {
        return name === "x" ? Qt.vector3d(1, 0, 0) : name === "z" ? Qt.vector3d(0, 0, 1) : Qt.vector3d(0, 1, 0)
    }
    // Extent of the gimbal at 0° (rotation ignored) for framing the camera, or null until all three parts are
    // loaded and measured (partial: the measured ones, null if none). A function, not a binding:
    // RuntimeLoader.bounds arrives after the first render and does not notify every change.
    function measuredBounds(partial: bool): var {
        const parts = [[baseLoader, Qt.vector3d(0, 0, 0)],
                       [panLoader, panPivot.plus(panOffset)],
                       [tiltLoader, panPivot.plus(tiltPosition).plus(tiltOffset)]]
        let min = null, max = null
        for (const [loader, shift] of parts) {
            const b = loader.bounds
            if (loader.status !== RuntimeLoader.Success || b.maximum.minus(b.minimum).length() <= 0) {
                if (partial)
                    continue
                return null
            }
            const lo = b.minimum.plus(shift), hi = b.maximum.plus(shift)
            min = min ? Qt.vector3d(Math.min(min.x, lo.x), Math.min(min.y, lo.y), Math.min(min.z, lo.z)) : lo
            max = max ? Qt.vector3d(Math.max(max.x, hi.x), Math.max(max.y, hi.y), Math.max(max.z, hi.z)) : hi
        }
        return min ? { minimum: min, maximum: max } : null
    }

    RuntimeLoader {
        id: baseLoader
        source: gimbal.spec.base
    }
    Node {
        id: panNode
        position: gimbal.panPivot
        rotation: Quaternion.fromAxisAndAngle(gimbal.axis(gimbal.spec.panAxis), gimbal.spec.panSign * gimbal.pan)
        RuntimeLoader {
            id: panLoader
            position: gimbal.panOffset
            source: gimbal.spec.pan
        }
        Node {
            id: tiltNode
            position: gimbal.tiltPosition
            rotation: Quaternion.fromAxisAndAngle(gimbal.axis(gimbal.spec.tiltAxis), gimbal.spec.tiltSign * gimbal.tilt)
            RuntimeLoader {
                id: tiltLoader
                position: gimbal.tiltOffset
                source: gimbal.spec.tilt
            }
        }
    }
}
