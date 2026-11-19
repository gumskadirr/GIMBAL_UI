import QtQuick
import QtTest
import IDS_GIMBAL
import "TestUtils.js" as TestUtils

// Alignment page against the real ImageViewModel (data from tst_qml.cpp's image fake provider).
TestCase {
    id: testCase
    name: "Alignment"
    when: windowShown
    width: 1400
    height: 1000

    Component {
        id: pageComponent
        AlignmentPage {
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
        tryVerify(() => testImageViewModel.sample.offsetX.valid)
        return page
    }

    // Values of the design.
    function test_designValuesShown() {
        const page = openWithDevice()
        compare(findChild(page, "combo-camera").currentText, "CMOS sensor")
        compare(findChild(page, "value-zoom").text, "x1.0")
        compare(findChild(page, "focusMode").currentIndex, 0)
        compare(findChild(page, "input-focusDistance").text, "Infinity")
        compare(findChild(page, "input-fovGain").text, "Infinity")
        verify(findChild(page, "toggle-overlay").switchItem.checked)
        compare(findChild(page, "value-imageScale").text, "x1.0")
        compare(findChild(page, "offsetValue-offsetX").text, "9")
        compare(findChild(page, "offsetValue-offsetY").text, "11")
        verify(!findChild(page, "toggle-stabilization").switchItem.checked)
        compare(findChild(page, "mode-gain").currentIndex, 1) // Auto
        compare(findChild(page, "mode-iris").currentIndex, 1)
        compare(findChild(page, "mode-shutter").currentIndex, 1)
    }

    function test_noDataShowsDashes() {
        const page = createTemporaryObject(pageComponent, testCase, {pageActive: true})
        compare(findChild(page, "value-zoom").text, "—")
        compare(findChild(page, "input-focusDistance").text, "")
    }

    // Without command support nothing on the cards can be used.
    function test_cardsDisabledWithoutCommands() {
        const page = createTemporaryObject(pageComponent, testCase, {pageActive: true})
        testHelper.connectImageWithSample()
        const controls = TestUtils.interactiveControls(findChild(page, "imageCards"))
        verify(controls.length >= 18)
        for (const control of controls)
            verify(!control.enabled, control.objectName || control.text || String(control))
        verify(findChild(page, "openVideo").enabled)
    }

    // Minus / plus change the page's own value only; Write offset sends all three values.
    function test_stepsAreLocalAndWriteOffsetSendsAll() {
        const page = openWithDevice()
        const sent = testHelper.imageSentCount()
        findChild(page, "offsetPlus-offsetX").clicked()
        findChild(page, "offsetPlus-offsetX").clicked()
        findChild(page, "offsetMinus-offsetY").clicked()
        compare(findChild(page, "offsetValue-offsetX").text, "11")
        compare(findChild(page, "offsetValue-offsetY").text, "10")
        const slider = findChild(page, "slider-imageScale")
        slider.value = 1.5
        slider.moved()
        compare(testHelper.imageSentCount(), sent) // nothing went out
        testHelper.sendImageSample() // telemetry does not undo the edit
        compare(findChild(page, "offsetValue-offsetX").text, "11")
        TestUtils.confirm(testCase, findChild(page, "command-writeOffset"))
        compare(testHelper.imageSentCount(), sent + 1)
        compare(testHelper.lastImageCommandKind(), Command.ImageWriteOffset)
        compare(testHelper.lastImageCommandArgs().x, 11)
        compare(testHelper.lastImageCommandArgs().y, 10)
        compare(testHelper.lastImageCommandArgs().scale, 1.5)
    }

    function test_settingsGoOutAsSettings() {
        const page = openWithDevice()
        const toggle = findChild(page, "toggle-stabilization")
        toggle.switchItem.checked = true
        toggle.toggled()
        compare(testHelper.lastImageCommandKind(), Command.ImageSetStreamSetting)
        compare(testHelper.lastImageCommandArgs().setting, "stabilization")
        compare(testHelper.lastImageCommandArgs().value, true)
        testHelper.answerLastImageCommand(Command.Accepted)
        const mode = findChild(page, "mode-iris")
        mode.activated(0)
        compare(testHelper.lastImageCommandArgs().setting, "irisMode")
        compare(testHelper.lastImageCommandArgs().value, 0)
    }

    function test_cameraStepAndFocus() {
        const page = openWithDevice()
        findChild(page, "step-shutter-more").clicked()
        compare(testHelper.lastImageCommandKind(), Command.ImageCameraStep)
        compare(testHelper.lastImageCommandArgs().param, "shutter")
        compare(testHelper.lastImageCommandArgs().delta, 1)
        testHelper.answerLastImageCommand(Command.Accepted)
        const field = findChild(page, "input-focusDistance")
        field.text = "-5"
        field.textEdited()
        const sent = testHelper.imageSentCount()
        findChild(page, "command-setFocus").clicked()
        verify(field.error)
        compare(testHelper.imageSentCount(), sent)
        field.text = "12.5"
        field.textEdited()
        findChild(page, "command-setFocus").clicked()
        compare(testHelper.lastImageCommandKind(), Command.ImageSetFocus)
        compare(testHelper.lastImageCommandArgs().distance, 12.5)
        testHelper.answerLastImageCommand(Command.Accepted)
        findChild(page, "command-focusInfinity").clicked()
        compare(testHelper.lastImageCommandArgs().distance, Infinity)
    }
}
