#include "DemoProvider.h"

#include <cmath>

DemoProvider::DemoProvider(int intervalMs, int linkLossAfter, int lateResultDelayMs, QObject *parent)
    : IDeviceProvider(parent), m_linkLossAfter(linkLossAfter), m_lateResultDelayMs(lateResultDelayMs)
{
    m_timer.setInterval(intervalMs);
    connect(&m_timer, &QTimer::timeout, this, &DemoProvider::tick);
}

void DemoProvider::start(quint64 sessionId)
{
    stop();
    m_sessionId = sessionId;
    m_n = 0;
    QTimer::singleShot(0, this, [this, sessionId] {
        if (m_sessionId != sessionId)
            return; // stopped before the connection "completed"
        emit stateChanged(sessionId, ConnectionState::Connected, {});
        m_timer.start();
    });
}

void DemoProvider::stop()
{
    if (m_sessionId == 0)
        return;
    m_timer.stop();
    const quint64 old = m_sessionId;
    const DeviceSample late = sampleAt(m_n);
    m_sessionId = 0;
    // Context object `this` cancels the delayed result if the provider is destroyed first.
    QTimer::singleShot(m_lateResultDelayMs, this, [this, old, late] { emit sampleReceived(old, late); });
}

void DemoProvider::tick()
{
    if (m_n >= m_linkLossAfter) {
        m_timer.stop();
        emit stateChanged(m_sessionId, ConnectionState::Error, QStringLiteral("Simulated link loss"));
        return;
    }
    emit sampleReceived(m_sessionId, sampleAt(m_n++));
}

DeviceSample DemoProvider::sampleAt(int n)
{
    constexpr double kPi = 3.14159265358979323846;
    const bool tempValid = !(n % 100 >= 40 && n % 100 < 50);
    return DeviceSample{{30.0 * std::sin(2.0 * kPi * n / 50.0), true}, {35.0 + 0.01 * n, tempValid}};
}
