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
        testHelper.disconnectDevice()
        testHelper.restoreConnection()
    }

    function test_axesFollowAngles() {
        const component = Qt.createComponent("IDS_GIMBAL", "GimbalZR10")
        verify(component.status === Component.Ready, component.errorString())
        const gimbal = createTemporaryObject(component, null, { pan: 30, tilt: 20 }) // no scene: only the node rotations
        fuzzyCompare(gimbal.panPart.eulerRotation.y, 30, 0.01)
        fuzzyCompare(gimbal.tiltPart.eulerRotation.x, -20, 0.01) // ZR10: tilt down is negative
        gimbal.pan = -45
        fuzzyCompare(gimbal.panPart.eulerRotation.y, -45, 0.01)
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
