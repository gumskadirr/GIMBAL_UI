import QtQuick
import QtTest
import IDS_GIMBAL
import "TestUtils.js" as TestUtils

// View & control page against the real ImageViewModel (data from tst_qml.cpp's image fake provider).
TestCase {
    id: testCase
    name: "ViewControl"
    when: windowShown
    width: 1400
    height: 1000

    Component {
        id: pageComponent
        ViewControlPage {
            width: testCase.width
            height: testCase.height
            viewModel: testImageViewModel
            settings: testSettings
        }
    }

    function cleanup() {
        testHelper.disconnectImage()
        testHelper.setImageCommandsSupported(false)
        testLocalization.setLanguage("en")
        NumberFormat.language = "en"
    }

    function openWithDevice() {
        testHelper.setImageCommandsSupported(true)
        const page = createTemporaryObject(pageComponent, testCase, {pageActive: true})
        testHelper.connectImageWithSample()
        tryVerify(() => testImageViewModel.sample.fps.valid)
        return page
    }

    function toggle(row) {
        row.switchItem.checked = !row.switchItem.checked
        row.switchItem.toggled()
    }

    // The device answers: Accepted, then its next telemetry.
    function answer() {
        testHelper.answerLastImageCommand(Command.Accepted)
        testHelper.sendImageSample()
    }

    // Values of the design.
    function test_designValuesShown() {
        const page = openWithDevice()
        compare(findChild(page, "tagAttitude").text, "PAN 0.0  TILT 0.0")
        compare(findChild(page, "tagStream").text, "30 FPS · x1.0")
        compare(findChild(page, "statusValue").text, "OK")
        compare(findChild(page, "modeValue").text, "Locked")
        compare(findChild(page, "value-zoom").text, "x1.0")
        compare(findChild(page, "value-brightness").text, "200")
        compare(findChild(page, "slider-brightness").value, 200)
        compare(findChild(page, "combo-streamMode").currentText, "Blend")
        compare(findChild(page, "combo-polarity").displayText, "Select...")
        compare(findChild(page, "combo-ffcMode").currentText, "FFC manual")
        compare(findChild(page, "lrfDistance").text, "—") // no reading: never shown as 0
        compare(findChild(page, "tile-pan").value, "0.0")
        compare(findChild(page, "command-attitudeEnable").text, "Enable")
    }

    function test_turkishDecimalComma() {
        const page = openWithDevice()
        verify(testLocalization.setLanguage("tr"))
        NumberFormat.language = "tr"
        compare(findChild(page, "tagStream").text, "30 FPS · x1,0")
        compare(findChild(page, "tagAttitude").text, "PAN 0,0  TILT 0,0")
    }

    function test_noDataShowsDashes() {
        const page = createTemporaryObject(pageComponent, testCase, {pageActive: true})
        compare(findChild(page, "tagStream").text, "— FPS · x—")
        compare(findChild(page, "statusValue").text, "—")
        compare(findChild(page, "value-brightness").text, "—")
    }

    // Without command support (real target) nothing on the cards can be used.
    function test_cardsDisabledWithoutCommands() {
        const page = createTemporaryObject(pageComponent, testCase, {pageActive: true})
        testHelper.connectImageWithSample()
        const controls = TestUtils.interactiveControls(findChild(page, "imageCards"))
        verify(controls.length >= 20)
        for (const control of controls)
            verify(!control.enabled, control.objectName || control.text || String(control))
        verify(findChild(page, "openVideo").enabled) // the source row is not a device command
    }

    // A slider sends once, on release; until the device reports it keeps the position of the user.
    function test_sliderSendsOnRelease() {
        const page = openWithDevice()
        const slider = findChild(page, "slider-contrast")
        const sent = testHelper.imageSentCount()
        slider.value = 191
        slider.moved()
        compare(testHelper.imageSentCount(), sent + 1)
        compare(testHelper.lastImageCommandKind(), Command.ImageSetStreamSetting)
        compare(testHelper.lastImageCommandArgs().setting, "contrast")
        compare(testHelper.lastImageCommandArgs().value, 191)
        const userValue = slider.value
        verify(!slider.enabled) // pending: no second press
        testHelper.sendImageSample() // telemetry before the device applied it
        compare(slider.value, userValue)
        compare(findChild(page, "value-contrast").text, "0") // the shown value is the device value
        testHelper.answerLastImageCommand(Command.Accepted)
        tryCompare(slider, "value", 0) // the device value wins again
        verify(slider.enabled)
    }

    function test_failedSettingReturnsToDeviceValue() {
        const page = openWithDevice()
        const slider = findChild(page, "slider-brightness")
        slider.value = 50
        slider.moved()
        compare(testHelper.lastImageCommandArgs().setting, "brightness")
        testHelper.answerLastImageCommand(Command.Failed)
        tryCompare(slider, "value", 200)
    }

    function test_choicesAndSwitchesSend() {
        const page = openWithDevice()
        const combo = findChild(page, "combo-streamMode")
        combo.currentIndex = 1
        combo.activated(1)
        compare(testHelper.lastImageCommandKind(), Command.ImageSetStreamSetting)
        compare(testHelper.lastImageCommandArgs().setting, "streamMode")
        compare(testHelper.lastImageCommandArgs().value, 1)
        answer()
        tryCompare(combo, "currentIndex", 2) // back to the choice of the device

        toggle(findChild(page, "toggle-skyUp")) // the device holds true
        compare(testHelper.lastImageCommandArgs().setting, "skyUp")
        compare(testHelper.lastImageCommandArgs().value, false)
        answer()

        findChild(page, "controlDevice").activated(1)
        compare(testHelper.lastImageCommandKind(), Command.ImageSetControlDevice)
        compare(testHelper.lastImageCommandArgs().device, "joystick")
        answer()

        toggle(findChild(page, "toggle-lrfPointer"))
        compare(testHelper.lastImageCommandKind(), Command.ImageLrfPointer)
        compare(testHelper.lastImageCommandArgs().enabled, true)
        answer()
        toggle(findChild(page, "toggle-followTarget"))
        compare(testHelper.lastImageCommandKind(), Command.ImageFollowTarget)
        compare(testHelper.lastImageCommandArgs().enabled, true)
        answer()
    }

    function test_buttonsSendCommands() {
        const page = openWithDevice()
        for (const [name, kind] of [["command-nuc", Command.ImageTriggerNuc], ["command-park", Command.ImagePark],
                                    ["command-resetPosition", Command.ImageResetPosition], ["command-track", Command.ImageTrack]]) {
            findChild(page, name).clicked()
            compare(testHelper.lastImageCommandKind(), kind, name)
            answer()
        }
        findChild(page, "command-attitudeEnable").clicked()
        compare(testHelper.lastImageCommandKind(), Command.ImageAttitudeEnable)
        compare(testHelper.lastImageCommandArgs().enabled, true)
        answer()
        findChild(page, "command-boxSmaller").clicked()
        compare(testHelper.lastImageCommandKind(), Command.ImageBoxSize)
        compare(testHelper.lastImageCommandArgs().delta, -1)
        answer()
        findChild(page, "command-lrfMeasure").clicked()
        compare(testHelper.lastImageCommandKind(), Command.ImageLrfMeasure)
        compare(testHelper.lastImageCommandArgs().mode, "single")
        answer()
        findChild(page, "combo-lrfMode").currentIndex = 1
        findChild(page, "command-lrfMeasure").clicked()
        compare(testHelper.lastImageCommandArgs().mode, "continuous")
        answer()
    }

    function test_positionNeedsValidNumbers() {
        const page = openWithDevice()
        const pan = findChild(page, "input-pan")
        const tilt = findChild(page, "input-tilt")
        const sent = testHelper.imageSentCount()
        pan.text = "200" // out of range
        tilt.text = "5"
        findChild(page, "command-setPosition").clicked()
        verify(pan.error)
        verify(!tilt.error)
        compare(testHelper.imageSentCount(), sent)
        pan.text = "10.5"
        tilt.text = "-3"
        findChild(page, "command-setPosition").clicked()
        compare(testHelper.lastImageCommandKind(), Command.ImageSetPosition)
        compare(testHelper.lastImageCommandArgs().pan, 10.5)
        compare(testHelper.lastImageCommandArgs().tilt, -3)
        answer()
        verify(testLocalization.setLanguage("tr"))
        NumberFormat.language = "tr"
        pan.text = "10.5" // the dot is not a Turkish decimal
        findChild(page, "command-setPosition").clicked()
        verify(pan.error)
    }

    // Open does not decode video yet: it says so and keeps the address.
    function test_openSaysVideoNotAvailable() {
        const page = createTemporaryObject(pageComponent, testCase, {pageActive: true})
        const video = findChild(page, "video")
        compare(video.placeholderTitle, "")
        const url = findChild(page, "rtspUrl")
        url.text = "rtsp://10.1.1.9/main"
        findChild(page, "openVideo").clicked()
        compare(video.placeholderTitle, "Video is not available in this version")
        compare(testSettings.rtspUrl, "rtsp://10.1.1.9/main")
    }
}
