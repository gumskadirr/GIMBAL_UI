#pragma once

#include <QTimer>

#include "device/api/IDeviceProvider.h"

// Deterministic sample data for the demo target and tests. Not a gimbal simulator and does not
// exercise any protocol parser. Scenarios: steady data, periodic invalid temperature (samples
// 40-49 of every 100), link loss after `linkLossAfter` samples, and a delayed result carrying
// the old session id after stop(). Commands: every command is accepted after kCommandDelayMs (mock);
// UpdateFirmware reports progress for about 5 s (kFirmwareStepMs x 100) and is accepted at the end,
// CancelFirmwareUpdate ends it as Cancelled; StepResponse is accepted and answers with stepMetricsReceived; StartStream / StopStream switch the streaming flag; the three calibrations run the same way for about 5 s and then send
// their result (raw position stays telemetry); a second long command while one runs is Rejected; parameters behave like a device: read returns them, write changes them, defaults restores them.
class DemoProvider : public IDeviceProvider
{
    Q_OBJECT

public:
    explicit DemoProvider(int intervalMs = 100, int linkLossAfter = 300, int lateResultDelayMs = 500,
                          QObject *parent = nullptr);

    void start(quint64 sessionId, const ConnectionTarget &target = {}) override; // target ignored
    void stop() override;
    bool supportsCommands() const override { return true; }
    void send(quint64 sessionId, quint64 requestId, const DeviceCommand &command) override;

    static constexpr int kCommandDelayMs = 400;
    static constexpr int kFirmwareStepMs = 50;

    // Deterministic sample number n (pure; public for tests).
    static DeviceSample sampleAt(int n);
    static BoardInfo sampleBoardInfo(); // sent once after connecting
    static BitReport sampleBitReport(const QString &lastRun); // the 8 items of the Gimbal info design
    static QVariantMap defaultParameters();

private:
    void tick();
    void firmwareStep();

    QTimer m_timer;
    quint64 m_sessionId = 0;
    int m_n = 0;
    int m_linkLossAfter;
    int m_lateResultDelayMs;
    QVariantMap m_parameters = defaultParameters();
    QTimer m_firmwareTimer; // drives every long command (firmware update, calibrations)
    quint64 m_firmwareSession = 0;
    quint64 m_firmwareRequest = 0; // 0: no long command running
    Command::Kind m_longKind = Command::UpdateFirmware;
    int m_firmwarePercent = 0;
    bool m_streaming = true; // StartStream / StopStream; the packet counter keeps counting
};
