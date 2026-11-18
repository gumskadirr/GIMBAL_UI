#include <QDir>
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

    void lastPagePersists()
    {
        {
            AppSettings s(path());
            QCOMPARE(s.lastPage(), QString());
            s.setLastPage(QStringLiteral("heater"));
        }
        AppSettings s2(path());
        QCOMPARE(s2.lastPage(), QStringLiteral("heater"));
    }

    void rtspUrlPersists()
    {
        {
            AppSettings s(path());
            QVERIFY(s.rtspUrl().startsWith(QLatin1String("rtsp://")));
            s.setRtspUrl(QStringLiteral("rtsp://10.0.0.5/cam"));
        }
        AppSettings s2(path());
        QCOMPARE(s2.rtspUrl(), QStringLiteral("rtsp://10.0.0.5/cam"));
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

    void writeRecoversAfterFailure()
    {
        const QString blocked = m_dir.filePath(QStringLiteral("blocked.ini"));
        QVERIFY(QDir().mkdir(blocked)); // a directory where the settings file should be
        AppSettings s(blocked);
        QSignalSpy spy(&s, &AppSettings::writeFailed);
        s.setTheme(QStringLiteral("light"));
        QCOMPARE(spy.count(), 1);

        QVERIFY(QDir().rmdir(blocked));
        s.setTheme(QStringLiteral("blue"));
        QCOMPARE(spy.count(), 1); // an earlier failure does not taint later writes
        QCOMPARE(AppSettings(blocked).theme(), QStringLiteral("blue"));
    }
};

QTEST_GUILESS_MAIN(tst_AppSettings)
#include "tst_appsettings.moc"
