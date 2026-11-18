#include "ImageDemoProvider.h"

ImageDemoProvider::ImageDemoProvider(QObject *parent) : IDeviceProvider(parent)
{
    m_timer.setInterval(kTickMs);
    connect(&m_timer, &QTimer::timeout, this, [this] {
        m_tx += kTxPerTick;
        m_rx += kRxPerTick;
        emit trafficCounted(m_sessionId, m_tx, m_rx);
        emit imageSampleReceived(m_sessionId, m_state);
    });
    // Values of the View & control design; no LRF reading and no polarity yet.
    m_state.rollDeg = m_state.tiltDeg = m_state.rollRateDps = m_state.tiltRateDps = {0.0, true};
    m_state.fps = {30.0, true};
    m_state.zoom = {1.0, true};
    m_state.blend = {0.0, true};
    m_state.brightness = {200.0, true};
    m_state.contrast = {0.0, true};
    m_state.streamMode = {2.0, true}; // Blend
    m_state.ffcMode = {0.0, true};    // FFC manual
    m_state.overlay = m_state.skyUp = {true, true};
    m_state.attitudeEnabled = m_state.lrfPointer = m_state.followTarget = {false, true};
    m_state.controlDevice = {0.0, true}; // Keyboard
    m_state.status = {QStringLiteral("OK"), true};
    m_state.mode = {QStringLiteral("Locked"), true};
}

void ImageDemoProvider::start(quint64 sessionId, const ConnectionTarget &)
{
    stop();
    m_sessionId = sessionId;
    m_tx = m_rx = 0;
    QTimer::singleShot(0, this, [this, sessionId] {
        if (m_sessionId != sessionId)
            return; // stopped before the connection "completed"
        emit stateChanged(sessionId, ConnectionState::Connected, {});
        m_timer.start();
    });
}

void ImageDemoProvider::stop()
{
    m_timer.stop();
    m_sessionId = 0;
}

void ImageDemoProvider::send(quint64 sessionId, quint64 requestId, const DeviceCommand &command)
{
    const QVariantMap &a = command.args;
    switch (command.kind) {
    case Command::ImageSetStreamSetting: {
        const QString name = a.value(QStringLiteral("setting")).toString();
        const QVariant v = a.value(QStringLiteral("value"));
        const Measurement m{v.toDouble(), true};
        if (name == QLatin1String("zoom")) m_state.zoom = m;
        else if (name == QLatin1String("blend")) m_state.blend = m;
        else if (name == QLatin1String("brightness")) m_state.brightness = m;
        else if (name == QLatin1String("contrast")) m_state.contrast = m;
        else if (name == QLatin1String("streamMode")) m_state.streamMode = m;
        else if (name == QLatin1String("polarity")) m_state.polarity = m;
        else if (name == QLatin1String("ffcMode")) m_state.ffcMode = m;
        else if (name == QLatin1String("overlay")) m_state.overlay = {v.toBool(), true};
        else if (name == QLatin1String("skyUp")) m_state.skyUp = {v.toBool(), true};
        break;
    }
    case Command::ImageAttitudeEnable: m_state.attitudeEnabled = {a.value(QStringLiteral("enabled")).toBool(), true}; break;
    case Command::ImageSetControlDevice:
        m_state.controlDevice = {a.value(QStringLiteral("device")).toString() == QLatin1String("joystick") ? 1.0 : 0.0, true};
        break;
    case Command::ImageSetPosition:
        m_state.rollDeg = {a.value(QStringLiteral("roll")).toDouble(), true};
        m_state.tiltDeg = {a.value(QStringLiteral("tilt")).toDouble(), true};
        break;
    case Command::ImagePark:
    case Command::ImageResetPosition: m_state.rollDeg = m_state.tiltDeg = {0.0, true}; break;
    case Command::ImageLrfPointer: m_state.lrfPointer = {a.value(QStringLiteral("enabled")).toBool(), true}; break;
    case Command::ImageLrfMeasure: m_state.lrfDistanceM = {1250.5, true}; break;
    case Command::ImageFollowTarget: m_state.followTarget = {a.value(QStringLiteral("enabled")).toBool(), true}; break;
    default: break;
    }
    QTimer::singleShot(kCommandDelayMs, this, [this, sessionId, requestId] {
        emit commandFinished(sessionId, requestId, {Command::Accepted, {}});
    });
}
