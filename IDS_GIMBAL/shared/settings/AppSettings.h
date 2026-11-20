#pragma once

#include <QObject>
#include <QSettings>
#include <QtQml/qqmlregistration.h>
#include <memory>

#include "GimbalLibrary.h"

// Typed application preferences (not gimbal parameters). Invalid stored values fall back to defaults.
class AppSettings : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("Owned by the application")
    Q_PROPERTY(QString theme READ theme WRITE setTheme NOTIFY themeChanged)
    Q_PROPERTY(QString language READ language WRITE setLanguage NOTIFY languageChanged)
    Q_PROPERTY(QString lastPage READ lastPage WRITE setLastPage NOTIFY lastPageChanged)
    Q_PROPERTY(QString rtspUrl READ rtspUrl WRITE setRtspUrl NOTIFY rtspUrlChanged)
    Q_PROPERTY(QString gimbal READ gimbal WRITE setGimbal NOTIFY gimbalChanged)
    Q_PROPERTY(QString gimbalVersion READ gimbalVersion WRITE setGimbalVersion NOTIFY gimbalVersionChanged)
    Q_PROPERTY(bool gimbalOnStart READ gimbalOnStart WRITE setGimbalOnStart NOTIFY gimbalOnStartChanged)
    Q_PROPERTY(GimbalLibrary *gimbalLibrary READ gimbalLibrary CONSTANT)

public:
    explicit AppSettings(QObject *parent = nullptr); // platform store, keyed by org/app name
    explicit AppSettings(const QString &iniFilePath, QObject *parent = nullptr);

    QString theme() const { return m_theme; }      // "dark" | "light" | "blue"
    void setTheme(const QString &theme);
    QString language() const { return m_language; } // "tr" | "en"
    void setLanguage(const QString &language);
    QString lastPage() const { return m_lastPage; } // id of the page open at exit; unknown ids are resolved by the shell
    void setLastPage(const QString &page);
    QString rtspUrl() const { return m_rtspUrl; } // IDS Image video source (the design's address until changed)
    void setRtspUrl(const QString &url);
    // Gimbal the user works with (display only: top bar and 3D view). Unknown ids are resolved by the shell.
    QString gimbal() const { return m_gimbal; }
    void setGimbal(const QString &id);
    QString gimbalVersion() const { return m_gimbalVersion; }
    void setGimbalVersion(const QString &version);
    bool gimbalOnStart() const { return m_gimbalOnStart; } // false: the selection opens at every start
    void setGimbalOnStart(bool on);
    // The gimbal list and 3D models, next to the settings file (or in the platform app data folder).
    GimbalLibrary *gimbalLibrary() const { return m_gimbalLibrary.get(); }

signals:
    void themeChanged();
    void languageChanged();
    void lastPageChanged();
    void rtspUrlChanged();
    void gimbalChanged();
    void gimbalVersionChanged();
    void gimbalOnStartChanged();
    void writeFailed(const QString &key);

private:
    void load();
    std::unique_ptr<QSettings> open() const;
    void write(const QString &key, const QString &value);

    QString m_iniFilePath; // empty = platform store
    QString m_theme;
    QString m_language;
    QString m_lastPage;
    QString m_rtspUrl;
    QString m_gimbal;
    QString m_gimbalVersion;
    bool m_gimbalOnStart = true;
    std::unique_ptr<GimbalLibrary> m_gimbalLibrary;
};
