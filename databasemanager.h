#ifndef DATABASEMANAGER_H
#define DATABASEMANAGER_H

#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QUrl>
#include <QDate>
#include <QDebug>
#include <QVariant>
#include <emscripten.h>

class DatabaseManager : public QObject {
    Q_OBJECT
public:
    explicit DatabaseManager(QObject *parent = nullptr) : QObject(parent) {
        manager = new QNetworkAccessManager(this);
    }

    // --- FUNZIONE 1: LOGIN ---
    Q_INVOKABLE void login(QString cip) {
        qDebug() << "[DEBUG LOGIN] Avvio tentativo per CIP:" << cip;
        QUrl url("https://tbgjaxoukzcimtfkbqua.supabase.co/rest/v1/utenti?cip=eq." + cip);
        qDebug() << "[DEBUG LOGIN] URL richiesto:" << url.toString();
        QNetworkRequest request(url);
        impostaHeader(request);

        QNetworkReply* reply = manager->get(request);

        connect(reply, &QNetworkReply::finished, [this, reply, cip]() {
            QByteArray responseData = reply->readAll();
            if (reply->error() != QNetworkReply::NoError) {
                qDebug() << "[DEBUG LOGIN] ERRORE DI RETE:" << reply->errorString();
                qDebug() << "[DEBUG LOGIN] Codice HTTP:" << reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
            }
            qDebug() << "[DEBUG LOGIN] Risposta grezza dal server:" << responseData;
            if (reply->error() == QNetworkReply::NoError) {
                QJsonDocument doc = QJsonDocument::fromJson(responseData);
                QJsonArray array = doc.array();
                if (doc.isNull()) {
                    qDebug() << "[DEBUG LOGIN] ERRORE: Risposta JSON non valida.";
                    emit loginError("Errore di comunicazione con il server. Riprova più tardi.");
                } else if (doc.isArray()) {
                    QJsonArray array = doc.array();
                    qDebug() << "[DEBUG LOGIN] Trovati" << array.size() << "utenti corrispondenti.";        

                    if (!array.isEmpty()) {
                        QJsonObject utente = array.first().toObject();
                        m_nomeUtenteLoggato = utente["nome"].toString() + " " + utente["cognome"].toString();
                        m_idUtenteLoggato = QString::number(utente["id_utente"].toInt());

                        qDebug() << "Login riuscito Nome:" << m_nomeUtenteLoggato << "ID Utente:" << m_idUtenteLoggato;
                        controllaStatoBlocco();
                    } else {
                        emit loginError("CIP non trovato");
                    }
                }
            } else {
                emit loginError("Errore di connessione al database.");
            }
            reply->deleteLater();
        });
    }

    Q_INVOKABLE void controllaStatoBlocco() {
        QUrl url("https://tbgjaxoukzcimtfkbqua.supabase.co/rest/v1/config_sistema?id=eq.1");
        QNetworkRequest request(url);
        impostaHeader(request);
        QNetworkReply* reply = manager->get(request);
        connect(reply, &QNetworkReply::finished, [this, reply]() {
            if (reply->error() == QNetworkReply::NoError) {
                QByteArray response = reply->readAll();
                QJsonArray array = QJsonDocument::fromJson(response).array();
                if (!array.isEmpty()) {
                    QJsonObject obj = array.first().toObject();

                    // Salviamo i dati nelle variabili private che abbiamo creato
                    m_bloccoAttivo = obj["is_active"].toBool();
                    m_inizioBlocco = QDate::fromString(obj["data_inizio"].toString(), Qt::ISODate);
                    qDebug() << "Blocco caricato. Ora sblocco l'interfaccia.";
                    emit loginSuccess(m_nomeUtenteLoggato, m_idUtenteLoggato);
                    m_fineBlocco = QDate::fromString(obj["data_fine"].toString(), Qt::ISODate);
                    
                    qDebug() << "DATA INIZIO CARICATA:" << m_inizioBlocco.toString("dd/MM/yyyy");
                    qDebug() << "DATA FINE CARICATA:" << m_fineBlocco.toString("dd/MM/yyyy");
                    qDebug() << "Verifica Blocco effettuata. Attivo:" << m_bloccoAttivo;
                }
            } else {
                qDebug() << "Errore caricamento stato blocco:" << reply->errorString();
            }
            reply->deleteLater();
        });
    }

    Q_INVOKABLE void aggiornaBloccoSistema(QString inizio, QString fine, bool attivo) {
        QJsonObject dati;
        // Trasformiamo date da GG-MM-AAAA a YYYY-MM-DD per Supabase
        dati["data_inizio"] = QDate::fromString(inizio, "dd-MM-yyyy").toString("yyyy-MM-dd");
        dati["data_fine"] = QDate::fromString(fine, "dd-MM-yyyy").toString("yyyy-MM-dd");
        dati["is_active"] = attivo;

        QUrl url("https://tbgjaxoukzcimtfkbqua.supabase.co/rest/v1/config_sistema?id=eq.1");
        QNetworkRequest request(url);
        impostaHeader(request);
        request.setRawHeader("Prefer", "return=representation");

        manager->sendCustomRequest(request, "PATCH", QJsonDocument(dati).toJson());
        // Aggiorniamo anche le variabili locali
        m_bloccoAttivo = attivo;
        m_inizioBlocco = QDate::fromString(inizio, "dd-MM-yyyy");
        m_fineBlocco = QDate::fromString(fine, "dd-MM-yyyy");

        emit operazioneCompletata(attivo ? "SISTEMA BLOCCATO" : "SISTEMA SBLOCCATO");
    }
    Q_PROPERTY(QString inizioBlocco READ inizioBlocco NOTIFY bloccoCambiato)
    Q_PROPERTY(QString fineBlocco READ fineBlocco NOTIFY bloccoCambiato)
    Q_PROPERTY(bool bloccoAttivo READ bloccoAttivo NOTIFY bloccoCambiato)
    QString inizioBlocco() const { return m_inizioBlocco.toString("yyyy-MM-dd"); }
    QString fineBlocco() const { return m_fineBlocco.toString("yyyy-MM-dd"); }
    bool bloccoAttivo() const { return m_bloccoAttivo; }

    Q_INVOKABLE void caricaRiposiDisponibili(QString idSeriale) {
        QUrl url("https://tbgjaxoukzcimtfkbqua.supabase.co/rest/v1/riposi?id_utente=eq." + idSeriale + "&fruizione=eq.DISPONIBILE&tipo_riposo=neq.LICENZA&order=giorno_di_riposo.desc");
        QNetworkRequest request(url);
        impostaHeader(request);

        QNetworkReply* reply = manager->get(request);
        connect(reply, &QNetworkReply::finished, [this, reply]() {
            if (reply->error() == QNetworkReply::NoError) {
                QJsonArray array = QJsonDocument::fromJson(reply->readAll()).array();
                QVariantList lista;
                for (const QJsonValue & v : array) {
                    QJsonObject obj = v.toObject();
                    QVariantMap item;
                    QString dataM = obj["giorno_di_riposo"].toString();
                    item["dataISO"] = dataM;
                    item["dataITA"] = QDate::fromString(dataM, "yyyy-MM-dd").toString("dd-MM-yyyy");
                    QString dataF = obj["data_fruizione"].toString();
                    if (!dataF.isEmpty() && dataF != "null") {
                        item["dataFruizioneITA"] = QDate::fromString(dataF, "yyyy-MM-dd").toString("dd-MM-yyyy");
                    } else {
                        item["dataFruizioneITA"] = ""; // Se è vuota, il QML mostrerà "Libero ✅"
                    }
                    item["tipo"] = obj["tipo_riposo"].toString();
                    item["stato"] = obj["stato"].toString();
                    lista.append(item);
                }
                emit riposiRicevuti(lista);
            }
            reply->deleteLater();
        });
    }
    // ---- Funzione Report
    Q_INVOKABLE void caricaReport(QString idSeriale, int tipoReport) {
        QString colonna = "giorno_di_riposo";
        QString ordine = "desc";
        QString filtroExtra = "";

        // Implementazione identica alla tua logica C++
        switch(tipoReport) {
        case 1: colonna = "giorno_di_riposo"; ordine = "desc"; break;
        case 2: colonna = "giorno_di_riposo"; ordine = "asc"; break;
        case 3: colonna = "tipo_riposo";      ordine = "asc"; break;
        case 4: colonna = "stato";            ordine = "asc"; break;
        case 5: filtroExtra = "&fruizione=eq.DISPONIBILE"; colonna = "giorno_di_riposo"; ordine = "desc"; break;
        case 6: filtroExtra = "&fruizione=eq.FRUITO";      colonna = "giorno_di_riposo"; ordine = "desc"; break;
        }

        QUrl url("https://tbgjaxoukzcimtfkbqua.supabase.co/rest/v1/riposi?id_utente=eq." + idSeriale +
                 "&select=giorno_di_riposo,tipo_riposo,stato,fruizione,data_fruizione" +
                 filtroExtra + "&order=" + colonna + "." + ordine);

        QNetworkRequest request(url);
        impostaHeader(request);

        QNetworkReply* reply = manager->get(request);
        connect(reply, &QNetworkReply::finished, [this, reply]() {
            if (reply->error() == QNetworkReply::NoError) {
                QJsonArray array = QJsonDocument::fromJson(reply->readAll()).array();
                QVariantList lista;
                for (const QJsonValue & v : array) {
                    QJsonObject obj = v.toObject();
                    QVariantMap item;
                    QString dataRaw = obj["giorno_di_riposo"].toString();
                    QDate dataObj = QDate::fromString(dataRaw, "yyyy-MM-dd");
                    item["dataISO"] = dataRaw;
                    item["dataITA"] = dataObj.toString("dd-MM-yyyy");
                    QString dataF = obj["data_fruizione"].toString();
                    if (!dataF.isEmpty() && dataF != "null") {
                        item["dataF"] = QDate::fromString(dataF, "yyyy-MM-dd").toString("dd-MM-yyyy");
                    } else {
                        item["dataF"] = "";
                    }
                    item["tipo"] = obj["tipo_riposo"].toString();
                    item["stato"] = obj["stato"].toString();
                    item["fruiz"] = obj["fruizione"].toString();

                    lista.append(item);
                }
                emit riposiRicevuti(lista);
            }
            reply->deleteLater();
        });
    }

    // FUNZIONE DI INSERIMENTO RIPOSI
    Q_INVOKABLE void aggiungiRiposo(QString idSeriale, QString dataGGMMAAAA, int sceltaTipo) {
        QStringList parti = dataGGMMAAAA.split("-");
        QString dataISO = QDate(parti[2].toInt(), parti[1].toInt(), parti[0].toInt()).toString("yyyy-MM-dd");
        if (isOperazioneBloccata(idSeriale, dataISO)) return;
        QStringList tipi = {
            "RIPOSO SETTIMANALE",
            "RIPOSO FESTIVO",
            "RIPOSO MEDICO",
            "RIPOSO STUDIO",
            "RIPOSO DONAZIONE SANGUE",
            "RIPOSO DI ALTRO TIPO"
        };
        if (sceltaTipo < 1 || sceltaTipo > 6) {
            emit loginError("Scelta tipo non valida.");
            return;
        }
        parti = dataGGMMAAAA.split("-");
        if (parti.size() != 3) {
            emit loginError("Formato data non valido. Usa GG--MM-YYYY");
            return;
        }
        QDate dataInserita = QDate(parti[2].toInt(), parti[1].toInt(), parti[0].toInt());
        QDate dataOggi = QDate::currentDate();
        if (dataInserita < dataOggi) {
            emit loginError("Non può essere inserita una data precedente a oggi!");
            return;
        }
        dataISO = dataInserita.toString("yyyy-MM-dd");
        QUrl url("https://tbgjaxoukzcimtfkbqua.supabase.co/rest/v1/riposi");
        QNetworkRequest request(url);
        impostaHeader(request);
        request.setRawHeader("Content-Type", "application/json");
        request.setRawHeader("Prefer", "return=representation");

        // Creiamo il JSON proprio come facevi nel tuo payload
        QJsonObject dati;
        dati["id_utente"] = idSeriale.toInt();
        dati["giorno_di_riposo"] = dataInserita.toString("yyyy-MM-dd");
        dati["tipo_riposo"] = tipi[sceltaTipo - 1];
        dati["stato"] = "ACQUISITO";
        dati["fruizione"] = "DISPONIBILE";

        QJsonDocument doc(dati);
        QByteArray body = doc.toJson();

        QNetworkReply* reply = manager->post(request, QJsonDocument(dati).toJson());

        connect(reply, &QNetworkReply::finished, [this, reply, dataGGMMAAAA, sceltaTipo, idSeriale]() {
            QByteArray responseData = reply->readAll();

            if (reply->error() == QNetworkReply::NoError) {
                QJsonObject info;
                info["data"] = dataGGMMAAAA;
                info["tipo_scelto"] = sceltaTipo;
                scriviLog(idSeriale, "INSERIMENTO", info);
                emit operazioneCompletata("Riposo inserito con successo!");
            } else {
                QJsonDocument errorDoc = QJsonDocument::fromJson(responseData);
                QJsonObject errorObj = errorDoc.object();
                QString errorCode = errorObj["code"].toString();
                QString errorDetail = errorObj["message"].toString();
                qDebug() << "Errore Supabase Code:" << errorCode;

                if(errorCode == "23505" || responseData.contains("23505")) {
                    emit loginError("Errore: Hai gia' acquisito questo giorno di riposo.");
                } else {
                    emit loginError("Errore durante l'inserimento nel database:" + errorDetail);
                }
            }
            reply->deleteLater();
        });
    }

    Q_INVOKABLE void fruisciRiposo(QString idSeriale, QString dataMaturazioneISO, QString dataFruizioneGGMMAAAA, int statoScelto) {
        QStringList parti = dataFruizioneGGMMAAAA.split("-");
        if (parti.size() != 3) {
            emit loginError("Formato data non valido.");
            return;
        }
        QDate dataFruizione = QDate(parti[2].toInt(), parti[1].toInt(), parti[0].toInt());
        qDebug() << "[FRUISCI] Oggi secondo Qt:" << QDate::currentDate().toString("dd-MM-yyyy");
        qDebug() << "[FRUISCI] Data inserita:" << dataFruizioneGGMMAAAA;
        qDebug() << "[FRUISCI] Data parsata:" << dataFruizione.toString("dd-MM-yyyy");
        qDebug() << "[FRUISCI] È passata?" << (dataFruizione < QDate::currentDate());
        if (!dataFruizione.isValid() || dataFruizione < QDate::currentDate()) {
            emit loginError("Data: " + dataFruizioneGGMMAAAA + " | Mat: " + dataMaturazioneISO);
            return;
        }
        if (isBloccoAdmin(idSeriale, dataMaturazioneISO)) return;
        
        QString dataFruizioneISO = dataFruizione.toString("yyyy-MM-dd");
        if (isBloccoAdmin(idSeriale, dataFruizioneISO)) return;

        QUrl checkUrl("https://tbgjaxoukzcimtfkbqua.supabase.co/rest/v1/riposi?id_utente=eq." + idSeriale + "&data_fruizione=eq." + dataFruizioneISO);
        QNetworkRequest checkRequest(checkUrl);
        checkRequest.setRawHeader("apikey", "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRiZ2pheG91a3pjaW10ZmticXVhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY3NjMzNjIsImV4cCI6MjA5MjMzOTM2Mn0.n2WCdp7SZ-VBg_8j1IJUJH7pGbqecFkOdar727qwQJ0");
        checkRequest.setRawHeader("Authorization", "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRiZ2pheG91a3pjaW10ZmticXVhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY3NjMzNjIsImV4cCI6MjA5MjMzOTM2Mn0.n2WCdp7SZ-VBg_8j1IJUJH7pGbqecFkOdar727qwQJ0");
        QNetworkReply* reply = manager->get(checkRequest);
        connect(reply, &QNetworkReply::finished, [this, reply, idSeriale, dataMaturazioneISO, dataFruizioneISO, statoScelto, dataFruizioneGGMMAAAA]() {
            if (reply->error() == QNetworkReply::NoError) {
                QJsonArray checkArray = QJsonDocument::fromJson(reply->readAll()).array();
                if (!checkArray.isEmpty()) {
                    QJsonObject esistente = checkArray.first().toObject();
                    QString dataMatISO = esistente["giorno_di_riposo"].toString();
                    QStringList p = dataMatISO.split("-");
                    QString dataMatITA = (p.size() == 3) ? (p[2] + "-" + p[1] + "-" + p[0]) : dataMatISO;
                    emit loginError("Hai già un riposo il " + dataFruizioneGGMMAAAA + "!\n(Maturato il: " + dataMatITA + ")");
                } else {
                    eseguiPatchFruizione(idSeriale, dataMaturazioneISO, dataFruizioneISO, statoScelto);
                }
            } else {
                emit loginError("Errore nel controllo disponibilità.");
            }
            reply->deleteLater();
        });
    }

    Q_INVOKABLE void modificaRiposo(QString idSeriale, QString dataMaturazioneITA, int tipoIdx, int statoIdx) {
        QStringList parti = dataMaturazioneITA.split("-");
        if (parti.size() != 3) {
            emit loginError("Formato data non valido.");
            return;
        }
        QDate dataMaturazioneObj = QDate(parti[2].toInt(), parti[1].toInt(), parti[0].toInt());
        QString dataISO = dataMaturazioneObj.toString("yyyy-MM-dd");

        // Per la modifica, l'utente può agire sui propri riposi anche se datati nel passato.
        // L'unico vincolo rimane il periodo bloccato dall'admin.
        if (isBloccoAdmin(idSeriale, dataISO)) return;
        QStringList tipi = {"RIPOSO SETTIMANALE", "RIPOSO FESTIVO", "RIPOSO MEDICO", "RIPOSO STUDIO", "RIPOSO DONAZIONE SANGUE", "RIPOSO DI ALTRO TIPO"};
        QStringList stati = {"ACQUISITO", "RICHIESTO", "VALIDATO"};
        QString statoScelto = stati[statoIdx];
        QString nFruizione = (statoScelto == "VALIDATO") ? "FRUITO" : "DISPONIBILE";

        QUrl urlGet("https://tbgjaxoukzcimtfkbqua.supabase.co/rest/v1/riposi?id_utente=eq." + idSeriale + "&giorno_di_riposo=eq." + dataISO);
        QNetworkRequest reqGet(urlGet);
        reqGet.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
        reqGet.setRawHeader("apikey", "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRiZ2pheG91a3pjaW10ZmticXVhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY3NjMzNjIsImV4cCI6MjA5MjMzOTM2Mn0.n2WCdp7SZ-VBg_8j1IJUJH7pGbqecFkOdar727qwQJ0"); // Usa la tua chiave presente nel file
        reqGet.setRawHeader("Authorization", "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRiZ2pheG91a3pjaW10ZmticXVhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY3NjMzNjIsImV4cCI6MjA5MjMzOTM2Mn0.n2WCdp7SZ-VBg_8j1IJUJH7pGbqecFkOdar727qwQJ0");

        QNetworkReply* replyGet = manager->get(reqGet);
        connect(replyGet, &QNetworkReply::finished, [this, replyGet, statoScelto, idSeriale, dataISO, dataMaturazioneITA, tipoIdx, tipi]() {
            QByteArray response = replyGet->readAll();
            QJsonDocument doc = QJsonDocument::fromJson(response);
            QJsonArray array = doc.array();
            if (!array.isEmpty()) {
                QJsonObject attuale = array.first().toObject();
                QString dataFruizioneRaw = attuale["data_fruizione"].toString();
                bool haDataFruizione = !dataFruizioneRaw.isEmpty() && dataFruizioneRaw != "null";
                QString statoPulito = statoScelto.trimmed();
                if ((statoPulito == "RICHIESTO" || statoPulito == "VALIDATO") && !haDataFruizione) {
                    emit loginError("Operazione negata: per impostare '" + statoPulito + "' devi prima assegnare una data di fruizione nella pagina 'Fruisci'.");
                } else {
                    eseguiUpdateModifica(idSeriale, dataISO, tipoIdx, statoPulito);
                }
            } else {
                emit loginError("ERRORE: La data " + dataMaturazioneITA + " non è presente in archivio.");
            }
            replyGet->deleteLater();
        });
    }
    Q_INVOKABLE void controllaEsistenzaEChiediConferma(QString idSeriale, QString dataGGMMAAAA) {
        QStringList parti = dataGGMMAAAA.split("-");
        if (parti.size() != 3) {
            emit loginError("Formato data non valido. Usa GG-MM-YYYY");
            return;
        }
        QString dataISO = QDate(parti[2].toInt(), parti[1].toInt(), parti[0].toInt()).toString("yyyy-MM-dd");

        QUrl url("https://tbgjaxoukzcimtfkbqua.supabase.co/rest/v1/riposi?id_utente=eq." + idSeriale + "&giorno_di_riposo=eq." + dataISO);
        QNetworkRequest request(url);
        request.setRawHeader("apikey", "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRiZ2pheG91a3pjaW10ZmticXVhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY3NjMzNjIsImV4cCI6MjA5MjMzOTM2Mn0.n2WCdp7SZ-VBg_8j1IJUJH7pGbqecFkOdar727qwQJ0");
        request.setRawHeader("Authorization", "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRiZ2pheG91a3pjaW10ZmticXVhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY3NjMzNjIsImV4cCI6MjA5MjMzOTM2Mn0.n2WCdp7SZ-VBg_8j1IJUJH7pGbqecFkOdar727qwQJ0");

        QNetworkReply* reply = manager->get(request);
        connect(reply, &QNetworkReply::finished, [this, reply, dataGGMMAAAA]() {
            if (reply->error() == QNetworkReply::NoError) {
                QJsonArray array = QJsonDocument::fromJson(reply->readAll()).array();
                if (array.isEmpty()) {
                    emit loginError("ERRORE: La data " + dataGGMMAAAA + " non è presente in archivio.");
                } else {
                    // Se esiste, inviamo i dati al QML per il popup di conferma
                    QJsonObject obj = array.first().toObject();
                    QVariantMap dati;
                    dati["data"] = dataGGMMAAAA;
                    dati["tipo"] = obj["tipo_riposo"].toString();
                    dati["stato"] = obj["stato"].toString();
                    emit confermaCancellazioneRichiesta(dati);
                }
            }
            reply->deleteLater();
        });
    }
    Q_INVOKABLE void cancellaRiposoEffettivo(QString idSeriale, QString dataGGMMAAAA) {
        QStringList parti = dataGGMMAAAA.split("-");
        QString dataISO = QDate(parti[2].toInt(), parti[1].toInt(), parti[0].toInt()).toString("yyyy-MM-dd");
        if (isOperazioneBloccata(idSeriale, dataISO)) return;
        if (parti.size() != 3) {
            emit loginError("Formato data non valido per la cancellazione.");
            return;
        }
        QUrl url("https://tbgjaxoukzcimtfkbqua.supabase.co/rest/v1/riposi?id_utente=eq." + idSeriale + "&giorno_di_riposo=eq." + dataISO);
        QNetworkRequest request(url);
        request.setRawHeader("apikey", "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRiZ2pheG91a3pjaW10ZmticXVhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY3NjMzNjIsImV4cCI6MjA5MjMzOTM2Mn0.n2WCdp7SZ-VBg_8j1IJUJH7pGbqecFkOdar727qwQJ0");
        request.setRawHeader("Authorization", "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRiZ2pheG91a3pjaW10ZmticXVhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY3NjMzNjIsImV4cCI6MjA5MjMzOTM2Mn0.n2WCdp7SZ-VBg_8j1IJUJH7pGbqecFkOdar727qwQJ0");
        QNetworkReply* reply = manager->sendCustomRequest(request, "DELETE");
        connect(reply, &QNetworkReply::finished, [this, reply, idSeriale, dataGGMMAAAA]() {
            if (reply->error() == QNetworkReply::NoError) {
                QJsonObject info;
                info["data_cancellata"] = dataGGMMAAAA;
                scriviLog(idSeriale, "CANCELLAZIONE", info); // <--- LOG
                emit operazioneCompletata("Riposo del " + dataGGMMAAAA + " cancellato con successo!");
            } else {
                emit loginError("Errore durante la cancellazione: data non trovata o problema di rete.");
            }
            reply->deleteLater();
        });
    }
    Q_INVOKABLE void caricaSpecchioAdmin(QString dataInizioGGMMAAAA, QString dataFineGGMMAAAA) {
        QStringList pI = dataInizioGGMMAAAA.split("-");
        QStringList pF = dataFineGGMMAAAA.split("-");
        if (pI.size() != 3 || pF.size() != 3)return;

        QDate dataRiferimento(pI[2].toInt(), pI[1].toInt(), pI[0].toInt());
        int giorniNelMese = dataRiferimento.daysInMonth();
        QString isoInizio = QDate(pI[2].toInt(), pI[1].toInt(), pI[0].toInt()).toString("yyyy-MM-dd");
        QString isoFine = QDate(pF[2].toInt(), pF[1].toInt(), pF[0].toInt()).toString("yyyy-MM-dd");

        // TEST 1: Solo le colonne base (senza il join con utenti e senza alias)
        QUrl urlUtenti("https://tbgjaxoukzcimtfkbqua.supabase.co/rest/v1/utenti?select=id_utente,nome,cognome&order=ordine_manuale.asc");
        QNetworkRequest reqUtenti(urlUtenti);
        impostaHeader(reqUtenti);
        QNetworkReply* replyUtenti = manager->get(reqUtenti);
        connect(replyUtenti, &QNetworkReply::finished, [this, replyUtenti, isoInizio, isoFine, giorniNelMese]() {
            if (replyUtenti->error() == QNetworkReply::NoError) {
                QJsonArray utentiArray = QJsonDocument::fromJson(replyUtenti->readAll()).array();
                QUrl urlRiposi("https://tbgjaxoukzcimtfkbqua.supabase.co/rest/v1/riposi?select=id_riposo,stato,data_fruizione,tipo_riposo,id_utente,a,giorno_di_riposo&data_fruizione=gte." + isoInizio + "&data_fruizione=lte." + isoFine);
                QNetworkRequest reqRiposi(urlRiposi);
                impostaHeader(reqRiposi);
                QNetworkReply* replyRiposi = manager->get(reqRiposi);
                connect(replyRiposi, &QNetworkReply::finished, [this, replyRiposi, utentiArray, giorniNelMese]() {
                    if (replyRiposi->error() == QNetworkReply::NoError) {
                        QJsonArray riposiArray = QJsonDocument::fromJson(replyRiposi->readAll()).array();
                        QVariantList listaFinale;
                        QMap<int, QList<QJsonObject>> mappaRiposi;
                        for(const QJsonValue &v : riposiArray) {
                            QJsonObject ro = v.toObject();
                            mappaRiposi[ro["id_utente"].toInt()].append(ro);
                        }
                        for (const QJsonValue &uVal : utentiArray) {
                            QJsonObject uObj = uVal.toObject();
                            int idU = uObj["id_utente"].toInt();
                            QString nomeU = (uObj["cognome"].toString() + " " + uObj["nome"].toString()).toUpper();
                            if (mappaRiposi.contains(idU)) {
                                for (const QJsonObject &rObj : mappaRiposi[idU]) {
                                    QVariantMap r;
                                    r["u"] = nomeU;
                                    r["id_reale"] = idU;
                                    r["id_riposo"] = rObj["id_riposo"].toInt();
                                    r["stato"] = rObj["stato"].toString();
                                    r["d"] = QDate::fromString(rObj["data_fruizione"].toString(), "yyyy-MM-dd").day();
                                    r["tipo"] = rObj["tipo_riposo"].toString();
                                    r["maturato"] = QDate::fromString(rObj["giorno_di_riposo"].toString(), "yyyy-MM-dd").toString("dd-MM-yyyy");

                                    QString tipo = rObj["tipo_riposo"].toString().toUpper();
                                    if (tipo == "LICENZA") {
                                        r["a"] = rObj["a"].toString().toUpper();
                                    } else {
                                        if (tipo.contains("SETTIMANALE")) r["a"] = "RS";
                                        else if (tipo.contains("FESTIVO")) r["a"] = "RF";
                                        else if (tipo.contains("MEDICO")) r["a"] = "RM";
                                        else if (tipo.contains("STUDIO")) r["a"] = "RST";
                                        else if (tipo.contains("DONAZIONE SANGUE")) r["a"] = "RDS";
                                        else r["a"] = "RAT";
                                    }
                                    listaFinale.append(r);
                                }
                            } else {
                                QVariantMap r;
                                r["u"] = nomeU;
                                r["id_reale"] = idU;
                                r["d"] = 0; // Giorno 0 = nessuna sigla disegnata
                                r["a"] = "";
                                listaFinale.append(r);
                            }
                        }
                        emit specchioRicevuto(listaFinale, giorniNelMese);
                    }
                    replyRiposi->deleteLater();
                });
            }
            replyUtenti->deleteLater();
        });
    }
    // Salva o aggiorna una licenza (codice semplice come "L" o "P")
    Q_INVOKABLE void salvaLicenzaPersonale(QString idUtenteLoggato, QString dataISO, QString codiceLicenza) {
        if (isOperazioneBloccata(idUtenteLoggato, dataISO)) return;
        QJsonObject dati;
        dati["id_utente"] = idUtenteLoggato.toInt();
        dati["data_fruizione"] = dataISO;
        dati["tipo_riposo"] = "LICENZA";
        dati["a"] = codiceLicenza.toUpper().trimmed();
        dati["stato"] = "VALIDATO";      // Non può essere null
        dati["fruizione"] = "FRUITO";
        qDebug() << "INVIO LICENZA - Data:" << dataISO << "Codice A:" << codiceLicenza;
        QUrl url("https://tbgjaxoukzcimtfkbqua.supabase.co/rest/v1/riposi?on_conflict=id_utente,data_fruizione");
        QNetworkRequest request(url);
        request.setRawHeader("apikey", "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRiZ2pheG91a3pjaW10ZmticXVhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY3NjMzNjIsImV4cCI6MjA5MjMzOTM2Mn0.n2WCdp7SZ-VBg_8j1IJUJH7pGbqecFkOdar727qwQJ0");
        request.setRawHeader("Authorization", "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRiZ2pheG91a3pjaW10ZmticXVhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY3NjMzNjIsImV4cCI6MjA5MjMzOTM2Mn0.n2WCdp7SZ-VBg_8j1IJUJH7pGbqecFkOdar727qwQJ0");
        request.setRawHeader("Content-Type", "application/json");
        request.setRawHeader("Prefer", "resolution=merge-duplicates");
        QJsonDocument doc(dati);
        QNetworkReply *reply = manager->post(request, doc.toJson());
        connect(reply, &QNetworkReply::finished, [this, reply, idUtenteLoggato, dataISO, codiceLicenza]() {
            if (reply->error() == QNetworkReply::NoError) {
                QJsonObject info;
                info["data"] = dataISO;
                info["codice"] = codiceLicenza;
                scriviLog(idUtenteLoggato, "INSERIMENTO LICENZA", info);
                emit operazioneCompletata("Salvato");
            } else {
            }
            reply->deleteLater();
        });
    }
    Q_INVOKABLE void cancellaLicenza(QString idSeriale, QString dataISO, QString codiceLicenza) {
        if (isOperazioneBloccata(idSeriale, dataISO)) return;
        // URL che punta esattamente al record di quell'utente in quel giorno
        QUrl url("https://tbgjaxoukzcimtfkbqua.supabase.co/rest/v1/riposi?id_utente=eq." + idSeriale + "&data_fruizione=eq." + dataISO);

        QNetworkRequest request(url);
        request.setRawHeader("apikey", "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRiZ2pheG91a3pjaW10ZmticXVhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY3NjMzNjIsImV4cCI6MjA5MjMzOTM2Mn0.n2WCdp7SZ-VBg_8j1IJUJH7pGbqecFkOdar727qwQJ0");
        request.setRawHeader("Authorization", "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRiZ2pheG91a3pjaW10ZmticXVhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY3NjMzNjIsImV4cCI6MjA5MjMzOTM2Mn0.n2WCdp7SZ-VBg_8j1IJUJH7pGbqecFkOdar727qwQJ0");

        // Inviamo una richiesta DELETE
        QNetworkReply* reply = manager->sendCustomRequest(request, "DELETE");

        connect(reply, &QNetworkReply::finished, [this, reply, idSeriale, dataISO, codiceLicenza]() {
            if (reply->error() == QNetworkReply::NoError) {
                QJsonObject info;
                info["data_licenza_rimossa"] = dataISO;
                info["codice_licenza_rimosso"] = codiceLicenza;
                scriviLog(idSeriale, "CANCELLAZIONE LICENZA", info);
                emit operazioneCompletata("Licenza eliminata con successo!");
            } else {
                emit loginError("Errore durante l'eliminazione.");
            }
            reply->deleteLater();
        });
    }

    Q_INVOKABLE void caricaRichiesteInBlocco() {
        QString isoInizio = m_inizioBlocco.toString("yyyy-MM-dd");
        QString isoFine = m_fineBlocco.toString("yyyy-MM-dd");

        // Query con Join per avere nome e cognome dell'utente
        QUrl url("https://tbgjaxoukzcimtfkbqua.supabase.co/rest/v1/riposi?select=*,utenti(nome,cognome)&stato=eq.RICHIESTO&data_fruizione=gte." + isoInizio + "&data_fruizione=lte." + isoFine);
        QNetworkRequest request(url);
        impostaHeader(request);

        QNetworkReply* reply = manager->get(request);
        connect(reply, &QNetworkReply::finished, [this, reply]() {
            if (reply->error() == QNetworkReply::NoError) {
                QJsonArray array = QJsonDocument::fromJson(reply->readAll()).array();
                QVariantList lista;
                for (const QJsonValue & v : array) {
                    QJsonObject obj = v.toObject();
                    QVariantMap item;
                    item["id_riposo"] = obj["id_riposo"].toInt(); // Assumendo ci sia un ID univoco
                    item["id_utente"] = obj["id_utente"].toInt();
                    item["nome_utente"] = obj["utenti"].toObject()["cognome"].toString() + " " + obj["utenti"].toObject()["nome"].toString();
                    item["data_mat"] = QDate::fromString(obj["giorno_di_riposo"].toString(), "yyyy-MM-dd").toString("dd-MM-yyyy");
                    item["data_fru"] = QDate::fromString(obj["data_fruizione"].toString(), "yyyy-MM-dd").toString("dd-MM-yyyy");
                    item["tipo"] = obj["tipo_riposo"].toString();
                    lista.append(item);
                }
                emit richiesteBloccoRicevute(lista);
            }
            reply->deleteLater();
        });
    }

    // Valida o Rifiuta massivamente
    Q_INVOKABLE void processaValidazioni(QVariantList idRiposiRaw, bool valida, QString nomeAdmin, int idDestinatario) {
        if (idRiposiRaw.isEmpty()) {
            qDebug() << "DEBUG: Lista ID vuota.";
            return;
        }
        QStringList listaId;
        for (const QVariant &v : idRiposiRaw) {
            int idCorrente = v.toInt();                       
            listaId << QString::number(idCorrente);
            QString messaggio = valida ? "Il tuo riposo è stato APPROVATO" : "Il tuo riposo è stato RIFIUTATO";
            qDebug() << "[NOTIFICA] id_riposo_rif:" << idCorrente << "dest:" << idDestinatario;
        }

        QString stringaId = listaId.join(",");
        QUrl url("https://tbgjaxoukzcimtfkbqua.supabase.co/rest/v1/riposi?id_riposo=in.(" + stringaId + ")");
        QNetworkRequest request(url);
        impostaHeader(request);

        QJsonObject dati;
        if (valida) {
            dati["stato"] = "VALIDATO";
            dati["fruizione"] = "FRUITO";
            dati["validata_da"] = nomeAdmin;
        } else {
            dati["stato"] = "ACQUISITO";
            dati["fruizione"] = "DISPONIBILE";
            dati["validata_da"] = nomeAdmin;
            dati["data_fruizione"] = QJsonValue::Null;
        }
        QNetworkReply* reply = manager->sendCustomRequest(request, "PATCH", QJsonDocument(dati).toJson());
        connect(reply, &QNetworkReply::finished, [this, reply]() {
            if (reply->error() == QNetworkReply::NoError) {
                emit operazioneCompletata("Elaborazione completata");
            } else {
                qDebug() << "Errore Supabase:" << reply->errorString();
            }
            reply->deleteLater();
        });
    }
    Q_INVOKABLE void inserisciNotifica(int idDestinatario, QString messaggio, int idRiposoRif = -1, QString nomeAdmin = "") {
        QJsonObject notifica;
        notifica["id_utente_dest"] = idDestinatario;
        notifica["messaggio"] = messaggio;
        notifica["letta"] = false;
        notifica["data_notifica"] = QDateTime::currentDateTime().toString(Qt::ISODate);
        if (idRiposoRif > 0) {
            notifica["id_riposo_rif"] = idRiposoRif;
        } else {
            notifica["id_riposo_rif"] = QJsonValue::Null;
        }
        notifica["validata_da"] = nomeAdmin.isEmpty() ? QJsonValue(QJsonValue::Null) : QJsonValue(nomeAdmin);

        QUrl url("https://tbgjaxoukzcimtfkbqua.supabase.co/rest/v1/notifiche");
        QNetworkRequest request(url);
        impostaHeader(request);

        manager->post(request, QJsonDocument(notifica).toJson());
    }

    Q_INVOKABLE void contaNotificheNonLette(int idUtente) {
        // Cerchiamo solo le righe non lette per l'utente loggato
        QUrl url("https://tbgjaxoukzcimtfkbqua.supabase.co/rest/v1/notifiche?id_utente_dest=eq."
                 + QString::number(idUtente) + "&letta=eq.false");

        QNetworkRequest request(url);
        QByteArray apikey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRiZ2pheG91a3pjaW10ZmticXVhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY3NjMzNjIsImV4cCI6MjA5MjMzOTM2Mn0.n2WCdp7SZ-VBg_8j1IJUJH7pGbqecFkOdar727qwQJ0";
        request.setRawHeader("apikey", apikey);
        request.setRawHeader("Authorization", "Bearer " + apikey);
        request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
        request.setRawHeader("Prefer", "count=exact");
        request.setRawHeader("Range-Unit", "items");

        QNetworkReply* reply = manager->get(request);
        connect(reply, &QNetworkReply::finished, [this, reply]() {
            if (reply->error() == QNetworkReply::NoError) {
                // Supabase restituisce il count nell'header Content-Range (es: "0-0/5")
                QString contentRange = reply->rawHeader("Content-Range");
                qDebug() << "[NOTIFICHE] Content-Range ricevuto:" << contentRange;
                int count = 0;
                if (!contentRange.isEmpty()) {
                    count = contentRange.section('/', 1).toInt();
                }
                qDebug() << "[NOTIFICHE] Conteggio notifiche non lette:" << count;
                emit notificheConteggiate(count);
            } else {
                qDebug() << "[NOTIFICHE] Errore rete:" << reply->errorString();
            }
            reply->deleteLater();
        });
    }
    Q_INVOKABLE void caricaDettagliNotifiche(int idUtente) {
        QUrl url("https://tbgjaxoukzcimtfkbqua.supabase.co/rest/v1/notifiche""?id_utente_dest=eq." + QString::number(idUtente) +"&letta=eq.false&order=data_notifica.desc""&select=messaggio,data_notifica,id_riposo_rif,validata_da,data_fruizione_rif");
        QNetworkRequest request(url);
        impostaHeader(request);
        QNetworkReply* reply = manager->get(request);
        connect(reply, &QNetworkReply::finished, [this, reply]() {
            if (reply->error() == QNetworkReply::NoError) {
                QJsonArray array = QJsonDocument::fromJson(reply->readAll()).array();
                QStringList ids;
                QVariantList notifiche;
                for (const QJsonValue &v : array) {
                    QJsonObject obj = v.toObject();
                    QVariantMap item;
                    item["messaggio"] = obj["messaggio"].toString();
                    item["dataOra"] = QDateTime::fromString(obj["data_notifica"].toString(), Qt::ISODate)
                                        .toLocalTime().toString("dd-MM-yyyy HH:mm");
                    item["validatoDa"] = obj["validata_da"].isNull() ? "N/D" : obj["validata_da"].toString();
                    item["idRiposo"]   = obj["id_riposo_rif"].isNull() ? -1 : obj["id_riposo_rif"].toInt();
                    QString dataF = obj["data_fruizione_rif"].toString();
                    item["dataFruizione"] = dataF.isEmpty() ? "N/D"
                        : QDate::fromString(dataF, "yyyy-MM-dd").toString("dd-MM-yyyy");
                    notifiche.append(item);
                }
                emit notificheRicevute(notifiche);
            }
            reply->deleteLater();
        });
    }
    Q_INVOKABLE void segnaNotificheComeLette(int idUtente) {
        QUrl url("https://tbgjaxoukzcimtfkbqua.supabase.co/rest/v1/notifiche?id_utente_dest=eq." + QString::number(idUtente));
        QNetworkRequest request(url);
        impostaHeader(request);

        QJsonObject body;
        body["letta"] = true;

        // PATCH massiva: tutte le notifiche dell'utente diventano 'lette'
        manager->sendCustomRequest(request, "PATCH", QJsonDocument(body).toJson());
    }
    Q_INVOKABLE void caricaLogAttivita() {
        QString dataInizio = QDate::currentDate().addDays(-5).toString("yyyy-MM-dd");
        QUrl url("https://tbgjaxoukzcimtfkbqua.supabase.co/rest/v1/log_attivita_riposi?data_operazione=gte." + dataInizio + "&order=data_operazione.desc");
        QNetworkRequest request(url);
        impostaHeader(request);
        QNetworkReply* reply = manager->get(request);
        connect(reply, &QNetworkReply::finished, [this, reply]() {
            if (reply->error() == QNetworkReply::NoError) {
                QJsonArray array = QJsonDocument::fromJson(reply->readAll()).array();
                QVariantList lista;
                for (const QJsonValue & v : array) {
                    QJsonObject obj = v.toObject();
                    QVariantMap item;
                    // Formattazione data e ora italiana
                    QDateTime dt = QDateTime::fromString(obj["data_operazione"].toString(), Qt::ISODate).toLocalTime();
                    item["dataOra"] = dt.toString("dd-MM-yyyy HH:mm");
                    item["operazione"] = obj["operazione"].toString();
                    item["utente"] = obj["id_utente"].toString();
                    item["dettagli"] = QJsonDocument(obj["dati_record"].toObject()).toJson(QJsonDocument::Compact);
                    lista.append(item);
                }
                emit logRicevuti(lista);
            }
            reply->deleteLater();
        });
    }
    Q_INVOKABLE bool isOperazioneBloccata(QString idUtenteRichiedente, QString dataOperazioneISO = "") {
        QStringList adminIDs = {"1", "2", "3", "19"};
        QDate dataTarget = dataOperazioneISO.isEmpty() ? QDate::currentDate() : QDate::fromString(dataOperazioneISO, "yyyy-MM-dd");
        QDate dataOggi = QDate::currentDate();
        if (!adminIDs.contains(idUtenteRichiedente) && dataTarget < dataOggi) {
            emit loginError("OPERAZIONE NEGATA: Non puoi inserire o modificare dati per una data passata (" + 
                    dataTarget.toString("dd-MM-yyyy") + ").");
        return true; 
        }
        if (adminIDs.contains(idUtenteRichiedente)) return false;
        if (!m_bloccoAttivo) return false;
        if (dataTarget >= m_inizioBlocco && dataTarget <= m_fineBlocco) {
            QString msg = "PERIODO BLOCCATO: Non puoi operare sulle date comprese tra il " + 
                    m_inizioBlocco.toString("dd-MM-yyyy") + " e il " + 
                    m_fineBlocco.toString("dd-MM-yyyy") + ".";
            emit erroreOperazione(msg);
            return true;
        }
        return false;
    }
    Q_INVOKABLE void generaPDF(QVariantList utenti, QVariantList dati, int giorni, QString inizio, QString fine) {
        QString utentiJson = QJsonDocument(QJsonArray::fromVariantList(utenti)).toJson(QJsonDocument::Compact);
        QString datiJson = QJsonDocument(QJsonArray::fromVariantList(dati)).toJson(QJsonDocument::Compact);
        emscripten_run_script(("window.__pdfUtenti = " + utentiJson.toStdString() + ";").c_str());
        emscripten_run_script(("window.__pdfDati = "   + datiJson.toStdString()   + ";").c_str());
        emscripten_run_script(("window.__pdfGiorni = "  + std::to_string(giorni)  + ";").c_str());
        emscripten_run_script(("window.__pdfInizio = '" + inizio.toStdString()    + "';").c_str());
        emscripten_run_script(("window.__pdfFine = '"   + fine.toStdString()      + "';").c_str());
        emscripten_run_script("generaPDFSpecchio(window.__pdfUtenti, window.__pdfDati, window.__pdfGiorni, window.__pdfInizio, window.__pdfFine);");
    }
    // --- STRAORDINARI ---

    Q_INVOKABLE void caricaStraordinariMese(QString idUtente, int anno, int mese) {
        QDate primoGiorno(anno, mese, 1);
        QDate primoMeseSucc = primoGiorno.addMonths(1);
        QUrl url("https://tbgjaxoukzcimtfkbqua.supabase.co/rest/v1/straordinari"
                "?id_utente=eq." + idUtente +
                "&data=gte." + primoGiorno.toString("yyyy-MM-dd") +
                "&data=lt." + primoMeseSucc.toString("yyyy-MM-dd") +
                "&order=data.desc");
        QNetworkRequest request(url);
        impostaHeader(request);

        QNetworkReply* reply = manager->get(request);
        connect(reply, &QNetworkReply::finished, [this, reply]() {
            if (reply->error() == QNetworkReply::NoError) {
                QJsonArray array = QJsonDocument::fromJson(reply->readAll()).array();
                QVariantList lista;
                double totale = 0.0;
                for (const QJsonValue &v : array) {
                    QJsonObject obj = v.toObject();
                    QVariantMap item;
                    item["id"]      = obj["id"].toInt();
                    item["dataISO"] = obj["data"].toString();
                    item["dataITA"] = QDate::fromString(obj["data"].toString(), "yyyy-MM-dd").toString("dd-MM-yyyy");
                    item["ore"]     = obj["ore"].toDouble();
                    item["oraInizio"] = obj["ora_inizio"].toString();
                    item["oraFine"]   = obj["ora_fine"].toString();
                    item["nota"]      = obj["nota"].toString();
                    totale += obj["ore"].toDouble();
                    lista.append(item);
                }
                emit straordinariRicevuti(lista, totale);
            } else {
                emit erroreOperazione("Errore caricamento straordinari: " + reply->errorString());
            }
            reply->deleteLater();
        });
    }


    Q_INVOKABLE void salvaOreStraordinario(QString idUtente, QString dataISO,
                                           QString oraInizio, QString oraFine, QString nota) {
        QDate dataInserita = QDate::fromString(dataISO, "yyyy-MM-dd");
        if (dataInserita > QDate::currentDate()) {
            emit erroreOperazione("Non puoi inserire straordinari per una data futura!");
            return;
        }

        if (isBloccoAdmin(idUtente, dataISO)) return;

        QTime tInizio = QTime::fromString(oraInizio, "HH:mm");
        QTime tFine   = QTime::fromString(oraFine,   "HH:mm");
        if (!tInizio.isValid() || !tFine.isValid() || tFine <= tInizio) {
            emit erroreOperazione("Orario non valido: l'ora di fine deve essere successiva all'ora di inizio!");
            return;
        }
        double ore = tInizio.secsTo(tFine) / 3600.0;

        // Prima controlla sovrapposizioni per quella data
        QUrl checkUrl("https://tbgjaxoukzcimtfkbqua.supabase.co/rest/v1/straordinari"
                      "?id_utente=eq." + idUtente +
                      "&data=eq." + dataISO);
        QNetworkRequest checkRequest(checkUrl);
        impostaHeader(checkRequest);

        QNetworkReply* checkReply = manager->get(checkRequest);
        connect(checkReply, &QNetworkReply::finished, [this, checkReply, idUtente, dataISO,
                oraInizio, oraFine, nota, ore, tInizio, tFine]() {

            if (checkReply->error() == QNetworkReply::NoError) {
                QJsonArray esistenti = QJsonDocument::fromJson(checkReply->readAll()).array();

                // Controlla sovrapposizione con ogni riga esistente
                for (const QJsonValue &v : esistenti) {
                    QJsonObject obj = v.toObject();
                    QTime eInizio = QTime::fromString(obj["ora_inizio"].toString(), "HH:mm");
                    QTime eFine   = QTime::fromString(obj["ora_fine"].toString(),   "HH:mm");
                    if (!eInizio.isValid() || !eFine.isValid()) continue;

                    // Sovrapposizione: i due intervalli si toccano o si incrociano
                    if (tInizio < eFine && tFine > eInizio) {
                        emit erroreOperazione(
                            "Sovrapposizione oraria! Hai già uno straordinario dalle " +
                            obj["ora_inizio"].toString() + " alle " +
                            obj["ora_fine"].toString() + " in questa data."
                        );
                        checkReply->deleteLater();
                        return;
                    }
                }

                // Nessuna sovrapposizione — procedi con l'inserimento
                QJsonObject dati;
                dati["id_utente"]  = idUtente.toInt();
                dati["data"]       = dataISO;
                dati["ore"]        = ore;
                dati["ora_inizio"] = oraInizio;
                dati["ora_fine"]   = oraFine;
                if (!nota.isEmpty()) dati["nota"] = nota;

                QUrl url("https://tbgjaxoukzcimtfkbqua.supabase.co/rest/v1/straordinari");
                QNetworkRequest request(url);
                impostaHeader(request);

                QNetworkReply* reply = manager->post(request, QJsonDocument(dati).toJson());
                connect(reply, &QNetworkReply::finished, [this, reply]() {
                    if (reply->error() == QNetworkReply::NoError) {
                        emit operazioneCompletata("Salvato!");
                    } else {
                        emit erroreOperazione("Errore salvataggio: " + reply->errorString());
                    }
                    reply->deleteLater();
                });

            } else {
                emit erroreOperazione("Errore verifica sovrapposizioni: " + checkReply->errorString());
            }
            checkReply->deleteLater();
        });
    }

    Q_INVOKABLE void eliminaStraordinario(int id) {
        QUrl url("https://tbgjaxoukzcimtfkbqua.supabase.co/rest/v1/straordinari?id=eq." + QString::number(id));
        QNetworkRequest request(url);
        impostaHeader(request);

        QNetworkReply* reply = manager->sendCustomRequest(request, "DELETE", QByteArray());
        connect(reply, &QNetworkReply::finished, [this, reply]() {
            if (reply->error() == QNetworkReply::NoError) {
                emit operazioneCompletata("Eliminato!");
            } else {
                emit erroreOperazione("Errore eliminazione: " + reply->errorString());
            }
            reply->deleteLater();
        });
    }
    // Funzione separata SOLO per il badge del menu (mese corrente)
    Q_INVOKABLE void caricaOreBadgeMenu(QString idUtente, int anno, int mese) {
        QDate primoGiorno(anno, mese, 1);
        QDate primoMeseSucc = primoGiorno.addMonths(1);
        QUrl url("https://tbgjaxoukzcimtfkbqua.supabase.co/rest/v1/straordinari"
                 "?id_utente=eq." + idUtente +
                 "&data=gte." + primoGiorno.toString("yyyy-MM-dd") +
                 "&data=lt." + primoMeseSucc.toString("yyyy-MM-dd"));
        QNetworkRequest request(url);
        impostaHeader(request);
        QNetworkReply* reply = manager->get(request);
        connect(reply, &QNetworkReply::finished, [this, reply]() {
            if (reply->error() == QNetworkReply::NoError) {
                QJsonArray array = QJsonDocument::fromJson(reply->readAll()).array();
                double totale = 0.0;
                for (const QJsonValue &v : array)
                    totale += v.toObject()["ore"].toDouble();
                emit oreBadgeMenuRicevute(totale);
            }
            reply->deleteLater();
        });
    }
    Q_INVOKABLE void caricaDettaglioStraordinariMese(QString idUtente, int anno, int mese) {
        QDate primoGiorno(anno, mese, 1);
        QDate primoMeseSucc = primoGiorno.addMonths(1);
        QUrl url("https://tbgjaxoukzcimtfkbqua.supabase.co/rest/v1/straordinari"
                "?id_utente=eq." + idUtente +
                "&data=gte." + primoGiorno.toString("yyyy-MM-dd") +
                "&data=lt."  + primoMeseSucc.toString("yyyy-MM-dd") +
                "&select=data,ore");
        QNetworkRequest request(url);
        impostaHeader(request);
        QNetworkReply* reply = manager->get(request);
        connect(reply, &QNetworkReply::finished, [this, reply]() {
            if (reply->error() == QNetworkReply::NoError) {
                QJsonArray array = QJsonDocument::fromJson(reply->readAll()).array();
                QVariantList lista;
                for (const QJsonValue &v : array) {
                    QJsonObject obj = v.toObject();
                    QVariantMap item;
                    item["dataISO"] = obj["data"].toString();
                    item["ore"]     = obj["ore"].toDouble();
                    lista.append(item);
                }
                emit dettaglioStraordinariRicevuti(lista);
            }
            reply->deleteLater();
        });
    }
    // Badge Riposi e Licenze — scarica tutti i record dell'utente
    Q_INVOKABLE void caricaBadgeRiposi(QString idUtente) {
        QUrl url("https://tbgjaxoukzcimtfkbqua.supabase.co/rest/v1/riposi"
                 "?id_utente=eq." + idUtente +
                 "&select=giorno_di_riposo,tipo_riposo,fruizione,stato,data_fruizione,a"
                 "&order=giorno_di_riposo.asc");
        QNetworkRequest request(url);
        impostaHeader(request);
        QNetworkReply* reply = manager->get(request);
        connect(reply, &QNetworkReply::finished, [this, reply]() {
            if (reply->error() == QNetworkReply::NoError) {
                QJsonArray array = QJsonDocument::fromJson(reply->readAll()).array();
                QVariantList lista;
                for (const QJsonValue &v : array) {
                    QJsonObject obj = v.toObject();
                    QVariantMap item;
                    item["data"]    = obj["giorno_di_riposo"].toString(); // "yyyy-MM-dd"
                    item["tipo"]    = obj["tipo_riposo"].toString();
                    item["fruiz"]   = obj["fruizione"].toString();
                    item["stato"]   = obj["stato"].toString();
                    item["data_fruizione"] = obj["data_fruizione"].toString();
                    item["a"] = obj["a"].toString();
                    lista.append(item);
                }
                emit badgeRiposiRicevuti(lista);
            }
            reply->deleteLater();
        });
    }
    Q_INVOKABLE void contaColleghiPerData(QString idUtente, QString dataISO) {
        QUrl url("https://tbgjaxoukzcimtfkbqua.supabase.co/rest/v1/rpc/conta_colleghi_per_data");
        QNetworkRequest request(url);
        impostaHeader(request);

        QJsonObject body;
        body["p_id_utente"] = idUtente.toInt();
        body["p_data"] = dataISO; // "yyyy-MM-dd"

        QNetworkReply* reply = manager->post(request, QJsonDocument(body).toJson());
        connect(reply, &QNetworkReply::finished, [this, reply, dataISO]() {
            if (reply->error() == QNetworkReply::NoError) {
                QByteArray raw = reply->readAll();
                int count = QString(raw).trimmed().remove("\"").toInt();
                emit colleghiPerDataRicevuti(dataISO, count);
            }
            reply->deleteLater();
        });
    }
    // Salva badge del mese (chiamata a fine calcolaBadge)
    Q_INVOKABLE void salvaBadgeMese(QString idUtente, int anno, int mese, QVariantList badges) {
        for (const QVariant &bv : badges) {
            QVariantMap b = bv.toMap();
            QJsonObject dati;
            dati["id_utente"]   = idUtente;
            dati["anno"]        = anno;
            dati["mese"]        = mese;
            dati["nome_badge"]  = b["nome"].toString();
            dati["livello"]     = b["livello"].toInt();
            dati["colore"]      = b["colore"].toString();
            dati["occorrenze"]  = b.contains("occorrenze") ? b["occorrenze"].toInt() : 1;

            QUrl url("https://tbgjaxoukzcimtfkbqua.supabase.co/rest/v1/badge_storico"
                    "?on_conflict=id_utente,anno,mese,nome_badge");
            QNetworkRequest request(url);
            impostaHeader(request);
            request.setRawHeader("Prefer", "resolution=merge-duplicates,return=minimal");

            QNetworkReply* reply = manager->post(request, QJsonDocument(dati).toJson());
            connect(reply, &QNetworkReply::finished, [reply]() {
                if (reply->error() != QNetworkReply::NoError)
                    qDebug() << "ERRORE salvaBadgeMese:" << reply->errorString() << reply->readAll();
                else
                    qDebug() << "salvaBadgeMese OK:" << reply->readAll();
                reply->deleteLater();
            });
        }
    }

    // Carica storico badge dell'anno corrente
    Q_INVOKABLE void caricaStoricoBadge(QString idUtente, int anno) {
        QUrl url("https://tbgjaxoukzcimtfkbqua.supabase.co/rest/v1/badge_storico"
                "?id_utente=eq." + idUtente +
                "&anno=eq." + QString::number(anno) +
                "&select=mese,nome_badge,livello,colore,occorrenze&order=mese.asc");
        QNetworkRequest request(url);
        impostaHeader(request);
        QNetworkReply* reply = manager->get(request);
        connect(reply, &QNetworkReply::finished, [this, reply]() {
            if (reply->error() == QNetworkReply::NoError) {
                QByteArray raw = reply->readAll();
                qDebug() << "caricaStoricoBadge risposta:" << raw;
                QJsonArray array = QJsonDocument::fromJson(raw).array();
                QVariantList lista;
                for (const QJsonValue &v : array) {
                    QJsonObject obj = v.toObject();
                    QVariantMap item;
                    item["mese"]       = obj["mese"].toInt();
                    item["nome_badge"] = obj["nome_badge"].toString();
                    item["livello"]    = obj["livello"].toInt();
                    item["colore"]     = obj["colore"].toString();
                    item["occorrenze"] = obj["occorrenze"].toInt();
                    lista.append(item);
                }
                emit storicoBadgeRicevuto(lista);
            } else {
                qDebug() << "caricaStoricoBadge ERRORE:" << reply->errorString() << reply->readAll();
            }
            reply->deleteLater();
        });
    }

    // Carica riposi fruiti dell'anno per tipo
    Q_INVOKABLE void caricaRiposiAnnualiPerTipo(QString idUtente, int anno, QString oggiISO) {
        QUrl url("https://tbgjaxoukzcimtfkbqua.supabase.co/rest/v1/riposi"
            "?id_utente=eq." + idUtente +
            "&data_fruizione=gte." + QString::number(anno) + "-01-01" +
            "&data_fruizione=lte." + oggiISO +
            "&data_fruizione=not.is.null"
            "&select=tipo_riposo,data_fruizione,a");
        QNetworkRequest request(url);
        impostaHeader(request);
        QNetworkReply* reply = manager->get(request);
        connect(reply, &QNetworkReply::finished, [this, reply]() {
            if (reply->error() == QNetworkReply::NoError) {
                QJsonArray array = QJsonDocument::fromJson(reply->readAll()).array();
                QVariantList lista;
                for (const QJsonValue &v : array) {
                    QJsonObject obj = v.toObject();
                    QVariantMap item;
                    item["tipo"]  = obj["tipo_riposo"].toString();
                    item["data"]  = obj["data_fruizione"].toString();
                    item["a"] = obj["a"].toString();
                    lista.append(item);
                }
                emit riposiAnnualiRicevuti(lista);
            }
            reply->deleteLater();
        });
    }
    Q_INVOKABLE void caricaOreStrAnnuali(QString idUtente, int anno, QString oggiISO) {
        QUrl url("https://tbgjaxoukzcimtfkbqua.supabase.co/rest/v1/straordinari"
                "?id_utente=eq." + idUtente +
                "&data=gte." + QString::number(anno) + "-01-01" +
                "&data=lte." + oggiISO +
                "&select=ore");
        QNetworkRequest request(url);
        impostaHeader(request);
        QNetworkReply* reply = manager->get(request);
        connect(reply, &QNetworkReply::finished, [this, reply]() {
            if (reply->error() == QNetworkReply::NoError) {
                QJsonArray array = QJsonDocument::fromJson(reply->readAll()).array();
                double totale = 0;
                for (const QJsonValue &v : array)
                    totale += v.toObject()["ore"].toDouble();
                emit oreStrAnnualiRicevute(totale);
            }
            reply->deleteLater();
        });
    }
    // Nel blocco pubblico, accanto a caricaOreStrAnnuali
    Q_INVOKABLE void caricaOreStrMese(QString idUtente, int anno, int mese) {
        QDate primoGiorno(anno, mese, 1);
        QDate primoMeseSucc = primoGiorno.addMonths(1);
        QUrl url("https://tbgjaxoukzcimtfkbqua.supabase.co/rest/v1/straordinari"
                "?id_utente=eq." + idUtente +
                "&data=gte." + primoGiorno.toString("yyyy-MM-dd") +
                "&data=lt."  + primoMeseSucc.toString("yyyy-MM-dd") +
                "&select=ore");
        QNetworkRequest request(url);
        impostaHeader(request);
        QNetworkReply* reply = manager->get(request);
        connect(reply, &QNetworkReply::finished, [this, reply]() {
            if (reply->error() == QNetworkReply::NoError) {
                QJsonArray array = QJsonDocument::fromJson(reply->readAll()).array();
                double totale = 0;
                for (const QJsonValue &v : array)
                    totale += v.toObject()["ore"].toDouble();
                emit oreStrMeseRicevute(totale);
            }
            reply->deleteLater();
        });
    }
    Q_INVOKABLE void caricaProfiloAltroUtente(QString idUtente, int anno, QString oggiISO) {
        QUrl urlB("https://tbgjaxoukzcimtfkbqua.supabase.co/rest/v1/badge_storico"
                "?id_utente=eq." + idUtente +
                "&anno=eq." + QString::number(anno) +
                "&select=mese,nome_badge,livello,colore,occorrenze&order=mese.asc");
        QNetworkRequest reqB(urlB);
        impostaHeader(reqB);
        QNetworkReply* replyB = manager->get(reqB);
        connect(replyB, &QNetworkReply::finished, [this, replyB]() {
            if (replyB->error() == QNetworkReply::NoError) {
                QJsonArray array = QJsonDocument::fromJson(replyB->readAll()).array();
                QVariantList lista;
                for (const QJsonValue &v : array) {
                    QJsonObject obj = v.toObject();
                    QVariantMap item;
                    item["mese"]       = obj["mese"].toInt();
                    item["nome_badge"] = obj["nome_badge"].toString();
                    item["livello"]    = obj["livello"].toInt();
                    item["colore"]     = obj["colore"].toString();
                    item["occorrenze"] = obj["occorrenze"].toInt();
                    lista.append(item);
                }
                emit profiloAltroStoricoBadge(lista);
            }
            replyB->deleteLater();
        });

        // 2) Riposi annuali per tipo
        QUrl urlR("https://tbgjaxoukzcimtfkbqua.supabase.co/rest/v1/riposi"
                "?id_utente=eq." + idUtente +
                "&data_fruizione=gte." + QString::number(anno) + "-01-01" +
                "&data_fruizione=lte." + oggiISO +
                "&data_fruizione=not.is.null"
                "&select=tipo_riposo,data_fruizione,a");
        QNetworkRequest reqR(urlR);
        impostaHeader(reqR);
        QNetworkReply* replyR = manager->get(reqR);
        connect(replyR, &QNetworkReply::finished, [this, replyR]() {
            if (replyR->error() == QNetworkReply::NoError) {
                QJsonArray array = QJsonDocument::fromJson(replyR->readAll()).array();
                QVariantList lista;
                for (const QJsonValue &v : array) {
                    QJsonObject obj = v.toObject();
                    QVariantMap item;
                    item["tipo"] = obj["tipo_riposo"].toString();
                    item["data"] = obj["data_fruizione"].toString();
                    item["a"]    = obj["a"].toString();
                    lista.append(item);
                }
                emit profiloAltroRiposiAnnuali(lista);
            }
            replyR->deleteLater();
        });

        // 3) Ore straordinari annuali
        QUrl urlS("https://tbgjaxoukzcimtfkbqua.supabase.co/rest/v1/straordinari"
                "?id_utente=eq." + idUtente +
                "&data=gte." + QString::number(anno) + "-01-01" +
                "&data=lte." + oggiISO +
                "&select=ore");
        QNetworkRequest reqS(urlS);
        impostaHeader(reqS);
        QNetworkReply* replyS = manager->get(reqS);
        connect(replyS, &QNetworkReply::finished, [this, replyS]() {
            if (replyS->error() == QNetworkReply::NoError) {
                QJsonArray array = QJsonDocument::fromJson(replyS->readAll()).array();
                double totale = 0;
                for (const QJsonValue &v : array)
                    totale += v.toObject()["ore"].toDouble();
                emit profiloAltroOreStr(totale);
            }
            replyS->deleteLater();
        });
    }


signals:
    void loginSuccess(QString nomeCompleto, QString idSeriale);
    void loginError(QString messaggio);
    void riposiRicevuti(QVariantList lista);
    void operazioneCompletata(QString messaggio);
    void confermaCancellazioneRichiesta(QVariantMap dati);
    void specchioRicevuto(QVariantList lista, int giorniMese);
    void bloccoCambiato();
    void logRicevuti(QVariantList lista);
    void straordinariRicevuti(QVariantList lista, double totale);
    void richiesteBloccoRicevute(QVariantList lista);
    void notificheConteggiate(int count);
    void erroreOperazione(QString messaggio);
    void notificheRicevute(QVariantList lista);
    void oreBadgeMenuRicevute(double totaleOre);
    void badgeRiposiRicevuti(QVariantList lista);
    void colleghiPerDataRicevuti(QString dataISO, int count);
    void dettaglioStraordinariRicevuti(QVariantList lista);
    void storicoBadgeRicevuto(QVariantList lista);
    void riposiAnnualiRicevuti(QVariantList lista);
    void oreStrAnnualiRicevute(double totale);
    void oreStrMeseRicevute(double totale);
    void profiloAltroStoricoBadge(QVariantList lista);
    void profiloAltroRiposiAnnuali(QVariantList lista);
    void profiloAltroOreStr(double totale);

private:
    bool m_bloccoAttivo = false;
    QDate m_inizioBlocco;
    QDate m_fineBlocco;
    QString m_nomeUtenteLoggato;
    QString m_idUtenteLoggato;
    QNetworkAccessManager* manager;

    void impostaHeader(QNetworkRequest &request) {
        QByteArray apikey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRiZ2pheG91a3pjaW10ZmticXVhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY3NjMzNjIsImV4cCI6MjA5MjMzOTM2Mn0.n2WCdp7SZ-VBg_8j1IJUJH7pGbqecFkOdar727qwQJ0";
        request.setRawHeader("apikey", apikey);
        request.setRawHeader("Authorization", "Bearer " + apikey);
        request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
        request.setRawHeader("Prefer", "return=representation");
    }

    // Controlla SOLO il blocco admin sull'intervallo date — senza il vincolo "data passata".
    // Usato da modificaRiposo: l'utente può editare i propri riposi (anche datati nel passato),
    // tranne quelli il cui giorno_di_riposo cade nel periodo congelato dall'admin.
    bool isBloccoAdmin(const QString &idUtenteRichiedente, const QString &dataOperazioneISO) {
        static const QStringList adminIDs = {"1", "2", "3", "19"};
        if (adminIDs.contains(idUtenteRichiedente)) return false;
        if (!m_bloccoAttivo) return false;
        QDate dataTarget = QDate::fromString(dataOperazioneISO, "yyyy-MM-dd");
        if (dataTarget >= m_inizioBlocco && dataTarget <= m_fineBlocco) {
            emit erroreOperazione("PERIODO BLOCCATO: Non puoi modificare date comprese nel periodo congelato.");
            return true;
        }
        return false;
    }

    void eseguiUpdateModifica(QString idSeriale, QString dataISO, int tipoIdx, QString nStato) {
        QStringList tipi = {"RIPOSO SETTIMANALE", "RIPOSO FESTIVO", "RIPOSO MEDICO", "RIPOSO STUDIO", "RIPOSO DONAZIONE SANGUE", "RIPOSO DI ALTRO TIPO"};

        QJsonObject dati;
        dati["tipo_riposo"] = tipi[tipoIdx];
        dati["stato"] = nStato;

        // Applichiamo il tuo vincolo: VALIDATO -> FRUITO, Altrimenti -> DISPONIBILE
        dati["fruizione"] = (nStato == "VALIDATO") ? "FRUITO" : "DISPONIBILE";

        // Se l'utente riporta lo stato indietro (es. da Validato a Acquisito), cancelliamo la data_fruizione
        if (nStato == "ACQUISITO") {
            dati["data_fruizione"] = QJsonValue::Null;
        }

        QUrl url("https://tbgjaxoukzcimtfkbqua.supabase.co/rest/v1/riposi?id_utente=eq." + idSeriale + "&giorno_di_riposo=eq." + dataISO);
        QNetworkRequest request(url);
        request.setRawHeader("Content-Type", "application/json");
        request.setRawHeader("apikey", "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRiZ2pheG91a3pjaW10ZmticXVhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY3NjMzNjIsImV4cCI6MjA5MjMzOTM2Mn0.n2WCdp7SZ-VBg_8j1IJUJH7pGbqecFkOdar727qwQJ0");
        request.setRawHeader("Authorization", "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRiZ2pheG91a3pjaW10ZmticXVhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY3NjMzNjIsImV4cCI6MjA5MjMzOTM2Mn0.n2WCdp7SZ-VBg_8j1IJUJH7pGbqecFkOdar727qwQJ0");
        request.setRawHeader("Prefer", "return=representation");

        QNetworkReply* reply = manager->sendCustomRequest(request, "PATCH", QJsonDocument(dati).toJson());
        connect(reply, &QNetworkReply::finished, [this, reply, idSeriale, dataISO, nStato]() {
            QByteArray res = reply->readAll();
            if (reply->error() == QNetworkReply::NoError) {
                QJsonObject info;
                info["data_modificata"] = dataISO;
                info["nuovo_stato"] = nStato;
                scriviLog(idSeriale, "MODIFICA", info);
                QJsonDocument doc = QJsonDocument::fromJson(res);
                if (doc.isArray() && !doc.array().isEmpty()) {
                    emit operazioneCompletata("Riposo modificato con successo!");
                } else {
                    emit erroreOperazione("Attenzione: Nessun record corrispondente trovato per l'aggiornamento.");
                }
            } else {
                emit erroreOperazione("ERRORE DI RETE " + reply->errorString());
            }
            reply->deleteLater();
        });
    }

    void eseguiPatchFruizione(QString idSeriale, QString dataMaturazioneISO, QString dataFruizioneISO, int statoScelto) {
        qDebug() << "[PATCH] idSeriale:" << idSeriale;
        qDebug() << "[PATCH] dataMaturazioneISO:" << dataMaturazioneISO;
        qDebug() << "[PATCH] dataFruizioneISO:" << dataFruizioneISO;
        QString nStato = (statoScelto == 1) ? "RICHIESTO" : "VALIDATO";
        QString nFruizione = (nStato == "VALIDATO") ? "FRUITO" : "DISPONIBILE";
        QJsonObject dati;
        dati["data_fruizione"] = dataFruizioneISO;
        dati["stato"] = nStato;
        dati["fruizione"] = nFruizione;

        QUrl url("https://tbgjaxoukzcimtfkbqua.supabase.co/rest/v1/riposi?id_utente=eq." + idSeriale + "&giorno_di_riposo=eq." + dataMaturazioneISO);
        QNetworkRequest request(url);
        request.setRawHeader("apikey", "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRiZ2pheG91a3pjaW10ZmticXVhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY3NjMzNjIsImV4cCI6MjA5MjMzOTM2Mn0.n2WCdp7SZ-VBg_8j1IJUJH7pGbqecFkOdar727qwQJ0");
        request.setRawHeader("Authorization", "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRiZ2pheG91a3pjaW10ZmticXVhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY3NjMzNjIsImV4cCI6MjA5MjMzOTM2Mn0.n2WCdp7SZ-VBg_8j1IJUJH7pGbqecFkOdar727qwQJ0");
        request.setRawHeader("Content-Type", "application/json");

        QNetworkReply* reply = manager->sendCustomRequest(request, "PATCH", QJsonDocument(dati).toJson());
        connect(reply, &QNetworkReply::finished, [this, reply, nStato]() {
            QByteArray res = reply->readAll();
            qDebug() << "[PATCH] HTTP status:" << reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
            qDebug() << "[PATCH] risposta:" << res;
            if (reply->error() == QNetworkReply::NoError) {
                QString msg = (nStato == "RICHIESTO") ? "Richiesta inviata (ancora disponibile)."
                                                      : "Riposo validato e fruito!";
                emit operazioneCompletata(msg);
            } else {
                qDebug() << "[PATCH] Errore rete:" << reply->errorString();
                emit erroreOperazione("Non puoi fruire di un giorno in data precedente a oggi.");
            }
            reply->deleteLater();
        });
    }

    void scriviLog(QString idUtente, QString tipoOp, QJsonObject datiRecord) {
        QJsonObject log;
        log["id_utente"] = idUtente;
        log["operazione"] = tipoOp;
        log["dati_record"] = datiRecord; // Colonna jsonb
        // La data_operazione viene inserita automaticamente da Supabase se hai impostato il default now()
        // Altrimenti puoi aggiungerla qui:
        log["data_operazione"] = QDateTime::currentDateTime().toString(Qt::ISODate);

        QUrl url("https://tbgjaxoukzcimtfkbqua.supabase.co/rest/v1/log_attivita_riposi");
        QNetworkRequest request(url);
        impostaHeader(request); // Usa gli header apikey e bearer già presenti

        manager->post(request, QJsonDocument(log).toJson());
        qDebug() << "Log registrato:" << tipoOp << "per utente" << idUtente;
    }
};
#endif