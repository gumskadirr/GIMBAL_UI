#include "ScriptFile.h"

#include <QFile>
#include <QLocale>
#include <cmath>
#include <limits>

namespace {
// First column whose name starts with the axis: "pan", "pan_deg", "Pan (deg)".
int guess(const QStringList &columns, const QString &axis)
{
    for (int i = 0; i < columns.size(); ++i) {
        if (columns.at(i).startsWith(axis, Qt::CaseInsensitive))
            return i;
    }
    return -1;
}
} // namespace

double ScriptFile::value(int row, int column, double offset) const
{
    if (row < 0 || row >= m_rows || column < 0 || column >= m_columns.size())
        return std::numeric_limits<double>::quiet_NaN();
    return m_values.at(row * m_columns.size() + column) + offset;
}

bool ScriptFile::reject(const QString &path, const QString &reason)
{
    m_error = reason;
    emit failed(path, reason);
    return false;
}

bool ScriptFile::load(const QUrl &url)
{
    const QString path = url.toLocalFile();
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly))
        return reject(path, file.errorString());
    if (file.size() > kMaxBytes)
        return reject(path, tr("File is larger than %1 MB").arg(kMaxBytes / (1024 * 1024)));
    return loadData(file.readAll(), path);
}

bool ScriptFile::loadData(const QByteArray &data, const QString &path)
{
    QString text = QString::fromUtf8(data);
    if (text.startsWith(QChar(0xFEFF)))
        text.remove(0, 1);
    const QStringList lines = text.split(QLatin1Char('\n'));

    QStringList columns;
    QVector<double> values;
    QChar separator = QLatin1Char(',');
    int rows = 0;
    for (int n = 0; n < lines.size(); ++n) {
        const QString line = lines.at(n).trimmed();
        if (line.isEmpty())
            continue;
        if (columns.isEmpty()) {
            if (line.contains(QLatin1Char(';')))
                separator = QLatin1Char(';');
            for (const QString &name : line.split(separator))
                columns << name.trimmed();
            continue;
        }
        const QStringList cells = line.split(separator);
        if (cells.size() != columns.size())
            return reject(path, tr("Line %1: %2 columns, the header has %3").arg(n + 1).arg(cells.size()).arg(columns.size()));
        if (rows >= kMaxRows)
            return reject(path, tr("Line %1: more than %2 rows").arg(n + 1).arg(kMaxRows));
        for (int c = 0; c < cells.size(); ++c) {
            bool ok = false;
            const QString cell = cells.at(c).trimmed();
            const double v = QLocale::c().toDouble(cell, &ok);
            if (!ok || !std::isfinite(v))
                return reject(path, tr("Line %1, column %2: \"%3\" is not a number").arg(n + 1).arg(columns.at(c), cell));
            values << v;
        }
        ++rows;
    }
    if (columns.isEmpty())
        return reject(path, tr("The file is empty"));
    if (rows == 0)
        return reject(path, tr("The file has a header but no data rows"));

    m_columns = columns;
    m_values = values;
    m_rows = rows;
    m_path = path;
    m_error.clear();
    const int time = columns.indexOf(QStringLiteral("time_ms"));
    m_sampleMs = time >= 0 && rows > 1 ? qMax(0, int(std::lround(values.at(columns.size() + time) - values.at(time)))) : 0;
    m_pan = guess(columns, QStringLiteral("pan"));
    m_tilt = guess(columns, QStringLiteral("tilt"));
    if (m_pan < 0 && m_tilt < 0) { // no names: the first two columns after the time
        m_pan = time == 0 ? 1 : 0;
        m_tilt = m_pan + 1;
        m_pan = m_pan < columns.size() ? m_pan : -1;
        m_tilt = m_tilt < columns.size() ? m_tilt : -1;
    }
    emit loadedChanged();
    emit axesChanged();
    return true;
}

bool ScriptFile::save(const QUrl &url)
{
    const QString path = url.toLocalFile();
    if (!loaded())
        return reject(path, tr("No script loaded"));
    QFile file(path);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate))
        return reject(path, file.errorString());
    QByteArray out = m_columns.join(QLatin1Char(',')).toUtf8() + "\r\n";
    const int n = m_columns.size();
    for (int r = 0; r < m_rows; ++r) {
        for (int c = 0; c < n; ++c) {
            const double v = c == m_pan ? pan(r) : c == m_tilt ? tilt(r) : m_values.at(r * n + c);
            if (c > 0)
                out += ',';
            out += QLocale::c().toString(v, 'g', 12).toUtf8();
        }
        out += "\r\n";
    }
    if (file.write(out) != out.size())
        return reject(path, file.errorString());
    return true;
}
