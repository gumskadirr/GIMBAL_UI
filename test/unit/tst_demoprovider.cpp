#include <QSignalSpy>
#include <QTest>

#include "DemoProvider.h"
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
