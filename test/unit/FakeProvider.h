#pragma once

#include "device/api/IDeviceProvider.h"

// Records calls; tests emit results directly with `emit provider->stateChanged(...)`.
class FakeProvider : public IDeviceProvider
{
    Q_OBJECT

public:
    void start(quint64 sessionId) override
    {
        lastSessionId = sessionId;
        ++starts;
    }
    void stop() override { ++stops; }

    quint64 lastSessionId = 0;
    int starts = 0;
    int stops = 0;
};

// Pan angle and gimbal temperature only; every other field stays invalid.
inline DeviceSample makeSample(double pan, bool panValid, double temp, bool tempValid)
{
    DeviceSample s;
    s.panDeg = {pan, panValid};
    s.gimbalTempC = {temp, tempValid};
    return s;
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
    return s;
}
