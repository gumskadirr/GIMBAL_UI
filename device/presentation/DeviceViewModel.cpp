#include "DeviceViewModel.h"

#include "device/session/DeviceSession.h"

#include <QCoreApplication>
#include <QSerialPortInfo>

namespace {
bool anyValid(const DeviceSample &s)
{
    for (const Measurement &m : {s.panDeg, s.panRefDeg, s.tiltDeg, s.tiltRefDeg, s.gimbalTempC, s.imuTempC,
                                 s.supplyVoltageV}) {
        if (m.valid)
            return true;
    }
    return s.safeControlLocked.valid;
}
} // namespace

DeviceViewModel::DeviceViewModel(DeviceSession *session, QObject *parent)
    : QObject(parent), m_session(session)
{
    connect(m_session, &DeviceSession::stateChanged, this, &DeviceViewModel::onSessionState);
    connect(m_session, &DeviceSession::sessionStarted, this, &DeviceViewModel::clearSessionData);
    connect(m_session, &DeviceSession::sampleAccepted, this, &DeviceViewModel::onSample);
    connect(m_session, &DeviceSession::boardInfoAccepted, this, [this](const BoardInfo &info) {
        m_boardInfo = info;
        m_hasBoardInfo = true;
        emit boardInfoChanged();
    });

    m_staleCheck.setInterval(kStaleAfterMs / 4);
    connect(&m_staleCheck, &QTimer::timeout, this, [this] {
        if (m_sinceSample.isValid() && m_sinceSample.elapsed() > kStaleAfterMs)
            invalidate();
    });
}

QString DeviceViewModel::connectionText() const
{
    switch (m_session->state()) {
    case ConnectionState::Disconnected: return tr("Disconnected");
    case ConnectionState::Connecting: return tr("Connecting");
    case ConnectionState::Connected: return tr("Connected");
    case ConnectionState::Error: return tr("Error");
    }
    return {};
}

bool DeviceViewModel::connected() const { return m_session->state() == ConnectionState::Connected; }
bool DeviceViewModel::busy() const { return m_session->state() == ConnectionState::Connecting; }
bool DeviceViewModel::hasError() const { return m_session->state() == ConnectionState::Error; }
QString DeviceViewModel::errorDetail() const
{
    // Same "Detail" context as NotificationModel: raw device text has no entry and stays as is.
    return QCoreApplication::translate("Detail", m_session->detail().toUtf8().constData());
}

QString DeviceViewModel::connectionSummary() const
{
    const ConnectionTarget t = m_session->target();
    if (!t.configured())
        return tr("Not configured");
    if (t.transport == ConnectionTarget::Transport::Udp)
        return QStringLiteral("IP/UDP · %1:%2").arg(t.host).arg(t.port);
    const QChar parity = parityName(t.parity).at(0).toUpper(); // N / E / O
    return QStringLiteral("UART · %1 · %2 %3%4%5").arg(t.serialPort).arg(t.baudRate).arg(t.dataBits).arg(parity).arg(t.stopBits);
}

bool DeviceViewModel::connectionConfigured() const { return m_session->target().configured(); }

QVariantMap DeviceViewModel::connectionTarget() const
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

void DeviceViewModel::applyConnection(const QVariantMap &settings)
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
    emit connectionChanged();
    emit connectionApplied();
    m_session->connectDevice();
}

QStringList DeviceViewModel::availableSerialPorts() const
{
    QStringList ports;
    for (const QSerialPortInfo &info : QSerialPortInfo::availablePorts())
        ports << info.portName();
    ports.sort();
    return ports;
}

void DeviceViewModel::connectDevice() { m_session->connectDevice(); }
void DeviceViewModel::disconnectDevice() { m_session->disconnectDevice(); }

void DeviceViewModel::retranslate() { emit connectionChanged(); }

void DeviceViewModel::onSessionState()
{
    if (m_session->state() != ConnectionState::Connected)
        clearSessionData();
    emit connectionChanged();
}

void DeviceViewModel::onSample(const DeviceSample &sample)
{
    m_sample = sample;
    m_sinceSample.start();
    m_staleCheck.start();
    emit measurementsChanged();
}

void DeviceViewModel::clearSessionData()
{
    invalidate();
    if (!m_hasBoardInfo)
        return;
    m_boardInfo = BoardInfo{};
    m_hasBoardInfo = false;
    emit boardInfoChanged();
}

void DeviceViewModel::invalidate()
{
    m_staleCheck.stop();
    m_sinceSample.invalidate();
    if (!anyValid(m_sample))
        return;
    m_sample = DeviceSample{}; // every field invalid
    emit measurementsChanged();
}
