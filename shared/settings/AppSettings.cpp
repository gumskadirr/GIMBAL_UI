#include "AppSettings.h"

namespace {
const QStringList kThemes{QStringLiteral("dark"), QStringLiteral("light")};
const QStringList kLanguages{QStringLiteral("tr"), QStringLiteral("en")};
const QString kThemeKey = QStringLiteral("ui/theme");
const QString kLanguageKey = QStringLiteral("ui/language");

QString validOr(const QString &value, const QStringList &allowed)
{
    return allowed.contains(value) ? value : allowed.first();
}
} // namespace

AppSettings::AppSettings(QObject *parent)
    : QObject(parent), m_settings(std::make_unique<QSettings>())
{
    load();
}

AppSettings::AppSettings(const QString &iniFilePath, QObject *parent)
    : QObject(parent), m_settings(std::make_unique<QSettings>(iniFilePath, QSettings::IniFormat))
{
    load();
}

void AppSettings::load()
{
    m_theme = validOr(m_settings->value(kThemeKey).toString(), kThemes);
    m_language = validOr(m_settings->value(kLanguageKey).toString(), kLanguages);
}

void AppSettings::setTheme(const QString &theme)
{
    if (!kThemes.contains(theme) || theme == m_theme)
        return;
    m_theme = theme;
    emit themeChanged();
    write(kThemeKey, theme);
}

void AppSettings::setLanguage(const QString &language)
{
    if (!kLanguages.contains(language) || language == m_language)
        return;
    m_language = language;
    emit languageChanged();
    write(kLanguageKey, language);
}

void AppSettings::write(const QString &key, const QString &value)
{
    m_settings->setValue(key, value);
    m_settings->sync();
    if (m_settings->status() != QSettings::NoError)
        emit writeFailed(key.section(QLatin1Char('/'), -1));
}
