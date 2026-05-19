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
#include <emscripten/val.h>
#include <QRegularExpression>

class DatabaseManager : public QObject {
    Q_OBJECT
public:
    explicit DatabaseManager(QObject *parent = nullptr) : QObject(parent) {
        manager = new QNetworkAccessManager(this);
    }
    Q_INVOKABLE int offsetPrimoGiornoMese(int anno, int mese) {
        QDate data(anno, mese, 1);
        if (!data.isValid()) {
            return 0;
        }
        return data.dayOfWeek() - 1;
    }

    Q_INVOKABLE int giorniNelMese(int anno, int mese) {
        return QDate(anno, mese, 1).daysInMonth();
    }

    Q_INVOKABLE int giornoSettimana(int anno, int mese, int giorno) {
        return QDate(anno, mese, giorno).dayOfWeek();
    }

    // --- FUNZIONE 1: LOGIN ---
    Q_INVOKABLE void login(QString cip) {
        qDebug() << "[DEBUG LOGIN] Avvio tentativo per CIP:" << cip;
        QUrl url("https://tbgjaxoukzcimtfkbqua.supabase.co/rest/v1/utenti?cip=eq." + cip);
        qDebug() << "[DEBUG LOGIN] URL richiesto:" << url.toString();
        QNetworkRequest request(url);
        impostaHeader(request);
        request.setTransferTimeout(20000);

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
                        emit loginSuccess(m_nomeUtenteLoggato, m_idUtenteLoggato);
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
                 "&select=giorno_di_riposo,tipo_riposo,stato,fruizione,data_fruizione,a" +
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
                    item["a"] = obj["a"].toString();

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
        
        QString dataFruizioneISO = dataFruizione.toString("yyyy-MM-dd");

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
                emit operazioneCompletata("Riposo del " + dataGGMMAAAA + " cancellato con successo!");
            } else {
                emit loginError("Errore durante la cancellazione: data non trovata o problema di rete.");
            }
            reply->deleteLater();
        });
    }

    // Salva o aggiorna una licenza (codice semplice come "L" o "P")
    Q_INVOKABLE void salvaLicenzaPersonale(QString idUtenteLoggato, QString dataISO, QString codiceLicenza) {
        if (isOperazioneBloccata(idUtenteLoggato, dataISO)) return;

        QString codiceNorm = codiceLicenza.toUpper().trimmed();
        static const QStringList CODICI_VALIDATI   = {"LS", "CP", "104", "CIT"};
        static const QStringList CODICI_PREFERENZA = {"MAT", "POM", "SER"};  // aggiunto SER
        static const QRegularExpression rxNumeroSlash("^\\d+/\\d+$");

        QString statoFinale;
        QString fruizioneFinale;
        statoFinale     = "VALIDATO";
        fruizioneFinale = "FRUITO";

        QJsonObject dati;
        dati["id_utente"]        = idUtenteLoggato.toInt();
        dati["data_fruizione"]   = dataISO;
        dati["tipo_riposo"]      = "LICENZA";
        dati["a"]                = codiceNorm;
        dati["stato"]            = statoFinale;
        dati["fruizione"]        = fruizioneFinale;
        dati["giorno_di_riposo"] = QJsonValue();
        qDebug() << "INVIO LICENZA - Data:" << dataISO << "Codice:" << codiceNorm << "Stato:" << statoFinale << "Fruizione:" << fruizioneFinale;
        QUrl url("https://tbgjaxoukzcimtfkbqua.supabase.co/rest/v1/riposi?on_conflict=id_utente,data_fruizione");
        QNetworkRequest request(url);
        request.setRawHeader("apikey", "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRiZ2pheG91a3pjaW10ZmticXVhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY3NjMzNjIsImV4cCI6MjA5MjMzOTM2Mn0.n2WCdp7SZ-VBg_8j1IJUJH7pGbqecFkOdar727qwQJ0");
        request.setRawHeader("Authorization", "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRiZ2pheG91a3pjaW10ZmticXVhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY3NjMzNjIsImV4cCI6MjA5MjMzOTM2Mn0.n2WCdp7SZ-VBg_8j1IJUJH7pGbqecFkOdar727qwQJ0");
        request.setRawHeader("Content-Type", "application/json");
        request.setRawHeader("Prefer", "resolution=merge-duplicates,return=representation");
        QJsonDocument doc(dati);
        QNetworkReply *reply = manager->post(request, doc.toJson());
        connect(reply, &QNetworkReply::finished, [this, reply, idUtenteLoggato, dataISO, codiceLicenza]() {
            QByteArray res = reply->readAll();
            qDebug() << "LICENZA HTTP status:" << reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
            qDebug() << "LICENZA risposta DB:" << res;
            if (reply->error() == QNetworkReply::NoError) {
                QJsonObject info;
                info["data"] = dataISO;
                info["codice"] = codiceLicenza;
                emit operazioneCompletata("Salvato");
            } else {
                qDebug() << "LICENZA errore rete:" << reply->errorString();
                emit erroreOperazione("Errore salvataggio licenza: " + reply->errorString());
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
                emit operazioneCompletata("Licenza eliminata con successo!");
            } else {
                emit loginError("Errore durante l'eliminazione.");
            }
            reply->deleteLater();
        });
    }

    Q_INVOKABLE bool isOperazioneBloccata(QString idUtenteRichiedente, QString dataOperazioneISO = "") {
        QDate dataTarget = dataOperazioneISO.isEmpty() ? QDate::currentDate() : QDate::fromString(dataOperazioneISO, "yyyy-MM-dd");
        QDate dataOggi = QDate::currentDate();
        QStringList adminIDs = {"1", "2", "3", "19"};
        if (!adminIDs.contains(idUtenteRichiedente) && dataTarget < dataOggi) {
            emit loginError("OPERAZIONE NEGATA: Non puoi inserire o modificare dati per una data passata (" +
                    dataTarget.toString("dd-MM-yyyy") + ").");
            return true;
        }
        return false;
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
    

signals:
    void loginSuccess(QString nomeCompleto, QString idSeriale);
    void loginError(QString messaggio);
    void riposiRicevuti(QVariantList lista);
    void operazioneCompletata(QString messaggio);
    void confermaCancellazioneRichiesta(QVariantMap dati);
    void straordinariRicevuti(QVariantList lista, double totale);
    void erroreOperazione(QString messaggio);
    void badgeRiposiRicevuti(QVariantList lista);
    void dettaglioStraordinariRicevuti(QVariantList lista);
    void riposiAnnualiRicevuti(QVariantList lista);
    void oreStrAnnualiRicevute(double totale);
    void oreStrMeseRicevute(double totale);

private:
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
};
#endif
