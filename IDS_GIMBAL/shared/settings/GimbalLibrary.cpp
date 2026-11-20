#include "GimbalLibrary.h"

#include <algorithm>
#include <QDateTime>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QSaveFile>
#include <QUrl>

namespace {
const QStringList kParts{QStringLiteral("base"), QStringLiteral("pan"), QStringLiteral("tilt")};
const QStringList kAxes{QStringLiteral("x"), QStringLiteral("y"), QStringLiteral("z")};
const QString kBundledZr10 = QStringLiteral(":/qt/qml/IDS_GIMBAL/features/gimbal3d/zr10/");

QString localPath(const QVariant &fileOrUrl)
{
    const QString text = fileOrUrl.toString();
    const QUrl url(text);
    return url.isLocalFile() ? url.toLocalFile() : text;
}

QVariantList vector(const QVariant &value)
{
    const QVariantList list = value.toList();
    QVariantList out;
    for (int i = 0; i < 3; ++i)
        out << (i < list.size() ? list.at(i).toDouble() : 0.0);
    return out;
}

// Keeps only the known model fields, with valid values.
QVariantMap cleanModel(const QVariantMap &model)
{
    const auto axis = [&](const QString &key, const QString &fallback) {
        const QString value = model.value(key).toString().toLower();
        return kAxes.contains(value) ? value : fallback;
    };
    return {
        {QStringLiteral("panAxis"), axis(QStringLiteral("panAxis"), QStringLiteral("y"))},
        {QStringLiteral("panSign"), model.value(QStringLiteral("panSign")).toDouble() < 0 ? -1 : 1},
        {QStringLiteral("panPivot"), vector(model.value(QStringLiteral("panPivot")))},
        {QStringLiteral("tiltAxis"), axis(QStringLiteral("tiltAxis"), QStringLiteral("x"))},
        {QStringLiteral("tiltSign"), model.value(QStringLiteral("tiltSign")).toDouble() < 0 ? -1 : 1},
        {QStringLiteral("tiltPivot"), vector(model.value(QStringLiteral("tiltPivot")))},
        {QStringLiteral("inPlace"), model.value(QStringLiteral("inPlace"), true).toBool()},
    };
}

QVariantMap entry(const QString &id, const QString &name, const QStringList &versions)
{
    return {{QStringLiteral("id"), id}, {QStringLiteral("name"), name},
            {QStringLiteral("versions"), QVariant(versions)}, {QStringLiteral("model"), QVariant()}};
}
} // namespace

GimbalLibrary::GimbalLibrary(const QString &dir, QObject *parent) : QObject(parent), m_dir(dir)
{
    reload();
}

QString GimbalLibrary::listPath() const { return m_dir + QStringLiteral("/gimbals.json"); }
QString GimbalLibrary::folder(const QString &id) const { return m_dir + u'/' + id; }

void GimbalLibrary::reload()
{
    m_entries.clear();
    m_keptBadFile.clear();
    QFile file(listPath());
    if (!file.exists()) {
        seedDefaults();
        return;
    }
    QJsonParseError error{};
    const QJsonDocument doc = file.open(QIODevice::ReadOnly) ? QJsonDocument::fromJson(file.readAll(), &error)
                                                             : QJsonDocument();
    file.close();
    if (!doc.isArray()) {
        const QString bad = listPath() + QStringLiteral(".bad");
        QFile::remove(bad);
        QFile::rename(listPath(), bad);
        m_keptBadFile = bad;
        emit problem(QStringLiteral("gimbals.readFailed"), bad);
        seedDefaults();
        return;
    }
    for (const QVariant &item : doc.array().toVariantList()) {
        const QVariantMap map = item.toMap();
        if (!map.value(QStringLiteral("id")).toString().isEmpty() && !map.value(QStringLiteral("name")).toString().isEmpty())
            m_entries << map;
    }
    emit changed();
}

void GimbalLibrary::seedDefaults()
{
    m_entries = {entry(QStringLiteral("g160"), QStringLiteral("G160"), {QStringLiteral("v1.0"), QStringLiteral("v2.0")}),
                 entry(QStringLiteral("g180"), QStringLiteral("G180"),
                       {QStringLiteral("v1.0"), QStringLiteral("v2.0"), QStringLiteral("v3.0")}),
                 entry(QStringLiteral("kashif700"), QStringLiteral("Kashif700"), {QStringLiteral("v1.0")})};
    // ZR10 comes with the application; its files are centred on their axes (not in assembly position).
    QVariantMap zr10 = entry(QStringLiteral("zr10"), QStringLiteral("ZR10"), {QStringLiteral("v1.0")});
    QVariantMap model = cleanModel({{QStringLiteral("tiltPivot"), QVariantList{-4.1, -53.1, 13.94}},
                                    {QStringLiteral("tiltSign"), -1},
                                    {QStringLiteral("inPlace"), false}});
    QDir().mkpath(folder(zr10.value(QStringLiteral("id")).toString()));
    bool copied = true;
    for (const QString &part : kParts) {
        const QString target = folder(QStringLiteral("zr10")) + u'/' + part + QStringLiteral(".glb");
        QFile::remove(target);
        copied = QFile::copy(kBundledZr10 + part + QStringLiteral(".glb"), target) && copied;
        QFile::setPermissions(target, QFile::ReadOwner | QFile::WriteOwner); // resource copies are read-only
        model.insert(part, part + QStringLiteral(".glb"));
    }
    if (copied)
        zr10.insert(QStringLiteral("model"), model);
    m_entries << zr10;
    write();
    emit changed();
}

bool GimbalLibrary::write()
{
    QDir().mkpath(m_dir);
    QSaveFile file(listPath());
    if (file.open(QIODevice::WriteOnly)
        && file.write(QJsonDocument(QJsonArray::fromVariantList(m_entries)).toJson()) >= 0 && file.commit())
        return true;
    emit problem(QStringLiteral("gimbals.writeFailed"), listPath());
    return false;
}

QVariantMap GimbalLibrary::toQml(const QVariantMap &stored) const
{
    QVariantMap out = stored;
    const QVariantMap model = stored.value(QStringLiteral("model")).toMap();
    if (model.isEmpty()) {
        out.insert(QStringLiteral("model"), QVariant::fromValue(nullptr)); // null in QML, not undefined
        return out;
    }
    QVariantMap qml = cleanModel(model);
    const QString dir = folder(stored.value(QStringLiteral("id")).toString());
    for (const QString &part : kParts)
        qml.insert(part, QUrl::fromLocalFile(dir + u'/' + model.value(part).toString()).toString());
    out.insert(QStringLiteral("model"), qml);
    return out;
}

QVariantList GimbalLibrary::gimbals() const
{
    QVariantList out;
    for (const QVariant &stored : m_entries)
        out << toQml(stored.toMap());
    return out;
}

QString GimbalLibrary::uniqueId(const QString &name) const
{
    QString base;
    for (const QChar c : name.toLower())
        if ((c >= u'a' && c <= u'z') || (c >= u'0' && c <= u'9'))
            base += c;
    if (base.isEmpty())
        base = QStringLiteral("gimbal");
    const auto taken = [&](const QString &id) {
        return std::any_of(m_entries.cbegin(), m_entries.cend(),
                           [&](const QVariant &e) { return e.toMap().value(QStringLiteral("id")) == id; });
    };
    QString id = base;
    for (int n = 2; taken(id); ++n)
        id = base + u'-' + QString::number(n);
    return id;
}

QString GimbalLibrary::save(const QVariantMap &gimbal, const QVariantMap &files)
{
    const QString name = gimbal.value(QStringLiteral("name")).toString().trimmed();
    if (name.isEmpty())
        return tr("Enter a name.");
    QStringList versions;
    for (const QVariant &v : gimbal.value(QStringLiteral("versions")).toList()) {
        const QString version = v.toString().trimmed();
        if (version.isEmpty())
            continue;
        if (versions.contains(version))
            return tr("Version %1 is listed twice.").arg(version);
        versions << version;
    }
    if (versions.isEmpty())
        return tr("Enter at least one version.");

    const QString givenId = gimbal.value(QStringLiteral("id")).toString();
    qsizetype index = -1;
    for (qsizetype i = 0; i < m_entries.size(); ++i) {
        const QVariantMap other = m_entries.at(i).toMap();
        if (other.value(QStringLiteral("id")).toString() == givenId)
            index = i;
        else if (other.value(QStringLiteral("name")).toString().compare(name, Qt::CaseInsensitive) == 0)
            return tr("A gimbal named %1 already exists.").arg(name);
    }
    const QVariantMap old = index >= 0 ? m_entries.at(index).toMap() : QVariantMap();
    const QString id = index >= 0 ? givenId : uniqueId(name);
    const QVariantMap oldModel = old.value(QStringLiteral("model")).toMap();

    QVariantMap stored = entry(id, name, versions);
    const QVariant modelValue = gimbal.value(QStringLiteral("model"));
    if (modelValue.isValid() && !modelValue.isNull()) {
        QVariantMap model = cleanModel(modelValue.toMap());
        QStringList copied, replaced;
        const auto undo = [&] {
            for (const QString &file : copied)
                QFile::remove(file);
        };
        QDir().mkpath(folder(id));
        for (const QString &part : kParts) {
            const QString source = localPath(files.value(part));
            if (source.isEmpty()) {
                const QString kept = oldModel.value(part).toString();
                if (kept.isEmpty()) {
                    undo();
                    return tr("Choose the base, pan and tilt files.");
                }
                model.insert(part, kept);
                continue;
            }
            if (!source.endsWith(QStringLiteral(".glb"), Qt::CaseInsensitive)) {
                undo();
                return tr("%1 is not a .glb file.").arg(QFileInfo(source).fileName());
            }
            // A new name per copy, so a view showing the old file reloads.
            const QString fileName = part + u'-' + QString::number(QDateTime::currentMSecsSinceEpoch()) + QStringLiteral(".glb");
            const QString target = folder(id) + u'/' + fileName;
            if (!QFile::copy(source, target)) {
                undo();
                return tr("%1 could not be copied.").arg(QFileInfo(source).fileName());
            }
            QFile::setPermissions(target, QFile::ReadOwner | QFile::WriteOwner);
            copied << target;
            if (!oldModel.value(part).toString().isEmpty())
                replaced << folder(id) + u'/' + oldModel.value(part).toString();
            model.insert(part, fileName);
        }
        for (const QString &file : replaced)
            QFile::remove(file);
        stored.insert(QStringLiteral("model"), model);
    } else if (!oldModel.isEmpty()) {
        QDir(folder(id)).removeRecursively();
    }

    if (index >= 0)
        m_entries[index] = stored;
    else
        m_entries << stored;
    write();
    emit changed();
    return {};
}

QString GimbalLibrary::remove(const QString &id)
{
    for (qsizetype i = 0; i < m_entries.size(); ++i) {
        if (m_entries.at(i).toMap().value(QStringLiteral("id")).toString() != id)
            continue;
        m_entries.removeAt(i);
        QDir(folder(id)).removeRecursively();
        write();
        emit changed();
        return {};
    }
    return tr("Unknown gimbal: %1").arg(id);
}
