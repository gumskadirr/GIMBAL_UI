#include <QFile>
#include <QSettings>
#include <QSignalSpy>
#include <QTemporaryDir>
#include <QTest>

#include "shared/settings/AppSettings.h"

class tst_AppSettings : public QObject
{
    Q_OBJECT

private:
    QTemporaryDir m_dir;
    QString path() const { return m_dir.filePath(QStringLiteral("settings.ini")); }

private slots:
    void init() { QFile::remove(path()); }

    void defaultsWhenEmpty()
    {
        AppSettings s(path());
        QCOMPARE(s.theme(), QStringLiteral("dark"));
        QCOMPARE(s.language(), QStringLiteral("tr"));
    }

    void persistsAcrossInstances()
    {
        {
            AppSettings s(path());
            s.setTheme(QStringLiteral("light"));
            s.setLanguage(QStringLiteral("en"));
        }
        AppSettings s2(path());
        QCOMPARE(s2.theme(), QStringLiteral("light"));
        QCOMPARE(s2.language(), QStringLiteral("en"));
    }

    void invalidStoredValuesFallBack()
    {
        {
            QSettings raw(path(), QSettings::IniFormat);
            raw.setValue("ui/theme", "purple");
            raw.setValue("ui/language", "de");
        }
        AppSettings s(path());
        QCOMPARE(s.theme(), QStringLiteral("dark"));
        QCOMPARE(s.language(), QStringLiteral("tr"));
    }

    void invalidSetIgnored()
    {
        AppSettings s(path());
        QSignalSpy spy(&s, &AppSettings::themeChanged);
        s.setTheme(QStringLiteral("purple"));
        QCOMPARE(s.theme(), QStringLiteral("dark"));
        QCOMPARE(spy.count(), 0);
    }

    void writeFailureReported()
    {
        // A directory cannot be written as a settings file; a read-only file is not enough on
        // Windows because QSettings replaces the file atomically.
        AppSettings s(m_dir.path());
        QSignalSpy spy(&s, &AppSettings::writeFailed);
        s.setTheme(QStringLiteral("light"));

        QCOMPARE(spy.count(), 1);
        QCOMPARE(spy.at(0).at(0).toString(), QStringLiteral("theme"));
        QCOMPARE(s.theme(), QStringLiteral("light")); // app stays usable
    }
};

QTEST_GUILESS_MAIN(tst_AppSettings)
#include "tst_appsettings.moc"
