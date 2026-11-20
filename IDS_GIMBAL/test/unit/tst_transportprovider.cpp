#include <QNetworkDatagram>
#include <QSignalSpy>
#include <QUdpSocket>
#include <QTest>

#include "device/transport/TransportProvider.h"

namespace {
ConnectionState stateOf(const QSignalSpy &spy, int i)
{
    return spy.at(i).at(1).value<ConnectionState>();
}

ConnectionTarget udp(const QString &host, quint16 port)
{
    ConnectionTarget t;
    t.transport = ConnectionTarget::Transport::Udp;
    t.host = host;
    t.port = port;
    return t;
}
} // namespace

// No hardware needed: failures use ports that do not exist, success uses UDP on the loopback address.
class tst_TransportProvider : public QObject
{
    Q_OBJECT

private slots:
    void noSerialPortSelected()
    {
        TransportProvider p;
        QSignalSpy states(&p, &IDeviceProvider::stateChanged);
        p.start(1, ConnectionTarget{});
        QCOMPARE(states.count(), 0); // never synchronously from start()
        QTRY_COMPARE(states.count(), 1);
        QCOMPARE(stateOf(states, 0), ConnectionState::Error);
        QCOMPARE(states.at(0).at(2).toString(), QStringLiteral("No serial port selected"));
    }

    void missingSerialPortFails()
    {
        TransportProvider p;
        QSignalSpy states(&p, &IDeviceProvider::stateChanged);
        ConnectionTarget t;
        t.serialPort = QStringLiteral("IDS_NO_SUCH_PORT");
        p.start(1, t);
        QCOMPARE(states.count(), 0);
        QTRY_COMPARE(states.count(), 1);
        QCOMPARE(stateOf(states, 0), ConnectionState::Error);
        QVERIFY(!states.at(0).at(2).toString().isEmpty()); // operating system text
    }

    void invalidUdpAddressFails()
    {
        TransportProvider p;
        QSignalSpy states(&p, &IDeviceProvider::stateChanged);
        p.start(1, udp(QStringLiteral("not an address"), 5000));
        QTRY_COMPARE(states.count(), 1);
        QCOMPARE(stateOf(states, 0), ConnectionState::Error);
        QCOMPARE(states.at(0).at(2).toString(), QStringLiteral("Invalid UDP address"));

        p.start(2, udp(QStringLiteral("127.0.0.1"), 0)); // port 0 is not a device port
        QTRY_COMPARE(states.count(), 2);
        QCOMPARE(stateOf(states, 1), ConnectionState::Error);
    }

    void udpLoopbackConnects()
    {
        TransportProvider p;
        QSignalSpy states(&p, &IDeviceProvider::stateChanged);
        p.start(7, udp(QStringLiteral("127.0.0.1"), 5000));
        QCOMPARE(states.count(), 0);
        QTRY_COMPARE(states.count(), 1);
        QCOMPARE(states.at(0).at(0).toULongLong(), 7u);
        QCOMPARE(stateOf(states, 0), ConnectionState::Connected);
        p.stop();
        p.stop(); // idempotent
    }

    // TX is what write() sends, RX what arrives; totals since start(), counted without any protocol.
    void udpTrafficIsCounted()
    {
        QUdpSocket peer;
        QVERIFY(peer.bind(QHostAddress::LocalHost, 0));
        TransportProvider p;
        QSignalSpy states(&p, &IDeviceProvider::stateChanged);
        QSignalSpy traffic(&p, &IDeviceProvider::trafficCounted);
        QVERIFY(!p.write("no link")); // nothing open yet
        p.start(3, udp(QStringLiteral("127.0.0.1"), peer.localPort()));
        QTRY_COMPARE(states.count(), 1);
        QVERIFY(p.write("abcd"));
        QCOMPARE(traffic.last().at(0).toULongLong(), 3u);
        QCOMPARE(traffic.last().at(1).toULongLong(), 4u);
        QCOMPARE(traffic.last().at(2).toULongLong(), 0u);

        QTRY_VERIFY(peer.hasPendingDatagrams());
        const QNetworkDatagram request = peer.receiveDatagram();
        peer.writeDatagram(QByteArray("hello!"), request.senderAddress(), request.senderPort());
        QTRY_COMPARE(traffic.last().at(2).toULongLong(), 6u);
        QCOMPARE(traffic.last().at(1).toULongLong(), 4u);

        p.stop();
        const int counted = traffic.count();
        QVERIFY(!p.write("closed"));
        QCOMPARE(traffic.count(), counted);
        p.start(4, udp(QStringLiteral("127.0.0.1"), peer.localPort())); // totals restart with the session
        QTRY_COMPARE(states.count(), 2);
        QVERIFY(p.write("x"));
        QCOMPARE(traffic.last().at(1).toULongLong(), 1u);
    }

    // A result of a session stopped before delivery must not be reported.
    void stopBeforeResultDropsIt()
    {
        TransportProvider p;
        QSignalSpy states(&p, &IDeviceProvider::stateChanged);
        p.start(1, udp(QStringLiteral("127.0.0.1"), 5000));
        p.stop();
        QTest::qWait(50);
        QCOMPARE(states.count(), 0);
    }
};

QTEST_GUILESS_MAIN(tst_TransportProvider)
#include "tst_transportprovider.moc"
