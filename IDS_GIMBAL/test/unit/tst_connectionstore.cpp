#include <QDir>
#include <QSettings>
#include <QSignalSpy>
#include <QTemporaryDir>
#include <QTest>

#include "device/session/ConnectionStore.h"

class tst_ConnectionStore : public QObject
{
    Q_OBJECT

    QTemporaryDir m_dir;
    QString path() const { return m_dir.filePath(QStringLiteral("settings.ini")); }

    static ConnectionTarget serialTarget()
    {
        ConnectionTarget t;
        t.serialPort = QStringLiteral("COM3");
        t.baudRate = 921600;
        t.dataBits = 7;
        t.parity = ConnectionTarget::Parity::Even;
        t.stopBits = 2;
        return t;
    }

private slots:
    void init() { QFile::remove(path()); }

    void nothingSavedGivesNoTarget()
    {
        ConnectionStore store(path());
        QVERIFY(!store.load(QStringLiteral("mainControl")).has_value());
    }

    void serialRoundTrip()
    {
        QVERIFY(ConnectionStore(path()).save(QStringLiteral("mainControl"), serialTarget()));
        const auto t = ConnectionStore(path()).load(QStringLiteral("mainControl"));
        QVERIFY(t.has_value());
        QCOMPARE(t->transport, ConnectionTarget::Transport::Serial);
        QCOMPARE(t->serialPort, QStringLiteral("COM3"));
        QCOMPARE(t->baudRate, 921600);
        QCOMPARE(t->dataBits, 7);
        QCOMPARE(t->parity, ConnectionTarget::Parity::Even);
        QCOMPARE(t->stopBits, 2);
    }

    // Switching the transport leaves no values of the old one behind; services are independent.
    void udpReplacesSerialPerService()
    {
        ConnectionStore store(path());
        store.save(QStringLiteral("mainControl"), serialTarget());
        store.save(QStringLiteral("idsImage"), serialTarget());
        ConnectionTarget udp;
        udp.transport = ConnectionTarget::Transport::Udp;
        udp.host = QStringLiteral("192.168.1.89");
        udp.port = 5000;
        QVERIFY(store.save(QStringLiteral("mainControl"), udp));

        const auto t = store.load(QStringLiteral("mainControl"));
        QVERIFY(t.has_value());
        QCOMPARE(t->transport, ConnectionTarget::Transport::Udp);
        QCOMPARE(t->host, QStringLiteral("192.168.1.89"));
        QCOMPARE(t->port, quint16(5000));
        QVERIFY(!QSettings(path(), QSettings::IniFormat).contains(QStringLiteral("connection/mainControl/serialPort")));
        QCOMPARE(store.load(QStringLiteral("idsImage"))->transport, ConnectionTarget::Transport::Serial);
    }

    void invalidStoredValuesIgnored()
    {
        {
            QSettings raw(path(), QSettings::IniFormat);
            raw.setValue(QStringLiteral("connection/a/transport"), QStringLiteral("tcp"));
            raw.setValue(QStringLiteral("connection/b/transport"), QStringLiteral("serial")); // no port
            raw.setValue(QStringLiteral("connection/c/transport"), QStringLiteral("udp"));
            raw.setValue(QStringLiteral("connection/c/host"), QStringLiteral("10.0.0.2"));
            raw.setValue(QStringLiteral("connection/c/port"), 70000);
        }
        ConnectionStore store(path());
        QVERIFY(!store.load(QStringLiteral("a")).has_value());
        QVERIFY(!store.load(QStringLiteral("b")).has_value());
        QVERIFY(!store.load(QStringLiteral("c")).has_value());
    }

    void writeFailureReported()
    {
        // A directory cannot be written as a settings file (see tst_appsettings).
        ConnectionStore store(m_dir.path());
        QSignalSpy failed(&store, &ConnectionStore::writeFailed);
        QVERIFY(!store.save(QStringLiteral("mainControl"), serialTarget()));
        QCOMPARE(failed.count(), 1);
        QCOMPARE(failed.at(0).at(0).toString(), QStringLiteral("mainControl"));
    }
};

QTEST_GUILESS_MAIN(tst_ConnectionStore)
#include "tst_connectionstore.moc"
