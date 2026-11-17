#pragma once

#include <QTimer>

#include "device/api/IDeviceProvider.h"

// Deterministic sample data for the demo target and tests. Not a gimbal simulator and does not
// exercise any protocol parser. Scenarios: steady data, periodic invalid temperature (samples
// 40-49 of every 100), link loss after `linkLossAfter` samples, and a delayed result carrying
// the old session id after stop().
class DemoProvider : public IDeviceProvider
{
    Q_OBJECT

public:
    explicit DemoProvider(int intervalMs = 100, int linkLossAfter = 300, int lateResultDelayMs = 500,
                          QObject *parent = nullptr);

    void start(quint64 sessionId, const ConnectionTarget &target = {}) override; // target ignored
    void stop() override;

    // Deterministic sample number n (pure; public for tests).
    static DeviceSample sampleAt(int n);
    static BoardInfo sampleBoardInfo(); // sent once after connecting

private:
    void tick();

    QTimer m_timer;
    quint64 m_sessionId = 0;
    int m_n = 0;
    int m_linkLossAfter;
    int m_lateResultDelayMs;
};
