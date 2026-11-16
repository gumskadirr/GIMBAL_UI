#include <QSignalSpy>
#include <QTest>

#include "FakeProvider.h"
#include "device/presentation/DeviceViewModel.h"
#include "device/session/DeviceSession.h"
#include "shared/localization/Localization.h"

class tst_DeviceViewModel : public QObject
{
    Q_OBJECT

    struct Fixture {
        FakeProvider *fake = new FakeProvider;
        DeviceSession session{std::unique_ptr<IDeviceProvider>(fake)};
        DeviceViewModel vm{&session};

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
        QVERIFY(!f.vm.connected());
        QVERIFY(!f.vm.pan().valid);
        QVERIFY(!f.vm.gimbalTemp().valid);
        QCOMPARE(f.vm.connectionText(), QStringLiteral("Disconnected"));
        QCOMPARE(f.vm.msSinceLastSample(), -1);
    }

    void sampleUpdatesValues()
    {
        Fixture f;
        f.connect();
        QVERIFY(f.vm.connected());
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
        f.vm.connectDevice();
        QVERIFY(!f.vm.pan().valid);
        QVERIFY(!f.vm.gimbalTemp().valid);
        QVERIFY(f.vm.busy());
    }

    void disconnectInvalidates()
    {
        Fixture f;
        f.connect();
        emit f.fake->sampleReceived(1, makeSample(5, true, 30, true));
        f.vm.disconnectDevice();
        QVERIFY(!f.vm.pan().valid);
    }

    void errorExposed()
    {
        Fixture f;
        f.connect();
        emit f.fake->stateChanged(1, ConnectionState::Error, QStringLiteral("link lost"));
        QVERIFY(f.vm.hasError());
        QCOMPARE(f.vm.errorDetail(), QStringLiteral("link lost"));
        QCOMPARE(f.vm.connectionText(), QStringLiteral("Error"));
    }

    void noCommandsWithoutProtocol()
    {
        Fixture f;
        QVERIFY(!f.vm.commandsAvailable());
        f.connect();
        QVERIFY(f.vm.connected());
        QVERIFY(!f.vm.commandsAvailable()); // connected is not enough while there is no protocol
    }

    void everyFieldInvalidated()
    {
        Fixture f;
        f.connect();
        emit f.fake->sampleReceived(1, makeFullSample());
        QVERIFY(f.vm.tiltRef().valid && f.vm.supplyVoltage().valid && f.vm.safeControl().valid);
        QCOMPARE(f.vm.tilt().value, -8.204);
        f.vm.connectDevice(); // new session
        for (const Measurement &m : {f.vm.pan(), f.vm.panRef(), f.vm.tilt(), f.vm.tiltRef(), f.vm.gimbalTemp(),
                                     f.vm.imuTemp(), f.vm.supplyVoltage()})
            QVERIFY(!m.valid);
        QVERIFY(!f.vm.safeControl().valid);
    }

    void becomesStale()
    {
        Fixture f;
        f.connect();
        emit f.fake->sampleReceived(1, makeSample(5, true, 30, true));
        QVERIFY(f.vm.pan().valid);
        QTRY_VERIFY_WITH_TIMEOUT(!f.vm.pan().valid, DeviceViewModel::kStaleAfterMs + 1000);
        QVERIFY(!f.vm.gimbalTemp().valid);
        QCOMPARE(f.vm.msSinceLastSample(), -1);
    }

    void retranslateUpdatesText()
    {
        Fixture f;
        Localization l;
        QVERIFY(l.setLanguage("tr"));
        QSignalSpy spy(&f.vm, &DeviceViewModel::connectionChanged);
        f.vm.retranslate();
        QCOMPARE(spy.count(), 1);
        QCOMPARE(f.vm.connectionText(), QStringLiteral("Bağlantı yok"));
        l.setLanguage("en");
    }
};

QTEST_GUILESS_MAIN(tst_DeviceViewModel)
#include "tst_deviceviewmodel.moc"
