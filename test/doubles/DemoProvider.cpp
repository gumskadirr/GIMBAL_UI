#include "DemoProvider.h"

#include <cmath>

DemoProvider::DemoProvider(int intervalMs, int linkLossAfter, int lateResultDelayMs, QObject *parent)
    : IDeviceProvider(parent), m_linkLossAfter(linkLossAfter), m_lateResultDelayMs(lateResultDelayMs)
{
    m_timer.setInterval(intervalMs);
    connect(&m_timer, &QTimer::timeout, this, &DemoProvider::tick);
}

void DemoProvider::start(quint64 sessionId, const ConnectionTarget &)
{
    stop();
    m_sessionId = sessionId;
    m_n = 0;
    QTimer::singleShot(0, this, [this, sessionId] {
        if (m_sessionId != sessionId)
            return; // stopped before the connection "completed"
        emit stateChanged(sessionId, ConnectionState::Connected, {});
        emit boardInfoReceived(sessionId, sampleBoardInfo());
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

BoardInfo DemoProvider::sampleBoardInfo()
{
    // Values of the Gimbal info design.
    const auto text = [](const char *value) { return TextValue{QString::fromLatin1(value), true}; };
    BoardInfo info;
    info.deviceId = text("0x1A42");
    info.firmware = text("v2.4.1");
    info.model = text("MCB-2");
    info.mcuDeviceId = text("0x0451");
    info.uid = text("3A00 2F14 5133 3532");
    info.flashSizeKb = text("1024");
    info.bootloaderVersion = text("1.3.0");
    info.boardId = text("0x07");
    return info;
}

DeviceSample DemoProvider::sampleAt(int n)
{
    constexpr double kPi = 3.14159265358979323846;
    const double phase = 2.0 * kPi * n / 50.0;
    const bool tempValid = !(n % 100 >= 40 && n % 100 < 50); // repeatable sensor dropout
    DeviceSample s;
    s.panRefDeg = {150.0 * std::sin(phase), true};
    s.panDeg = {0.999 * s.panRefDeg.value, true}; // small tracking error
    s.tiltRefDeg = {-8.2 + 20.0 * std::sin(phase / 2.0), true};
    s.tiltDeg = {s.tiltRefDeg.value - 0.004, true};
    s.gimbalTempC = {41.0 + 0.01 * n, tempValid};
    s.imuTempC = {38.6 + 0.01 * n, tempValid};
    s.supplyVoltageV = {24.1 + 0.05 * std::sin(phase), true};
    s.safeControlLocked = {(n / 100) % 2 == 0, true};
    return s;
}
