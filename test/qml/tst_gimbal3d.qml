import QtQuick
import QtTest
import IDS_GIMBAL

// 3D gimbal view: the axes follow the angles, the Main control pages show the selected gimbal's model, and
// where Qt Quick 3D cannot draw (these offscreen tests use the software renderer) the placeholder says why.
TestCase {
    id: testCase
    name: "Gimbal3D"
    when: windowShown

    function createMain() {
        const component = Qt.createComponent("IDS_GIMBAL", "Main")
        verify(component.status === Component.Ready, component.errorString())
        const main = createTemporaryObject(component, testCase, {
            settings: testSettings,
            localization: testLocalization,
            notifications: testNotifications,
            mainControl: testMainControl, imageViewModel: testImageViewModel,
            demoMode: true
        })
        verify(main)
        main.currentPageId = "gimbalInfo"
        return main
    }

    function gimbalView(main) {
        const loader = findChild(main.contentItem, "page-gimbalInfo")
        tryVerify(() => loader.item !== null)
        return findChild(loader.item, "gimbalView")
    }

    function init() { testLocalization.setLanguage("en") }

    function cleanup() {
        testSettings.gimbal = "g180"
        testSettings.gimbalVersion = "v2.0"
        testHelper.resetGimbalLibrary()
        testHelper.disconnectDevice()
        testHelper.restoreConnection()
    }

    function createModel(spec) {
        const component = Qt.createComponent("IDS_GIMBAL", "GimbalModel")
        verify(component.status === Component.Ready, component.errorString())
        return createTemporaryObject(component, null, { spec: spec }) // no scene: only the node transforms
    }
    function zr10() { return testSettings.gimbalLibrary.gimbals.find(g => g.id === "zr10").model }

    function test_axesFollowAngles() {
        const gimbal = createModel(zr10())
        gimbal.pan = 30
        gimbal.tilt = 20
        fuzzyCompare(gimbal.panPart.eulerRotation.y, 30, 0.01)
        fuzzyCompare(gimbal.tiltPart.eulerRotation.x, -20, 0.01) // ZR10: tilt down is negative
        gimbal.pan = -45
        fuzzyCompare(gimbal.panPart.eulerRotation.y, -45, 0.01)
        compare(gimbal.tiltPart.position, Qt.vector3d(-4.1, -53.1, 13.94)) // ZR10 parts are centred on their axes
        compare(gimbal.tiltLoader.position, Qt.vector3d(0, 0, 0))
        verify(String(gimbal.spec.tilt).startsWith("file:"))
    }

    function test_inPlaceOffsetsParts() {
        const spec = Object.assign({}, zr10(), { inPlace: true, panPivot: [1, 2, 3], tiltPivot: [4, 5, 6],
                                                 tiltAxis: "z", tiltSign: 1 })
        const gimbal = createModel(spec)
        compare(gimbal.panPart.position, Qt.vector3d(1, 2, 3))
        compare(gimbal.panLoader.position, Qt.vector3d(-1, -2, -3))
        compare(gimbal.tiltPart.position, Qt.vector3d(3, 3, 3)) // relative to the pan part
        compare(gimbal.tiltLoader.position, Qt.vector3d(-4, -5, -6))
        gimbal.tilt = 15
        fuzzyCompare(gimbal.tiltPart.eulerRotation.z, 15, 0.01)
    }

    function test_followsSelectedGimbal() {
        const main = createMain()
        const view = gimbalView(main)
        const viewport = view.parent.parent
        compare(view.model, null) // G180 has no model yet
        compare(viewport.placeholderText, "No 3D model for this gimbal yet")

        testSettings.gimbal = "zr10"
        testSettings.gimbalVersion = "v1.0"
        verify(view.model !== null)
        compare(findChild(main.contentItem, "gimbalButton").text, "ZR10 · v1.0")
    }

    function test_softwareRendererMessage() {
        testSettings.gimbal = "zr10"
        testSettings.gimbalVersion = "v1.0"
        const main = createMain()
        const view = gimbalView(main)
        verify(!view.available)
        verify(!view.shown)
        compare(view.gimbal, null) // no View3D is built
        compare(view.parent.parent.placeholderTitle, "3D gimbal model")
        compare(view.parent.parent.placeholderText, "The 3D view needs a 3D graphics driver")
    }

    function test_telemetryValidity() {
        const main = createMain()
        const view = gimbalView(main)
        verify(!view.valid)
        testHelper.connectWithFullSample()
        tryCompare(view, "valid", true)
        compare(view.pan, testMainControl.pan.value)
        compare(view.tilt, testMainControl.tilt.value)
    }
}
