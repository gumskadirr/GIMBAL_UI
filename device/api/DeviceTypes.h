#pragma once

#include <QMetaType>
#include <QObject>

enum class ConnectionState { Disconnected, Connecting, Connected, Error };

// Gadgets so QML can read .value/.valid (registered as QML value types in device/presentation).
struct Measurement
{
    Q_GADGET
    Q_PROPERTY(double value MEMBER value)
    Q_PROPERTY(bool valid MEMBER valid)

public:
    double value = 0.0;
    bool valid = false; // false means "no reading", never "reading of 0"
};

struct Flag
{
    Q_GADGET
    Q_PROPERTY(bool value MEMBER value)
    Q_PROPERTY(bool valid MEMBER valid)

public:
    bool value = false;
    bool valid = false;
};

// Display fields of the Gimbal info summary, named and scaled after the final design.
// shortcut: names, units and scale are taken from the design, not the protocol; recheck every field
// when the protocol document arrives (architecture §7). Commands never go into this struct.
struct DeviceSample
{
    Measurement panDeg;
    Measurement panRefDeg;
    Measurement tiltDeg;
    Measurement tiltRefDeg;
    Measurement gimbalTempC;
    Measurement imuTempC;
    Measurement supplyVoltageV;
    Flag safeControlLocked;
};

Q_DECLARE_METATYPE(ConnectionState)
Q_DECLARE_METATYPE(DeviceSample)
