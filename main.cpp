#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>         // <--- AGGIUNGI QUESTO
#include "databasemanager.h"   // <--- AGGIUNGI QUESTO

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    DatabaseManager dbManager; // Creiamo l'oggetto che gestirà i dati

    QQmlApplicationEngine engine;

    // Colliamo l'oggetto C++ al mondo QML.
    // Da ora in poi, in QML potrai usare la parola "Backend" per chiamare le funzioni C++
    engine.rootContext()->setContextProperty("Backend", &dbManager);

    const QUrl url(QStringLiteral("qrc:/qt/qml/Gestione_Riposo/Main.qml"));
    engine.load(url);

    return app.exec();
}
