#include <QFile>
#include <QSignalSpy>
#include <QTemporaryDir>
#include <QTest>
#include <cmath>

#include "features/telemetry/ScriptFile.h"

class tst_ScriptFile : public QObject
{
    Q_OBJECT

    static bool load(ScriptFile &f, const char *text) { return f.loadData(QByteArray(text)); }

private slots:
    void goodFile()
    {
        ScriptFile f;
        QVERIFY(load(f, "time_ms,pan_deg,tilt_deg\r\n0,1.5,-2\r\n10,2.5,-3\r\n\r\n20,3.5,-4\r\n"));
        QCOMPARE(f.rowCount(), 3);
        QCOMPARE(f.columns(), (QStringList{"time_ms", "pan_deg", "tilt_deg"}));
        QCOMPARE(f.sampleMs(), 10);
        QCOMPARE(f.panColumn(), 1);
        QCOMPARE(f.tiltColumn(), 2);
        QCOMPARE(f.pan(2), 3.5);
        f.setPanOffset(10);
        QCOMPARE(f.pan(2), 13.5);
        QVERIFY(std::isnan(f.pan(3)));
    }

    void semicolonSeparator()
    {
        ScriptFile f;
        QVERIFY(load(f, "a;b\n1.5;2\n3;4.25\n"));
        QCOMPARE(f.rowCount(), 2);
        QCOMPARE(f.sampleMs(), 0);  // no time column: entered in the UI
        QCOMPARE(f.panColumn(), 0); // no pan/tilt names: the first two columns
        QCOMPARE(f.tiltColumn(), 1);
        QCOMPARE(f.tilt(1), 4.25);
    }

    void emptyFile()
    {
        ScriptFile f;
        QSignalSpy failed(&f, &ScriptFile::failed);
        QVERIFY(!load(f, ""));
        QVERIFY(!load(f, "\n  \n"));
        QVERIFY(!load(f, "pan,tilt\n"));
        QCOMPARE(failed.count(), 3);
        QVERIFY(!f.loaded());
    }

    void nonNumericCellNamesTheLine()
    {
        ScriptFile f;
        QVERIFY(!load(f, "pan,tilt\n1,2\n3,x\n"));
        QVERIFY(f.error().contains(QLatin1String("Line 3, column tilt")));
    }

    void missingColumnNamesTheLine()
    {
        ScriptFile f;
        QVERIFY(!load(f, "pan,tilt\n1,2\n3\n"));
        QVERIFY(f.error().contains(QLatin1String("Line 3")));
    }

    void emptyCellIsNotANumber()
    {
        ScriptFile f;
        QVERIFY(!load(f, "pan,tilt\n1,\n"));
        QVERIFY(f.error().contains(QLatin1String("Line 2")));
    }

    void badFileKeepsThePreviousScript()
    {
        ScriptFile f;
        QVERIFY(load(f, "pan,tilt\n1,2\n"));
        QVERIFY(!load(f, "pan,tilt\n1,nan\n"));
        QCOMPARE(f.rowCount(), 1);
    }

    void tooLargeFile()
    {
        QTemporaryDir dir;
        QFile big(dir.filePath(QStringLiteral("big.csv")));
        QVERIFY(big.open(QIODevice::WriteOnly));
        big.resize(ScriptFile::kMaxBytes + 1);
        big.close();
        ScriptFile f;
        QVERIFY(!f.load(QUrl::fromLocalFile(big.fileName())));
        QVERIFY(f.error().contains(QLatin1String("larger")));
    }

    void saveWritesTheOffsetRows()
    {
        QTemporaryDir dir;
        ScriptFile f;
        QVERIFY(load(f, "time_ms;pan_deg;tilt_deg\n0;1.5;2\n10;2;3\n"));
        f.setPanOffset(1);
        const QUrl url = QUrl::fromLocalFile(dir.filePath(QStringLiteral("out.csv")));
        QVERIFY(f.save(url));
        QFile file(url.toLocalFile());
        QVERIFY(file.open(QIODevice::ReadOnly));
        QCOMPARE(file.readAll(), QByteArray("time_ms,pan_deg,tilt_deg\r\n0,2.5,2\r\n10,3,3\r\n"));
        ScriptFile again;
        QVERIFY(again.load(url));
        QCOMPARE(again.pan(0), 2.5);
    }
};

QTEST_GUILESS_MAIN(tst_ScriptFile)
#include "tst_scriptfile.moc"
