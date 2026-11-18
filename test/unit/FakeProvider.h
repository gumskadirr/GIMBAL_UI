#pragma once

#include "device/api/IDeviceProvider.h"

// Records calls; tests emit results directly with `emit provider->stateChanged(...)`.
class FakeProvider : public IDeviceProvider
{
    Q_OBJECT

public:
    void start(quint64 sessionId, const ConnectionTarget &target) override
    {
        lastSessionId = sessionId;
        lastTarget = target;
        ++starts;
    }
    void stop() override { ++stops; }
    bool supportsCommands() const override { return commands; }
    void send(quint64 sessionId, quint64 requestId, const DeviceCommand &command) override
    {
        sent << command;
        lastCommandSessionId = sessionId;
        lastRequestId = requestId;
    }

    quint64 lastSessionId = 0;
    ConnectionTarget lastTarget;
    int starts = 0;
    int stops = 0;
    bool commands = false; // like the real target until a protocol exists
    QList<DeviceCommand> sent;
    quint64 lastCommandSessionId = 0;
    quint64 lastRequestId = 0;
};

// Pan angle and gimbal temperature only; every other field stays invalid.
inline DeviceSample makeSample(double pan, bool panValid, double temp, bool tempValid)
{
    DeviceSample s;
    s.panDeg = {pan, panValid};
    s.gimbalTempC = {temp, tempValid};
    return s;
}

inline BoardInfo makeBoardInfo()
{
    BoardInfo info;
    info.deviceId = {QStringLiteral("0x1A42"), true};
    info.firmware = {QStringLiteral("v2.4.1"), true};
    info.firmwareBuilt = {QStringLiteral("2026-10-28"), true};
    info.model = {QStringLiteral("MCB-2"), true};
    info.mcuDeviceId = {QStringLiteral("0x0451"), true};
    info.uid = {QStringLiteral("3A00 2F14 5133 3532"), true};
    info.flashSizeKb = {QStringLiteral("1024"), true};
    info.bootloaderVersion = {QStringLiteral("1.3.0"), true};
    info.boardId = {QStringLiteral("0x07"), true};
    return info;
}

// The report of the Gimbal info design (7 pass, 1 warning).
inline BitReport makeBitReport()
{
    BitReport report;
    for (const char *name : {"Power supply", "IMU", "Pan motor", "Tilt motor", "Encoders", "Heater", "LRF", "Flash memory"})
        report.items.append({QString::fromLatin1(name), BitItem::Pass, QStringLiteral("OK")});
    report.items[2].status = BitItem::Warning;
    report.lastRun = QStringLiteral("14:20:05 at power-on");
    report.valid = true;
    return report;
}

// Every field valid (the "full" sample the Gimbal info page shows).
inline DeviceSample makeFullSample()
{
    DeviceSample s;
    s.panDeg = {124.496, true};
    s.panRefDeg = {124.5, true};
    s.tiltDeg = {-8.204, true};
    s.tiltRefDeg = {-8.2, true};
    s.gimbalTempC = {41.2, true};
    s.imuTempC = {38.6, true};
    s.supplyVoltageV = {24.1, true};
    s.safeControlLocked = {true, true};
    s.onTimeS = {11520.0, true};
    s.inBootloader = {false, true};
    return s;
}
