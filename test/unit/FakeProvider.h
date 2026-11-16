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

inline DeviceSample makeSample(double angle, bool angleValid, double temp, bool tempValid)
{
    return DeviceSample{{angle, angleValid}, {temp, tempValid}};
}
