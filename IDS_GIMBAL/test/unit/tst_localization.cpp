#include <QCoreApplication>
#include <QSignalSpy>
#include <QTemporaryDir>
#include <QTest>

#include "shared/localization/Localization.h"

namespace {
QString sample()
{
    return QCoreApplication::translate("NotificationModel", "Language could not be loaded: %1");
}
const QString kEnglish = QStringLiteral("Language could not be loaded: %1");
const QString kTurkish = QStringLiteral("Dil yüklenemedi: %1");
} // namespace

class tst_Localization : public QObject
{
    Q_OBJECT

private slots:
    void startsInEnglish()
    {
        Localization l;
        QCOMPARE(l.language(), QStringLiteral("en"));
        QCOMPARE(sample(), kEnglish);
    }

    void switchToTurkishAndBack()
    {
        Localization l;
        QSignalSpy spy(&l, &Localization::languageChanged);
        QVERIFY(l.setLanguage("tr"));
        QCOMPARE(l.language(), QStringLiteral("tr"));
        QCOMPARE(spy.count(), 1);
        QCOMPARE(sample(), kTurkish);

        QVERIFY(l.setLanguage("en"));
        QCOMPARE(sample(), kEnglish);
    }

    void unsupportedKeepsCurrent()
    {
        Localization l;
        QVERIFY(l.setLanguage("tr"));
        QSignalSpy failed(&l, &Localization::languageLoadFailed);
        QVERIFY(!l.setLanguage("de"));
        QCOMPARE(l.language(), QStringLiteral("tr"));
        QCOMPARE(failed.count(), 1);
        QCOMPARE(sample(), kTurkish);
        l.setLanguage("en");
    }

    void missingQmKeepsCurrent()
    {
        QTemporaryDir empty;
        Localization l(empty.path());
        QSignalSpy failed(&l, &Localization::languageLoadFailed);
        QVERIFY(!l.setLanguage("tr"));
        QCOMPARE(l.language(), QStringLiteral("en"));
        QCOMPARE(failed.count(), 1);
        QCOMPARE(sample(), kEnglish);
    }

    void sameLanguageNoSignal()
    {
        Localization l;
        QSignalSpy spy(&l, &Localization::languageChanged);
        QVERIFY(l.setLanguage("en"));
        QCOMPARE(spy.count(), 0);
    }
};

QTEST_GUILESS_MAIN(tst_Localization)
#include "tst_localization.moc"
