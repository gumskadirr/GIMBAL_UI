#include "DeviceViewModel.h"

#include "device/session/DeviceSession.h"

#include <QCoreApplication>

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
    connect(m_session, &DeviceSession::sessionStarted, this, &DeviceViewModel::invalidate);
    connect(m_session, &DeviceSession::sampleAccepted, this, &DeviceViewModel::onSample);

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

void DeviceViewModel::connectDevice() { m_session->connectDevice(); }
void DeviceViewModel::disconnectDevice() { m_session->disconnectDevice(); }

void DeviceViewModel::retranslate() { emit connectionChanged(); }

void DeviceViewModel::onSessionState()
{
    if (m_session->state() != ConnectionState::Connected)
        invalidate();
    emit connectionChanged();
}

void DeviceViewModel::onSample(const DeviceSample &sample)
{
    m_sample = sample;
    m_sinceSample.start();
    m_staleCheck.start();
    emit measurementsChanged();
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
