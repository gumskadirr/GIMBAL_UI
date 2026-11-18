#pragma once

#include <QTimer>

#include "device/api/IDeviceProvider.h"

// Sample provider of the IDS Image service (demo target). Skeleton: connects, accepts every command after
// kCommandDelayMs and makes up traffic; T17-T20 add the IDS Image telemetry.
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
    static constexpr quint64 kTxPerTick = 10; // made-up traffic: the demo has no real link
    static constexpr quint64 kRxPerTick = 4000;

private:
    QTimer m_timer;
    quint64 m_sessionId = 0;
    quint64 m_tx = 0;
    quint64 m_rx = 0;
};
