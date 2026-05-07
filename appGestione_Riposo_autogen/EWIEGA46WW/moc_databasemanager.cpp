/****************************************************************************
** Meta object code from reading C++ file 'databasemanager.h'
**
** Created by: The Qt Meta Object Compiler version 69 (Qt 6.11.0)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#include "../../databasemanager.h"
#include <QtNetwork/QSslError>
#include <QtCore/qmetatype.h>

#include <QtCore/qtmochelpers.h>

#include <memory>


#include <QtCore/qxptype_traits.h>
#if !defined(Q_MOC_OUTPUT_REVISION)
#error "The header file 'databasemanager.h' doesn't include <QObject>."
#elif Q_MOC_OUTPUT_REVISION != 69
#error "This file was generated using the moc from 6.11.0. It"
#error "cannot be used with the include files from this version of Qt."
#error "(The moc has changed too much.)"
#endif

#ifndef Q_CONSTINIT
#define Q_CONSTINIT
#endif

QT_WARNING_PUSH
QT_WARNING_DISABLE_DEPRECATED
QT_WARNING_DISABLE_GCC("-Wuseless-cast")
namespace {
struct qt_meta_tag_ZN15DatabaseManagerE_t {};
} // unnamed namespace

template <> constexpr inline auto DatabaseManager::qt_create_metaobjectdata<qt_meta_tag_ZN15DatabaseManagerE_t>()
{
    namespace QMC = QtMocConstants;
    QtMocHelpers::StringRefStorage qt_stringData {
        "DatabaseManager",
        "loginSuccess",
        "",
        "nomeCompleto",
        "idSeriale",
        "loginError",
        "messaggio",
        "riposiRicevuti",
        "QVariantList",
        "lista",
        "operazioneCompletata",
        "confermaCancellazioneRichiesta",
        "QVariantMap",
        "dati",
        "specchioRicevuto",
        "giorniMese",
        "bloccoCambiato",
        "logRicevuti",
        "richiesteBloccoRicevute",
        "notificheConteggiate",
        "count",
        "erroreOperazione",
        "notificheRicevute",
        "login",
        "cip",
        "controllaStatoBlocco",
        "aggiornaBloccoSistema",
        "inizio",
        "fine",
        "attivo",
        "caricaRiposiDisponibili",
        "caricaReport",
        "tipoReport",
        "aggiungiRiposo",
        "dataGGMMAAAA",
        "sceltaTipo",
        "fruisciRiposo",
        "dataMaturazioneISO",
        "dataFruizioneGGMMAAAA",
        "statoScelto",
        "modificaRiposo",
        "dataMaturazioneITA",
        "tipoIdx",
        "statoIdx",
        "controllaEsistenzaEChiediConferma",
        "cancellaRiposoEffettivo",
        "caricaSpecchioAdmin",
        "dataInizioGGMMAAAA",
        "dataFineGGMMAAAA",
        "salvaLicenzaPersonale",
        "idUtenteLoggato",
        "dataISO",
        "codiceLicenza",
        "cancellaLicenza",
        "caricaRichiesteInBlocco",
        "processaValidazioni",
        "idRiposiRaw",
        "valida",
        "nomeAdmin",
        "idDestinatario",
        "inserisciNotifica",
        "idRiposoRif",
        "contaNotificheNonLette",
        "idUtente",
        "caricaDettagliNotifiche",
        "segnaNotificheComeLette",
        "caricaLogAttivita",
        "isOperazioneBloccata",
        "idUtenteRichiedente",
        "dataOperazioneISO",
        "generaPDF",
        "utenti",
        "giorni",
        "inizioBlocco",
        "fineBlocco",
        "bloccoAttivo"
    };

    QtMocHelpers::UintData qt_methods {
        // Signal 'loginSuccess'
        QtMocHelpers::SignalData<void(QString, QString)>(1, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 3 }, { QMetaType::QString, 4 },
        }}),
        // Signal 'loginError'
        QtMocHelpers::SignalData<void(QString)>(5, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 6 },
        }}),
        // Signal 'riposiRicevuti'
        QtMocHelpers::SignalData<void(QVariantList)>(7, 2, QMC::AccessPublic, QMetaType::Void, {{
            { 0x80000000 | 8, 9 },
        }}),
        // Signal 'operazioneCompletata'
        QtMocHelpers::SignalData<void(QString)>(10, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 6 },
        }}),
        // Signal 'confermaCancellazioneRichiesta'
        QtMocHelpers::SignalData<void(QVariantMap)>(11, 2, QMC::AccessPublic, QMetaType::Void, {{
            { 0x80000000 | 12, 13 },
        }}),
        // Signal 'specchioRicevuto'
        QtMocHelpers::SignalData<void(QVariantList, int)>(14, 2, QMC::AccessPublic, QMetaType::Void, {{
            { 0x80000000 | 8, 9 }, { QMetaType::Int, 15 },
        }}),
        // Signal 'bloccoCambiato'
        QtMocHelpers::SignalData<void()>(16, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'logRicevuti'
        QtMocHelpers::SignalData<void(QVariantList)>(17, 2, QMC::AccessPublic, QMetaType::Void, {{
            { 0x80000000 | 8, 9 },
        }}),
        // Signal 'richiesteBloccoRicevute'
        QtMocHelpers::SignalData<void(QVariantList)>(18, 2, QMC::AccessPublic, QMetaType::Void, {{
            { 0x80000000 | 8, 9 },
        }}),
        // Signal 'notificheConteggiate'
        QtMocHelpers::SignalData<void(int)>(19, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 20 },
        }}),
        // Signal 'erroreOperazione'
        QtMocHelpers::SignalData<void(QString)>(21, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 6 },
        }}),
        // Signal 'notificheRicevute'
        QtMocHelpers::SignalData<void(QVariantList)>(22, 2, QMC::AccessPublic, QMetaType::Void, {{
            { 0x80000000 | 8, 9 },
        }}),
        // Method 'login'
        QtMocHelpers::MethodData<void(QString)>(23, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 24 },
        }}),
        // Method 'controllaStatoBlocco'
        QtMocHelpers::MethodData<void()>(25, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'aggiornaBloccoSistema'
        QtMocHelpers::MethodData<void(QString, QString, bool)>(26, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 27 }, { QMetaType::QString, 28 }, { QMetaType::Bool, 29 },
        }}),
        // Method 'caricaRiposiDisponibili'
        QtMocHelpers::MethodData<void(QString)>(30, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 4 },
        }}),
        // Method 'caricaReport'
        QtMocHelpers::MethodData<void(QString, int)>(31, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 4 }, { QMetaType::Int, 32 },
        }}),
        // Method 'aggiungiRiposo'
        QtMocHelpers::MethodData<void(QString, QString, int)>(33, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 4 }, { QMetaType::QString, 34 }, { QMetaType::Int, 35 },
        }}),
        // Method 'fruisciRiposo'
        QtMocHelpers::MethodData<void(QString, QString, QString, int)>(36, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 4 }, { QMetaType::QString, 37 }, { QMetaType::QString, 38 }, { QMetaType::Int, 39 },
        }}),
        // Method 'modificaRiposo'
        QtMocHelpers::MethodData<void(QString, QString, int, int)>(40, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 4 }, { QMetaType::QString, 41 }, { QMetaType::Int, 42 }, { QMetaType::Int, 43 },
        }}),
        // Method 'controllaEsistenzaEChiediConferma'
        QtMocHelpers::MethodData<void(QString, QString)>(44, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 4 }, { QMetaType::QString, 34 },
        }}),
        // Method 'cancellaRiposoEffettivo'
        QtMocHelpers::MethodData<void(QString, QString)>(45, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 4 }, { QMetaType::QString, 34 },
        }}),
        // Method 'caricaSpecchioAdmin'
        QtMocHelpers::MethodData<void(QString, QString)>(46, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 47 }, { QMetaType::QString, 48 },
        }}),
        // Method 'salvaLicenzaPersonale'
        QtMocHelpers::MethodData<void(QString, QString, QString)>(49, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 50 }, { QMetaType::QString, 51 }, { QMetaType::QString, 52 },
        }}),
        // Method 'cancellaLicenza'
        QtMocHelpers::MethodData<void(QString, QString, QString)>(53, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 4 }, { QMetaType::QString, 51 }, { QMetaType::QString, 52 },
        }}),
        // Method 'caricaRichiesteInBlocco'
        QtMocHelpers::MethodData<void()>(54, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'processaValidazioni'
        QtMocHelpers::MethodData<void(QVariantList, bool, QString, int)>(55, 2, QMC::AccessPublic, QMetaType::Void, {{
            { 0x80000000 | 8, 56 }, { QMetaType::Bool, 57 }, { QMetaType::QString, 58 }, { QMetaType::Int, 59 },
        }}),
        // Method 'inserisciNotifica'
        QtMocHelpers::MethodData<void(int, QString, int, QString)>(60, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 59 }, { QMetaType::QString, 6 }, { QMetaType::Int, 61 }, { QMetaType::QString, 58 },
        }}),
        // Method 'inserisciNotifica'
        QtMocHelpers::MethodData<void(int, QString, int)>(60, 2, QMC::AccessPublic | QMC::MethodCloned, QMetaType::Void, {{
            { QMetaType::Int, 59 }, { QMetaType::QString, 6 }, { QMetaType::Int, 61 },
        }}),
        // Method 'inserisciNotifica'
        QtMocHelpers::MethodData<void(int, QString)>(60, 2, QMC::AccessPublic | QMC::MethodCloned, QMetaType::Void, {{
            { QMetaType::Int, 59 }, { QMetaType::QString, 6 },
        }}),
        // Method 'contaNotificheNonLette'
        QtMocHelpers::MethodData<void(int)>(62, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 63 },
        }}),
        // Method 'caricaDettagliNotifiche'
        QtMocHelpers::MethodData<void(int)>(64, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 63 },
        }}),
        // Method 'segnaNotificheComeLette'
        QtMocHelpers::MethodData<void(int)>(65, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 63 },
        }}),
        // Method 'caricaLogAttivita'
        QtMocHelpers::MethodData<void()>(66, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'isOperazioneBloccata'
        QtMocHelpers::MethodData<bool(QString, QString)>(67, 2, QMC::AccessPublic, QMetaType::Bool, {{
            { QMetaType::QString, 68 }, { QMetaType::QString, 69 },
        }}),
        // Method 'isOperazioneBloccata'
        QtMocHelpers::MethodData<bool(QString)>(67, 2, QMC::AccessPublic | QMC::MethodCloned, QMetaType::Bool, {{
            { QMetaType::QString, 68 },
        }}),
        // Method 'generaPDF'
        QtMocHelpers::MethodData<void(QVariantList, QVariantList, int, QString, QString)>(70, 2, QMC::AccessPublic, QMetaType::Void, {{
            { 0x80000000 | 8, 71 }, { 0x80000000 | 8, 13 }, { QMetaType::Int, 72 }, { QMetaType::QString, 27 },
            { QMetaType::QString, 28 },
        }}),
    };
    QtMocHelpers::UintData qt_properties {
        // property 'inizioBlocco'
        QtMocHelpers::PropertyData<QString>(73, QMetaType::QString, QMC::DefaultPropertyFlags, 6),
        // property 'fineBlocco'
        QtMocHelpers::PropertyData<QString>(74, QMetaType::QString, QMC::DefaultPropertyFlags, 6),
        // property 'bloccoAttivo'
        QtMocHelpers::PropertyData<bool>(75, QMetaType::Bool, QMC::DefaultPropertyFlags, 6),
    };
    QtMocHelpers::UintData qt_enums {
    };
    return QtMocHelpers::metaObjectData<DatabaseManager, qt_meta_tag_ZN15DatabaseManagerE_t>(QMC::MetaObjectFlag{}, qt_stringData,
            qt_methods, qt_properties, qt_enums);
}
Q_CONSTINIT const QMetaObject DatabaseManager::staticMetaObject = { {
    QMetaObject::SuperData::link<QObject::staticMetaObject>(),
    qt_staticMetaObjectStaticContent<qt_meta_tag_ZN15DatabaseManagerE_t>.stringdata,
    qt_staticMetaObjectStaticContent<qt_meta_tag_ZN15DatabaseManagerE_t>.data,
    qt_static_metacall,
    nullptr,
    qt_staticMetaObjectRelocatingContent<qt_meta_tag_ZN15DatabaseManagerE_t>.metaTypes,
    nullptr
} };

void DatabaseManager::qt_static_metacall(QObject *_o, QMetaObject::Call _c, int _id, void **_a)
{
    auto *_t = static_cast<DatabaseManager *>(_o);
    if (_c == QMetaObject::InvokeMetaMethod) {
        switch (_id) {
        case 0: _t->loginSuccess((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[2]))); break;
        case 1: _t->loginError((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1]))); break;
        case 2: _t->riposiRicevuti((*reinterpret_cast<std::add_pointer_t<QVariantList>>(_a[1]))); break;
        case 3: _t->operazioneCompletata((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1]))); break;
        case 4: _t->confermaCancellazioneRichiesta((*reinterpret_cast<std::add_pointer_t<QVariantMap>>(_a[1]))); break;
        case 5: _t->specchioRicevuto((*reinterpret_cast<std::add_pointer_t<QVariantList>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[2]))); break;
        case 6: _t->bloccoCambiato(); break;
        case 7: _t->logRicevuti((*reinterpret_cast<std::add_pointer_t<QVariantList>>(_a[1]))); break;
        case 8: _t->richiesteBloccoRicevute((*reinterpret_cast<std::add_pointer_t<QVariantList>>(_a[1]))); break;
        case 9: _t->notificheConteggiate((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        case 10: _t->erroreOperazione((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1]))); break;
        case 11: _t->notificheRicevute((*reinterpret_cast<std::add_pointer_t<QVariantList>>(_a[1]))); break;
        case 12: _t->login((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1]))); break;
        case 13: _t->controllaStatoBlocco(); break;
        case 14: _t->aggiornaBloccoSistema((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[2])),(*reinterpret_cast<std::add_pointer_t<bool>>(_a[3]))); break;
        case 15: _t->caricaRiposiDisponibili((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1]))); break;
        case 16: _t->caricaReport((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[2]))); break;
        case 17: _t->aggiungiRiposo((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[2])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[3]))); break;
        case 18: _t->fruisciRiposo((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[2])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[3])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[4]))); break;
        case 19: _t->modificaRiposo((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[2])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[3])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[4]))); break;
        case 20: _t->controllaEsistenzaEChiediConferma((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[2]))); break;
        case 21: _t->cancellaRiposoEffettivo((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[2]))); break;
        case 22: _t->caricaSpecchioAdmin((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[2]))); break;
        case 23: _t->salvaLicenzaPersonale((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[2])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[3]))); break;
        case 24: _t->cancellaLicenza((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[2])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[3]))); break;
        case 25: _t->caricaRichiesteInBlocco(); break;
        case 26: _t->processaValidazioni((*reinterpret_cast<std::add_pointer_t<QVariantList>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<bool>>(_a[2])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[3])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[4]))); break;
        case 27: _t->inserisciNotifica((*reinterpret_cast<std::add_pointer_t<int>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[2])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[3])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[4]))); break;
        case 28: _t->inserisciNotifica((*reinterpret_cast<std::add_pointer_t<int>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[2])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[3]))); break;
        case 29: _t->inserisciNotifica((*reinterpret_cast<std::add_pointer_t<int>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[2]))); break;
        case 30: _t->contaNotificheNonLette((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        case 31: _t->caricaDettagliNotifiche((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        case 32: _t->segnaNotificheComeLette((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        case 33: _t->caricaLogAttivita(); break;
        case 34: { bool _r = _t->isOperazioneBloccata((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[2])));
            if (_a[0]) *reinterpret_cast<bool*>(_a[0]) = std::move(_r); }  break;
        case 35: { bool _r = _t->isOperazioneBloccata((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])));
            if (_a[0]) *reinterpret_cast<bool*>(_a[0]) = std::move(_r); }  break;
        case 36: _t->generaPDF((*reinterpret_cast<std::add_pointer_t<QVariantList>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QVariantList>>(_a[2])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[3])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[4])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[5]))); break;
        default: ;
        }
    }
    if (_c == QMetaObject::IndexOfMethod) {
        if (QtMocHelpers::indexOfMethod<void (DatabaseManager::*)(QString , QString )>(_a, &DatabaseManager::loginSuccess, 0))
            return;
        if (QtMocHelpers::indexOfMethod<void (DatabaseManager::*)(QString )>(_a, &DatabaseManager::loginError, 1))
            return;
        if (QtMocHelpers::indexOfMethod<void (DatabaseManager::*)(QVariantList )>(_a, &DatabaseManager::riposiRicevuti, 2))
            return;
        if (QtMocHelpers::indexOfMethod<void (DatabaseManager::*)(QString )>(_a, &DatabaseManager::operazioneCompletata, 3))
            return;
        if (QtMocHelpers::indexOfMethod<void (DatabaseManager::*)(QVariantMap )>(_a, &DatabaseManager::confermaCancellazioneRichiesta, 4))
            return;
        if (QtMocHelpers::indexOfMethod<void (DatabaseManager::*)(QVariantList , int )>(_a, &DatabaseManager::specchioRicevuto, 5))
            return;
        if (QtMocHelpers::indexOfMethod<void (DatabaseManager::*)()>(_a, &DatabaseManager::bloccoCambiato, 6))
            return;
        if (QtMocHelpers::indexOfMethod<void (DatabaseManager::*)(QVariantList )>(_a, &DatabaseManager::logRicevuti, 7))
            return;
        if (QtMocHelpers::indexOfMethod<void (DatabaseManager::*)(QVariantList )>(_a, &DatabaseManager::richiesteBloccoRicevute, 8))
            return;
        if (QtMocHelpers::indexOfMethod<void (DatabaseManager::*)(int )>(_a, &DatabaseManager::notificheConteggiate, 9))
            return;
        if (QtMocHelpers::indexOfMethod<void (DatabaseManager::*)(QString )>(_a, &DatabaseManager::erroreOperazione, 10))
            return;
        if (QtMocHelpers::indexOfMethod<void (DatabaseManager::*)(QVariantList )>(_a, &DatabaseManager::notificheRicevute, 11))
            return;
    }
    if (_c == QMetaObject::ReadProperty) {
        void *_v = _a[0];
        switch (_id) {
        case 0: *reinterpret_cast<QString*>(_v) = _t->inizioBlocco(); break;
        case 1: *reinterpret_cast<QString*>(_v) = _t->fineBlocco(); break;
        case 2: *reinterpret_cast<bool*>(_v) = _t->bloccoAttivo(); break;
        default: break;
        }
    }
}

const QMetaObject *DatabaseManager::metaObject() const
{
    return QObject::d_ptr->metaObject ? QObject::d_ptr->dynamicMetaObject() : &staticMetaObject;
}

void *DatabaseManager::qt_metacast(const char *_clname)
{
    if (!_clname) return nullptr;
    if (!strcmp(_clname, qt_staticMetaObjectStaticContent<qt_meta_tag_ZN15DatabaseManagerE_t>.strings))
        return static_cast<void*>(this);
    return QObject::qt_metacast(_clname);
}

int DatabaseManager::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
{
    _id = QObject::qt_metacall(_c, _id, _a);
    if (_id < 0)
        return _id;
    if (_c == QMetaObject::InvokeMetaMethod) {
        if (_id < 37)
            qt_static_metacall(this, _c, _id, _a);
        _id -= 37;
    }
    if (_c == QMetaObject::RegisterMethodArgumentMetaType) {
        if (_id < 37)
            *reinterpret_cast<QMetaType *>(_a[0]) = QMetaType();
        _id -= 37;
    }
    if (_c == QMetaObject::ReadProperty || _c == QMetaObject::WriteProperty
            || _c == QMetaObject::ResetProperty || _c == QMetaObject::BindableProperty
            || _c == QMetaObject::RegisterPropertyMetaType) {
        qt_static_metacall(this, _c, _id, _a);
        _id -= 3;
    }
    return _id;
}

// SIGNAL 0
void DatabaseManager::loginSuccess(QString _t1, QString _t2)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 0, nullptr, _t1, _t2);
}

// SIGNAL 1
void DatabaseManager::loginError(QString _t1)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 1, nullptr, _t1);
}

// SIGNAL 2
void DatabaseManager::riposiRicevuti(QVariantList _t1)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 2, nullptr, _t1);
}

// SIGNAL 3
void DatabaseManager::operazioneCompletata(QString _t1)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 3, nullptr, _t1);
}

// SIGNAL 4
void DatabaseManager::confermaCancellazioneRichiesta(QVariantMap _t1)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 4, nullptr, _t1);
}

// SIGNAL 5
void DatabaseManager::specchioRicevuto(QVariantList _t1, int _t2)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 5, nullptr, _t1, _t2);
}

// SIGNAL 6
void DatabaseManager::bloccoCambiato()
{
    QMetaObject::activate(this, &staticMetaObject, 6, nullptr);
}

// SIGNAL 7
void DatabaseManager::logRicevuti(QVariantList _t1)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 7, nullptr, _t1);
}

// SIGNAL 8
void DatabaseManager::richiesteBloccoRicevute(QVariantList _t1)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 8, nullptr, _t1);
}

// SIGNAL 9
void DatabaseManager::notificheConteggiate(int _t1)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 9, nullptr, _t1);
}

// SIGNAL 10
void DatabaseManager::erroreOperazione(QString _t1)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 10, nullptr, _t1);
}

// SIGNAL 11
void DatabaseManager::notificheRicevute(QVariantList _t1)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 11, nullptr, _t1);
}
QT_WARNING_POP
