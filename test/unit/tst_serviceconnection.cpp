#include <QSignalSpy>
#include <QTest>

#include "DemoProvider.h"
#include "FakeProvider.h"
#include "device/transport/TransportProvider.h"
#include "device/presentation/ServiceConnection.h"
#include "device/session/DeviceSession.h"
#include "shared/localization/Localization.h"

class tst_ServiceConnection : public QObject
{
    Q_OBJECT

    struct Fixture {
        FakeProvider *fake = new FakeProvider;
        DeviceSession session{std::unique_ptr<IDeviceProvider>(fake)};
        ServiceConnection vm{&session};

        void connect()
        {
            session.connectDevice();
            emit fake->stateChanged(session.activeSessionId(), ConnectionState::Connected, {});
        }
    };

private slots:
    // Two services: both connected at once; cutting one leaves the other connected.
    void twoConnectionsAreIndependent()
    {
        Fixture main, image;
        main.connect();
        image.connect();
        QVERIFY(main.vm.connected() && image.vm.connected());
        image.session.disconnectDevice();
        QVERIFY(!image.vm.connected());
        QVERIFY(main.vm.connected());
        QCOMPARE(main.fake->stops, 0);
    }

    void trafficActivityAndRate()
    {
        Fixture f;
        f.connect();
        const quint64 id = f.session.activeSessionId();
        QSignalSpy changed(&f.vm, &ServiceConnection::trafficChanged);
        QVERIFY(!f.vm.txActive() && !f.vm.rxActive());
        QCOMPARE(f.vm.dataRateBps(), 0.0);

        emit f.fake->trafficCounted(id, 100, 12500);
        QTRY_VERIFY(f.vm.rxActive());
        QVERIFY(f.vm.txActive());
        QCOMPARE(f.vm.txBytes(), 100.0);
        QCOMPARE(f.vm.rxBytes(), 12500.0);
        QTRY_VERIFY(f.vm.dataRateBps() > 0.0);

        QTRY_VERIFY(!f.vm.rxActive()); // no new byte: the LED goes out after kActiveMs
        QVERIFY(!f.vm.txActive());
        emit f.fake->trafficCounted(id, 100, 12600); // only RX grows
        QTRY_VERIFY(f.vm.rxActive());
        QVERIFY(!f.vm.txActive());
        QTRY_COMPARE_WITH_TIMEOUT(f.vm.dataRateBps(), 0.0, 3000); // the window empties
        QVERIFY(changed.count() > 0);
    }

    void trafficOfOldSessionIsDropped()
    {
        Fixture f;
        f.connect();
        const int before = f.vm.staleDropped();
        emit f.fake->trafficCounted(f.session.activeSessionId() + 7, 5, 5);
        QCOMPARE(f.vm.txBytes(), 0.0);
        QCOMPARE(f.vm.staleDropped(), before + 1);
    }

    void pendingCommandNamesAreRawKinds()
    {
        Fixture f;
        f.fake->commands = true;
        f.connect();
        QVERIFY(f.vm.send(Command::RunBit));
        QCOMPARE(f.vm.pendingCommandNames(), QStringList{QStringLiteral("RunBit")});
    }

    void progressFollowsTheRunningCommand()
    {
        Fixture f;
        f.fake->commands = true;
        f.connect();
        QCOMPARE(f.vm.progressKind(), -1);
        QVERIFY(f.vm.send(Command::UpdateFirmware));
        QSignalSpy changed(&f.vm, &ServiceConnection::progressChanged);
        emit f.fake->commandProgress(1, f.fake->lastRequestId, 40, QStringLiteral("Writing"));
        QCOMPARE(f.vm.progressKind(), int(Command::UpdateFirmware));
        QCOMPARE(f.vm.progressPercent(), 40);
        QCOMPARE(f.vm.progressStage(), QStringLiteral("Writing"));
        QCOMPARE(changed.count(), 1);
        emit f.fake->commandFinished(1, f.fake->lastRequestId, {Command::Accepted, {}});
        QCOMPARE(f.vm.progressKind(), -1);
        QCOMPARE(f.vm.progressPercent(), 0);
        QVERIFY(f.vm.progressStage().isEmpty());
        QCOMPARE(changed.count(), 2);
    }

    void progressResetsWhenTheSessionEnds()
    {
        Fixture f;
        f.fake->commands = true;
        f.connect();
        QVERIFY(f.vm.send(Command::UpdateFirmware));
        emit f.fake->commandProgress(1, f.fake->lastRequestId, 70, {});
        f.vm.disconnectDevice(); // pending commands finish as Cancelled
        QCOMPARE(f.vm.progressKind(), -1);
        QCOMPARE(f.vm.progressPercent(), 0);
    }

    void firmwareUpdateCancelledWhenTheLinkDrops()
    {
        Fixture f;
        f.fake->commands = true;
        f.connect();
        QSignalSpy finished(&f.vm, &ServiceConnection::commandFinished);
        QVERIFY(f.vm.send(Command::UpdateFirmware));
        emit f.fake->stateChanged(1, ConnectionState::Disconnected, {}); // the link drops, no user action
        QCOMPARE(finished.size(), 1);
        QCOMPARE(finished.at(0).at(0).toInt(), int(Command::UpdateFirmware));
        QCOMPARE(finished.at(0).at(1).toInt(), int(Command::Cancelled));
        QVERIFY(f.vm.pendingCommands().isEmpty());
    }

    void startsDisconnected()
    {
        Fixture f;
        QVERIFY(!f.vm.connected());
        QCOMPARE(f.vm.statusText(), QStringLiteral("Disconnected"));
    }

    void errorExposed()
    {
        Fixture f;
        f.connect();
        emit f.fake->stateChanged(1, ConnectionState::Error, QStringLiteral("link lost"));
        QVERIFY(f.vm.hasError());
        QCOMPARE(f.vm.errorDetail(), QStringLiteral("link lost"));
        QCOMPARE(f.vm.statusText(), QStringLiteral("Error"));
    }

    void noCommandsWithoutProtocol()
    {
        Fixture f;
        QVERIFY(!f.vm.commandsAvailable());
        f.connect();
        QVERIFY(f.vm.connected());
        QVERIFY(!f.vm.commandsAvailable()); // connected is not enough while there is no protocol
        QVERIFY(!f.vm.send(Command::RunBit));
        QVERIFY(f.fake->sent.isEmpty());
    }

    void commandBusyUntilAnswered()
    {
        Fixture f;
        f.fake->commands = true;
        f.connect();
        QVERIFY(f.vm.commandsAvailable());
        QSignalSpy finished(&f.vm, &ServiceConnection::commandFinished);
        QVERIFY(f.vm.send(Command::RunBit));
        QCOMPARE(f.vm.pendingCommands(), QList<int>{Command::RunBit});
        QVERIFY(!f.vm.send(Command::RunBit)); // pressed again while waiting
        QVERIFY(!f.vm.send(9999));            // not a command kind
        QCOMPARE(f.fake->sent.size(), 1);

        emit f.fake->commandFinished(1, f.fake->lastRequestId, {Command::Failed, QStringLiteral("timeout")});
        QVERIFY(f.vm.pendingCommands().isEmpty());
        QCOMPARE(finished.count(), 1);
        QCOMPARE(finished.at(0).at(0).toInt(), int(Command::RunBit));
        QCOMPARE(finished.at(0).at(1).toInt(), int(Command::Failed));
        QCOMPARE(finished.at(0).at(2).toString(), QStringLiteral("timeout"));
    }

    // Demo target: commands are mocked and accepted; real target: no protocol, so buttons stay disabled.
    void demoTargetHasCommandsRealTargetHasNot()
    {
        DeviceSession demoSession{std::make_unique<DemoProvider>(10, 1000, 10)};
        ServiceConnection demo{&demoSession};
        demo.connectDevice();
        QTRY_VERIFY(demo.connected());
        QVERIFY(demo.commandsAvailable());
        QSignalSpy finished(&demo, &ServiceConnection::commandFinished);
        QVERIFY(demo.send(Command::AskBootloader));
        QTRY_COMPARE(finished.count(), 1);
        QCOMPARE(finished.at(0).at(1).toInt(), int(Command::Accepted));

        DeviceSession realSession{std::make_unique<TransportProvider>()};
        QVERIFY(!realSession.supportsCommands());
        ServiceConnection real{&realSession};
        QVERIFY(!real.commandsAvailable());
    }

    void connectionSettingsFromUi()
    {
        Fixture f;
        QVERIFY(!f.vm.configured());
        QCOMPARE(f.vm.summary(), QStringLiteral("Not configured"));
        QSignalSpy applied(&f.vm, &ServiceConnection::applied);

        f.vm.apply({{QStringLiteral("transport"), QStringLiteral("serial")},
                              {QStringLiteral("serialPort"), QStringLiteral("COM3")},
                              {QStringLiteral("baudRate"), 115200},
                              {QStringLiteral("dataBits"), 8},
                              {QStringLiteral("parity"), QStringLiteral("none")},
                              {QStringLiteral("stopBits"), 1}});
        QCOMPARE(applied.count(), 1);
        QCOMPARE(f.fake->lastTarget.serialPort, QStringLiteral("COM3")); // connected with the new target
        QVERIFY(f.vm.busy());
        QCOMPARE(f.vm.summary(), QStringLiteral("UART · COM3 · 115200 8N1"));

        const QVariantMap map = f.vm.target();
        QCOMPARE(map.value(QStringLiteral("transport")).toString(), QStringLiteral("serial"));
        QCOMPARE(map.value(QStringLiteral("parity")).toString(), QStringLiteral("none"));

        f.vm.apply({{QStringLiteral("transport"), QStringLiteral("udp")},
                              {QStringLiteral("host"), QStringLiteral(" 192.168.1.89 ")},
                              {QStringLiteral("port"), 5000}});
        QCOMPARE(f.vm.summary(), QStringLiteral("IP/UDP · 192.168.1.89:5000"));
        QCOMPARE(f.fake->lastTarget.host, QStringLiteral("192.168.1.89"));
        QVERIFY(f.vm.configured());
    }

    void retranslateUpdatesText()
    {
        Fixture f;
        Localization l;
        QVERIFY(l.setLanguage("tr"));
        QSignalSpy spy(&f.vm, &ServiceConnection::changed);
        f.vm.retranslate();
        QCOMPARE(spy.count(), 1);
        QCOMPARE(f.vm.statusText(), QStringLiteral("Bağlantı yok"));
        l.setLanguage("en");
    }
};

QTEST_GUILESS_MAIN(tst_ServiceConnection)
#include "tst_serviceconnection.moc"
