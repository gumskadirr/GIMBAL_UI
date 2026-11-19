import QtQuick
import QtTest
import IDS_GIMBAL

// Errors page against the real ImageViewModel (data from tst_qml.cpp's image fake provider).
TestCase {
    id: testCase
    name: "Errors"
    when: windowShown
    width: 1400
    height: 1000

    Component {
        id: pageComponent
        ErrorsPage {
            width: testCase.width
            height: testCase.height
            viewModel: testImageViewModel
            settings: testSettings
        }
    }

    function cleanup() {
        testHelper.disconnectImage()
        testHelper.setImageCommandsSupported(false)
    }

    function openWithDevice() {
        testHelper.setImageCommandsSupported(true)
        const page = createTemporaryObject(pageComponent, testCase, {pageActive: true})
        testHelper.connectImageWithSample()
        tryVerify(() => testImageViewModel.sample.errorsValid)
        return page
    }

    // Values of the design.
    function test_designValuesShown() {
        const page = openWithDevice()
        compare(page.items.length, 21)
        compare(page.groups.map(g => g.name), ["PMCB", "TMCB", "BMACB", "MACB", "MINIPC"])
        compare(findChild(page, "errorsSummary").text, "21 OK")
        verify(findChild(page, "error-MACB_LRF"))
        compare(findChild(page, "toggle-dhcp").switchItem.checked, false)
        compare(findChild(page, "input-ipAddress").text, "192.168.1.50")
    }

    function test_noDataShowsNothing() {
        const page = createTemporaryObject(pageComponent, testCase, {pageActive: true})
        compare(page.items.length, 0)
        verify(!findChild(page, "errorsSummary").visible)
        compare(findChild(page, "input-ipAddress").text, "")
    }

    function test_failedItemIsHighlighted() {
        const page = openWithDevice()
        const okBorder = findChild(page, "error-MACB_LRF").border.color
        const summary = findChild(page, "errorsSummary")
        const okText = summary.text
        testHelper.sendImageErrors("MACB_LRF")
        tryCompare(summary, "text", "1 FAIL")
        const tile = findChild(page, "error-MACB_LRF") // the tiles are rebuilt with a changed list
        verify(!Qt.colorEqual(tile.border.color, okBorder))
        compare(summary.kind, "crit")
        compare(tile.tone, "crit")
        compare(findChild(page, "error-MACB_IMU").tone, "ok")
        testHelper.sendImageErrors("")
        tryCompare(summary, "text", okText)
        compare(findChild(page, "error-MACB_LRF").tone, "ok")
    }

    // Nothing can be used without command support (real target).
    function test_everythingDisabledWithoutCommands() {
        const page = createTemporaryObject(pageComponent, testCase, {pageActive: true})
        testHelper.connectImageWithSample()
        tryVerify(() => testImageViewModel.sample.errorsValid)
        verify(findChild(page, "command-setIp"))
        verify(!findChild(page, "command-setIp").enabled)
        verify(!findChild(page, "input-ipAddress").enabled)
        verify(!findChild(page, "toggle-dhcp").switchItem.enabled)
    }

    function test_invalidAddressIsNotSent() {
        const page = openWithDevice()
        const field = findChild(page, "input-ipAddress")
        const set = findChild(page, "command-setIp")
        const sent = testHelper.imageSentCount()
        for (const bad of ["", "192.168.1", "192.168.1.256", "192.168.1.50.1", "a.b.c.d", "192.168.01.5x"]) {
            field.text = bad
            field.textEdited()
            verify(!set.enabled, bad)
            verify(field.error, bad)
            field.accepted() // Enter must not send either
        }
        compare(testHelper.imageSentCount(), sent)
    }

    function test_validAddressIsSent() {
        const page = openWithDevice()
        const field = findChild(page, "input-ipAddress")
        const set = findChild(page, "command-setIp")
        field.text = " 10.0.0.7 "
        field.textEdited()
        verify(set.enabled)
        verify(!field.error)
        set.clicked()
        compare(testHelper.lastImageCommandKind(), Command.ImageSetIp)
        compare(testHelper.lastImageCommandArgs().dhcp, false)
        compare(testHelper.lastImageCommandArgs().address, "10.0.0.7")
        verify(!set.enabled) // pending: no second press
        testHelper.answerLastImageCommand(Command.Accepted)
        verify(set.enabled)
    }

    function test_dhcpDisablesAddressAndSends() {
        const page = openWithDevice()
        const row = findChild(page, "toggle-dhcp")
        const field = findChild(page, "input-ipAddress")
        const set = findChild(page, "command-setIp")
        field.text = "bad"
        field.textEdited()
        row.switchItem.checked = true
        row.switchItem.toggled()
        verify(!field.enabled)
        verify(!field.error)
        verify(set.enabled) // the address does not matter with DHCP
        set.clicked()
        compare(testHelper.lastImageCommandArgs().dhcp, true)
        compare(testHelper.lastImageCommandArgs().address, "")
    }

    function test_typedAddressSurvivesTelemetry() {
        const page = openWithDevice()
        const field = findChild(page, "input-ipAddress")
        field.text = "10.0.0.7"
        field.textEdited()
        testHelper.sendImageSample()
        compare(field.text, "10.0.0.7")
    }
}
