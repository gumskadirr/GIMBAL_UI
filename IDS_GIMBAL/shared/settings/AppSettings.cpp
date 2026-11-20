#include "AppSettings.h"

#include <QFileInfo>
#include <QStandardPaths>

namespace {
const QStringList kThemes{QStringLiteral("dark"), QStringLiteral("light"), QStringLiteral("blue")};
const QStringList kLanguages{QStringLiteral("tr"), QStringLiteral("en")};
const QString kThemeKey = QStringLiteral("ui/theme");
const QString kLanguageKey = QStringLiteral("ui/language");
const QString kLastPageKey = QStringLiteral("ui/lastPage");
const QString kRtspUrlKey = QStringLiteral("image/rtspUrl");
const QString kGimbalKey = QStringLiteral("gimbal/id");
const QString kGimbalVersionKey = QStringLiteral("gimbal/version");
const QString kGimbalOnStartKey = QStringLiteral("gimbal/onStart");
const QString kDefaultRtspUrl = QStringLiteral("rtsp://192.168.1.160:8554/operator/h264");

QString validOr(const QString &value, const QStringList &allowed)
{
    return allowed.contains(value) ? value : allowed.first();
}
} // namespace

AppSettings::AppSettings(QObject *parent)
    : QObject(parent),
      m_gimbalLibrary(std::make_unique<GimbalLibrary>(
          QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) + QStringLiteral("/gimbals")))
{
    load();
}

AppSettings::AppSettings(const QString &iniFilePath, QObject *parent)
    : QObject(parent), m_iniFilePath(iniFilePath),
      m_gimbalLibrary(std::make_unique<GimbalLibrary>(QFileInfo(iniFilePath).absolutePath() + QStringLiteral("/gimbals")))
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
    m_lastPage = settings->value(kLastPageKey).toString();
    m_rtspUrl = settings->value(kRtspUrlKey, kDefaultRtspUrl).toString();
    m_gimbal = settings->value(kGimbalKey).toString();
    m_gimbalVersion = settings->value(kGimbalVersionKey).toString();
    m_gimbalOnStart = settings->value(kGimbalOnStartKey, true).toBool();
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

void AppSettings::setLastPage(const QString &page)
{
    if (page == m_lastPage)
        return;
    m_lastPage = page;
    emit lastPageChanged();
    write(kLastPageKey, page);
}

void AppSettings::setRtspUrl(const QString &url)
{
    if (url == m_rtspUrl)
        return;
    m_rtspUrl = url;
    emit rtspUrlChanged();
    write(kRtspUrlKey, url);
}

void AppSettings::setGimbal(const QString &id)
{
    if (id == m_gimbal)
        return;
    m_gimbal = id;
    emit gimbalChanged();
    write(kGimbalKey, id);
}

void AppSettings::setGimbalVersion(const QString &version)
{
    if (version == m_gimbalVersion)
        return;
    m_gimbalVersion = version;
    emit gimbalVersionChanged();
    write(kGimbalVersionKey, version);
}

void AppSettings::setGimbalOnStart(bool on)
{
    if (on == m_gimbalOnStart)
        return;
    m_gimbalOnStart = on;
    emit gimbalOnStartChanged();
    write(kGimbalOnStartKey, on ? QStringLiteral("true") : QStringLiteral("false"));
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
