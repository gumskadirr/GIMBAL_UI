#include "DemoProvider.h"

#include <QTime>
#include <cmath>
#include <utility>

#include "device/api/ParameterKeys.h"

DemoProvider::DemoProvider(int intervalMs, int linkLossAfter, int lateResultDelayMs, QObject *parent)
    : IDeviceProvider(parent), m_linkLossAfter(linkLossAfter), m_lateResultDelayMs(lateResultDelayMs)
{
    m_timer.setInterval(intervalMs);
    connect(&m_timer, &QTimer::timeout, this, &DemoProvider::tick);
    m_firmwareTimer.setInterval(kFirmwareStepMs);
    connect(&m_firmwareTimer, &QTimer::timeout, this, &DemoProvider::firmwareStep);
}

void DemoProvider::start(quint64 sessionId, const ConnectionTarget &)
{
    stop();
    m_sessionId = sessionId;
    m_n = 0;
    QTimer::singleShot(0, this, [this, sessionId] {
        if (m_sessionId != sessionId)
            return; // stopped before the connection "completed"
        emit stateChanged(sessionId, ConnectionState::Connected, {});
        emit boardInfoReceived(sessionId, sampleBoardInfo());
        emit bitReportReceived(sessionId, sampleBitReport(QStringLiteral("14:20:05 at power-on")));
        m_timer.start();
    });
}

void DemoProvider::stop()
{
    if (m_sessionId == 0)
        return;
    m_timer.stop();
    m_firmwareTimer.stop();
    m_firmwareRequest = 0;
    const quint64 old = m_sessionId;
    const DeviceSample late = sampleAt(m_n);
    m_sessionId = 0;
    // Context object `this` cancels the delayed result if the provider is destroyed first.
    QTimer::singleShot(m_lateResultDelayMs, this, [this, old, late] { emit sampleReceived(old, late); });
}

void DemoProvider::send(quint64 sessionId, quint64 requestId, const DeviceCommand &command)
{
    if (command.kind == Command::UpdateFirmware) { // no fixed delay: progress starts at once, the answer ends it
        m_firmwareSession = sessionId;
        m_firmwareRequest = requestId;
        m_firmwarePercent = 0;
        m_firmwareTimer.start();
        QTimer::singleShot(0, this, [this, sessionId, requestId] { emit commandProgress(sessionId, requestId, 0, QStringLiteral("Erasing")); });
        return;
    }
    if (command.kind == Command::CancelFirmwareUpdate && m_firmwareRequest != 0) {
        m_firmwareTimer.stop();
        const quint64 request = std::exchange(m_firmwareRequest, 0);
        QTimer::singleShot(0, this, [this, request] { emit commandFinished(m_firmwareSession, request, {Command::Cancelled, {}}); });
    }
    QTimer::singleShot(kCommandDelayMs, this, [this, sessionId, requestId, command] {
        switch (command.kind) {
        case Command::WriteParameters:
            m_parameters.insert(command.args.value(QStringLiteral("values")).toMap());
            break;
        case Command::RestoreDefaultParameters:
            m_parameters = defaultParameters();
            [[fallthrough]];
        case Command::ReadParameters:
            emit parametersReceived(sessionId, m_parameters);
            break;
        case Command::RunBit:
            emit bitReportReceived(sessionId, sampleBitReport(QTime::currentTime().toString(QStringLiteral("HH:mm:ss")) + QStringLiteral(" manual run")));
            break;
        default:
            break;
        }
        emit commandFinished(sessionId, requestId, {Command::Accepted, {}});
    });
}

void DemoProvider::firmwareStep()
{
    m_firmwarePercent += 1;
    const QString stage = m_firmwarePercent < 15 ? QStringLiteral("Erasing")
                        : m_firmwarePercent < 90 ? QStringLiteral("Writing") : QStringLiteral("Verifying");
    emit commandProgress(m_firmwareSession, m_firmwareRequest, m_firmwarePercent, stage);
    if (m_firmwarePercent >= 100) {
        m_firmwareTimer.stop();
        emit commandFinished(m_firmwareSession, std::exchange(m_firmwareRequest, 0), {Command::Accepted, {}});
    }
}

QVariantMap DemoProvider::defaultParameters()
{
    // Plausible values in every key's range; not taken from a real board.
    QVariantMap values;
    for (const ParameterSpec &spec : ParameterKeys::all()) {
        const bool tilt = spec.key.startsWith(QLatin1String("tilt."));
        switch (spec.type) {
        case ParameterType::Number:
            values.insert(spec.key, spec.key.endsWith(QLatin1String("Deg"))
                                        ? (spec.key.contains(QLatin1String("forward")) ? 170.0 : spec.key.contains(QLatin1String("backward")) ? -170.0 : 0.0)
                                        : (tilt ? 0.8 : 1.2));
            break;
        case ParameterType::Integer: values.insert(spec.key, 0); break;
        case ParameterType::Bool: values.insert(spec.key, spec.key.endsWith(QLatin1String("slipRing")) && !tilt); break;
        case ParameterType::Text: values.insert(spec.key, tilt ? QStringLiteral("TM-2207") : QStringLiteral("PM-3110")); break;
        }
    }
    return values;
}

void DemoProvider::tick()
{
    if (m_n >= m_linkLossAfter) {
        m_timer.stop();
        emit stateChanged(m_sessionId, ConnectionState::Error, QStringLiteral("Simulated link loss"));
        return;
    }
    emit sampleReceived(m_sessionId, sampleAt(m_n++));
}

BoardInfo DemoProvider::sampleBoardInfo()
{
    // Values of the Gimbal info design.
    const auto text = [](const char *value) { return TextValue{QString::fromLatin1(value), true}; };
    BoardInfo info;
    info.deviceId = text("0x1A42");
    info.firmware = text("v2.4.1");
    info.firmwareBuilt = text("2026-10-28");
    info.model = text("MCB-2");
    info.mcuDeviceId = text("0x0451");
    info.uid = text("3A00 2F14 5133 3532");
    info.flashSizeKb = text("1024");
    info.bootloaderVersion = text("1.3.0");
    info.boardId = text("0x07");
    return info;
}

BitReport DemoProvider::sampleBitReport(const QString &lastRun)
{
    struct Row { const char *name; BitItem::Status status; const char *description; };
    static const Row rows[] = {
        {"Power supply", BitItem::Pass, "24.1 V, within limits"},
        {"IMU", BitItem::Pass, "Gyro bias within limits"},
        {"Pan motor", BitItem::Warning, "Position limit reached"},
        {"Tilt motor", BitItem::Pass, "Driver and current OK"},
        {"Encoders", BitItem::Pass, "Pan and tilt signals OK"},
        {"Heater", BitItem::Pass, "All zones respond"},
        {"LRF", BitItem::Pass, "Optical crosstalk 0.4%"},
        {"Flash memory", BitItem::Pass, "Checksum OK"},
    };
    BitReport report;
    for (const Row &r : rows)
        report.items.append({QString::fromLatin1(r.name), r.status, QString::fromLatin1(r.description)});
    report.lastRun = lastRun;
    report.valid = true;
    return report;
}

DeviceSample DemoProvider::sampleAt(int n)
{
    constexpr double kPi = 3.14159265358979323846;
    const double phase = 2.0 * kPi * n / 50.0;
    const bool tempValid = !(n % 100 >= 40 && n % 100 < 50); // repeatable sensor dropout
    DeviceSample s;
    s.panRefDeg = {150.0 * std::sin(phase), true};
    s.panDeg = {0.999 * s.panRefDeg.value, true}; // small tracking error
    s.tiltRefDeg = {-8.2 + 20.0 * std::sin(phase / 2.0), true};
    s.tiltDeg = {s.tiltRefDeg.value - 0.004, true};
    s.gimbalTempC = {41.0 + 0.01 * n, tempValid};
    s.imuTempC = {38.6 + 0.01 * n, tempValid};
    s.supplyVoltageV = {24.1 + 0.05 * std::sin(phase), true};
    s.safeControlLocked = {(n / 100) % 2 == 0, true};
    s.onTimeS = {11520.0 + n / 10, true}; // 3 h 12 min at the start (design), 10 samples per second
    s.inBootloader = {false, true};
    return s;
}
