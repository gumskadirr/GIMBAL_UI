#include "TransportProvider.h"

#include <QHostAddress>
#include <QNetworkDatagram>
#include <QTimer>

TransportProvider::TransportProvider(QObject *parent) : IDeviceProvider(parent)
{
    // A port that disappears while open (cable pulled, device reset) ends the session.
    connect(&m_serial, &QSerialPort::errorOccurred, this, [this](QSerialPort::SerialPortError error) {
        if (!m_open || error == QSerialPort::NoError)
            return;
        const quint64 id = m_sessionId;
        const QString detail = m_serial.errorString();
        stop();
        emit stateChanged(id, ConnectionState::Error, detail);
    });
    connect(&m_udp, &QUdpSocket::errorOccurred, this, [this](QAbstractSocket::SocketError) {
        if (!m_open)
            return;
        const quint64 id = m_sessionId;
        const QString detail = m_udp.errorString();
        stop();
        emit stateChanged(id, ConnectionState::Error, detail);
    });

    // No protocol yet: incoming bytes are only counted (traffic LEDs, data rate) and dropped.
    connect(&m_serial, &QSerialPort::readyRead, this, [this] { count(0, m_serial.readAll().size()); });
    connect(&m_udp, &QUdpSocket::readyRead, this, [this] {
        while (m_udp.hasPendingDatagrams())
            count(0, m_udp.receiveDatagram().data().size());
    });
}

TransportProvider::~TransportProvider()
{
    stop();
}

void TransportProvider::start(quint64 sessionId, const ConnectionTarget &target)
{
    stop();
    m_sessionId = sessionId;
    m_tx = m_rx = 0;
    const QString error = target.transport == ConnectionTarget::Transport::Serial ? openSerial(target)
                                                                                    : openUdp(target);
    m_open = error.isEmpty();
    // Results are never emitted from inside start() (IDeviceProvider contract).
    QTimer::singleShot(0, this, [this, sessionId, error] {
        if (m_sessionId != sessionId)
            return; // stopped or restarted before the result was delivered
        if (!error.isEmpty())
            m_sessionId = 0;
        emit stateChanged(sessionId, error.isEmpty() ? ConnectionState::Connected : ConnectionState::Error, error);
    });
}

bool TransportProvider::write(const QByteArray &bytes)
{
    if (!m_open)
        return false;
    const qint64 written = m_serial.isOpen() ? m_serial.write(bytes) : m_udp.write(bytes);
    if (written > 0)
        count(written, 0);
    return written == bytes.size();
}

void TransportProvider::count(quint64 tx, quint64 rx)
{
    if (!m_open)
        return;
    m_tx += tx;
    m_rx += rx;
    emit trafficCounted(m_sessionId, m_tx, m_rx);
}

void TransportProvider::stop()
{
    m_open = false;
    m_sessionId = 0;
    if (m_serial.isOpen())
        m_serial.close();
    if (m_udp.state() != QAbstractSocket::UnconnectedState)
        m_udp.abort();
}

QString TransportProvider::openSerial(const ConnectionTarget &target)
{
    if (target.serialPort.isEmpty())
        return QString::fromUtf8(QT_TRANSLATE_NOOP("Detail", "No serial port selected"));
    m_serial.setPortName(target.serialPort);
    m_serial.setBaudRate(target.baudRate);
    m_serial.setDataBits(target.dataBits == 7 ? QSerialPort::Data7 : QSerialPort::Data8);
    m_serial.setStopBits(target.stopBits == 2 ? QSerialPort::TwoStop : QSerialPort::OneStop);
    m_serial.setParity(target.parity == ConnectionTarget::Parity::Even ? QSerialPort::EvenParity
                       : target.parity == ConnectionTarget::Parity::Odd ? QSerialPort::OddParity
                                                                         : QSerialPort::NoParity);
    m_serial.setFlowControl(QSerialPort::NoFlowControl);
    if (!m_serial.open(QIODevice::ReadWrite))
        return m_serial.errorString(); // raw OS text, shown as the detail
    return {};
}

QString TransportProvider::openUdp(const ConnectionTarget &target)
{
    const QHostAddress address(target.host);
    if (address.isNull() || target.port == 0)
        return QString::fromUtf8(QT_TRANSLATE_NOOP("Detail", "Invalid UDP address"));
    if (!m_udp.bind(address.protocol() == QAbstractSocket::IPv6Protocol ? QHostAddress::AnyIPv6
                                                                        : QHostAddress::AnyIPv4,
                    0))
        return m_udp.errorString();
    m_udp.connectToHost(address, target.port); // default peer of the session; UDP itself has no handshake
    return {};
}
