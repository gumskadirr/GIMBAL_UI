#include <QElapsedTimer>
#include <QSignalSpy>
#include <QTest>
#include <QThread>
#include <QTimer>

#include "FakeProvider.h"
#include "device/presentation/ServiceConnection.h"
#include "device/session/DeviceSession.h"
#include "features/telemetry/ScriptRunner.h"

// Answers every command at once (like the demo target).
class AnsweringProvider : public FakeProvider
{
public:
    Command::Status answer = Command::Accepted;
    void send(quint64 sessionId, quint64 requestId, const DeviceCommand &command) override
    {
        FakeProvider::send(sessionId, requestId, command);
        QTimer::singleShot(0, this, [this, sessionId, requestId] { emit commandFinished(sessionId, requestId, {answer, {}}); });
    }
};

class tst_ScriptRunner : public QObject
{
    Q_OBJECT

    struct Fixture {
        AnsweringProvider *fake = new AnsweringProvider;
        DeviceSession session{std::unique_ptr<IDeviceProvider>(fake)};
        ServiceConnection connection{&session};
        ScriptRunner runner{&connection};

        Fixture(int rows = 5, int sampleMs = 20)
        {
            fake->commands = true;
            session.connectDevice();
            emit fake->stateChanged(session.activeSessionId(), ConnectionState::Connected, {});
            QByteArray csv = "pan_deg,tilt_deg\n";
            for (int i = 0; i < rows; ++i)
                csv += QByteArray::number(i) + "," + QByteArray::number(-i) + "\n";
            runner.file()->loadData(csv);
            runner.setSampleMs(sampleMs);
        }
        bool waitDone() { return QTest::qWaitFor([this] { return !runner.running(); }, 5000); }
    };

private slots:
    void sendsOneCommandPerRowInTheSampleTime()
    {
        Fixture f(5, 20);
        QVERIFY(f.runner.start());
        QElapsedTimer t;
        t.start();
        QVERIFY(f.waitDone());
        const qint64 ms = t.elapsed();
        QCOMPARE(f.runner.state(), ScriptRunner::Done);
        QCOMPARE(f.fake->sent.size(), 5);
        QCOMPARE(f.runner.row(), 5);
        QCOMPARE(f.runner.percent(), 100);
        QVERIFY2(ms >= 75 && ms < 250, qPrintable(QString::number(ms))); // the last row is due at 4 * 20 ms
        for (int i = 0; i < 5; ++i) {
            QCOMPARE(f.fake->sent.at(i).kind, Command::ScriptPoint);
            QCOMPARE(f.fake->sent.at(i).args.value("pan").toDouble(), double(i));
            QCOMPARE(f.fake->sent.at(i).args.value("tilt").toDouble(), double(-i));
            QCOMPARE(f.fake->sent.at(i).args.value("type").toString(), QStringLiteral("position"));
        }
    }

    void offsetAndAxisChoice()
    {
        Fixture f(3, 5);
        f.runner.file()->setPanOffset(10);
        f.runner.setTiltEnabled(false);
        QVERIFY(f.runner.start());
        QVERIFY(f.waitDone());
        QCOMPARE(f.fake->sent.last().args.value("pan").toDouble(), 12.0);
        QVERIFY(!f.fake->sent.last().args.contains("tilt"));
        QVERIFY(!f.runner.commandTilt().valid);
        QCOMPARE(f.runner.commandPan().value, 12.0);
    }

    void stopMeansNoMoreCommands()
    {
        Fixture f(50, 20);
        QVERIFY(f.runner.start());
        QTest::qWait(50);
        f.runner.stop();
        QCOMPARE(f.runner.state(), ScriptRunner::Stopped);
        const int sent = int(f.fake->sent.size());
        QVERIFY(sent >= 1 && sent < 50);
        QTest::qWait(100);
        QCOMPARE(f.fake->sent.size(), sent);
    }

    void connectionLossStops()
    {
        Fixture f(50, 20);
        QSignalSpy lost(&f.runner, &ScriptRunner::connectionLost);
        QVERIFY(f.runner.start());
        QTest::qWait(30);
        emit f.fake->stateChanged(f.session.activeSessionId(), ConnectionState::Error, QStringLiteral("link down"));
        QCOMPARE(f.runner.state(), ScriptRunner::Stopped);
        QCOMPARE(lost.count(), 1);
        const int sent = int(f.fake->sent.size());
        QTest::qWait(60);
        QCOMPARE(f.fake->sent.size(), sent);
    }

    void refusedPointFails()
    {
        Fixture f(50, 5);
        f.fake->answer = Command::Rejected;
        QVERIFY(f.runner.start());
        QVERIFY(f.waitDone());
        QCOMPARE(f.runner.state(), ScriptRunner::Failed);
        QCOMPARE(f.fake->sent.size(), 1);
    }

    void lateRowsAreNotSkipped()
    {
        Fixture f(5, 1);
        QVERIFY(f.runner.start());
        QThread::msleep(30); // the event loop is blocked: every row is late
        QVERIFY(f.waitDone());
        QCOMPARE(f.fake->sent.size(), 5);
    }

    void remainingFollowsTheRowsNotTheClock()
    {
        Fixture f(10, 20);
        f.fake->answer = Command::Accepted;
        QCOMPARE(f.runner.remainingMs(), 200);
        QVERIFY(f.runner.start());
        QVERIFY(QTest::qWaitFor([&] { return f.runner.row() >= 4; }, 2000));
        QVERIFY(f.runner.running());
        const int row = f.runner.row();
        QCOMPARE(f.runner.remainingMs(), qint64(10 - row) * 20);
        QVERIFY(f.runner.remainingMs() > 0);
        f.runner.stop();
        QVERIFY(f.runner.remainingMs() > 0); // stopped: still the unsent rows
    }

    void cannotStartWithoutCommandsOrFile()
    {
        Fixture f;
        f.session.disconnectDevice();
        QVERIFY(!f.runner.canStart());
        QVERIFY(!f.runner.start());
        Fixture g(0);
        QVERIFY(!g.runner.canStart()); // no rows loaded
    }
};

QTEST_MAIN(tst_ScriptRunner)
#include "tst_scriptrunner.moc"
