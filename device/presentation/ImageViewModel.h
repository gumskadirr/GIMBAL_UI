#pragma once

#include <QObject>
#include <QtQml/qqmlregistration.h>

#include "device/presentation/ServiceConnection.h"

// IDS Image service data as QML sees it; its connection is `connection`. Skeleton: T17-T20 add the data.
class ImageViewModel : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("Owned by the application")
    Q_PROPERTY(ServiceConnection *connection READ connection CONSTANT)

public:
    explicit ImageViewModel(ServiceConnection *connection, QObject *parent = nullptr)
        : QObject(parent), m_connection(connection)
    {
    }

    ServiceConnection *connection() const { return m_connection; }

private:
    ServiceConnection *m_connection;
};
