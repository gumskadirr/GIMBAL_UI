#pragma once

#include <QMetaType>

enum class ConnectionState { Disconnected, Connecting, Connected, Error };

struct Measurement
{
    double value = 0.0;
    bool valid = false; // false means "no reading", never "reading of 0"
};

// Sample fields are placeholders for the validation page; real protocol fields are added
// only after the protocol document is read.
struct DeviceSample
{
    Measurement angleDeg;
    Measurement temperatureC;
};

Q_DECLARE_METATYPE(ConnectionState)
Q_DECLARE_METATYPE(DeviceSample)
