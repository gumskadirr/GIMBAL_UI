#include <QSignalSpy>
#include <QTest>

#include "shared/localization/Localization.h"
#include "shared/notifications/NotificationModel.h"

class tst_NotificationModel : public QObject
{
    Q_OBJECT

    static QVariant at(const NotificationModel &m, int row, int role)
    {
        return m.data(m.index(row), role);
    }

private slots:
    void newestFirst()
    {
        NotificationModel m;
        m.add("a", {}, NotificationModel::Info);
        m.add("b", {}, NotificationModel::Info);
        m.add("c", {}, NotificationModel::Info);
        QCOMPARE(m.rowCount(), 3);
        QCOMPARE(at(m, 0, NotificationModel::CodeRole).toString(), QStringLiteral("c"));
    }

    void mergeRepeated()
    {
        NotificationModel m;
        m.add("x", {}, NotificationModel::Error, "raw");
        m.add("y", {}, NotificationModel::Error);
        m.add("x", {}, NotificationModel::Error, "raw");
        QCOMPARE(m.rowCount(), 2);
        QCOMPARE(at(m, 0, NotificationModel::CodeRole).toString(), QStringLiteral("x")); // moved to top
        QCOMPARE(at(m, 0, NotificationModel::CountRole).toInt(), 2);
    }

    void differentDetailNotMerged()
    {
        NotificationModel m;
        m.add("x", {}, NotificationModel::Error, "a");
        m.add("x", {}, NotificationModel::Error, "b");
        QCOMPARE(m.rowCount(), 2);
    }

    void capacityBounded()
    {
        NotificationModel m;
        for (int i = 0; i < 60; ++i)
            m.add(QStringLiteral("c%1").arg(i), {}, NotificationModel::Info);
        QCOMPARE(m.rowCount(), NotificationModel::kCapacity);
        QCOMPARE(at(m, 0, NotificationModel::CodeRole).toString(), QStringLiteral("c59"));
        QCOMPARE(at(m, 49, NotificationModel::CodeRole).toString(), QStringLiteral("c10"));
    }

    void textFormatting()
    {
        NotificationModel m;
        m.add("language.loadFailed", {"de"}, NotificationModel::Warning);
        QCOMPARE(at(m, 0, NotificationModel::TextRole).toString(),
                 QStringLiteral("Language could not be loaded: de"));
    }

    void appDetailFollowsLanguage()
    {
        NotificationModel m;
        m.add("device.error.mainControl", {}, NotificationModel::Error, "No serial port selected");
        m.add("device.error.mainControl", {}, NotificationModel::Error, "RAW-ERR 0x12");
        Localization l;
        QVERIFY(l.setLanguage("tr"));
        QCOMPARE(at(m, 1, NotificationModel::DetailRole).toString(),
                 QStringLiteral("Seri port seçilmedi"));
        QCOMPARE(at(m, 0, NotificationModel::DetailRole).toString(), QStringLiteral("RAW-ERR 0x12"));
        l.setLanguage("en");
    }

    void unknownCodeShowsCode()
    {
        NotificationModel m;
        m.add("foo.bar", {}, NotificationModel::Info);
        QCOMPARE(at(m, 0, NotificationModel::TextRole).toString(), QStringLiteral("foo.bar"));
    }

    void detailPreserved()
    {
        NotificationModel m;
        m.add("x", {}, NotificationModel::Warning, "RAW-ERR 0x12");
        QCOMPARE(at(m, 0, NotificationModel::DetailRole).toString(), QStringLiteral("RAW-ERR 0x12"));
    }

    void retranslateEmitsDataChanged()
    {
        NotificationModel m;
        m.add("a", {}, NotificationModel::Info);
        m.add("b", {}, NotificationModel::Info);
        QSignalSpy spy(&m, &NotificationModel::dataChanged);
        m.retranslate();
        QCOMPARE(spy.count(), 1);
        const auto roles = spy.at(0).at(2).value<QList<int>>();
        QVERIFY(roles.contains(NotificationModel::TextRole));
    }

    void dismissAndClear()
    {
        NotificationModel m;
        m.add("a", {}, NotificationModel::Info);
        m.add("b", {}, NotificationModel::Info);
        m.dismiss(0);
        QCOMPARE(m.rowCount(), 1);
        QCOMPARE(at(m, 0, NotificationModel::CodeRole).toString(), QStringLiteral("a"));
        m.dismiss(5); // out of range is ignored
        m.clear();
        QCOMPARE(m.rowCount(), 0);
    }
};

QTEST_GUILESS_MAIN(tst_NotificationModel)
#include "tst_notificationmodel.moc"
