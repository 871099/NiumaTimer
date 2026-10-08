// 应用入口：初始化 Qt Quick、工作计时控制器并加载跨平台 QML 界面。
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>

#include <cstdlib>

#include "app/WorkTimer.h"
#include "app/WorkHistoryStore.h"

int main(int argc, char *argv[]) {
    QGuiApplication app(argc, argv);
    QCoreApplication::setOrganizationName(QStringLiteral("NiumaTimer"));
    QCoreApplication::setApplicationName(QStringLiteral("牛马打工计时器"));
    QCoreApplication::setApplicationVersion(QStringLiteral("0.1.0"));

    QQuickStyle::setStyle(QStringLiteral("Basic"));

    WorkHistoryStore workHistory;
    WorkTimer timer;
    timer.setHistoryStore(&workHistory);
    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty(QStringLiteral("workTimer"), &timer);
    engine.rootContext()->setContextProperty(QStringLiteral("workHistory"), &workHistory);
    QObject::connect(
        &engine, &QQmlApplicationEngine::objectCreationFailed,
        &app, [] { QCoreApplication::exit(EXIT_FAILURE); },
        Qt::QueuedConnection);
    engine.loadFromModule(QStringLiteral("NiumaTimer"), QStringLiteral("Main"));

    QObject::connect(&app, &QGuiApplication::applicationStateChanged,
                     &timer, [&timer](Qt::ApplicationState state) {
        if (state == Qt::ApplicationActive) {
            timer.syncNetworkTime();
            timer.refresh();
        }
    });

    return app.exec();
}
