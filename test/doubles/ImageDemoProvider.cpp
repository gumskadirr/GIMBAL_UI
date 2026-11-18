#include "ImageDemoProvider.h"

ImageDemoProvider::ImageDemoProvider(QObject *parent) : IDeviceProvider(parent)
{
    m_timer.setInterval(kTickMs);
    connect(&m_timer, &QTimer::timeout, this, [this] {
        m_tx += kTxPerTick;
        m_rx += kRxPerTick;
        emit trafficCounted(m_sessionId, m_tx, m_rx);
    });
}

void ImageDemoProvider::start(quint64 sessionId, const ConnectionTarget &)
{
    stop();
    m_sessionId = sessionId;
    m_tx = m_rx = 0;
    QTimer::singleShot(0, this, [this, sessionId] {
        if (m_sessionId != sessionId)
            return; // stopped before the connection "completed"
        emit stateChanged(sessionId, ConnectionState::Connected, {});
        m_timer.start();
    });
}

void ImageDemoProvider::stop()
{
    m_timer.stop();
    m_sessionId = 0;
}

void ImageDemoProvider::send(quint64 sessionId, quint64 requestId, const DeviceCommand &)
{
    QTimer::singleShot(kCommandDelayMs, this, [this, sessionId, requestId] {
        emit commandFinished(sessionId, requestId, {Command::Accepted, {}});
    });
}
