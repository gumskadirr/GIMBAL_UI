#include "MainControlViewModel.h"

#include "device/session/DeviceSession.h"

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

MainControlViewModel::MainControlViewModel(DeviceSession *session, ServiceConnection *connection, QObject *parent)
    : QObject(parent), m_session(session), m_connection(connection)
{
    connect(m_session, &DeviceSession::stateChanged, this, [this] {
        if (m_session->state() != ConnectionState::Connected)
            clearSessionData();
    });
    connect(m_session, &DeviceSession::sessionStarted, this, &MainControlViewModel::clearSessionData);
    connect(m_session, &DeviceSession::sampleAccepted, this, &MainControlViewModel::onSample);
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

void MainControlViewModel::onSample(const DeviceSample &sample)
{
    m_sample = sample;
    m_sinceSample.start();
    m_staleCheck.start();
    emit measurementsChanged();
}

void MainControlViewModel::clearSessionData()
{
    invalidate();
    if (!m_hasBoardInfo)
        return;
    m_boardInfo = BoardInfo{};
    m_hasBoardInfo = false;
    emit boardInfoChanged();
}

void MainControlViewModel::invalidate()
{
    m_staleCheck.stop();
    m_sinceSample.invalidate();
    if (!anyValid(m_sample))
        return;
    m_sample = DeviceSample{}; // every field invalid
    emit measurementsChanged();
}
