#pragma once

#include <QMetaType>
#include <QObject>
#include <optional>

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

    // Needed by moc for gadget properties of this type (ImageSample).
    friend bool operator==(const Measurement &a, const Measurement &b) { return a.value == b.value && a.valid == b.valid; }
    friend bool operator!=(const Measurement &a, const Measurement &b) { return !(a == b); }
};

struct Flag
{
    Q_GADGET
    Q_PROPERTY(bool value MEMBER value)
    Q_PROPERTY(bool valid MEMBER valid)

public:
    bool value = false;
    bool valid = false;

    friend bool operator==(const Flag &a, const Flag &b) { return a.value == b.value && a.valid == b.valid; }
    friend bool operator!=(const Flag &a, const Flag &b) { return !(a == b); }
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
// (MainControlViewModel::kStaleAfterMs). Display fields of the Gimbal info summary, named and scaled after the
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
    Measurement onTimeS; // seconds since power on
    Flag inBootloader;   // false: the application is running
    // Gimbal settings
    Flag streaming;            // the device streams its scope data
    Measurement streamRateHz;  // reported by the device (1 kHz or 2 kHz, architecture §17)
    Measurement packetCount;
    Measurement rawPosition;   // encoder counts of the electrical angle calibration
    TextValue boardMode;       // raw device text, e.g. "Speed"
    // Scope series (Gimbal settings), streamed with the rest.
    Measurement panRateDps;    // deg/s
    Measurement panRateRefDps;
    Measurement tiltRateDps;
    Measurement tiltRateRefDps;
    Measurement panTorqueA;    // Iq in A
    Measurement tiltTorqueA;
};

// Read once per session (on connect or on request), not streamed: valid until the session ends and never
// stale by time. Identity and MCU details of the Gimbal info page.
// shortcut: fields and formats follow the design; recheck them when the protocol document arrives.
struct BoardInfo
{
    Q_GADGET
    Q_PROPERTY(TextValue deviceId MEMBER deviceId)
    Q_PROPERTY(TextValue firmware MEMBER firmware)
    Q_PROPERTY(TextValue firmwareBuilt MEMBER firmwareBuilt)
    Q_PROPERTY(TextValue model MEMBER model)
    Q_PROPERTY(TextValue mcuDeviceId MEMBER mcuDeviceId)
    Q_PROPERTY(TextValue uid MEMBER uid)
    Q_PROPERTY(TextValue flashSizeKb MEMBER flashSizeKb)
    Q_PROPERTY(TextValue bootloaderVersion MEMBER bootloaderVersion)
    Q_PROPERTY(TextValue boardId MEMBER boardId)

public:
    TextValue deviceId;
    TextValue firmware;
    TextValue firmwareBuilt; // build date as the device reports it
    TextValue model;
    TextValue mcuDeviceId;
    TextValue uid;
    TextValue flashSizeKb;
    TextValue bootloaderVersion;
    TextValue boardId;
};

// Streamed telemetry of the IDS Image service (stale shortly after it stops, like DeviceSample). Angles in
// degrees, rates in deg/s. The stream settings are the values the device holds now: the page shows these, never
// what the user last asked for. Option settings are indices into the lists of ViewControlPage.
// shortcut: fields and option lists follow the design; recheck them when the protocol document arrives.
struct ImageSample
{
    Q_GADGET
    Q_PROPERTY(Measurement rollDeg MEMBER rollDeg)
    Q_PROPERTY(Measurement tiltDeg MEMBER tiltDeg)
    Q_PROPERTY(Measurement rollRateDps MEMBER rollRateDps)
    Q_PROPERTY(Measurement tiltRateDps MEMBER tiltRateDps)
    Q_PROPERTY(Measurement fps MEMBER fps)
    Q_PROPERTY(Measurement zoom MEMBER zoom)
    Q_PROPERTY(Measurement blend MEMBER blend)
    Q_PROPERTY(Measurement brightness MEMBER brightness)
    Q_PROPERTY(Measurement contrast MEMBER contrast)
    Q_PROPERTY(Measurement streamMode MEMBER streamMode)
    Q_PROPERTY(Measurement polarity MEMBER polarity)
    Q_PROPERTY(Measurement ffcMode MEMBER ffcMode)
    Q_PROPERTY(Flag overlay MEMBER overlay)
    Q_PROPERTY(Flag skyUp MEMBER skyUp)
    Q_PROPERTY(Flag attitudeEnabled MEMBER attitudeEnabled)
    Q_PROPERTY(Measurement controlDevice MEMBER controlDevice)
    Q_PROPERTY(Flag lrfPointer MEMBER lrfPointer)
    Q_PROPERTY(Measurement lrfDistanceM MEMBER lrfDistanceM)
    Q_PROPERTY(Flag followTarget MEMBER followTarget)
    Q_PROPERTY(TextValue status MEMBER status)
    Q_PROPERTY(TextValue mode MEMBER mode)
    Q_PROPERTY(Measurement camera MEMBER camera)
    Q_PROPERTY(Measurement focusMode MEMBER focusMode)
    Q_PROPERTY(Measurement focusDistanceM MEMBER focusDistanceM)
    Q_PROPERTY(Measurement offsetX MEMBER offsetX)
    Q_PROPERTY(Measurement offsetY MEMBER offsetY)
    Q_PROPERTY(Measurement imageScale MEMBER imageScale)
    Q_PROPERTY(Measurement fovGain MEMBER fovGain)
    Q_PROPERTY(Flag stabilization MEMBER stabilization)
    Q_PROPERTY(Measurement gainMode MEMBER gainMode)
    Q_PROPERTY(Measurement irisMode MEMBER irisMode)
    Q_PROPERTY(Measurement shutterMode MEMBER shutterMode)

public:
    Measurement rollDeg;
    Measurement tiltDeg;
    Measurement rollRateDps;
    Measurement tiltRateDps;
    Measurement fps;
    Measurement zoom;       // x1.0 ...
    Measurement blend;
    Measurement brightness;
    Measurement contrast;
    Measurement streamMode; // index
    Measurement polarity;   // index
    Measurement ffcMode;    // index
    Flag overlay;
    Flag skyUp;
    Flag attitudeEnabled;
    Measurement controlDevice; // 0 keyboard, 1 joystick
    Flag lrfPointer;
    Measurement lrfDistanceM;
    Flag followTarget;
    TextValue status; // raw device text ("OK"); the page colours it
    TextValue mode;   // raw device text ("Locked")
    // Alignment page.
    Measurement camera;         // index: 0 CMOS sensor, 1 Thermal sensor
    Measurement focusMode;      // index: 0 Auto, 1 Manual
    Measurement focusDistanceM; // infinity = +inf
    Measurement offsetX;        // pixels
    Measurement offsetY;
    Measurement imageScale;     // x1 ...
    Measurement fovGain;        // distance in m the offset is calibrated for; +inf = infinity
    Flag stabilization;         // Sony camera stabilization
    Measurement gainMode;       // index: 0 Manual, 1 Auto
    Measurement irisMode;
    Measurement shutterMode;
};

// One built-in test item; name and description are raw device text.
struct BitItem
{
    Q_GADGET
    Q_PROPERTY(QString name MEMBER name)
    Q_PROPERTY(int status MEMBER status)
    Q_PROPERTY(QString description MEMBER description)

public:
    enum Status { Pass, Warning, Fail };
    Q_ENUM(Status)

    QString name;
    int status = Pass; // Status
    QString description;

    friend bool operator==(const BitItem &a, const BitItem &b)
    {
        return a.name == b.name && a.status == b.status && a.description == b.description;
    }
    friend bool operator!=(const BitItem &a, const BitItem &b) { return !(a == b); }
};

// Built-in test result, read on request (RunBit) and after connecting; valid until the session ends.
struct BitReport
{
    Q_GADGET
    Q_PROPERTY(QList<BitItem> items MEMBER items)
    Q_PROPERTY(QString lastRun MEMBER lastRun)
    Q_PROPERTY(bool valid MEMBER valid)

public:
    QList<BitItem> items;
    QString lastRun;    // e.g. "14:20:05 at power-on", raw device text
    bool valid = false; // false: no report in this session
};

// Result of the optical crosstalk check, read on request (StartCrosstalkCheck); valid until the session ends.
struct CrosstalkResult
{
    Q_GADGET
    Q_PROPERTY(bool passed MEMBER passed)
    Q_PROPERTY(double percent MEMBER percent)
    Q_PROPERTY(bool valid MEMBER valid)

public:
    bool passed = false;
    double percent = 0.0;
    bool valid = false; // false: not checked in this session
};

// Gyro offsets in deg/s, read on request (StartImuBiasCalibration); valid until the session ends.
struct ImuBias
{
    Q_GADGET
    Q_PROPERTY(double x MEMBER x)
    Q_PROPERTY(double y MEMBER y)
    Q_PROPERTY(double z MEMBER z)
    Q_PROPERTY(bool valid MEMBER valid)

public:
    double x = 0.0;
    double y = 0.0;
    double z = 0.0;
    bool valid = false;
};

// Result of a step response measurement, read on request (StepResponse); valid until the session ends.
struct StepMetrics
{
    Q_GADGET
    Q_PROPERTY(double riseMs MEMBER riseMs)
    Q_PROPERTY(double overshootPct MEMBER overshootPct)
    Q_PROPERTY(double settlingMs MEMBER settlingMs)
    Q_PROPERTY(double ssErrorDps MEMBER ssErrorDps)
    Q_PROPERTY(double latencyMs MEMBER latencyMs)
    Q_PROPERTY(bool valid MEMBER valid)

public:
    double riseMs = 0.0;
    double overshootPct = 0.0;
    double settlingMs = 0.0;
    double ssErrorDps = 0.0; // steady-state error, deg/s
    double latencyMs = 0.0;
    bool valid = false; // false: no measurement in this session
};

// Where a service connects (architecture §2, §12). Plain values only: the API stays free of QtSerialPort and
// QtNetwork types.
struct ConnectionTarget
{
    enum class Transport { Serial, Udp };
    enum class Parity { None, Even, Odd };

    Transport transport = Transport::Serial;
    QString serialPort;  // e.g. "COM3", "/dev/ttyUSB0"
    qint32 baudRate = 115200;
    int dataBits = 8;    // 7 or 8
    Parity parity = Parity::None;
    int stopBits = 1;    // 1 or 2
    QString host;        // UDP: address of the device
    quint16 port = 0;    // UDP: port of the device

    // Enough to try a connection; the transport still reports Error for an unusable port or address.
    bool configured() const { return transport == Transport::Udp ? !host.isEmpty() && port != 0 : !serialPort.isEmpty(); }
};

// Stored / QML names of the parity values: "none", "even", "odd".
inline QString parityName(ConnectionTarget::Parity parity)
{
    switch (parity) {
    case ConnectionTarget::Parity::Even: return QStringLiteral("even");
    case ConnectionTarget::Parity::Odd: return QStringLiteral("odd");
    case ConnectionTarget::Parity::None: break;
    }
    return QStringLiteral("none");
}

inline std::optional<ConnectionTarget::Parity> parityFromName(const QString &name)
{
    if (name == QLatin1String("none"))
        return ConnectionTarget::Parity::None;
    if (name == QLatin1String("even"))
        return ConnectionTarget::Parity::Even;
    if (name == QLatin1String("odd"))
        return ConnectionTarget::Parity::Odd;
    return std::nullopt;
}

Q_DECLARE_METATYPE(ConnectionState)
Q_DECLARE_METATYPE(DeviceSample)
Q_DECLARE_METATYPE(BoardInfo)
Q_DECLARE_METATYPE(ImageSample)
Q_DECLARE_METATYPE(BitReport)
Q_DECLARE_METATYPE(CrosstalkResult)
Q_DECLARE_METATYPE(ImuBias)
Q_DECLARE_METATYPE(StepMetrics)
