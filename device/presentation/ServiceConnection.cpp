#include "ServiceConnection.h"

#include "device/session/DeviceSession.h"

#include <QCoreApplication>
#include <QMetaEnum>
#include <QSerialPortInfo>

ServiceConnection::ServiceConnection(DeviceSession *session, QObject *parent)
    : QObject(parent), m_session(session)
{
    connect(m_session, &DeviceSession::stateChanged, this, &ServiceConnection::changed);
    connect(m_session, &DeviceSession::pendingChanged, this, &ServiceConnection::pendingChanged);
    connect(m_session, &DeviceSession::commandFinished, this,
            [this](quint64, const DeviceCommand &command, const CommandResult &result) {
                emit commandFinished(command.kind, result.status, result.detail);
            });
}

bool ServiceConnection::commandsAvailable() const { return connected() && m_session->supportsCommands(); }

QList<int> ServiceConnection::pendingCommands() const
{
    QList<int> kinds;
    for (const DeviceCommand &c : m_session->pendingCommands())
        kinds << c.kind;
    return kinds;
}

bool ServiceConnection::send(int kind, const QVariantMap &args)
{
    if (!commandsAvailable() || pendingCommands().contains(kind)
        || !QMetaEnum::fromType<Command::Kind>().valueToKey(kind))
        return false;
    return m_session->send({Command::Kind(kind), args}) != 0;
}

QString ServiceConnection::statusText() const
{
    switch (m_session->state()) {
    case ConnectionState::Disconnected: return tr("Disconnected");
    case ConnectionState::Connecting: return tr("Connecting");
    case ConnectionState::Connected: return tr("Connected");
    case ConnectionState::Error: return tr("Error");
    }
    return {};
}

bool ServiceConnection::connected() const { return m_session->state() == ConnectionState::Connected; }
bool ServiceConnection::busy() const { return m_session->state() == ConnectionState::Connecting; }
bool ServiceConnection::hasError() const { return m_session->state() == ConnectionState::Error; }
QString ServiceConnection::errorDetail() const
{
    // Same "Detail" context as NotificationModel: raw device text has no entry and stays as is.
    return QCoreApplication::translate("Detail", m_session->detail().toUtf8().constData());
}

QString ServiceConnection::summary() const
{
    const ConnectionTarget t = m_session->target();
    if (!t.configured())
        return tr("Not configured");
    if (t.transport == ConnectionTarget::Transport::Udp)
        return QStringLiteral("IP/UDP · %1:%2").arg(t.host).arg(t.port);
    const QChar parity = parityName(t.parity).at(0).toUpper(); // N / E / O
    return QStringLiteral("UART · %1 · %2 %3%4%5").arg(t.serialPort).arg(t.baudRate).arg(t.dataBits).arg(parity).arg(t.stopBits);
}

bool ServiceConnection::configured() const { return m_session->target().configured(); }

QVariantMap ServiceConnection::target() const
{
    const ConnectionTarget t = m_session->target();
    return {
        {QStringLiteral("transport"), t.transport == ConnectionTarget::Transport::Udp ? QStringLiteral("udp") : QStringLiteral("serial")},
        {QStringLiteral("serialPort"), t.serialPort},
        {QStringLiteral("baudRate"), t.baudRate},
        {QStringLiteral("dataBits"), t.dataBits},
        {QStringLiteral("parity"), parityName(t.parity)},
        {QStringLiteral("stopBits"), t.stopBits},
        {QStringLiteral("host"), t.host},
        {QStringLiteral("port"), int(t.port)},
    };
}

void ServiceConnection::apply(const QVariantMap &settings)
{
    ConnectionTarget t;
    t.transport = settings.value(QStringLiteral("transport")).toString() == QLatin1String("udp")
                      ? ConnectionTarget::Transport::Udp
                      : ConnectionTarget::Transport::Serial;
    t.serialPort = settings.value(QStringLiteral("serialPort")).toString();
    t.baudRate = settings.value(QStringLiteral("baudRate"), t.baudRate).toInt();
    t.dataBits = settings.value(QStringLiteral("dataBits"), t.dataBits).toInt() == 7 ? 7 : 8;
    t.parity = parityFromName(settings.value(QStringLiteral("parity")).toString()).value_or(ConnectionTarget::Parity::None);
    t.stopBits = settings.value(QStringLiteral("stopBits"), t.stopBits).toInt() == 2 ? 2 : 1;
    t.host = settings.value(QStringLiteral("host")).toString().trimmed();
    const int port = settings.value(QStringLiteral("port")).toInt();
    t.port = port > 0 && port <= 65535 ? quint16(port) : 0;
    m_session->setTarget(t);
    emit changed();
    emit applied();
    m_session->connectDevice();
}

QStringList ServiceConnection::availableSerialPorts() const
{
    QStringList ports;
    for (const QSerialPortInfo &info : QSerialPortInfo::availablePorts())
        ports << info.portName();
    ports.sort();
    return ports;
}

void ServiceConnection::connectDevice() { m_session->connectDevice(); }
void ServiceConnection::disconnectDevice() { m_session->disconnectDevice(); }

void ServiceConnection::retranslate() { emit changed(); }
