#pragma once

#include <QTimer>

#include "device/api/IDeviceProvider.h"

// Sample provider of the IDS Image service (demo target): connects, makes up traffic and the telemetry of the
// View & control design, and accepts every command after kCommandDelayMs. Stream settings and attitude commands
// take effect at once, so the next telemetry shows them. the state stream starts and stops with ImageGimbalState.
class ImageDemoProvider : public IDeviceProvider
{
    Q_OBJECT

public:
    explicit ImageDemoProvider(QObject *parent = nullptr);

    void start(quint64 sessionId, const ConnectionTarget &target = {}) override; // target ignored
    void stop() override;
    bool supportsCommands() const override { return true; }
    void send(quint64 sessionId, quint64 requestId, const DeviceCommand &command) override;

    static constexpr int kCommandDelayMs = 400;
    static constexpr int kTickMs = 100;
    static constexpr int kCycleTicks = 300; // the Errors page: MACB_LRF fails for the last 50 ticks (5 s) of 30 s
    static constexpr int kFailTicks = 50;
    static constexpr quint64 kTxPerTick = 10; // made-up traffic: the demo has no real link
    static constexpr quint64 kRxPerTick = 4000;

private:
    void fillGimbalState();

    ImageSample m_state; // what the "device" holds
    int m_stateRateHz = 5;
    QTimer m_timer;
    quint64 m_sessionId = 0;
    quint64 m_tx = 0;
    quint64 m_rx = 0;
};
