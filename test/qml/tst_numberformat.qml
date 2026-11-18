import QtQuick
import QtTest
import IDS_GIMBAL

TestCase {
    name: "NumberFormat"

    function cleanup() {
        NumberFormat.language = "en"
    }

    function test_decimalSeparatorFollowsLanguage() {
        compare(NumberFormat.fixed(124.4964, 3), "124.496")
        NumberFormat.language = "tr"
        compare(NumberFormat.fixed(124.4964, 3), "124,496")
        compare(NumberFormat.fixed(-8.2, 1), "-8,2")
    }

    // A grouping separator would make 1.234 ambiguous between the two languages.
    function test_noThousandsSeparator() {
        compare(NumberFormat.fixed(1234.5, 1), "1234.5")
        NumberFormat.language = "tr"
        compare(NumberFormat.fixed(1234.5, 1), "1234,5")
    }

    function test_noNegativeZero() {
        compare(NumberFormat.fixed(-0.0001, 3), "0.000")
    }

    // Only the language's own decimal separator is read back.
    function test_parse() {
        compare(NumberFormat.parse(" -12.5 "), -12.5)
        verify(isNaN(NumberFormat.parse("12,5")))
        verify(isNaN(NumberFormat.parse("abc")))
        verify(isNaN(NumberFormat.parse("")))
        NumberFormat.language = "tr"
        compare(NumberFormat.parse("12,5"), 12.5)
        compare(NumberFormat.parse("7"), 7)
        verify(isNaN(NumberFormat.parse("12.5")))
    }
}
