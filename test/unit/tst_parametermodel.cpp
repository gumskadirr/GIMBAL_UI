#include <QFile>
#include <QSignalSpy>
#include <QTemporaryDir>
#include <QTest>

#include "DemoProvider.h"
#include "FakeProvider.h"
#include "device/api/ParameterKeys.h"
#include "device/presentation/ParameterModel.h"
#include "device/presentation/ServiceConnection.h"
#include "device/session/DeviceSession.h"

class tst_ParameterModel : public QObject
{
    Q_OBJECT

    struct Fixture {
        FakeProvider *fake = new FakeProvider;
        DeviceSession session{std::unique_ptr<IDeviceProvider>(fake)};
        ServiceConnection connection{&session};
        ParameterModel model{&session, &connection};

        Fixture()
        {
            fake->commands = true;
            session.connectDevice();
            emit fake->stateChanged(1, ConnectionState::Connected, {});
            emit fake->parametersReceived(1, {{QStringLiteral("pan.torqueKp"), 1.2},
                                              {QStringLiteral("pan.slipRing"), true},
                                              {QStringLiteral("tilt.modelSerial"), QStringLiteral("TM-2207")}});
        }
        void answer(Command::Status status = Command::Accepted)
        {
            emit fake->commandFinished(1, fake->lastRequestId, {status, {}});
        }
    };

    QTemporaryDir m_dir;
    QUrl file(const char *name) const { return QUrl::fromLocalFile(m_dir.filePath(QLatin1String(name))); }
    void writeFile(const char *name, const QByteArray &content)
    {
        QFile f(m_dir.filePath(QLatin1String(name)));
        QVERIFY(f.open(QIODevice::WriteOnly));
        f.write(content);
    }

private slots:
    void keysAreUniqueAndChecked()
    {
        QSet<QString> keys;
        for (const ParameterSpec &s : ParameterKeys::all())
            keys.insert(s.key);
        QCOMPARE(keys.size(), ParameterKeys::all().size());
        QVERIFY(keys.contains(QStringLiteral("tilt.trackerKd")));

        const auto border = *ParameterKeys::find(QStringLiteral("pan.forwardBorderDeg"));
        QCOMPARE(ParameterKeys::normalized(border, 180), QVariant(180.0));
        QVERIFY(!ParameterKeys::normalized(border, 180.5).isValid());
        QVERIFY(!ParameterKeys::normalized(border, QStringLiteral("12")).isValid()); // text is never parsed
        QVERIFY(!ParameterKeys::normalized(border, qQNaN()).isValid());
        const auto phase = *ParameterKeys::find(QStringLiteral("pan.phaseRotation"));
        QVERIFY(!ParameterKeys::normalized(phase, 1.5).isValid());
        QCOMPARE(ParameterKeys::normalized(phase, 5.0), QVariant(5));
    }

    void editCountAndRevert()
    {
        Fixture f;
        QCOMPARE(f.model.unsavedCount(), 0);
        QVERIFY(f.model.set(QStringLiteral("pan.torqueKp"), 2.5));
        QVERIFY(f.model.set(QStringLiteral("pan.speedKi"), 0.3)); // no device value yet: still an edit
        QCOMPARE(f.model.unsavedCount(), 2);
        QCOMPARE(f.model.values().value(QStringLiteral("pan.torqueKp")), QVariant(2.5));
        QCOMPARE(f.model.deviceValues().value(QStringLiteral("pan.torqueKp")), QVariant(1.2));

        QVERIFY(f.model.set(QStringLiteral("pan.torqueKp"), 1.2)); // back to the device value
        QCOMPARE(f.model.unsavedCount(), 1);
        QVERIFY(!f.model.set(QStringLiteral("pan.torqueKp"), -1)); // out of range
        QVERIFY(!f.model.set(QStringLiteral("pan.nope"), 1));       // unknown key
        QCOMPARE(f.model.unsavedCount(), 1);

        f.model.revert(QStringLiteral("pan.speedKi"));
        QCOMPARE(f.model.unsavedCount(), 0);
        f.model.set(QStringLiteral("pan.slipRing"), false);
        f.model.revertAll();
        QCOMPARE(f.model.values().value(QStringLiteral("pan.slipRing")), QVariant(true));
    }

    void writeClearsAcceptedEdits()
    {
        Fixture f;
        f.model.set(QStringLiteral("pan.torqueKp"), 2.5);
        QVERIFY(f.model.write());
        QCOMPARE(f.fake->sent.last().kind, Command::WriteParameters);
        QCOMPARE(f.fake->sent.last().args.value(QStringLiteral("values")).toMap(),
                 (QVariantMap{{QStringLiteral("pan.torqueKp"), 2.5}}));
        QCOMPARE(f.model.unsavedCount(), 1); // until the device accepts it
        f.answer();
        QCOMPARE(f.model.unsavedCount(), 0);
        QCOMPARE(f.model.deviceValues().value(QStringLiteral("pan.torqueKp")), QVariant(2.5));

        f.model.set(QStringLiteral("pan.torqueKp"), 3.0);
        f.model.write();
        f.answer(Command::Rejected);
        QCOMPARE(f.model.unsavedCount(), 1); // a refused write keeps the edit
        QVERIFY(!Fixture().model.write());   // nothing to write
    }

    void sessionEndKeepsEditsDropsDeviceValues()
    {
        Fixture f;
        f.model.set(QStringLiteral("pan.torqueKp"), 2.5);
        f.connection.disconnectDevice();
        QVERIFY(f.model.deviceValues().isEmpty());
        QCOMPARE(f.model.unsavedCount(), 1);
        QVERIFY(!f.model.read()); // no commands while disconnected
    }

    void profileRoundTrip()
    {
        Fixture f;
        f.model.set(QStringLiteral("pan.torqueKp"), 2.5);
        f.model.set(QStringLiteral("pan.phaseRotation"), 3);
        QVERIFY(f.model.saveProfile(file("profile.json")));
        QCOMPARE(f.model.profileFile(), file("profile.json"));

        Fixture g; // another device state: the file's differences become unsaved edits, nothing is sent
        const int sentBefore = int(g.fake->sent.size());
        QVERIFY(g.model.loadProfile(file("profile.json")));
        QCOMPARE(g.fake->sent.size(), sentBefore);
        QCOMPARE(g.model.values(), f.model.values());
        QCOMPARE(g.model.values().value(QStringLiteral("pan.phaseRotation")).typeId(), QMetaType::Int);
        QCOMPARE(g.model.unsavedCount(), 2); // pan.slipRing and tilt.modelSerial equal the device
    }

    void badProfileRejected_data()
    {
        QTest::addColumn<QByteArray>("content");
        QTest::newRow("not json") << QByteArray("{ nope");
        QTest::newRow("other format") << QByteArray(R"({"format":"x","version":1,"values":{"pan.torqueKp":1}})");
        QTest::newRow("newer version") << QByteArray(R"({"format":"ids-gimbal-parameters","version":2,"values":{"pan.torqueKp":1}})");
        QTest::newRow("unknown key") << QByteArray(R"({"format":"ids-gimbal-parameters","version":1,"values":{"pan.x":1}})");
        QTest::newRow("out of range") << QByteArray(R"({"format":"ids-gimbal-parameters","version":1,"values":{"pan.forwardBorderDeg":400}})");
        QTest::newRow("wrong type") << QByteArray(R"({"format":"ids-gimbal-parameters","version":1,"values":{"pan.slipRing":"yes"}})");
        QTest::newRow("empty") << QByteArray(R"({"format":"ids-gimbal-parameters","version":1,"values":{}})");
    }

    void badProfileRejected()
    {
        QFETCH(QByteArray, content);
        writeFile("bad.json", content);
        Fixture f;
        f.model.set(QStringLiteral("pan.torqueKp"), 2.5);
        QSignalSpy failed(&f.model, &ParameterModel::profileFailed);
        QVERIFY(!f.model.loadProfile(file("bad.json")));
        QCOMPARE(failed.count(), 1);
        QCOMPARE(f.model.unsavedCount(), 1); // nothing changed
        QVERIFY(f.model.profileFile().isEmpty());
        QVERIFY(!f.model.loadProfile(file("missing.json")));
    }

    void demoProviderBehavesLikeDevice()
    {
        DeviceSession session{std::make_unique<DemoProvider>(10, 100000, 10)};
        ServiceConnection connection{&session};
        ParameterModel model{&session, &connection};
        connection.connectDevice();
        QTRY_VERIFY(connection.connected());
        QVERIFY(model.read());
        QTRY_COMPARE(model.deviceValues().size(), ParameterKeys::all().size());
        model.set(QStringLiteral("tilt.speedKp"), 4.0);
        QVERIFY(model.write());
        QTRY_COMPARE(model.unsavedCount(), 0);
        QVERIFY(model.restoreDefaults());
        QTRY_COMPARE(model.deviceValues().value(QStringLiteral("tilt.speedKp")), QVariant(0.8));
    }
};

QTEST_GUILESS_MAIN(tst_ParameterModel)
#include "tst_parametermodel.moc"
