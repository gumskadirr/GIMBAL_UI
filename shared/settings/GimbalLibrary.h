#pragma once

#include <QObject>
#include <QVariantList>
#include <QtQml/qqmlregistration.h>

// The gimbals the user works with (display only: top bar and 3D view), kept in <dir>/gimbals.json. A 3D model is
// three .glb files copied into <dir>/<id>/ (base.glb, pan.glb, tilt.glb), so it survives the source files moving.
// QML entry: { id, name, versions: [..], model: null | { base, pan, tilt (file URLs), panAxis "x|y|z", panSign,
// panPivot [x,y,z], tiltAxis, tiltSign, tiltPivot, inPlace } }.
// An unreadable list is never overwritten silently: it is kept as gimbals.json.bad and the defaults are used.
class GimbalLibrary : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("Owned by AppSettings")
    Q_PROPERTY(QVariantList gimbals READ gimbals NOTIFY changed)

public:
    explicit GimbalLibrary(const QString &dir, QObject *parent = nullptr);

    QVariantList gimbals() const;
    void reload();
    // Where an unreadable list was moved by the last reload (empty if none): the library is created before anyone
    // listens to problem(), so the owner reports this one itself.
    QString keptBadFile() const { return m_keptBadFile; }

    // Adds (empty or unknown id) or updates a gimbal. files: { base, pan, tilt } local file URLs or paths of newly
    // chosen .glb files; a missing one keeps the stored file. Returns an error text, empty on success.
    Q_INVOKABLE QString save(const QVariantMap &gimbal, const QVariantMap &files = {});
    Q_INVOKABLE QString remove(const QString &id);

signals:
    void changed();
    void problem(const QString &code, const QString &detail); // gimbals.readFailed / gimbals.writeFailed

private:
    QString listPath() const;
    QString folder(const QString &id) const;
    QVariantMap toQml(const QVariantMap &entry) const;
    QString uniqueId(const QString &name) const;
    void seedDefaults();
    bool write();

    QString m_dir;
    QString m_keptBadFile;
    QVariantList m_entries; // stored form: model files are not part of the entry
};
