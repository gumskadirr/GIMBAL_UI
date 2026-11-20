#include <QDir>
#include <QFile>
#include <QJsonValue>
#include <QSignalSpy>
#include <QTemporaryDir>
#include <QTest>
#include <QUrl>

#include "shared/settings/GimbalLibrary.h"

class tst_GimbalLibrary : public QObject
{
    Q_OBJECT

private:
    std::unique_ptr<QTemporaryDir> m_dir;
    QString dir() const { return m_dir->path(); }

    // A small .glb-named source file outside the library.
    QString source(const QString &name, const QByteArray &content = "glTF")
    {
        const QString path = m_dir->filePath(QStringLiteral("src/") + name);
        QDir().mkpath(QFileInfo(path).absolutePath());
        QFile file(path);
        file.open(QIODevice::WriteOnly);
        file.write(content);
        return path;
    }
    static QVariantMap model() { return {{QStringLiteral("tiltPivot"), QVariantList{1, 2, 3}}}; }
    QVariantMap threeFiles()
    {
        return {{QStringLiteral("base"), QUrl::fromLocalFile(source(QStringLiteral("b.glb"))).toString()},
                {QStringLiteral("pan"), source(QStringLiteral("p.glb"))},
                {QStringLiteral("tilt"), source(QStringLiteral("t.glb"))}};
    }
    static QVariantMap find(const GimbalLibrary &lib, const QString &id)
    {
        for (const QVariant &g : lib.gimbals())
            if (g.toMap().value(QStringLiteral("id")) == id)
                return g.toMap();
        return {};
    }
    static QString file(const QVariantMap &gimbal, const QString &part)
    {
        return QUrl(gimbal.value(QStringLiteral("model")).toMap().value(part).toString()).toLocalFile();
    }
    static QVariantMap gimbal(const QString &id, const QString &name, const QVariant &model = {})
    {
        return {{QStringLiteral("id"), id}, {QStringLiteral("name"), name},
                {QStringLiteral("versions"), QVariantList{QStringLiteral("v1.0")}}, {QStringLiteral("model"), model}};
    }

private slots:
    void init() { m_dir = std::make_unique<QTemporaryDir>(); }

    void seedsDefaults()
    {
        GimbalLibrary lib(dir());
        QStringList names;
        for (const QVariant &g : lib.gimbals())
            names << g.toMap().value(QStringLiteral("name")).toString();
        QCOMPARE(names, (QStringList{"G160", "G180", "Kashif700", "ZR10"}));
        QVERIFY(find(lib, "g180").value(QStringLiteral("model")).isNull());
        const QVariantMap zr10 = find(lib, "zr10");
        QVERIFY(QFile(file(zr10, "tilt")).size() > 1000); // the bundled model
        QCOMPARE(zr10.value("model").toMap().value("tiltSign").toInt(), -1);
        QVERIFY(QFile::exists(dir() + "/gimbals.json"));
        QCOMPARE(QJsonValue::fromVariant(GimbalLibrary(dir()).gimbals()), QJsonValue::fromVariant(lib.gimbals())); // read back
    }

    void addCopiesFilesAndPersists()
    {
        GimbalLibrary lib(dir());
        QSignalSpy spy(&lib, &GimbalLibrary::changed);
        QCOMPARE(lib.save(gimbal({}, "G 200", model()), threeFiles()), QString());
        QCOMPARE(spy.count(), 1);
        const QVariantMap added = find(GimbalLibrary(dir()), "g200");
        QCOMPARE(added.value("name").toString(), QStringLiteral("G 200"));
        QVERIFY(file(added, "base").startsWith(dir() + "/g200/"));
        QCOMPARE(added.value("model").toMap().value("tiltPivot").toList().at(2).toDouble(), 3.0);
        QVERIFY(added.value("model").toMap().value("inPlace").toBool()); // default for new gimbals
    }

    void filesAreCopied()
    {
        GimbalLibrary lib(dir());
        QCOMPARE(lib.save(gimbal({}, "G200", model()), threeFiles()), QString());
        QVERIFY(QDir(dir() + "/src").removeRecursively());
        QVERIFY(QFile::exists(file(find(lib, "g200"), "pan")));
    }

    void editKeepsFiles()
    {
        GimbalLibrary lib(dir());
        lib.save(gimbal({}, "G200", model()), threeFiles());
        const QString pan = file(find(lib, "g200"), "pan");
        QCOMPARE(lib.save(gimbal("g200", "G200 Pro", model())), QString());
        const QVariantMap edited = find(lib, "g200"); // the id stays
        QCOMPARE(edited.value("name").toString(), QStringLiteral("G200 Pro"));
        QCOMPARE(file(edited, "pan"), pan);
        QVERIFY(QFile::exists(pan));
    }

    void editReplacesFile()
    {
        GimbalLibrary lib(dir());
        lib.save(gimbal({}, "G200", model()), threeFiles());
        const QString oldTilt = file(find(lib, "g200"), "tilt");
        QCOMPARE(lib.save(gimbal("g200", "G200", model()), {{"tilt", source("t2.glb", "new")}}), QString());
        const QString newTilt = file(find(lib, "g200"), "tilt");
        QVERIFY(newTilt != oldTilt); // a new name, so the view reloads
        QVERIFY(!QFile::exists(oldTilt));
        QFile f(newTilt);
        QVERIFY(f.open(QIODevice::ReadOnly));
        QCOMPARE(f.readAll(), QByteArray("new"));
    }

    void removeDeletesFolder()
    {
        GimbalLibrary lib(dir());
        QVERIFY(QDir(dir() + "/zr10").exists());
        QCOMPARE(lib.remove("zr10"), QString());
        QVERIFY(!QDir(dir() + "/zr10").exists());
        QVERIFY(find(GimbalLibrary(dir()), "zr10").isEmpty());
        QVERIFY(!lib.remove("zr10").isEmpty());
    }

    void duplicateNameRejected()
    {
        GimbalLibrary lib(dir());
        QVERIFY(!lib.save(gimbal({}, "g180")).isEmpty());
        QVERIFY(!lib.save(gimbal("g160", "G180")).isEmpty());
        QCOMPARE(lib.save(gimbal("g180", "g180")), QString()); // its own name, other case
        QCOMPARE(lib.gimbals().size(), 4);
    }

    void versionsValidated()
    {
        GimbalLibrary lib(dir());
        QVariantMap g = gimbal({}, "G200");
        g["versions"] = QVariantList{" ", ""};
        QVERIFY(!lib.save(g).isEmpty());
        g["versions"] = QVariantList{"v1", " v1 "};
        QVERIFY(!lib.save(g).isEmpty());
        g["versions"] = QVariantList{" v1 ", "v2"};
        QCOMPARE(lib.save(g), QString());
        QCOMPARE(find(lib, "g200").value("versions").toStringList(), (QStringList{"v1", "v2"}));
        QVERIFY(!lib.save(gimbal({}, "  ")).isEmpty());
    }

    void modelNeedsAllThreeFiles()
    {
        GimbalLibrary lib(dir());
        QVariantMap files = threeFiles();
        files.remove("tilt");
        QVERIFY(!lib.save(gimbal({}, "G200", model()), files).isEmpty());
        QVERIFY(find(lib, "g200").isEmpty());
        QVERIFY(QDir(dir() + "/g200").isEmpty()); // the copies made before the error are removed
        files = threeFiles();
        files["pan"] = source("p.obj");
        QVERIFY(!lib.save(gimbal({}, "G200", model()), files).isEmpty());
    }

    void removingModelDeletesFiles()
    {
        GimbalLibrary lib(dir());
        QCOMPARE(lib.save(gimbal("zr10", "ZR10")), QString());
        QVERIFY(find(lib, "zr10").value("model").isNull());
        QVERIFY(!QDir(dir() + "/zr10").exists());
    }

    void corruptFileIsKept()
    {
        QDir().mkpath(dir());
        QFile file(dir() + "/gimbals.json");
        QVERIFY(file.open(QIODevice::WriteOnly));
        file.write("{ not json");
        file.close();
        GimbalLibrary lib(dir());
        QCOMPARE(lib.gimbals().size(), 4);
        QCOMPARE(lib.keptBadFile(), dir() + "/gimbals.json.bad");
        QFile bad(lib.keptBadFile());
        QVERIFY(bad.open(QIODevice::ReadOnly));
        QCOMPARE(bad.readAll(), QByteArray("{ not json"));
    }

    void idFromName()
    {
        GimbalLibrary lib(dir());
        lib.save(gimbal({}, "Kashif 700!"));          // name differs from "Kashif700" only in spaces: allowed
        QVERIFY(!find(lib, "kashif700-2").isEmpty()); // id taken: suffixed
        lib.save(gimbal({}, "Ğ*"));
        QVERIFY(!find(lib, "gimbal").isEmpty());
    }
};

QTEST_GUILESS_MAIN(tst_GimbalLibrary)
#include "tst_gimballibrary.moc"
