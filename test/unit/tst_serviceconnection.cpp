#include <QSignalSpy>
#include <QTest>

#include "FakeProvider.h"
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
