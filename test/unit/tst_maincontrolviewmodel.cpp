#include <QSignalSpy>
#include <QTest>

#include "FakeProvider.h"
#include "device/presentation/MainControlViewModel.h"
#include "device/session/DeviceSession.h"

class tst_MainControlViewModel : public QObject
{
    Q_OBJECT

    struct Fixture {
        FakeProvider *fake = new FakeProvider;
        DeviceSession session{std::unique_ptr<IDeviceProvider>(fake)};
        ServiceConnection connection{&session};
        MainControlViewModel vm{&session, &connection};

        void connect()
        {
            session.connectDevice();
            emit fake->stateChanged(session.activeSessionId(), ConnectionState::Connected, {});
        }
    };

private slots:
    void startsInvalid()
    {
        Fixture f;
        QVERIFY(!f.connection.connected());
        QVERIFY(!f.vm.pan().valid);
        QVERIFY(!f.vm.gimbalTemp().valid);
        QCOMPARE(f.vm.msSinceLastSample(), -1);
    }

    void sampleUpdatesValues()
    {
        Fixture f;
        f.connect();
        QVERIFY(f.connection.connected());
        emit f.fake->sampleReceived(1, makeSample(12.5, true, 0, false));
        QCOMPARE(f.vm.pan().value, 12.5);
        QVERIFY(f.vm.pan().valid);
        QVERIFY(!f.vm.gimbalTemp().valid); // invalid reading is not shown as 0
        QVERIFY(f.vm.msSinceLastSample() >= 0);
    }

    void newSessionInvalidates()
    {
        Fixture f;
        f.connect();
        emit f.fake->sampleReceived(1, makeSample(5, true, 30, true));
        f.connection.connectDevice();
        QVERIFY(!f.vm.pan().valid);
        QVERIFY(!f.vm.gimbalTemp().valid);
        QVERIFY(f.connection.busy());
    }

    void disconnectInvalidates()
    {
        Fixture f;
        f.connect();
        emit f.fake->sampleReceived(1, makeSample(5, true, 30, true));
        f.connection.disconnectDevice();
        QVERIFY(!f.vm.pan().valid);
    }

    void everyFieldInvalidated()
    {
        Fixture f;
        f.connect();
        emit f.fake->sampleReceived(1, makeFullSample());
        QVERIFY(f.vm.tiltRef().valid && f.vm.supplyVoltage().valid && f.vm.safeControl().valid);
        QCOMPARE(f.vm.tilt().value, -8.204);
        f.connection.connectDevice(); // new session
        for (const Measurement &m : {f.vm.pan(), f.vm.panRef(), f.vm.tilt(), f.vm.tiltRef(), f.vm.gimbalTemp(),
                                     f.vm.imuTemp(), f.vm.supplyVoltage()})
            QVERIFY(!m.valid);
        QVERIFY(!f.vm.safeControl().valid);
    }

    // Read-once data must not disappear with the telemetry stale timeout.
    void boardInfoSurvivesTelemetryStaleTimeout()
    {
        Fixture f;
        f.connect();
        emit f.fake->sampleReceived(1, makeSample(5, true, 30, true));
        emit f.fake->boardInfoReceived(1, makeBoardInfo());
        QVERIFY(f.vm.boardInfo().deviceId.valid);
        QTRY_VERIFY_WITH_TIMEOUT(!f.vm.pan().valid, MainControlViewModel::kStaleAfterMs + 1000);
        QVERIFY(f.vm.boardInfo().deviceId.valid);
        QCOMPARE(f.vm.boardInfo().firmware.value, QStringLiteral("v2.4.1"));
    }

    void boardInfoClearedWhenSessionEnds()
    {
        Fixture f;
        f.connect();
        emit f.fake->boardInfoReceived(1, makeBoardInfo());
        QSignalSpy changed(&f.vm, &MainControlViewModel::boardInfoChanged);
        f.connection.disconnectDevice();
        QVERIFY(!f.vm.boardInfo().deviceId.valid);
        QCOMPARE(changed.count(), 1);

        f.connection.connectDevice(); // session 2
        emit f.fake->stateChanged(2, ConnectionState::Connected, {});
        emit f.fake->boardInfoReceived(2, makeBoardInfo());
        QVERIFY(f.vm.boardInfo().deviceId.valid);
        emit f.fake->stateChanged(2, ConnectionState::Error, QStringLiteral("link lost"));
        QVERIFY(!f.vm.boardInfo().deviceId.valid);

        f.connection.connectDevice(); // a new session never starts with the old identity
        QVERIFY(!f.vm.boardInfo().deviceId.valid);
    }

    void becomesStale()
    {
        Fixture f;
        f.connect();
        emit f.fake->sampleReceived(1, makeSample(5, true, 30, true));
        QVERIFY(f.vm.pan().valid);
        QTRY_VERIFY_WITH_TIMEOUT(!f.vm.pan().valid, MainControlViewModel::kStaleAfterMs + 1000);
        QVERIFY(!f.vm.gimbalTemp().valid);
        QCOMPARE(f.vm.msSinceLastSample(), -1);
    }

};

QTEST_GUILESS_MAIN(tst_MainControlViewModel)
#include "tst_maincontrolviewmodel.moc"
