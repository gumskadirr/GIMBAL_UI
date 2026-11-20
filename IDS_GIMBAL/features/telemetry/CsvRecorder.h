#pragma once

#include <QByteArray>
#include <QElapsedTimer>
#include <QFile>
#include <QObject>
#include <QTimer>
#include <QUrl>
#include <QtQml/qqmlregistration.h>

#include "device/api/DeviceTypes.h"

class DeviceSession;

// Manual CSV recording of the accepted streaming samples. Rows are collected in memory and written every
// kFlushRows rows or kFlushMs, whichever comes first. The file is locale independent: '.' decimals, ',' separators.
// A write error or the end of the session closes the file; errors are reported by failed(). Lives in the GUI thread.
class CsvRecorder : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("Owned by the main control view model")
    Q_PROPERTY(bool recording READ recording NOTIFY recordingChanged)
    Q_PROPERTY(int rowCount READ rowCount NOTIFY rowCountChanged) // data rows of the current or last recording
    Q_PROPERTY(QUrl fileUrl READ fileUrl NOTIFY recordingChanged)

public:
    static constexpr int kFlushRows = 100;
    static constexpr int kFlushMs = 1000;

    explicit CsvRecorder(DeviceSession *session, QObject *parent = nullptr);
    ~CsvRecorder() override;

    bool recording() const { return m_file.isOpen(); }
    int rowCount() const { return m_rows; }
    QUrl fileUrl() const { return m_url; }

    Q_INVOKABLE bool start(const QUrl &url); // false (and failed()) when the file cannot be opened
    Q_INVOKABLE void stop();

signals:
    void recordingChanged();
    void rowCountChanged();
    void failed(const QString &file, const QString &reason);

private:
    void onSample(const DeviceSample &sample);
    bool flush();
    void fail(const QString &reason);

    QFile m_file;
    QUrl m_url;
    QByteArray m_buffer;
    int m_rows = 0;
    int m_buffered = 0;
    QElapsedTimer m_clock;
    QTimer m_flushTimer;
};
