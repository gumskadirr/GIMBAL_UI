#include "CsvRecorder.h"

#include <QLocale>

#include "device/session/DeviceSession.h"

namespace {
struct Column
{
    const char *name;
    Measurement DeviceSample::*measurement;
    Flag DeviceSample::*flag;
};
const Column kColumns[] = {
    {"pan_deg", &DeviceSample::panDeg, nullptr},
    {"pan_ref_deg", &DeviceSample::panRefDeg, nullptr},
    {"tilt_deg", &DeviceSample::tiltDeg, nullptr},
    {"tilt_ref_deg", &DeviceSample::tiltRefDeg, nullptr},
    {"gimbal_temp_c", &DeviceSample::gimbalTempC, nullptr},
    {"imu_temp_c", &DeviceSample::imuTempC, nullptr},
    {"supply_voltage_v", &DeviceSample::supplyVoltageV, nullptr},
    {"safe_control_locked", nullptr, &DeviceSample::safeControlLocked},
    {"on_time_s", &DeviceSample::onTimeS, nullptr},
    {"in_bootloader", nullptr, &DeviceSample::inBootloader},
    {"streaming", nullptr, &DeviceSample::streaming},
    {"stream_rate_hz", &DeviceSample::streamRateHz, nullptr},
    {"packet_count", &DeviceSample::packetCount, nullptr},
    {"raw_position", &DeviceSample::rawPosition, nullptr},
};

// An invalid value is an empty cell, never 0.
void cell(QByteArray &row, bool valid, const QString &text)
{
    row += ',';
    if (valid)
        row += text.toUtf8();
}
} // namespace

CsvRecorder::CsvRecorder(DeviceSession *session, QObject *parent) : QObject(parent)
{
    m_flushTimer.setInterval(kFlushMs);
    connect(&m_flushTimer, &QTimer::timeout, this, [this] {
        if (!flush())
            fail(m_file.errorString());
    });
    connect(session, &DeviceSession::sampleAccepted, this, &CsvRecorder::onSample);
    // Recording never outlives the connection: close the file when the session leaves Connected.
    connect(session, &DeviceSession::stateChanged, this, [this, session] {
        if (session->state() != ConnectionState::Connected)
            stop();
    });
    connect(session, &DeviceSession::sessionStarted, this, &CsvRecorder::stop);
}

CsvRecorder::~CsvRecorder()
{
    stop();
}

bool CsvRecorder::start(const QUrl &url)
{
    stop();
    m_url = url;
    m_file.setFileName(url.toLocalFile());
    m_rows = 0;
    m_buffered = 0;
    emit rowCountChanged();
    if (!m_file.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        emit recordingChanged();
        emit failed(m_file.fileName(), m_file.errorString());
        return false;
    }
    QByteArray header = "time_ms";
    for (const Column &c : kColumns)
        header += QByteArray(",") + c.name + "," + c.name + "_valid";
    m_buffer = header + "\r\n";
    m_clock.start();
    m_flushTimer.start();
    if (!flush()) {
        fail(m_file.errorString());
        return false;
    }
    emit recordingChanged();
    return true;
}

void CsvRecorder::stop()
{
    if (!m_file.isOpen())
        return;
    m_flushTimer.stop();
    const bool ok = flush();
    const QString reason = m_file.errorString();
    m_file.close();
    emit recordingChanged();
    if (!ok)
        emit failed(m_file.fileName(), reason);
}

void CsvRecorder::onSample(const DeviceSample &sample)
{
    if (!m_file.isOpen())
        return;
    QByteArray row = QByteArray::number(m_clock.elapsed());
    for (const Column &c : kColumns) {
        const bool valid = c.measurement ? (sample.*c.measurement).valid : (sample.*c.flag).valid;
        const QString text = c.measurement ? QLocale::c().toString((sample.*c.measurement).value, 'g', 12)
                                           : ((sample.*c.flag).value ? QStringLiteral("1") : QStringLiteral("0"));
        cell(row, valid, text);
        row += valid ? ",1" : ",0";
    }
    m_buffer += row + "\r\n";
    ++m_rows;
    ++m_buffered;
    emit rowCountChanged();
    if (m_buffered >= kFlushRows && !flush())
        fail(m_file.errorString());
}

bool CsvRecorder::flush()
{
    const bool ok = m_file.write(m_buffer) == m_buffer.size() && m_file.flush();
    m_buffer.clear();
    m_buffered = 0;
    return ok;
}

void CsvRecorder::fail(const QString &reason)
{
    const QString name = m_file.fileName();
    m_flushTimer.stop();
    m_file.close();
    emit recordingChanged();
    emit failed(name, reason);
}
