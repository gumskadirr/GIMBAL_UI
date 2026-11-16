#include <QFontDatabase>
#include <QFontInfo>
#include <QTest>

#include "shared/ui/Fonts.h"

class tst_Fonts : public QObject
{
    Q_OBJECT

private slots:
    void embeddedFontsLoad()
    {
        QCOMPARE(loadAppFonts(), QStringList{});
        const QStringList families = QFontDatabase::families();
        QVERIFY(families.contains(QStringLiteral("Inter")));
        QVERIFY(families.contains(QStringLiteral("JetBrains Mono")));
    }

    void familiesResolveWithoutFallback()
    {
        loadAppFonts();
        QFont sans(QStringLiteral("Inter"));
        sans.setWeight(QFont::DemiBold);
        QCOMPARE(QFontInfo(sans).family(), QStringLiteral("Inter"));
        QCOMPARE(QFontInfo(QFont(QStringLiteral("JetBrains Mono"))).family(), QStringLiteral("JetBrains Mono"));
    }
};

QTEST_MAIN(tst_Fonts)
#include "tst_fonts.moc"
