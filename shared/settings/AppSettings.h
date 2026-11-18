#pragma once

#include <QObject>
#include <QSettings>
#include <QtQml/qqmlregistration.h>
#include <memory>

// Typed application preferences (not gimbal parameters). Invalid stored values fall back to defaults.
class AppSettings : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("Owned by the application")
    Q_PROPERTY(QString theme READ theme WRITE setTheme NOTIFY themeChanged)
    Q_PROPERTY(QString language READ language WRITE setLanguage NOTIFY languageChanged)
    Q_PROPERTY(QString lastPage READ lastPage WRITE setLastPage NOTIFY lastPageChanged)

public:
    explicit AppSettings(QObject *parent = nullptr); // platform store, keyed by org/app name
    explicit AppSettings(const QString &iniFilePath, QObject *parent = nullptr);

    QString theme() const { return m_theme; }      // "dark" | "light" | "blue"
    void setTheme(const QString &theme);
    QString language() const { return m_language; } // "tr" | "en"
    void setLanguage(const QString &language);
    QString lastPage() const { return m_lastPage; } // id of the page open at exit; unknown ids are resolved by the shell
    void setLastPage(const QString &page);

signals:
    void themeChanged();
    void languageChanged();
    void lastPageChanged();
    void writeFailed(const QString &key);

private:
    void load();
    std::unique_ptr<QSettings> open() const;
    void write(const QString &key, const QString &value);

    QString m_iniFilePath; // empty = platform store
    QString m_theme;
    QString m_language;
    QString m_lastPage;
};
