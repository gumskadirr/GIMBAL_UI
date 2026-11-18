#pragma once

#include <QElapsedTimer>
#include <QObject>
#include <QTimer>
#include <QtQml/qqmlregistration.h>

#include "device/api/DeviceTypes.h"
#include "features/telemetry/ScriptFile.h"

class ServiceConnection;

// Plays the rows of the script as Command::ScriptPoint, one row per sample time. Row n is due at n * sampleMs after
// the start; a late row is sent as soon as possible and in order, never skipped. It stops by itself when the
// connection is lost or the device refuses a point. Lives in the GUI thread, owned by the main control view model
// (not by a page), so it keeps playing when the page is left.
class ScriptRunner : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("Owned by the main control view model")
    Q_PROPERTY(ScriptFile *file READ file CONSTANT)
    Q_PROPERTY(State state READ state NOTIFY stateChanged)
    Q_PROPERTY(bool running READ running NOTIFY stateChanged)
    Q_PROPERTY(bool canStart READ canStart NOTIFY settingsChanged)
    Q_PROPERTY(bool panEnabled READ panEnabled WRITE setPanEnabled NOTIFY settingsChanged)
    Q_PROPERTY(bool tiltEnabled READ tiltEnabled WRITE setTiltEnabled NOTIFY settingsChanged)
    Q_PROPERTY(int motorMode READ motorMode WRITE setMotorMode NOTIFY settingsChanged) // 0 torque, 1 speed, 2 position
    Q_PROPERTY(int sampleMs READ sampleMs WRITE setSampleMs NOTIFY settingsChanged)
    Q_PROPERTY(int row READ row NOTIFY progressChanged)             // rows sent
    Q_PROPERTY(int rowCount READ rowCount NOTIFY settingsChanged)
    Q_PROPERTY(int percent READ percent NOTIFY progressChanged)
    Q_PROPERTY(qint64 durationMs READ durationMs NOTIFY settingsChanged)
    Q_PROPERTY(qint64 elapsedMs READ elapsedMs NOTIFY progressChanged)
    Q_PROPERTY(qint64 remainingMs READ remainingMs NOTIFY progressChanged)
    Q_PROPERTY(Measurement commandPan READ commandPan NOTIFY progressChanged) // last sent, offset included
    Q_PROPERTY(Measurement commandTilt READ commandTilt NOTIFY progressChanged)

public:
    enum State { Idle, Running, Done, Stopped, Failed };
    Q_ENUM(State)

    static constexpr int kMaxSampleMs = 10000;

    ScriptRunner(ServiceConnection *connection, QObject *parent = nullptr);

    ScriptFile *file() { return &m_file; }
    State state() const { return m_state; }
    bool running() const { return m_state == Running; }
    bool canStart() const;
    bool panEnabled() const { return m_panEnabled; }
    bool tiltEnabled() const { return m_tiltEnabled; }
    int motorMode() const { return m_motorMode; }
    int sampleMs() const { return m_sampleMs; }
    int row() const { return m_row; }
    int rowCount() const { return m_file.rowCount(); }
    int percent() const { return rowCount() > 0 ? int(qint64(m_row) * 100 / rowCount()) : 0; }
    qint64 durationMs() const { return qint64(rowCount()) * m_sampleMs; }
    qint64 elapsedMs() const { return running() ? m_clock.elapsed() : m_elapsedMs; }
    qint64 remainingMs() const { return qMax<qint64>(0, durationMs() - elapsedMs()); }
    Measurement commandPan() const { return m_commandPan; }
    Measurement commandTilt() const { return m_commandTilt; }
    void setPanEnabled(bool on) { set(m_panEnabled, on); }
    void setTiltEnabled(bool on) { set(m_tiltEnabled, on); }
    void setMotorMode(int mode) { if (mode >= 0 && mode <= 2) set(m_motorMode, mode); }
    void setSampleMs(int ms) { if (ms >= 1 && ms <= kMaxSampleMs) set(m_sampleMs, ms); }

    Q_INVOKABLE bool start(); // false when canStart is false
    Q_INVOKABLE void stop();

signals:
    void stateChanged();
    void settingsChanged();
    void progressChanged();
    void connectionLost(); // the script was running when the connection ended

private:
    template<typename T>
    void set(T &field, T value)
    {
        if (running() || field == value)
            return;
        field = value;
        emit settingsChanged();
    }
    void tick();
    bool sendRow();
    void end(State state);

    ServiceConnection *m_connection;
    ScriptFile m_file;
    QTimer m_timer;   // due check, every ms
    QTimer m_uiTimer; // elapsed / remaining for the page between rows
    QElapsedTimer m_clock;
    State m_state = Idle;
    bool m_panEnabled = true;
    bool m_tiltEnabled = true;
    int m_motorMode = 2;
    int m_sampleMs = 10;
    int m_row = 0;
    qint64 m_elapsedMs = 0;
    Measurement m_commandPan;
    Measurement m_commandTilt;
};
