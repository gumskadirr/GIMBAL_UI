#include "ScriptRunner.h"

#include "device/api/DeviceCommand.h"
#include "device/presentation/ServiceConnection.h"

ScriptRunner::ScriptRunner(ServiceConnection *connection, QObject *parent) : QObject(parent), m_connection(connection)
{
    m_timer.setInterval(1); // shortcut: a 1 ms poll instead of one timer shot per row; fine up to a few hundred Hz
    m_timer.setTimerType(Qt::PreciseTimer);
    connect(&m_timer, &QTimer::timeout, this, &ScriptRunner::tick);
    m_uiTimer.setInterval(100);
    connect(&m_uiTimer, &QTimer::timeout, this, &ScriptRunner::progressChanged);

    connect(&m_file, &ScriptFile::loadedChanged, this, [this] {
        stop(); // a new file replaces the rows being played
        if (m_file.sampleMs() > 0)
            setSampleMs(m_file.sampleMs());
        m_row = 0;
        m_elapsedMs = 0;
        m_commandPan = m_commandTilt = {};
        m_state = Idle;
        emit stateChanged();
        emit settingsChanged();
        emit progressChanged();
    });
    connect(&m_file, &ScriptFile::axesChanged, this, &ScriptRunner::settingsChanged);
    connect(m_connection, &ServiceConnection::changed, this, [this] {
        if (running() && !m_connection->commandsAvailable()) {
            end(Stopped);
            emit connectionLost();
        }
        emit settingsChanged();
    });
    // A refused point ends the script; the application already reports the refused command. A cancelled one
    // means the connection ended, which the handler above reports.
    connect(m_connection, &ServiceConnection::commandFinished, this, [this](int kind, int status, const QString &) {
        if (running() && kind == Command::ScriptPoint && status != Command::Accepted && status != Command::Cancelled)
            end(Failed);
    });
}

bool ScriptRunner::canStart() const
{
    const bool pan = m_panEnabled && m_file.panColumn() >= 0;
    const bool tilt = m_tiltEnabled && m_file.tiltColumn() >= 0;
    return !running() && m_file.loaded() && (pan || tilt) && m_connection->commandsAvailable();
}

bool ScriptRunner::start()
{
    if (!canStart())
        return false;
    m_row = 0;
    m_elapsedMs = 0;
    m_commandPan = m_commandTilt = {};
    m_state = Running;
    m_clock.start();
    m_timer.start();
    m_uiTimer.start();
    emit stateChanged();
    emit settingsChanged();
    emit progressChanged();
    tick();
    return true;
}

void ScriptRunner::stop()
{
    if (running())
        end(Stopped);
}

void ScriptRunner::end(State state)
{
    m_elapsedMs = m_clock.elapsed();
    m_timer.stop();
    m_uiTimer.stop();
    m_state = state;
    emit stateChanged();
    emit settingsChanged();
    emit progressChanged();
}

void ScriptRunner::tick()
{
    // Late rows go out in order, one per tick when the device answers slowly (a point is refused while the
    // previous one is unanswered); none is skipped.
    while (running() && m_row < rowCount() && m_clock.elapsed() >= qint64(m_row) * m_sampleMs) {
        if (!sendRow())
            return;
        ++m_row;
        emit progressChanged();
    }
    if (running() && m_row >= rowCount())
        end(Done);
}

bool ScriptRunner::sendRow()
{
    static const char *const types[] = {"torque", "speed", "position"};
    QVariantMap args{{QStringLiteral("type"), QLatin1String(types[m_motorMode])}};
    Measurement pan, tilt;
    if (m_panEnabled && m_file.panColumn() >= 0)
        pan = {m_file.pan(m_row), true};
    if (m_tiltEnabled && m_file.tiltColumn() >= 0)
        tilt = {m_file.tilt(m_row), true};
    if (pan.valid)
        args.insert(QStringLiteral("pan"), pan.value);
    if (tilt.valid)
        args.insert(QStringLiteral("tilt"), tilt.value);
    if (!m_connection->send(Command::ScriptPoint, args))
        return false;
    m_commandPan = pan;
    m_commandTilt = tilt;
    return true;
}
