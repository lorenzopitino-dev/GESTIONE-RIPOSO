/****************************************************************************
** Meta object code from reading C++ file 'databasemanager.h'
**
** Created by: The Qt Meta Object Compiler version 69 (Qt 6.11.0)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#include "../../../../databasemanager.h"
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
        "login",
        "cip",
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
        "cancellaLicenza"
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
        // Method 'login'
        QtMocHelpers::MethodData<void(QString)>(16, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 17 },
        }}),
        // Method 'caricaRiposiDisponibili'
        QtMocHelpers::MethodData<void(QString)>(18, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 4 },
        }}),
        // Method 'caricaReport'
        QtMocHelpers::MethodData<void(QString, int)>(19, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 4 }, { QMetaType::Int, 20 },
        }}),
        // Method 'aggiungiRiposo'
        QtMocHelpers::MethodData<void(QString, QString, int)>(21, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 4 }, { QMetaType::QString, 22 }, { QMetaType::Int, 23 },
        }}),
        // Method 'fruisciRiposo'
        QtMocHelpers::MethodData<void(QString, QString, QString, int)>(24, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 4 }, { QMetaType::QString, 25 }, { QMetaType::QString, 26 }, { QMetaType::Int, 27 },
        }}),
        // Method 'modificaRiposo'
        QtMocHelpers::MethodData<void(QString, QString, int, int)>(28, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 4 }, { QMetaType::QString, 29 }, { QMetaType::Int, 30 }, { QMetaType::Int, 31 },
        }}),
        // Method 'controllaEsistenzaEChiediConferma'
        QtMocHelpers::MethodData<void(QString, QString)>(32, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 4 }, { QMetaType::QString, 22 },
        }}),
        // Method 'cancellaRiposoEffettivo'
        QtMocHelpers::MethodData<void(QString, QString)>(33, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 4 }, { QMetaType::QString, 22 },
        }}),
        // Method 'caricaSpecchioAdmin'
        QtMocHelpers::MethodData<void(QString, QString)>(34, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 35 }, { QMetaType::QString, 36 },
        }}),
        // Method 'salvaLicenzaPersonale'
        QtMocHelpers::MethodData<void(QString, QString, QString)>(37, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 38 }, { QMetaType::QString, 39 }, { QMetaType::QString, 40 },
        }}),
        // Method 'cancellaLicenza'
        QtMocHelpers::MethodData<void(QString, QString, QString)>(41, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 4 }, { QMetaType::QString, 39 }, { QMetaType::QString, 40 },
        }}),
    };
    QtMocHelpers::UintData qt_properties {
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
        case 6: _t->login((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1]))); break;
        case 7: _t->caricaRiposiDisponibili((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1]))); break;
        case 8: _t->caricaReport((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[2]))); break;
        case 9: _t->aggiungiRiposo((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[2])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[3]))); break;
        case 10: _t->fruisciRiposo((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[2])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[3])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[4]))); break;
        case 11: _t->modificaRiposo((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[2])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[3])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[4]))); break;
        case 12: _t->controllaEsistenzaEChiediConferma((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[2]))); break;
        case 13: _t->cancellaRiposoEffettivo((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[2]))); break;
        case 14: _t->caricaSpecchioAdmin((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[2]))); break;
        case 15: _t->salvaLicenzaPersonale((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[2])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[3]))); break;
        case 16: _t->cancellaLicenza((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[2])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[3]))); break;
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
        if (_id < 17)
            qt_static_metacall(this, _c, _id, _a);
        _id -= 17;
    }
    if (_c == QMetaObject::RegisterMethodArgumentMetaType) {
        if (_id < 17)
            *reinterpret_cast<QMetaType *>(_a[0]) = QMetaType();
        _id -= 17;
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
QT_WARNING_POP
