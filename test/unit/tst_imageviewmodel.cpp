#include <QSignalSpy>
#include <QTest>

#include "FakeProvider.h"
#include "device/presentation/ImageViewModel.h"
#include "device/session/DeviceSession.h"

class tst_ImageViewModel : public QObject
{
    Q_OBJECT

    struct Fixture {
        FakeProvider *fake = new FakeProvider;
        DeviceSession session{std::unique_ptr<IDeviceProvider>(fake)};
        ServiceConnection connection{&session};
        ImageViewModel vm{&session, &connection};

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
        QVERIFY(!f.vm.sample().fps.valid);
        QVERIFY(!f.vm.sample().status.valid);
    }

    void sampleShown()
    {
        Fixture f;
        f.connect();
        emit f.fake->imageSampleReceived(1, makeImageSample());
        QCOMPARE(f.vm.sample().fps.value, 30.0);
        QCOMPARE(f.vm.sample().mode.value, QStringLiteral("Locked"));
        QVERIFY(!f.vm.sample().lrfDistanceM.valid); // not available: stays invalid, never 0
    }

    void clearedWhenSessionEnds()
    {
        Fixture f;
        f.connect();
        emit f.fake->imageSampleReceived(1, makeImageSample());
        QSignalSpy changed(&f.vm, &ImageViewModel::sampleChanged);
        f.session.disconnectDevice();
        QCOMPARE(changed.count(), 1);
        QVERIFY(!f.vm.sample().fps.valid);

        f.connect();
        emit f.fake->imageSampleReceived(2, makeImageSample());
        f.connect(); // a new session starts clean
        QVERIFY(!f.vm.sample().fps.valid);
    }

    void staleSampleOfOldSessionDropped()
    {
        Fixture f;
        f.connect();
        f.connect(); // session 2
        emit f.fake->imageSampleReceived(1, makeImageSample());
        QVERIFY(!f.vm.sample().fps.valid);
    }

    void goesStaleWhenTelemetryStops()
    {
        Fixture f;
        f.connect();
        emit f.fake->imageSampleReceived(1, makeImageSample());
        QVERIFY(f.vm.sample().fps.valid);
        QTRY_VERIFY_WITH_TIMEOUT(!f.vm.sample().fps.valid, 3 * ImageViewModel::kStaleAfterMs);
    }
};

QTEST_MAIN(tst_ImageViewModel)
#include "tst_imageviewmodel.moc"
