#pragma once

#include <QDir>
#include <QFileInfo>
#include <QObject>
#include <QUrl>
#include <QtQml/qqmlregistration.h>

// Name, size and folder of a local file chosen in a FileDialog; the file is never read.
class FileInfo : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(QUrl source READ source WRITE setSource NOTIFY changed)
    Q_PROPERTY(bool exists READ exists NOTIFY changed)
    Q_PROPERTY(QString path READ path NOTIFY changed)     // local path, as sent to the device layer
    Q_PROPERTY(QString name READ name NOTIFY changed)
    Q_PROPERTY(qint64 size READ size NOTIFY changed)      // bytes
    Q_PROPERTY(QString folder READ folder NOTIFY changed) // native separators, ends with one

public:
    using QObject::QObject;

    QUrl source() const { return m_source; }
    void setSource(const QUrl &source)
    {
        if (source == m_source)
            return;
        m_source = source;
        m_info = QFileInfo(source.toLocalFile());
        emit changed();
    }
    bool exists() const { return m_info.isFile(); }
    QString path() const { return m_info.filePath(); }
    QString name() const { return m_info.fileName(); }
    qint64 size() const { return m_info.size(); }
    QString folder() const { return QDir::toNativeSeparators(m_info.absolutePath() + QLatin1Char('/')); }

signals:
    void changed();

private:
    QUrl m_source;
    QFileInfo m_info;
};
