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

struct TextValue
{
    Q_GADGET
    Q_PROPERTY(QString value MEMBER value)
    Q_PROPERTY(bool valid MEMBER valid)

public:
    QString value; // display text as the device reports it (ids, versions)
    bool valid = false;

    // Needed by moc for gadget properties of this type (BoardInfo).
    friend bool operator==(const TextValue &a, const TextValue &b) { return a.value == b.value && a.valid == b.valid; }
    friend bool operator!=(const TextValue &a, const TextValue &b) { return !(a == b); }
};

// Streamed telemetry: arrives continuously and is treated as stale shortly after it stops
// (DeviceViewModel::kStaleAfterMs). Display fields of the Gimbal info summary, named and scaled after the
// final design.
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

// Read once per session (on connect or on request), not streamed: valid until the session ends and never
// stale by time. Identity and MCU details of the Gimbal info page.
// shortcut: fields and formats follow the design; recheck them when the protocol document arrives.
struct BoardInfo
{
    Q_GADGET
    Q_PROPERTY(TextValue deviceId MEMBER deviceId)
    Q_PROPERTY(TextValue firmware MEMBER firmware)
    Q_PROPERTY(TextValue model MEMBER model)
    Q_PROPERTY(TextValue mcuDeviceId MEMBER mcuDeviceId)
    Q_PROPERTY(TextValue uid MEMBER uid)
    Q_PROPERTY(TextValue flashSizeKb MEMBER flashSizeKb)
    Q_PROPERTY(TextValue bootloaderVersion MEMBER bootloaderVersion)
    Q_PROPERTY(TextValue boardId MEMBER boardId)

public:
    TextValue deviceId;
    TextValue firmware;
    TextValue model;
    TextValue mcuDeviceId;
    TextValue uid;
    TextValue flashSizeKb;
    TextValue bootloaderVersion;
    TextValue boardId;
};

Q_DECLARE_METATYPE(ConnectionState)
Q_DECLARE_METATYPE(DeviceSample)
Q_DECLARE_METATYPE(BoardInfo)
