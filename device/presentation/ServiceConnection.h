#pragma once

#include <QObject>
#include <QVariantMap>
#include <QtQml/qqmlregistration.h>

class DeviceSession;

// One service's connection as QML sees it (architecture §12): state, settings summary, connect/disconnect.
// One instance per service; the service's data lives in its own view model.
class ServiceConnection : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("Owned by the application")
    Q_PROPERTY(QString statusText READ statusText NOTIFY changed)
    Q_PROPERTY(bool connected READ connected NOTIFY changed)
    Q_PROPERTY(bool busy READ busy NOTIFY changed)
    Q_PROPERTY(bool hasError READ hasError NOTIFY changed)
    // Every button that sends a command to the device binds its enabled state to this.
    Q_PROPERTY(bool commandsAvailable READ commandsAvailable NOTIFY changed)
    Q_PROPERTY(QString errorDetail READ errorDetail NOTIFY changed)
    // Status bar text of the connection settings, e.g. "UART · COM3 · 115200 8N1".
    Q_PROPERTY(QString summary READ summary NOTIFY changed)
    Q_PROPERTY(bool configured READ configured NOTIFY changed)

public:
    explicit ServiceConnection(DeviceSession *session, QObject *parent = nullptr);

    QString statusText() const;
    bool connected() const;
    bool busy() const;
    bool hasError() const;
    // shortcut: always false (architecture §7, no protocol yet); T5 makes it connected && supportsCommands.
    bool commandsAvailable() const { return false; }
    QString errorDetail() const;
    QString summary() const;
    bool configured() const;

    Q_INVOKABLE void connectDevice();
    Q_INVOKABLE void disconnectDevice();
    // Settings map of ConnectionPopup.qml: transport ("serial" | "udp"), serialPort, baudRate, dataBits,
    // parity ("none" | "even" | "odd"), stopBits, host, port.
    Q_INVOKABLE QVariantMap target() const;
    // Sets the target, asks the owner to save it (applied) and connects (architecture §12, rule 5).
    Q_INVOKABLE void apply(const QVariantMap &settings);
    Q_INVOKABLE QStringList availableSerialPorts() const;

public slots:
    void retranslate(); // C++ texts are not refreshed by QQmlEngine::retranslate()

signals:
    void changed();
    void applied(); // the session target changed from the UI; the owner saves it

private:
    DeviceSession *m_session;
};
