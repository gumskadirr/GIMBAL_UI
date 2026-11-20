#pragma once

#include <QObject>
#include <QStringList>
#include <QUrl>
#include <QVector>
#include <QtQml/qqmlregistration.h>

// A script: a CSV file of numeric rows (header line + data rows, ',' or ';' separator, '.' decimals) and the
// choice of the Pan and Tilt columns with an offset each. A bad file is rejected as a whole with a line numbered
// reason; the previous script stays. Lives in the GUI thread.
class ScriptFile : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("Owned by the script runner")
    Q_PROPERTY(bool loaded READ loaded NOTIFY loadedChanged)
    Q_PROPERTY(QString path READ path NOTIFY loadedChanged)
    Q_PROPERTY(int rowCount READ rowCount NOTIFY loadedChanged)
    Q_PROPERTY(QStringList columns READ columns NOTIFY loadedChanged)
    Q_PROPERTY(int sampleMs READ sampleMs NOTIFY loadedChanged) // from the time_ms column; 0 = the file has none
    Q_PROPERTY(int panColumn READ panColumn WRITE setPanColumn NOTIFY axesChanged)   // -1 = none
    Q_PROPERTY(int tiltColumn READ tiltColumn WRITE setTiltColumn NOTIFY axesChanged)
    Q_PROPERTY(double panOffset READ panOffset WRITE setPanOffset NOTIFY axesChanged)
    Q_PROPERTY(double tiltOffset READ tiltOffset WRITE setTiltOffset NOTIFY axesChanged)

public:
    static constexpr qint64 kMaxBytes = 20 * 1024 * 1024; // shortcut: whole file in memory, ~1 M rows of 4 columns
    static constexpr int kMaxRows = 1000000;

    using QObject::QObject;

    bool loaded() const { return m_rows > 0; }
    QString path() const { return m_path; }
    int rowCount() const { return m_rows; }
    QStringList columns() const { return m_columns; }
    int sampleMs() const { return m_sampleMs; }
    int panColumn() const { return m_pan; }
    int tiltColumn() const { return m_tilt; }
    double panOffset() const { return m_panOffset; }
    double tiltOffset() const { return m_tiltOffset; }
    void setPanColumn(int column) { set(m_pan, column); }
    void setTiltColumn(int column) { set(m_tilt, column); }
    void setPanOffset(double offset) { set(m_panOffset, offset); }
    void setTiltOffset(double offset) { set(m_tiltOffset, offset); }

    // Value of a row for the Pan / Tilt column with its offset; NaN without a column or a row.
    double pan(int row) const { return value(row, m_pan, m_panOffset); }
    double tilt(int row) const { return value(row, m_tilt, m_tiltOffset); }

    Q_INVOKABLE bool load(const QUrl &url); // false: the reason is in error() and failed()
    bool loadData(const QByteArray &data, const QString &path = {});
    // Writes the rows with the offsets applied to the Pan and Tilt columns.
    Q_INVOKABLE bool save(const QUrl &url);
    QString error() const { return m_error; }

signals:
    void loadedChanged();
    void axesChanged();
    void failed(const QString &file, const QString &reason);

private:
    template<typename T>
    void set(T &field, T value)
    {
        if (field == value)
            return;
        field = value;
        emit axesChanged();
    }
    double value(int row, int column, double offset) const;
    bool reject(const QString &path, const QString &reason);

    QString m_path;
    QString m_error;
    QStringList m_columns;
    QVector<double> m_values; // row major
    int m_rows = 0;
    int m_sampleMs = 0;
    int m_pan = -1;
    int m_tilt = -1;
    double m_panOffset = 0;
    double m_tiltOffset = 0;
};
