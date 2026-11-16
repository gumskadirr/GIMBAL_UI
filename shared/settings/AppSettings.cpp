#include "AppSettings.h"

namespace {
const QStringList kThemes{QStringLiteral("dark"), QStringLiteral("light"), QStringLiteral("blue")};
const QStringList kLanguages{QStringLiteral("tr"), QStringLiteral("en")};
const QString kThemeKey = QStringLiteral("ui/theme");
const QString kLanguageKey = QStringLiteral("ui/language");

QString validOr(const QString &value, const QStringList &allowed)
{
    return allowed.contains(value) ? value : allowed.first();
}
} // namespace

AppSettings::AppSettings(QObject *parent) : QObject(parent)
{
    load();
}

AppSettings::AppSettings(const QString &iniFilePath, QObject *parent)
    : QObject(parent), m_iniFilePath(iniFilePath)
{
    load();
}

std::unique_ptr<QSettings> AppSettings::open() const
{
    return m_iniFilePath.isEmpty() ? std::make_unique<QSettings>()
                                   : std::make_unique<QSettings>(m_iniFilePath, QSettings::IniFormat);
}

void AppSettings::load()
{
    const auto settings = open();
    m_theme = validOr(settings->value(kThemeKey).toString(), kThemes);
    m_language = validOr(settings->value(kLanguageKey).toString(), kLanguages);
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
    // QSettings::status() keeps the first error forever, so every write gets a fresh object.
    const auto settings = open();
    settings->setValue(key, value);
    settings->sync();
    if (settings->status() != QSettings::NoError)
        emit writeFailed(key.section(QLatin1Char('/'), -1));
}
