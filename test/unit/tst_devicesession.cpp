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

    void boardInfoOfActiveSessionOnly()
    {
        Fixture f;
        QSignalSpy accepted(&f.session, &DeviceSession::boardInfoAccepted);
        f.session.connectDevice();
        emit f.fake->boardInfoReceived(1, makeBoardInfo());
        QCOMPARE(accepted.count(), 1);
        QCOMPARE(accepted.at(0).at(0).value<BoardInfo>().deviceId.value, QStringLiteral("0x1A42"));

        f.session.connectDevice(); // session 2
        emit f.fake->boardInfoReceived(1, makeBoardInfo()); // late answer of session 1
        QCOMPARE(accepted.count(), 1);
    }

    void targetPassedToProvider()
    {
        Fixture f;
        ConnectionTarget t;
        t.transport = ConnectionTarget::Transport::Udp;
        t.host = QStringLiteral("192.168.1.89");
        t.port = 5000;
        f.session.setTarget(t);
        f.session.connectDevice();
        QCOMPARE(f.fake->lastTarget.transport, ConnectionTarget::Transport::Udp);
        QCOMPARE(f.fake->lastTarget.host, QStringLiteral("192.168.1.89"));
        QCOMPARE(f.fake->lastTarget.port, quint16(5000));
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
        QCOMPARE(accepted.at(0).at(0).value<DeviceSample>().panDeg.value, 1.5);
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
    void commandNeedsConnectionAndSupport()
    {
        Fixture f;
        f.fake->commands = true;
        QCOMPARE(f.session.send({Command::RunBit, {}}), 0u); // not connected
        f.session.connectDevice();
        emit f.fake->stateChanged(1, ConnectionState::Connected, {});
        f.fake->commands = false;
        QCOMPARE(f.session.send({Command::RunBit, {}}), 0u); // provider has no commands
        QVERIFY(f.fake->sent.isEmpty());
    }

    void commandAnsweredOnce()
    {
        Fixture f;
        f.fake->commands = true;
        f.session.connectDevice();
        emit f.fake->stateChanged(1, ConnectionState::Connected, {});
        QSignalSpy finished(&f.session, &DeviceSession::commandFinished);
        const quint64 id = f.session.send({Command::StartBootBridge, {{QStringLiteral("board"), QStringLiteral("PMCB")}}});
        QVERIFY(id > 0);
        QCOMPARE(f.fake->lastCommandSessionId, 1u);
        QCOMPARE(f.fake->sent.at(0).args.value(QStringLiteral("board")).toString(), QStringLiteral("PMCB"));
        QCOMPARE(f.session.pendingCommands().size(), 1);

        emit f.fake->commandFinished(1, id, {Command::Rejected, QStringLiteral("busy")});
        emit f.fake->commandFinished(1, id, {Command::Accepted, {}}); // duplicate answer ignored
        QCOMPARE(finished.count(), 1);
        QCOMPARE(finished.at(0).at(2).value<CommandResult>().status, Command::Rejected);
        QCOMPARE(finished.at(0).at(1).value<DeviceCommand>().kind, Command::StartBootBridge);
        QVERIFY(f.session.pendingCommands().isEmpty());
    }

    void pendingCommandCancelledWhenSessionEnds()
    {
        Fixture f;
        f.fake->commands = true;
        f.session.connectDevice();
        emit f.fake->stateChanged(1, ConnectionState::Connected, {});
        QSignalSpy finished(&f.session, &DeviceSession::commandFinished);
        const quint64 a = f.session.send({Command::RunBit, {}});
        f.session.disconnectDevice();
        QCOMPARE(finished.count(), 1);
        QCOMPARE(finished.at(0).at(0).toULongLong(), a);
        QCOMPARE(finished.at(0).at(2).value<CommandResult>().status, Command::Cancelled);

        f.session.connectDevice(); // session 2
        emit f.fake->stateChanged(2, ConnectionState::Connected, {});
        f.session.send({Command::RunBit, {}});
        emit f.fake->stateChanged(2, ConnectionState::Error, QStringLiteral("link lost")); // link loss cancels too
        QCOMPARE(finished.count(), 2);
        QCOMPARE(finished.at(1).at(2).value<CommandResult>().status, Command::Cancelled);
    }

    void commandResultOfOldSessionDropped()
    {
        Fixture f;
        f.fake->commands = true;
        f.session.connectDevice();
        emit f.fake->stateChanged(1, ConnectionState::Connected, {});
        const quint64 id = f.session.send({Command::RunBit, {}});
        f.session.connectDevice(); // session 2; the command was cancelled
        QSignalSpy finished(&f.session, &DeviceSession::commandFinished);
        emit f.fake->commandFinished(1, id, {Command::Accepted, {}}); // late answer of session 1
        QCOMPARE(finished.count(), 0);
        QCOMPARE(f.session.staleDropped(), 1u);
    }
};

QTEST_GUILESS_MAIN(tst_DeviceSession)
#include "tst_devicesession.moc"
