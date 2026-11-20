#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QtQuick3D/qquick3d.h>

int main(int argc, char *argv[])
{
    // Qt Quick 3D için MSAA + derinlik tamponlu yüzey
    QSurfaceFormat::setDefaultFormat(QQuick3D::idealSurfaceFormat(4));
    QGuiApplication app(argc, argv);

    QQmlApplicationEngine engine;
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.loadFromModule("ZR10_3D", "Main");

    return QGuiApplication::exec();
}
