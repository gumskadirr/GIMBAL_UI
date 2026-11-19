import QtQuick
import QtTest
import IDS_GIMBAL

// Gimbal state page against the real ImageViewModel (data from tst_qml.cpp's image fake provider).
TestCase {
    id: testCase
    name: "GimbalState"
    when: windowShown
    width: 1400
    height: 1000

    Component {
        id: pageComponent
        GimbalStatePage {
            width: testCase.width
            height: testCase.height
            viewModel: testImageViewModel
            settings: testSettings
        }
    }

    function cleanup() {
        testHelper.disconnectImage()
        testHelper.setImageCommandsSupported(false)
        NumberFormat.language = "en"
    }

    function openWithDevice() {
        testHelper.setImageCommandsSupported(true)
        const page = createTemporaryObject(pageComponent, testCase, {pageActive: true})
        testHelper.connectImageWithSample()
        tryVerify(() => testImageViewModel.sample.stateValid)
        return page
    }

    // Values of the design.
    function test_designValuesShown() {
        const page = openWithDevice()
        compare(page.flags.length, 9)
        compare(findChild(page, "flagsRaw").text, "0xfff")
        compare(findChild(page, "flag-MECHANICAL_STAB").text, "TRUE")
        compare(findChild(page, "flag-FOLLOWING_ENABLED").text, "TRUE")
        compare(page.values.map(v => v.name), ["yaw", "pitch", "latitude", "longitude", "altitude", "zoom", "lrf_distance",
                                               "fov_horizontal", "fov_vertical", "gnss_status"])
        compare(findChild(page, "value-gnss_status").text, "0")
        compare(findChild(page, "combo-rate").currentText, "5 Hz")
    }

    function test_noDataShowsDash() {
        const page = createTemporaryObject(pageComponent, testCase, {pageActive: true})
        compare(page.flags.length, 0)
        compare(page.values.length, 0)
        compare(findChild(page, "flagsRaw").text, "—")
    }

    function test_falseFlagIsNeutralAndValuesFollowLanguage() {
        const page = openWithDevice()
        const trueKind = findChild(page, "flag-PAN_MOTOR_ENABLED").kind
        testHelper.sendImageGimbalState(true, 12.5, false)
        tryCompare(findChild(page, "value-yaw"), "text", "12.5")
        compare(findChild(page, "flag-PAN_MOTOR_ENABLED").text, "FALSE")
        verify(findChild(page, "flag-PAN_MOTOR_ENABLED").kind !== trueKind)
        compare(findChild(page, "flagsRaw").text, "0x0")
        NumberFormat.language = "tr"
        compare(page.shown(12.5), "12,5")
        compare(page.shown(100), "100")
    }

    function test_startSendsRateThenStopSends() {
        const page = openWithDevice()
        const button = findChild(page, "command-gimbalState")
        compare(button.text, "Start")
        button.clicked()
        compare(testHelper.lastImageCommandKind(), Command.ImageGimbalState)
        compare(testHelper.lastImageCommandArgs().running, true)
        compare(testHelper.lastImageCommandArgs().rateHz, 5)
        verify(!button.enabled) // pending: no second press
        testHelper.answerLastImageCommand(Command.Accepted)
        compare(button.text, "Start") // the label follows the device, not the press
        testHelper.sendImageGimbalState(true, 0)
        tryCompare(button, "text", "Stop")
        button.clicked()
        compare(testHelper.lastImageCommandArgs().running, false)
        testHelper.answerLastImageCommand(Command.Accepted)
        testHelper.sendImageGimbalState(false, 0)
        tryCompare(button, "text", "Start")
    }

    function test_rateChangeWhileRunningIsSent() {
        const page = openWithDevice()
        const combo = findChild(page, "combo-rate")
        combo.currentIndex = 2 // 10 Hz
        const sent = testHelper.imageSentCount()
        combo.activated(2)
        compare(testHelper.imageSentCount(), sent) // not running: nothing to tell the device
        testHelper.sendImageGimbalState(true, 0)
        tryVerify(() => page.streaming)
        combo.currentIndex = 0
        combo.activated(0)
        compare(testHelper.lastImageCommandKind(), Command.ImageGimbalState)
        compare(testHelper.lastImageCommandArgs().running, true)
        compare(testHelper.lastImageCommandArgs().rateHz, 1)
    }

    // Nothing can be used without command support (real target).
    function test_everythingDisabledWithoutCommands() {
        const page = createTemporaryObject(pageComponent, testCase, {pageActive: true})
        testHelper.connectImageWithSample()
        tryVerify(() => testImageViewModel.sample.stateValid)
        verify(!findChild(page, "command-gimbalState").enabled)
        verify(!findChild(page, "combo-rate").enabled)
    }
}
