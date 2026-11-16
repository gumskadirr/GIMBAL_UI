#include <QSignalSpy>
#include <QTest>

#include "FakeProvider.h"
#include "device/session/DeviceSession.h"

class tst_DeviceSession : public QObject
{
    Q_OBJECT

    struct Fixture {
        FakeProvider *fake = new FakeProvider;
        DeviceSession session{std::unique_ptr<IDeviceProvider>(fake)};
    };

private slots:
    void startsDisconnected()
    {
        Fixture f;
        QCOMPARE(f.session.state(), ConnectionState::Disconnected);
        QCOMPARE(f.session.activeSessionId(), 0u);
    }

    void connectStartsNewSession()
    {
        Fixture f;
        QSignalSpy started(&f.session, &DeviceSession::sessionStarted);
        f.session.connectDevice();
        QCOMPARE(f.session.state(), ConnectionState::Connecting);
        QCOMPARE(f.fake->lastSessionId, 1u);
        QCOMPARE(started.count(), 1);

        f.session.connectDevice(); // reconnect closes the old session first
        QCOMPARE(f.fake->stops, 1);
        QCOMPARE(f.fake->lastSessionId, 2u);
        QCOMPARE(f.session.activeSessionId(), 2u);
    }

    void connectedAndSampleAccepted()
    {
        Fixture f;
        f.session.connectDevice();
        emit f.fake->stateChanged(1, ConnectionState::Connected, {});
        QCOMPARE(f.session.state(), ConnectionState::Connected);

        QSignalSpy accepted(&f.session, &DeviceSession::sampleAccepted);
        emit f.fake->sampleReceived(1, makeSample(1.5, true, 30, true));
        QCOMPARE(accepted.count(), 1);
        QCOMPARE(accepted.at(0).at(0).value<DeviceSample>().angleDeg.value, 1.5);
    }

    void staleSampleDropped()
    {
        Fixture f;
        f.session.connectDevice();
        f.session.connectDevice();
        QSignalSpy accepted(&f.session, &DeviceSession::sampleAccepted);
        emit f.fake->sampleReceived(1, makeSample(9, true, 9, true));
        QCOMPARE(accepted.count(), 0);
        QCOMPARE(f.session.staleDropped(), 1u);
    }

    void lateConnectedAfterDisconnectIgnored()
    {
        Fixture f;
        f.session.connectDevice();
        f.session.disconnectDevice();
        emit f.fake->stateChanged(1, ConnectionState::Connected, {});
        QCOMPARE(f.session.state(), ConnectionState::Disconnected);
        QCOMPARE(f.session.staleDropped(), 1u);
    }

    void providerErrorClosesSession()
    {
        Fixture f;
        f.session.connectDevice();
        emit f.fake->stateChanged(1, ConnectionState::Error, QStringLiteral("boom"));
        QCOMPARE(f.session.state(), ConnectionState::Error);
        QCOMPARE(f.session.detail(), QStringLiteral("boom"));
        QCOMPARE(f.session.activeSessionId(), 0u);
        QCOMPARE(f.fake->stops, 1);

        emit f.fake->sampleReceived(1, makeSample(1, true, 1, true));
        QCOMPARE(f.session.staleDropped(), 1u);
    }

    void disconnectWhenIdleIsHarmless()
    {
        Fixture f;
        QSignalSpy changed(&f.session, &DeviceSession::stateChanged);
        f.session.disconnectDevice();
        QCOMPARE(changed.count(), 0);
        QCOMPARE(f.fake->stops, 0);
    }
};

QTEST_GUILESS_MAIN(tst_DeviceSession)
#include "tst_devicesession.moc"
