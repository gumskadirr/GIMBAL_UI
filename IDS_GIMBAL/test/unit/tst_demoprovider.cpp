#include <QSignalSpy>
#include <QTest>

#include "DemoProvider.h"
#include "ImageDemoProvider.h"
#include "device/session/DeviceSession.h"

namespace {
DeviceSample sampleAt(const QSignalSpy &spy, int i)
{
    return spy.at(i).at(1).value<DeviceSample>();
}
} // namespace

class tst_DemoProvider : public QObject
{
    Q_OBJECT

private slots:
    void connectsThenStreams()
    {
        DemoProvider p(5, 1000, 50);
        QSignalSpy states(&p, &IDeviceProvider::stateChanged);
        QSignalSpy samples(&p, &IDeviceProvider::sampleReceived);
        p.start(1, {});
        QCOMPARE(states.count(), 0); // never synchronously from start()
        QTRY_VERIFY(samples.count() >= 3);
        QCOMPARE(states.at(0).at(1).value<ConnectionState>(), ConnectionState::Connected);
        for (const auto &args : samples)
            QCOMPARE(args.at(0).toULongLong(), 1u);
        const DeviceSample first = sampleAt(samples, 0);
        QCOMPARE(first.panDeg.value, 0.0);
        for (const Measurement &m : {first.panDeg, first.panRefDeg, first.tiltDeg, first.tiltRefDeg,
                                     first.gimbalTempC, first.imuTempC, first.supplyVoltageV})
            QVERIFY(m.valid);
        QVERIFY(first.safeControlLocked.valid);
    }

    void imageDemoShowsDesignValuesAndAppliesSettings()
    {
        ImageDemoProvider p;
        QSignalSpy samples(&p, &IDeviceProvider::imageSampleReceived);
        p.start(1, {});
        QTRY_VERIFY(samples.count() >= 1);
        ImageSample s = samples.last().at(1).value<ImageSample>();
        QCOMPARE(s.status.value, QStringLiteral("OK"));
        QCOMPARE(s.mode.value, QStringLiteral("Locked"));
        QCOMPARE(s.fps.value, 30.0);
        QCOMPARE(s.zoom.value, 1.0);
        QCOMPARE(s.brightness.value, 200.0);
        QVERIFY(!s.lrfDistanceM.valid);
        QVERIFY(s.errorsValid);
        QCOMPARE(s.errors.size(), 21);
        QCOMPARE(s.ipAddress.value, QStringLiteral("192.168.1.50"));

        p.send(1, 1, {Command::ImageSetStreamSetting, {{"setting", "brightness"}, {"value", 90.0}}});
        const int seen = samples.count();
        QTRY_VERIFY(samples.count() > seen);
        QCOMPARE(samples.last().at(1).value<ImageSample>().brightness.value, 90.0);

        // The state stream is idle until Start, then shows the design values; Stop ends it.
        QVERIFY(!s.stateValid);
        QVERIFY(!s.stateStreaming.value);
        p.send(1, 2, {Command::ImageGimbalState, {{"running", true}, {"rateHz", 10}}});
        QTRY_VERIFY(samples.last().at(1).value<ImageSample>().stateStreaming.value);
        s = samples.last().at(1).value<ImageSample>();
        QVERIFY(s.stateValid);
        QCOMPARE(s.stateFlags.size(), 9);
        QCOMPARE(s.stateValues.size(), 10);
        QCOMPARE(s.stateFlagsRaw, 0xfff);
        p.send(1, 3, {Command::ImageGimbalState, {{"running", false}, {"rateHz", 10}}});
        QTRY_VERIFY(!samples.last().at(1).value<ImageSample>().stateStreaming.value);
    }

    void sendsBoardInfoOnceAfterConnecting()
    {
        DemoProvider p(5, 1000, 50);
        QSignalSpy info(&p, &IDeviceProvider::boardInfoReceived);
        p.start(1, {});
        QCOMPARE(info.count(), 0); // never synchronously from start()
        QTRY_COMPARE(info.count(), 1);
        QCOMPARE(info.at(0).at(0).toULongLong(), 1u);
        QVERIFY(info.at(0).at(1).value<BoardInfo>().uid.valid);
        QTest::qWait(50);
        QCOMPARE(info.count(), 1);
    }

    void valuesInDisplayRange()
    {
        for (int n = 0; n < 200; ++n) {
            const DeviceSample s = DemoProvider::sampleAt(n);
            QVERIFY2(qAbs(s.panDeg.value) <= 180.0, qPrintable(QString::number(n)));
            QVERIFY2(qAbs(s.tiltDeg.value) <= 90.0, qPrintable(QString::number(n)));
            QVERIFY(s.supplyVoltageV.value > 0.0);
        }
    }

    void temperatureDropout()
    {
        DemoProvider p(1, 1000, 50);
        QSignalSpy samples(&p, &IDeviceProvider::sampleReceived);
        p.start(1, {});
        QTRY_VERIFY_WITH_TIMEOUT(samples.count() >= 50, 5000);
        QVERIFY(sampleAt(samples, 39).gimbalTempC.valid);
        QVERIFY(!sampleAt(samples, 40).gimbalTempC.valid);
        QVERIFY(!sampleAt(samples, 49).gimbalTempC.valid);
    }

    void linkLoss()
    {
        DemoProvider p(1, 20, 50);
        QSignalSpy states(&p, &IDeviceProvider::stateChanged);
        QSignalSpy samples(&p, &IDeviceProvider::sampleReceived);
        p.start(1, {});
        QTRY_COMPARE_WITH_TIMEOUT(states.count(), 2, 5000);
        QCOMPARE(states.at(1).at(1).value<ConnectionState>(), ConnectionState::Error);
        QCOMPARE(states.at(1).at(2).toString(), QStringLiteral("Simulated link loss"));
        QCOMPARE(samples.count(), 20);
    }

    void sendsBitReportOnConnectAndAfterRunBit()
    {
        DemoProvider p(5, 1000, 50);
        QSignalSpy reports(&p, &IDeviceProvider::bitReportReceived);
        p.start(1, {});
        QTRY_COMPARE(reports.count(), 1);
        const BitReport first = reports.at(0).at(1).value<BitReport>();
        QCOMPARE(first.items.size(), 8);
        QCOMPARE(first.items.at(2).status, int(BitItem::Warning));
        p.send(1, 1, {Command::RunBit, {}});
        QTRY_COMPARE(reports.count(), 2);
    }

    void firmwareUpdateReportsProgressAndCanBeCancelled()
    {
        DemoProvider p(5, 1000, 50);
        QSignalSpy progress(&p, &IDeviceProvider::commandProgress);
        QSignalSpy finished(&p, &IDeviceProvider::commandFinished);
        p.start(1, {});
        p.send(1, 7, {Command::UpdateFirmware, {{QStringLiteral("file"), QStringLiteral("a.bin")}}});
        QTRY_VERIFY(progress.count() >= 3);
        QCOMPARE(progress.at(0).at(1).toULongLong(), 7u);
        QVERIFY(progress.last().at(2).toInt() > progress.at(0).at(2).toInt());
        p.send(1, 8, {Command::CancelFirmwareUpdate, {}});
        QTRY_COMPARE(finished.count(), 2);
        QCOMPARE(finished.at(0).at(1).toULongLong(), 7u); // the update ends as Cancelled
        QCOMPARE(finished.at(0).at(2).value<CommandResult>().status, Command::Cancelled);
        QCOMPARE(finished.at(1).at(1).toULongLong(), 8u); // the cancel itself is accepted
        QCOMPARE(finished.at(1).at(2).value<CommandResult>().status, Command::Accepted);
    }

    void demoReportsStreamAndCalibrationResults()
    {
        DemoProvider p(5, 1000, 50);
        QSignalSpy samples(&p, &IDeviceProvider::sampleReceived);
        QSignalSpy crosstalk(&p, &IDeviceProvider::crosstalkResultReceived);
        QSignalSpy finished(&p, &IDeviceProvider::commandFinished);
        p.start(1, {});
        QTRY_VERIFY(samples.count() >= 2);
        const DeviceSample first = samples.at(0).at(1).value<DeviceSample>();
        QCOMPARE(first.streamRateHz.value, 1000.0);
        QVERIFY(samples.at(1).at(1).value<DeviceSample>().packetCount.value > first.packetCount.value);
        p.send(1, 3, {Command::StartCrosstalkCheck, {}});
        p.send(1, 4, {Command::StartImuBiasCalibration, {}}); // one long command at a time
        QTRY_COMPARE(finished.count(), 1);
        QCOMPARE(finished.at(0).at(2).value<CommandResult>().status, Command::Rejected);
        QTRY_COMPARE_WITH_TIMEOUT(crosstalk.count(), 1, 10000);
        QVERIFY(crosstalk.at(0).at(1).value<CrosstalkResult>().passed);
        QTRY_COMPARE(finished.count(), 2);
        QCOMPARE(finished.at(1).at(2).value<CommandResult>().status, Command::Accepted);
    }

    void lateResultDroppedBySession()
    {
        DeviceSession session(std::make_unique<DemoProvider>(5, 1000, 30));
        session.connectDevice();
        QTRY_COMPARE(session.state(), ConnectionState::Connected);
        session.connectDevice(); // old session's delayed result arrives during the new one
        QTRY_VERIFY(session.staleDropped() >= 1);
        QCOMPARE(session.activeSessionId(), 2u);
    }

    void destroyWithPendingLateResult()
    {
        auto *p = new DemoProvider(5, 1000, 30);
        p->start(1, {});
        QTest::qWait(20);
        p->stop();
        delete p;
        QTest::qWait(60); // the pending delayed result must not fire into a deleted object
    }
};

QTEST_GUILESS_MAIN(tst_DemoProvider)
#include "tst_demoprovider.moc"
