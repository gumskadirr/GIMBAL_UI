#include <QFile>
#include <QLocale>
#include <QSignalSpy>
#include <QTemporaryDir>
#include <QTest>

#include "FakeProvider.h"
#include "device/session/DeviceSession.h"
#include "features/telemetry/CsvRecorder.h"

class tst_CsvRecorder : public QObject
{
    Q_OBJECT

    struct Fixture {
        FakeProvider *fake = new FakeProvider;
        DeviceSession session{std::unique_ptr<IDeviceProvider>(fake)};
        CsvRecorder recorder{&session};

        Fixture()
        {
            session.connectDevice();
            emit fake->stateChanged(1, ConnectionState::Connected, {});
        }
        void send(const DeviceSample &s) { emit fake->sampleReceived(1, s); }
    };

    QTemporaryDir m_dir;
    QString path(const char *name) const { return m_dir.filePath(QLatin1String(name)); }
    QStringList lines(const QString &file)
    {
        QFile f(file);
        [&] { QVERIFY(f.open(QIODevice::ReadOnly)); }();
        return QString::fromUtf8(f.readAll()).split(QStringLiteral("\r\n"), Qt::SkipEmptyParts);
    }

private slots:
    void writesHeaderAndOneRowPerSample()
    {
        Fixture f;
        const QString file = path("rows.csv");
        QVERIFY(f.recorder.start(QUrl::fromLocalFile(file)));
        QVERIFY(f.recorder.recording());
        for (int i = 0; i < 250; ++i)
            f.send(makeSample(i, true, 30, true));
        QCOMPARE(f.recorder.rowCount(), 250);
        f.recorder.stop();
        QVERIFY(!f.recorder.recording());
        const QStringList l = lines(file);
        QCOMPARE(l.size(), 251);
        QVERIFY(l.first().startsWith(QLatin1String("time_ms,pan_deg,pan_deg_valid,")));
        QCOMPARE(l.first().count(','), l.at(1).count(','));
        QVERIFY(l.at(1).contains(QLatin1String(",0,1,"))); // pan 0, valid
    }

    void invalidFieldIsAnEmptyCell()
    {
        Fixture f;
        const QString file = path("invalid.csv");
        QVERIFY(f.recorder.start(QUrl::fromLocalFile(file)));
        f.send(makeSample(12.5, false, 31.25, true)); // pan invalid
        f.recorder.stop();
        const QStringList cols = lines(file).at(1).split(',');
        QCOMPARE(cols.at(1), QString());          // pan_deg
        QCOMPARE(cols.at(2), QStringLiteral("0")); // pan_deg_valid
        QCOMPARE(cols.at(9), QStringLiteral("31.25")); // gimbal_temp_c
        QCOMPARE(cols.at(10), QStringLiteral("1"));
    }

    void unwritablePathFails()
    {
        Fixture f;
        QSignalSpy failed(&f.recorder, &CsvRecorder::failed);
        QVERIFY(!f.recorder.start(QUrl::fromLocalFile(path("missing/dir/x.csv"))));
        QCOMPARE(failed.size(), 1);
        QVERIFY(!f.recorder.recording());
    }

    void disconnectClosesTheFileWithAllRows()
    {
        Fixture f;
        const QString file = path("disc.csv");
        QVERIFY(f.recorder.start(QUrl::fromLocalFile(file)));
        for (int i = 0; i < 7; ++i) // fewer than a flush batch
            f.send(makeSample(i, true, 30, true));
        f.session.disconnectDevice();
        QVERIFY(!f.recorder.recording());
        QCOMPARE(lines(file).size(), 8);
    }

    void decimalPointIgnoresLocale()
    {
        QLocale::setDefault(QLocale(QLocale::Turkish, QLocale::Turkey));
        Fixture f;
        const QString file = path("tr.csv");
        QVERIFY(f.recorder.start(QUrl::fromLocalFile(file)));
        f.send(makeSample(1.5, true, 30, true));
        f.recorder.stop();
        QLocale::setDefault(QLocale::c());
        const QString row = lines(file).at(1);
        QVERIFY(row.contains(QLatin1String(",1.5,1,")));
        QVERIFY(!row.contains(QLatin1String("1,5")));
    }
};

QTEST_GUILESS_MAIN(tst_CsvRecorder)
#include "tst_csvrecorder.moc"
