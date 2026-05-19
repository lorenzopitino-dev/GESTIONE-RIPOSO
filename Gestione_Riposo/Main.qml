import QtQuick
import QtQuick.Controls
import QtQuick.Layouts



ApplicationWindow {
    id: window
    width: 360
    height: 640
    visibility: Window.Maximized
    visible: true
    title: "Gestore Riposi"
    color: "#f6f8fb"
    palette.window: "#f6f8fb"
    palette.windowText: "#202124"
    palette.base: "#ffffff"
    palette.alternateBase: "#eef2f7"
    palette.text: "#202124"
    palette.button: "#f2f4f8"
    palette.buttonText: "#202124"
    palette.highlight: "#1565C0"
    palette.highlightedText: "#ffffff"
    palette.placeholderText: "#6b7280"
    property bool haNotificheGlobal: false
    property int notificheCount: 0

    component DateMaskField: TextField {
        id: _dmf
        placeholderText: "GG-MM-YYYY"
        maximumLength: 10
        inputMethodHints: Qt.ImhDigitsOnly
        property string dateText: text
        property bool _applying: false

        onTextChanged: {
            if (_dmf._applying) return
            _dmf._applying = true
            let raw = text.replace(/[^0-9]/g, "")
            let masked = ""
            for (let i = 0; i < raw.length && i < 8; i++) {
                if (i === 2 || i === 4) masked += "-"
                masked += raw[i]
            }
            if (text !== masked) {
                let pos = cursorPosition
                text = masked
                let newPos = pos
                if (pos === 3 || pos === 6) newPos = pos + 1
                cursorPosition = Math.min(newPos, masked.length)
            }
            _dmf._applying = false
        }
    }

    component MenuActionButton: Button {
        id: _menuButton
        Layout.fillWidth: true
        implicitHeight: 42
        hoverEnabled: true
        font.pixelSize: 14
        font.bold: true

        contentItem: Text {
            text: _menuButton.text.trim()
            font: _menuButton.font
            color: _menuButton.enabled ? "#1f2937" : "#8b98aa"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }

        background: Rectangle {
            radius: 6
            color: _menuButton.down ? "#dbeafe"
                 : _menuButton.hovered ? "#eef6ff"
                 : "#ffffff"
            border.color: _menuButton.activeFocus ? "#1565C0"
                         : _menuButton.hovered ? "#4d91cf"
                         : "#7f9fbd"
            border.width: _menuButton.activeFocus || _menuButton.hovered ? 2 : 1
        }
    }

    component MenuDangerButton: Button {
        id: _dangerButton
        Layout.fillWidth: true
        implicitHeight: 42
        hoverEnabled: true
        font.pixelSize: 14
        font.bold: true

        contentItem: Text {
            text: _dangerButton.text.trim()
            font: _dangerButton.font
            color: "white"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }

        background: Rectangle {
            radius: 6
            color: _dangerButton.down ? "#b91c1c"
                 : _dangerButton.hovered ? "#dc2626"
                 : "#ef4444"
            border.color: _dangerButton.hovered || _dangerButton.activeFocus ? "#7f1d1d" : "#b91c1c"
            border.width: 2
        }
    }
    
    Popup {
        id: globalErrorPopup
        anchors.centerIn: parent
        width: parent.width * 0.8
        modal: true
        closePolicy: Popup.NoAutoClose
        background: Rectangle { color: "white"; radius: 10; border.color: "red" }
        ColumnLayout {
            anchors.fill: parent; anchors.margins: 15
            Label { text: "ERRORE"; color: "red"; font.bold: true; Layout.alignment: Qt.AlignHCenter }
            Label { id: globalErrorLabel; wrapMode: Text.WordWrap; Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter }
            Button { text: "OK"; Layout.alignment: Qt.AlignHCenter; onClicked: globalErrorPopup.close() }
        }
    }

    Connections {
        target: Backend
        function onLoginError(messaggio) {
            globalErrorLabel.text = messaggio
            globalErrorPopup.open()
        }
        function onErroreOperazione(messaggio) {
            globalErrorLabel.text = messaggio
            globalErrorPopup.open()
        }
        function onLoginSuccess(nomeCompleto, idSeriale) {
            console.log("Login ricevuto nel QML per:", nomeCompleto);
            stack.push(menuPage, {"utente": nomeCompleto, "idDatabase": idSeriale})
        }
        function onNotificheConteggiate(count) {
            window.haNotificheGlobal = (count > 0)
            window.notificheCount = count
            if (stack.currentItem && stack.currentItem.objectName === "menuPrincipale") {
                stack.currentItem.mostraNotifica = window.haNotificheGlobal
            }
        }
    }

    StackView {
        id: stack
        anchors.fill: parent
        initialItem: loginPage
    }


    // --- PAGINA 1: LOGIN ---
    Component {
        id: loginPage
        Page {
            id: paginaLogin
            property bool loginInCorso: false

            Timer {
                id: loginTimeout
                interval: 12000
                repeat: false
                onTriggered: {
                    if (!paginaLogin.loginInCorso) return
                    paginaLogin.loginInCorso = false
                    globalErrorLabel.text = "Accesso non completato: connessione lenta o risposta non ricevuta. Riprova."
                    globalErrorPopup.open()
                }
            }

            Connections {
                target: Backend
                function onLoginError(messaggio) {
                    paginaLogin.loginInCorso = false
                    loginTimeout.stop()
                }
                function onLoginSuccess(nomeCompleto, idSeriale) {
                    paginaLogin.loginInCorso = false
                    loginTimeout.stop()
                }
            }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 20

                Label { text: "ACCESSO"; font.bold: true; Layout.alignment: Qt.AlignHCenter }

                TextField {
                    id: cipInput
                    placeholderText: "Inserisci CIP"
                    Layout.fillWidth: true
                    inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhPreferUppercase
                    onTextChanged: {
                        var maiuscolo = text.toUpperCase()
                        if (text !== maiuscolo) text = maiuscolo
                    }
                }

                Button {
                    text: paginaLogin.loginInCorso ? "ACCESSO..." : "ACCEDI"
                    enabled: !paginaLogin.loginInCorso && cipInput.text.trim() !== ""
                    Layout.fillWidth: true
                    implicitHeight: 46
                    font.pixelSize: 15
                    font.bold: true
                    onClicked: {
                        paginaLogin.loginInCorso = true
                        loginTimeout.restart()
                        Backend.login(cipInput.text.trim().toUpperCase())
                    }
                    contentItem: Text {
                        text: parent.text
                        font: parent.font
                        color: "white"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        radius: 8
                        color: parent.enabled
                            ? (parent.down ? "#0d47a1" : parent.hovered ? "#1976D2" : "#1565C0")
                            : "#90a4c8"
                        border.color: parent.enabled ? "#0a3d91" : "#7a8fb0"
                        border.width: 2
                    }
                }

                Text { id: statusLabel; color: "red" }
            }
        }
    }

    // --- PAGINA 2: MENU PRINCIPALE ---
    Component {
        id: menuPage
        Page {
            id: paginaMenu
            objectName: "menuPrincipale"
            property string utente: ""
            property string idDatabase: ""
            property bool mostraNotifica: window.haNotificheGlobal
            property int conteggioNotifiche: window.notificheCount
            property var listaNotifiche: null
            property double oreStrMese: 0.0
            property var listaRiposiRaw: []
            property var badgeCorrente: ({ nome: "", livello: 0, colore: "#888888", emoji: "" })
            property var tuttiBadge: ([])
            property var mappaColleghi: ({})  // { "yyyy-MM-dd": numColleghi }
            property bool colleghiCaricati: false
            property int _attesaColleghi: 0
            property var listaDettaglioStr: []
            property bool refreshBadgeInCorso: false
            property string firmaBadgeSalvati: ""
            readonly property var adminIDs: ["1", "2", "3", "19"]

            function avviaRefreshBadge() {
                if (idDatabase === "" || refreshBadgeInCorso) return

                refreshBadgeInCorso = true
                refreshBadgeTimeout.restart()

                let oggi = new Date()
                Backend.caricaBadgeRiposi(idDatabase)
                Backend.caricaDettaglioStraordinariMese(idDatabase, oggi.getFullYear(), oggi.getMonth() + 1)
            }

            function completaRefreshBadge() {
                refreshBadgeInCorso = false
                refreshBadgeTimeout.stop()
            }

            function aggiornaBadgeDaRisultato(risultato) {
                paginaMenu.badgeCorrente = risultato && risultato.best ? risultato.best : { nome: "", livello: 0, colore: "#888888" }
                paginaMenu.tuttiBadge = risultato && risultato.tutti ? risultato.tutti : []
            }

            function toDate(s) {
                if (!s || s === "") return new Date(0)
                var p = s.split("-")
                return new Date(parseInt(p[0]), parseInt(p[1]) - 1, parseInt(p[2]))
            }
            function toISO(d) {
                let y = d.getFullYear()
                let m = ("0" + (d.getMonth() + 1)).slice(-2)
                let day = ("0" + d.getDate()).slice(-2)
                return y + "-" + m + "-" + day
            }
            function callGeneraPDFSpecchioSafe(utenti, dati, giorni, inizio, fine, timeoutMs = 7000) {
                return new Promise(function(resolve, reject) {
                    var start = Date.now();
                    function check() {
                        if (window.pdfJsReady && typeof window.generaPDFSpecchio === "function") {
                            callGeneraPDFSpecchioSafe(utenti, dati, giorni, inizio, fine)
                                .then(function(pdfBlob) {
                                    var url = URL.createObjectURL(pdfBlob);
                                    Qt.openUrlExternally(url);
                                })
                                .catch(function(err) {
                                    console.log("Errore generazione PDF:", err);
                                    globalErrorLabel.text = "Errore generazione PDF: " + (err && err.message ? err.message : err);
                                    globalErrorPopup.open();
                                });
                            return;
                        }
                        if ((Date.now() - start) >= timeoutMs) {
                            reject(new Error("generaPDFSpecchio non disponibile dopo timeout"));
                            return;
                        }
                        setTimeout(check, 50);
                    }
                    check();
                });
            }

            function isMeseCorrente(d) {
                let oggi = new Date()
                let meseCorrente = oggi.getMonth() + 1
                let annoCorrente = oggi.getFullYear()

                return d.getFullYear() === annoCorrente &&
                    (d.getMonth() + 1) === meseCorrente
            }
            function tuttiSabatiRiposo(lista) {
                var dateSet = {}
                lista.forEach(r => {
                    if (r.data_fruizione && r.data_fruizione !== "" && !isLicenzaParziale(r))
                        dateSet[r.data_fruizione] = true
                })
                var oggi = new Date()
                var d = new Date(oggi.getFullYear(), oggi.getMonth(), 1)
                var sabatiRiposo = 0
                while (d.getMonth() === oggi.getMonth() && d <= oggi) {
                    if (d.getDay() === 6 && dateSet[toISO(d)]) sabatiRiposo++
                    d.setDate(d.getDate() + 1)
                }
                return sabatiRiposo >= 4
            }

            function tutteDomeniche(lista) {
                var dateSet = {}
                lista.forEach(r => {
                    if (r.data_fruizione && r.data_fruizione !== "" && !isLicenzaParziale(r))
                        dateSet[r.data_fruizione] = true
                })
                var oggi = new Date()
                var d = new Date(oggi.getFullYear(), oggi.getMonth(), 1)
                var domenicheRiposo = 0
                while (d.getMonth() === oggi.getMonth() && d <= oggi) {
                    if (d.getDay() === 0 && dateSet[toISO(d)]) domenicheRiposo++
                    d.setDate(d.getDate() + 1)
                }
                return domenicheRiposo >= 4
            }

            function calcolaBadge(riposi, mappaColleghi, oreStr, dettaglioStr) {
                if (!riposi || riposi.length === 0)
                    return { best: { nome: "", livello: 0, colore: "#888888" }, tutti: [] }
                function isLicenzaParziale(r) {
                    if (!r.a) return false
                    let note = r.a.toUpperCase()
                    return (note.includes("MAT") || note.includes("CIT") ||
                            note.includes("POM") || note.includes("SER"))
                }

                function tipoLicenzaParziale(r) {
                    if (!r || !r.a) return ""
                    let note = r.a.toUpperCase()
                    if (note.includes("MAT")) return "MAT"
                    if (note.includes("POM")) return "POM"
                    if (note.includes("SER")) return "SER"
                    if (note.includes("CIT")) return "CIT"
                    return ""
                }

                function lunediSettimanaISO(dataISO) {
                    var d = toDate(dataISO)
                    var giorno = d.getDay()
                    var diff = giorno === 0 ? -6 : 1 - giorno
                    d.setDate(d.getDate() + diff)
                    return toISO(d)
                }

                function contaOccorrenzeLicenzeSettimana(lista, tipiValidi) {
                    var perSettimana = {}
                    lista.forEach(r => {
                        if (!r || !r.data_fruizione || r.data_fruizione === "") return
                        if ((r.stato || "").toUpperCase() !== "VALIDATO") return

                        var tipo = tipoLicenzaParziale(r)
                        if (tipiValidi.indexOf(tipo) === -1) return

                        var chiaveSettimana = lunediSettimanaISO(r.data_fruizione)
                        perSettimana[chiaveSettimana] = (perSettimana[chiaveSettimana] || 0) + 1
                    })

                    var occorrenze = 0
                    Object.keys(perSettimana).forEach(k => {
                        occorrenze += Math.floor(perSettimana[k] / 3)
                    })
                    return occorrenze
                }

                function checkMordiFuggi(lista) {
                    var dateSet = {}
                    lista.forEach(r => { if (r.data_fruizione && r.data_fruizione !== "") dateSet[r.data_fruizione] = true })
                    var date = Object.keys(dateSet).sort()
                    for (var i = 0; i < date.length - 1; i++) {
                        var d1 = toDate(date[i])
                        var d2 = new Date(d1); d2.setDate(d1.getDate() + 1)
                        var d3 = new Date(d1); d3.setDate(d1.getDate() + 2)
                        if (!dateSet[toISO(d2)] && dateSet[toISO(d3)]) return true
                    }
                    return false
                }

                function contaWeekendCompleti(lista) {
                    var oggi = new Date()
                    var meseCorrente = oggi.getMonth() + 1
                    var annoCorrente = oggi.getFullYear()
                    var dateSet = {}
                    lista.forEach(r => {
                        if (r.data_fruizione && r.data_fruizione !== "" && !isLicenzaParziale(r))
                            dateSet[r.data_fruizione] = true
                    })
                    var d = new Date(annoCorrente, meseCorrente - 1, 1)
                    var weekendCompleti = 0
                    while (d.getMonth() === meseCorrente - 1 && d <= oggi) {
                        if (d.getDay() === 6) {
                            var sabISO = toISO(d)
                            var domISO = toISO(new Date(d.getFullYear(), d.getMonth(), d.getDate() + 1))
                            if (dateSet[sabISO] === true && dateSet[domISO] === true)
                                weekendCompleti++
                        }
                        d.setDate(d.getDate() + 1)
                    }
                    return weekendCompleti
                }

                function contaWeekendGuerriero(lista) {
                    var oggi = new Date()
                    var meseCorrente = oggi.getMonth() + 1
                    var annoCorrente = oggi.getFullYear()
                    var dateSet = {}
                    lista.forEach(r => {
                        if (r.data_fruizione && r.data_fruizione !== "" && !isLicenzaParziale(r))
                            dateSet[r.data_fruizione] = true
                    })
                    var d = new Date(annoCorrente, meseCorrente - 1, 1)
                    var weekendConsecutivi = 0, maxConsecutivi = 0
                    while (d.getMonth() === meseCorrente - 1 && d <= oggi) {
                        if (d.getDay() === 6) {
                            var sabISO = toISO(d)
                            var domISO = toISO(new Date(d.getFullYear(), d.getMonth(), d.getDate() + 1))
                            if (!dateSet[sabISO] && !dateSet[domISO]) {
                                weekendConsecutivi++
                                if (weekendConsecutivi > maxConsecutivi) maxConsecutivi = weekendConsecutivi
                            } else {
                                weekendConsecutivi = 0
                            }
                        }
                        d.setDate(d.getDate() + 1)
                    }
                    return maxConsecutivi
                }

                function contaWeekendSenzaRiposo(lista) {
                    var oggi = new Date()
                    var meseCorrente = oggi.getMonth() + 1
                    var annoCorrente = oggi.getFullYear()
                    var dateSet = {}
                    lista.forEach(r => {
                        if (r.data_fruizione && r.data_fruizione !== "" && !isLicenzaParziale(r))
                            dateSet[r.data_fruizione] = true
                    })
                    var d = new Date(annoCorrente, meseCorrente - 1, 1)
                    var weekendSenza = 0
                    while (d.getMonth() === meseCorrente - 1 && d <= oggi) {
                        if (d.getDay() === 6) {
                            var sabISO = toISO(d)
                            var domISO = toISO(new Date(d.getFullYear(), d.getMonth(), d.getDate() + 1))
                            if (!dateSet[sabISO] && !dateSet[domISO])
                                weekendSenza++
                        }
                        d.setDate(d.getDate() + 1)
                    }
                    return weekendSenza
                }

                function checkTetris(lista) {
                    var oggi = new Date()
                    var meseCorrente = oggi.getMonth() + 1
                    var annoCorrente = oggi.getFullYear()
                    var dateSet = {}
                    lista.forEach(r => {
                        if (r.data_fruizione && r.data_fruizione !== "" && !isLicenzaParziale(r))
                            dateSet[r.data_fruizione] = true
                    })
                    var d = new Date(annoCorrente, meseCorrente - 1, 1)
                    var giorni = []
                    while (d.getMonth() === meseCorrente - 1 && d <= oggi) {
                        giorni.push(dateSet[toISO(d)] === true)
                        d.setDate(d.getDate() + 1)
                    }
                    var tetrisConsec = 0, i = 0
                    while (i < giorni.length) {
                        if (giorni[i]) { i++; continue }
                        if (i === 0 || !giorni[i - 1]) {
                            while (i < giorni.length && !giorni[i]) i++
                            tetrisConsec = 0; continue
                        }
                        var start = i
                        while (i < giorni.length && !giorni[i]) i++
                        var lunghezza = i - start
                        var seguitoDaRiposo = (i < giorni.length && giorni[i])
                        if (lunghezza <= 2 && seguitoDaRiposo) { tetrisConsec++; if (tetrisConsec >= 2) return true }
                        else tetrisConsec = 0
                    }
                    return false
                }

                function tuttiSabatiRiposo(lista) {
                    var oggi = new Date()
                    var meseCorrente = oggi.getMonth() + 1
                    var annoCorrente = oggi.getFullYear()
                    var dateSet = {}
                    lista.forEach(r => {
                        if (r.data_fruizione && r.data_fruizione !== "" && !isLicenzaParziale(r))
                            dateSet[r.data_fruizione] = true
                    })
                    var d = new Date(annoCorrente, meseCorrente - 1, 1)
                    var sabatiRiposo = 0
                    while (d.getMonth() === meseCorrente - 1 && d <= oggi) {
                        if (d.getDay() === 6) {
                            if (!dateSet[toISO(d)]) return false
                            sabatiRiposo++
                        }
                        d.setDate(d.getDate() + 1)
                    }
                    return sabatiRiposo >= 4
                }

                function tutteDomeniche(lista) {
                    var oggi = new Date()
                    var meseCorrente = oggi.getMonth() + 1
                    var annoCorrente = oggi.getFullYear()
                    var dateSet = {}
                    lista.forEach(r => {
                        if (r.data_fruizione && r.data_fruizione !== "" && !isLicenzaParziale(r))
                            dateSet[r.data_fruizione] = true
                    })
                    var d = new Date(annoCorrente, meseCorrente - 1, 1)
                    var domenicheRiposo = 0
                    while (d.getMonth() === meseCorrente - 1 && d <= oggi) {
                        if (d.getDay() === 0) {
                            if (!dateSet[toISO(d)]) return false
                            domenicheRiposo++
                        }
                        d.setDate(d.getDate() + 1)
                    }
                    return domenicheRiposo >= 4
                }

                function contaWeekendPieni(lista) {
                    var oggi = new Date()
                    var meseCorrente = oggi.getMonth() + 1
                    var annoCorrente = oggi.getFullYear()
                    var dateSet = {}
                    lista.forEach(r => {
                        if (r.data_fruizione && r.data_fruizione !== "" && !isLicenzaParziale(r))
                            dateSet[r.data_fruizione] = true
                    })
                    var d = new Date(annoCorrente, meseCorrente - 1, 1)
                    var weekendConsecutivi = 0
                    var maxConsecutivi = 0
                    while (d.getMonth() === meseCorrente - 1 && d <= oggi) {
                        if (d.getDay() === 6) {
                            var sabISO = toISO(d)
                            var domISO = toISO(new Date(d.getFullYear(), d.getMonth(), d.getDate() + 1))
                            if (dateSet[sabISO] === true && dateSet[domISO] === true) {
                                weekendConsecutivi++
                                if (weekendConsecutivi > maxConsecutivi) maxConsecutivi = weekendConsecutivi
                            } else {
                                weekendConsecutivi = 0
                            }
                        }
                        d.setDate(d.getDate() + 1)
                    }
                    return maxConsecutivi
                }

                function contaGiorni10Fila(lista) {
                    var dateSet = {}
                    lista.forEach(r => { if (r.data_fruizione && r.data_fruizione !== "") dateSet[r.data_fruizione] = true })
                    var date = Object.keys(dateSet).sort()
                    var maxSeq = 0, seq = 0
                    for (var i = 0; i < date.length; i++) {
                        var prev = new Date(toDate(date[i])); prev.setDate(prev.getDate() - 1)
                        seq = dateSet[toISO(prev)] ? seq + 1 : 1
                        if (seq > maxSeq) maxSeq = seq
                    }
                    return maxSeq
                }

                // ── 2. VARIABILI E FILTRO ─────────────────────────────────────────

                var _oggi = new Date()
                var _mese = _oggi.getMonth() + 1
                var _anno = _oggi.getFullYear()
                var oggiISO = toISO(_oggi)
                var primoMeseISO = toISO(new Date(_anno, _mese - 1, 1))
                var fineMesseISO = toISO(new Date(_anno, _mese, 0))

                // Tutto il mese (per Camaleonte — include date future del mese)
                var tuttiMese = riposi.filter(r =>
                    r && r.data_fruizione && r.data_fruizione !== "" &&
                    r.data_fruizione >= primoMeseISO &&
                    r.data_fruizione <= fineMesseISO
                )

                // Solo fino a oggi, senza licenze parziali (per tutti gli altri badge)
                var tuttiInsieme = tuttiMese.filter(r =>
                    r.data_fruizione <= oggiISO && !isLicenzaParziale(r)
                )
                var tuttiMeseAdOggi = tuttiMese.filter(r =>
                    r.data_fruizione <= oggiISO
                )

                // ── 3. VALUTAZIONE BADGE ──────────────────────────────────────────

                var candidati = []

                // UFFICIO ANAGRAFE / IL VAMPIRO - licenze validate nella stessa settimana lun-dom
                var occorrenzeAnagrafe = contaOccorrenzeLicenzeSettimana(tuttiMeseAdOggi, ["MAT"])
                if (occorrenzeAnagrafe > 0)
                    candidati.push({ nome: "Ufficio anagrafe", livello: 1, colore: "#C0C0C0", occorrenze: occorrenzeAnagrafe })

                var occorrenzeVampiro  = contaOccorrenzeLicenzeSettimana(tuttiMeseAdOggi, ["SER", "POM"])
                if (occorrenzeVampiro > 0)
                    candidati.push({ nome: "Il vampiro", livello: 1, colore: "#C0C0C0", occorrenze: occorrenzeVampiro })

                // CAMALEONTE — giorni in cui erano presenti 7+ colleghi
                var conteggioCAMALEONTE = 0
                var _dateGiaContateC = {}
                for (var k = 0; k < tuttiInsieme.length; k++) {
                    var _r = tuttiInsieme[k]
                    var _dataR = _r.data_fruizione
                    if (!_dataR || _dateGiaContateC[_dataR]) continue   // già contata → skip
                    if ((mappaColleghi[_dataR] || 0) >= 7) {
                        conteggioCAMALEONTE++
                        _dateGiaContateC[_dataR] = true
                    }
                }
                if (conteggioCAMALEONTE > 0)
                    candidati.push({ nome: "Il Camaleonte", livello: 1, colore: "#C0C0C0", occorrenze: conteggioCAMALEONTE })

                // MORDI E FUGGI — quante volte si verifica il pattern R-X-R nel mese
                var conteggioMORDI = 0
                var dateSetMF = {}
                tuttiInsieme.forEach(r => { if (r.data_fruizione && r.data_fruizione !== "") dateSetMF[r.data_fruizione] = true })
                var dateMF = Object.keys(dateSetMF).sort()
                for (var mf = 0; mf < dateMF.length; mf++) {
                    var d1mf = toDate(dateMF[mf])
                    var d2mf = new Date(d1mf); d2mf.setDate(d1mf.getDate() + 1)
                    var d3mf = new Date(d1mf); d3mf.setDate(d1mf.getDate() + 2)
                    if (!dateSetMF[toISO(d2mf)] && dateSetMF[toISO(d3mf)]) conteggioMORDI++
                }
                if (conteggioMORDI > 0)
                    candidati.push({ nome: "Mordi e fuggi", livello: 1, colore: "#C0C0C0", occorrenze: conteggioMORDI })

                // L'ARCHITETTO — quanti weekend consecutivi pieni (max streak)
                var wkPieni = contaWeekendPieni(tuttiInsieme)
                if (wkPieni >= 2)
                    candidati.push({ nome: "L'Architetto", livello: 2, colore: "#FFD700", occorrenze: wkPieni })

                // IL GUERRIERO — quanti weekend consecutivi senza riposo (max streak)
                var wkGuerr = contaWeekendGuerriero(tuttiInsieme)
                if (wkGuerr >= 2)
                    candidati.push({ nome: "Il Guerriero", livello: 2, colore: "#FFD700", occorrenze: 1 })

                // TETRIS — quante volte si incastra il pattern R-≤2gg-R
                var conteggioTETRIS = 0
                var dateSetT = {}
                tuttiInsieme.forEach(r => { if (r.data_fruizione && r.data_fruizione !== "" && !isLicenzaParziale(r)) dateSetT[r.data_fruizione] = true })
                var dT = new Date(_anno, _mese - 1, 1)
                var giorniT = []
                while (dT.getMonth() === _mese - 1 && dT <= new Date()) { giorniT.push(dateSetT[toISO(dT)] === true); dT.setDate(dT.getDate() + 1) }
                var tetrisConsec = 0, iT = 0
                while (iT < giorniT.length) {
                    if (giorniT[iT]) { iT++; continue }
                    if (iT === 0 || !giorniT[iT - 1]) { while (iT < giorniT.length && !giorniT[iT]) iT++; tetrisConsec = 0; continue }
                    var startT = iT
                    while (iT < giorniT.length && !giorniT[iT]) iT++
                    var lunghezzaT = iT - startT
                    var seguitoDaRiposoT = (iT < giorniT.length && giorniT[iT])
                    if (lunghezzaT <= 2 && seguitoDaRiposoT) { tetrisConsec++; if (tetrisConsec >= 2) conteggioTETRIS++ }
                    else tetrisConsec = 0
                }
                if (conteggioTETRIS > 0)
                    candidati.push({ nome: "Tetris", livello: 2, colore: "#FFD700", occorrenze: conteggioTETRIS })

                // FEBBRE DEL SABATO SERA — quanti sabati a riposo nel mese
                var sabatiRiposo = 0
                var dateSetFS = {}
                tuttiInsieme.forEach(r => { if (r.data_fruizione && r.data_fruizione !== "" && !isLicenzaParziale(r)) dateSetFS[r.data_fruizione] = true })
                var dFS = new Date(_anno, _mese - 1, 1)
                var tuttiSabatiOk = true
                while (dFS.getMonth() === _mese - 1 && dFS <= new Date()) {
                    if (dFS.getDay() === 6) { if (dateSetFS[toISO(dFS)]) sabatiRiposo++; else tuttiSabatiOk = false }
                    dFS.setDate(dFS.getDate() + 1)
                }
                if (sabatiRiposo >= 4 && tuttiSabatiOk)
                    candidati.push({ nome: "Febbre del Sabato Sera", livello: 2, colore: "#FFD700", occorrenze: sabatiRiposo })

                // RE DEI PONTI — quanti weekend completi nel mese
                var wkCompleti = contaWeekendCompleti(tuttiInsieme)
                if (wkCompleti >= 3)
                    candidati.push({ nome: "Re dei Ponti", livello: 3, colore: "#b9f2ff", occorrenze: wkCompleti })

                // TURISTA PER SEMPRE — quanti giorni nella sequenza più lunga
                var maxSeqTurista = contaGiorni10Fila(tuttiInsieme)
                if (maxSeqTurista >= 10)
                    candidati.push({ nome: "Turista per sempre", livello: 3, colore: "#b9f2ff", occorrenze: maxSeqTurista })

                // SUPEREROE — quanti weekend senza riposo nel mese
                var wkSenza = contaWeekendSenzaRiposo(tuttiInsieme)
                if (wkSenza >= 3)
                    candidati.push({ nome: "Supereroe", livello: 3, colore: "#b9f2ff", occorrenze: wkSenza })

                // IL PAPA — quante domeniche a riposo nel mese
                var domenicheRiposo = 0
                var dateSetPapa = {}
                tuttiInsieme.forEach(r => { if (r.data_fruizione && r.data_fruizione !== "" && !isLicenzaParziale(r)) dateSetPapa[r.data_fruizione] = true })
                var dPapa = new Date(_anno, _mese - 1, 1)
                var tutteDomenichePapa = true
                while (dPapa.getMonth() === _mese - 1 && dPapa <= new Date()) {
                    if (dPapa.getDay() === 0) { if (dateSetPapa[toISO(dPapa)]) domenicheRiposo++; else tutteDomenichePapa = false }
                    dPapa.setDate(dPapa.getDate() + 1)
                }
                if (domenicheRiposo >= 4 && tutteDomenichePapa)
                    candidati.push({ nome: "Il Papa", livello: 3, colore: "#b9f2ff", occorrenze: domenicheRiposo })

                // GIORNATA DA LEONI — quante giornate domenica/festivo con ≥4h straordinari
                var conteggioLEONI = 0
                var festiviSetL = {}
                tuttiInsieme.forEach(r => { if (r.tipo && r.tipo.toUpperCase().includes("FESTIV")) festiviSetL[r.data_fruizione] = true })
                if (dettaglioStr) {
                    for (var s = 0; s < dettaglioStr.length; s++) {
                        var dISO = dettaglioStr[s].dataISO
                        var ore  = dettaglioStr[s].ore
                        var dataStrL = toDate(dISO)
                        if ((dataStrL.getDay() === 0 || festiviSetL[dISO] === true) && ore >= 4) conteggioLEONI++
                    }
                }
                if (conteggioLEONI > 0)
                    candidati.push({ nome: "Giornata da Leoni", livello: 2, colore: "#FFD700", occorrenze: conteggioLEONI })

                // SPRINT DI FUOCO — ore totali nella prima settimana completa del mese
                var oreSprintFuoco = 0
                if (dettaglioStr) {
                    var primoDelMese = new Date(_anno, _mese - 1, 1)
                    var primoLunedi = new Date(primoDelMese)
                    while (primoLunedi.getDay() !== 1) primoLunedi.setDate(primoLunedi.getDate() + 1)
                    var ultimoGiornoSettimana = new Date(primoLunedi)
                    ultimoGiornoSettimana.setDate(primoLunedi.getDate() + 6)
                    for (var w = 0; w < dettaglioStr.length; w++) {
                        var dW = toDate(dettaglioStr[w].dataISO)
                        if (dW >= primoLunedi && dW <= ultimoGiornoSettimana) oreSprintFuoco += dettaglioStr[w].ore
                    }
                }
                if (oreSprintFuoco >= 10)
                    candidati.push({ nome: "Sprint di Fuoco", livello: 3, colore: "#b9f2ff", occorrenze: Math.round(oreSprintFuoco * 10) / 10 })

                if (candidati.length === 0)
                    return { best: { nome: "", livello: 0, colore: "#888888"}, tutti: [] }

                var best = candidati[0]
                for (var j = 1; j < candidati.length; j++) {
                    if (candidati[j].livello >= best.livello) best = candidati[j]
                }
                return { best: best, tutti: candidati }
            }

            header: ToolBar {
                id: menuHeader
                height: 100

                Row {
                    id: badgeEmblema
                    anchors.left: parent.left
                    anchors.leftMargin: 6
                    anchors.top: parent.top
                    anchors.topMargin: 6
                    spacing: 5
                    visible: paginaMenu.tuttiBadge.length > 0

                    Repeater {
                        model: paginaMenu.tuttiBadge
                        delegate: Rectangle {
                            height: 36
                            width: badgeCol.width + 20
                            radius: 8
                            color: modelData.colore
                            border.color: modelData.livello === 3 ? "#00bcd4" : Qt.darker(modelData.colore, 1.3)
                            border.width: 2

                            SequentialAnimation on border.color {
                                loops: Animation.Infinite
                                running: modelData.livello === 3
                                ColorAnimation { to: "#00bcd4"; duration: 900 }
                                ColorAnimation { to: "#e0f7fa"; duration: 900 }
                            }

                            Column {
                                id: badgeCol
                                anchors.centerIn: parent
                                spacing: 1
                                Text {
                                    text: modelData.nome
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: modelData.livello === 3 ? "#003344" : "white"
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    style: Text.Outline
                                    styleColor: modelData.livello === 3 ? "transparent" : "#00000044"
                                }
                                Text {
                                    text: modelData.livello === 1 ? "▲ ARGENTO"
                                        : modelData.livello === 2 ? "★ ORO"
                                        : "◆ DIAMANTE"
                                    font.pixelSize: 9
                                    font.bold: true
                                    color: modelData.livello === 3 ? "#005577" : "white"
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    opacity: 0.85
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    popupDettaglioBadge.nomeBadge = modelData.nome
                                    popupDettaglioBadge.livelloBadge = modelData.livello
                                    popupDettaglioBadge.coloreBadge = modelData.colore
                                    popupDettaglioBadge.open()
                                }
                            }
                        }
                    }
                }

                // RIGA 2 — Notifiche sotto i badge
                Rectangle {
                    id: notificaBar
                    anchors.left: parent.left
                    anchors.leftMargin: 6
                    anchors.top: badgeEmblema.bottom
                    anchors.topMargin: 4
                    visible: paginaMenu.mostraNotifica
                    width: notificaText.width + 20
                    height: 22
                    radius: 5
                    color: "#d32f2f"

                    SequentialAnimation on opacity {
                        loops: Animation.Infinite
                        running: paginaMenu.mostraNotifica
                        NumberAnimation { to: 0.4; duration: 500 }
                        NumberAnimation { to: 1.0; duration: 500 }
                    }

                    Text {
                        id: notificaText
                        text: "NOTIFICHE (" + window.notificheCount + ")"
                        color: "white"
                        font.bold: true
                        font.pixelSize: 11
                        anchors.centerIn: parent
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            Backend.caricaDettagliNotifiche(parseInt(paginaMenu.idDatabase))
                            popupNotifiche.open()
                        }
                    }
                }
                Label {
                    text: "MENU PRINCIPALE"
                    font.bold: true
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: 20
                }   

                Rectangle {
                    id: rectGestioneBlocco
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.rightMargin: 15
                    width: 130
                    height: 38
                    radius: 8
                    visible: paginaMenu.adminIDs.indexOf(paginaMenu.idDatabase) !== -1
                    color: "#fb8c00"
                    border.color: "#ffcc80"
                    border.width: 2
                    SequentialAnimation on border.color {
                        loops: Animation.Infinite
                        running: rectGestioneBlocco.visible
                        ColorAnimation {
                            to: "#e65100" // Arancione molto scuro
                            duration: 1000
                            easing.type: Easing.InOutQuad
                        }
                        ColorAnimation {
                            to: "#ffcc80" // Arancione chiaro
                            duration: 1000
                            easing.type: Easing.InOutQuad
                        }
                    }
                    Text {
                        text: "GESTIONE BLOCCO"
                        color: "white"
                        font.pixelSize: 11
                        font.bold: true
                        anchors.centerIn: parent
                    }
                    SequentialAnimation on scale {
                        loops: Animation.Infinite
                        running: rectGestioneBlocco.visible
                        NumberAnimation { to: 1.04; duration: 1200; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 1.0; duration: 1200; easing.type: Easing.InOutSine }
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: popupConfigBlocco.open()
                        onPressed: {
                            rectGestioneBlocco.color = "#ef6c00"
                            rectGestioneBlocco.scale = 0.95
                        }
                        onReleased: {
                            rectGestioneBlocco.color = "#fb8c00"
                            rectGestioneBlocco.scale = 1.0
                        }
                    }
                }
                Rectangle {
                    id: rectMioProfilo
                    anchors.right: rectGestioneBlocco.visible ? rectGestioneBlocco.left : parent.right
                    anchors.rightMargin: rectGestioneBlocco.visible ? 10 : 15
                    anchors.verticalCenter: parent.verticalCenter
                    width: 100
                    height: 38
                    radius: 8
                    color: "#1565C0"
                    border.color: "#90CAF9"
                    border.width: 2
                    Text {
                        text: "MIO PROFILO"
                        color: "white"
                        font.pixelSize: 11
                        font.bold: true
                        anchors.centerIn: parent
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            var oggi = new Date()
                            // Usa toISO locale (come già fai in calcolaBadge)
                            function toISO(d) {
                                return d.getFullYear() + "-" +
                                    ("0" + (d.getMonth()+1)).slice(-2) + "-" +
                                    ("0" + d.getDate()).slice(-2)
                            }
                            var oggiISO = toISO(oggi)
                            Backend.caricaStoricoBadge(paginaMenu.idDatabase, oggi.getFullYear())
                            Backend.caricaRiposiAnnualiPerTipo(paginaMenu.idDatabase, oggi.getFullYear(), oggiISO)
                            Backend.caricaOreStrAnnuali(paginaMenu.idDatabase, oggi.getFullYear(), oggiISO)
                            popupProfilo.open()
                        }
                    }
                }
            }
            Component.onCompleted: {
                Qt.callLater(function() {
                    console.log("ID DATABASE AL MOMENTO DEL CARICAMENTO:", idDatabase)
                    if (idDatabase !== "") {
                        Backend.contaNotificheNonLette(parseInt(idDatabase));
                        let oggi = new Date();
                        Backend.caricaOreBadgeMenu(idDatabase, oggi.getFullYear(), oggi.getMonth() + 1);
                        paginaMenu.avviaRefreshBadge()
                    }
                });
            }
            Timer {
                id: refreshBadgeTimeout
                interval: 25000
                repeat: false
                onTriggered: {
                    paginaMenu._attesaColleghi = 0
                    paginaMenu.completaRefreshBadge()
                }
            }
            Timer {
                id: notificheTimer
                interval: 60000
                repeat: true
                running: true    
                onTriggered: {
                    if (idDatabase !== "") {
                        Backend.contaNotificheNonLette(parseInt(idDatabase))
                        paginaMenu.avviaRefreshBadge()
                    }
                }
            }
            Connections {
                target: Backend

                function onNotificheRicevute(lista) {
                    paginaMenu.listaNotifiche = lista
                }
                function onOreBadgeMenuRicevute(totaleOre) {
                    paginaMenu.oreStrMese = totaleOre
                }
                function onOperazioneCompletata(messaggio) {
                    let oggi = new Date();
                    Backend.caricaOreBadgeMenu(idDatabase, oggi.getFullYear(), oggi.getMonth() + 1)
                    paginaMenu.avviaRefreshBadge()
                }
                function onBadgeRiposiRicevuti(lista) {
                    paginaMenu.listaRiposiRaw = lista
                    paginaMenu.mappaColleghi = {}
                    let oggiB = new Date()
                    let primoMeseB = oggiB.getFullYear() + "-" + ("0" + (oggiB.getMonth() + 1)).slice(-2) + "-01"
                    let fineMB = new Date(oggiB.getFullYear(), oggiB.getMonth() + 1, 0)
                    let fineMISOB = paginaMenu.toISO(fineMB)

                    let dateUnivoche = {}
                    lista.forEach(function(r) {
                        if (r.data_fruizione && r.data_fruizione !== "" &&
                            r.data_fruizione >= primoMeseB &&
                            r.data_fruizione <= fineMISOB)
                            dateUnivoche[r.data_fruizione] = true
                    })
                    let daRichiedere = Object.keys(dateUnivoche)

                    if (daRichiedere.length === 0) {
                        paginaMenu._attesaColleghi = 0
                        var risultato = paginaMenu.calcolaBadge(lista, {}, paginaMenu.oreStrMese, paginaMenu.listaDettaglioStr)
                        paginaMenu.aggiornaBadgeDaRisultato(risultato)
                        paginaMenu.completaRefreshBadge()
                        return
                    }

                    paginaMenu._attesaColleghi = daRichiedere.length
                    for (var i = 0; i < daRichiedere.length; i++) {
                        Backend.contaColleghiPerData(paginaMenu.idDatabase, daRichiedere[i])
                    }
                }
                function onColleghiPerDataRicevuti(dataISO, count) {
                    var mappa = paginaMenu.mappaColleghi
                    mappa[dataISO] = count
                    paginaMenu.mappaColleghi = mappa

                    if (Object.keys(paginaMenu.mappaColleghi).length === paginaMenu._attesaColleghi) {
                        var risultato = paginaMenu.calcolaBadge(paginaMenu.listaRiposiRaw, paginaMenu.mappaColleghi, paginaMenu.oreStrMese, paginaMenu.listaDettaglioStr)
                        paginaMenu.aggiornaBadgeDaRisultato(risultato)
                        paginaMenu.completaRefreshBadge()
                    }
                }
                function onDettaglioStraordinariRicevuti(lista) {
                    paginaMenu.listaDettaglioStr = lista

                    // ✅ FIX: ricalcola badge se i riposi sono già arrivati e non stiamo ancora aspettando i colleghi
                    if (paginaMenu.listaRiposiRaw.length === 0) return   // riposi non ancora arrivati, aspetta
                    if (paginaMenu._attesaColleghi !== 0) return         // stiamo aspettando i colleghi, ci penserà onColleghiPerDataRicevuti

                    var risultato = paginaMenu.calcolaBadge(
                        paginaMenu.listaRiposiRaw,
                        paginaMenu.mappaColleghi,
                        paginaMenu.oreStrMese,
                        lista
                    )
                    paginaMenu.aggiornaBadgeDaRisultato(risultato)
                    paginaMenu.completaRefreshBadge()
                }
            }
            

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 15
                width: parent.width * 0.8

                Item {
                    Layout.fillWidth: true
                    height: 200
                    Column {
                        anchors.centerIn: parent
                        spacing: 6
                        width: parent.width
                        AnimatedImage {
                            id: animalCanvas
                            width: 130
                            height: 130
                            fillMode: Image.PreserveAspectFit
                            playing: true
                            anchors.horizontalCenter: parent.horizontalCenter
                            source: {
                                let b = paginaMenu.badgeCorrente
                                if (b.livello === 0) return "https://media0.giphy.com/media/1xkMJIvxeKiDS/giphy.gif"
                                if (b.nome === "Mordi e fuggi")      return "https://media2.giphy.com/media/XZmjb11cwJdc7wotpe/giphy.gif"
                                if (b.nome === "Il Camaleonte")       return "https://media2.giphy.com/media/Le5est4QxTgWynFs7l/giphy.gif"
                                if (b.nome === "L'Architetto")        return "https://media2.giphy.com/media/A8WtEEVaoj1VVqE0I1/giphy.gif"
                                if (b.nome === "Il Guerriero")        return "https://media2.giphy.com/media/odPv8LGSL0fTvigh1N/giphy.gif"
                                if (b.nome === "Tetris")              return "https://media2.giphy.com/media/MOSebUr4rvZS0/giphy.gif"
                                if (b.nome === "Febbre del Sabato Sera")   return "https://media1.giphy.com/media/v1.Y2lkPTc5MGI3NjExNmtwaXluMHlkaWwwbnZqeWh2YTJncWdsMGZ4NmNzeTJyem90cHI3MSZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/Id67ff9s4Bc4O7M3fj/giphy.gif"
                                if (b.nome === "Re dei Ponti")        return "https://media2.giphy.com/media/9cEyhVgNyeM9EYhOEC/giphy.gif"
                                if (b.nome === "Turista per sempre")  return "https://media2.giphy.com/media/0gn0R3WCprTnIs9eB3/giphy.gif"
                                if (b.nome === "Supereroe")           return "https://media2.giphy.com/media/kCd6XpV0TOMmmjqvo8/giphy.gif"
                                if (b.nome === "Il Papa")             return "https://media2.giphy.com/media/m2lzGNOPx2UgE74kB2/giphy.gif"
                                if (b.nome === "Giornata da Leoni") return "https://media3.giphy.com/media/v1.Y2lkPTc5MGI3NjExc3QxZTJ3YTBqejNsNGU1MDMzMWZ1MnNmdzU1Ymh3aDF6Zjh4b2k3dSZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/l1BUojJe4cno1U0CgL/giphy.gif"
                                if (b.nome === "Sprint di Fuoco")   return "https://media0.giphy.com/media/v1.Y2lkPTc5MGI3NjExd2xybDdjMnIwazFpaWd5MmY0anA1cW4yczVhYWl2cWh5NGpleDZnaSZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/YA6dmVW0gfIw8/giphy.gif"
                                if (b.nome === "Ufficio anagrafe")  return "https://media4.giphy.com/media/v1.Y2lkPTc5MGI3NjExNW5mNnBzZWpucmF0cWJhajBsYmt1M3d4anUwa2pzbXh2NjA5ZHM3dSZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/cXblnKXr2BQOaYnTni/giphy.gif"
                                if (b.nome === "Il vampiro")        return "https://media1.giphy.com/media/v1.Y2lkPTc5MGI3NjExMjg3ZzVmbXQ0NTFtMmlxejFucXJrc2xiMjhzNXhkMWZ6YmZvaHY2aSZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/ljE57hRBCNcsg/giphy.gif"
                                return "https://media0.giphy.com/media/1xkMJIvxeKiDS/giphy.gif"
                            }
                        }

                        Label {
                            text: "Benvenuto, " + paginaMenu.utente
                            horizontalAlignment: Text.AlignHCenter
                            width: parent.width
                            font.pixelSize: 18
                            color: "#333"
                        }
                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 200
                            height: 32
                            radius: 16
                            visible: paginaMenu.badgeCorrente.livello > 0
                            color: paginaMenu.badgeCorrente.colore
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    popupDettaglioBadge.nomeBadge = paginaMenu.badgeCorrente.nome
                                    popupDettaglioBadge.livelloBadge = paginaMenu.badgeCorrente.livello
                                    popupDettaglioBadge.coloreBadge = paginaMenu.badgeCorrente.colore
                                    popupDettaglioBadge.open()
                                }
                            }

                            // Animazione bordo per DIAMANTE
                            border.width: paginaMenu.badgeCorrente.livello === 3 ? 2 : 0
                            border.color: "#80deea"

                            SequentialAnimation on border.color {
                                loops: Animation.Infinite
                                running: paginaMenu.badgeCorrente.livello === 3
                                ColorAnimation { to: "#00bcd4"; duration: 900 }
                                ColorAnimation { to: "#e0f7fa"; duration: 900 }
                            }

                            Text {
                                anchors.centerIn: parent
                                font.pixelSize: 11
                                font.bold: true
                                color: paginaMenu.badgeCorrente.livello === 3 ? "#1a6080" : "white"
                                text: {
                                    var b = paginaMenu.badgeCorrente
                                    if (b.livello === 0) return ""
                                    var livStr = b.livello === 1 ? " ARGENTO" : (b.livello === 2 ? " ORO" : " DIAMANTE")
                                    return b.nome + " —" + livStr
                                }
                            }
                        }
                    }
                }

                Label {
                    text: "⚠️ MODIFICHE BLOCCATE DALL'ADMIN"
                    color: "red"
                    font.bold: true
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    visible: false // Potrai collegarlo a una property del Backend se vuoi automatizzarlo
                }

                MenuActionButton {
                    text: "REPORT"
                    onClicked: stack.push(reportPage, {"idDatabase": paginaMenu.idDatabase})
                }
                MenuActionButton {
                    text: "STRAORDINARI"
                    onClicked: stack.push(straordinariPage, {"idDatabase": paginaMenu.idDatabase})
                }

                MenuActionButton {
                    text: "VISUALIZZA SPECCHIO"
                    onClicked: stack.push(specchioPage, {
                                    "idDatabase": paginaMenu.idDatabase,
                                    "utente": paginaMenu.utente
                                })
                }

                MenuActionButton {
                    text: " INSERISCI NUOVO RIPOSO"
                    onClicked: stack.push(inserimentoPage, {"idDatabase": paginaMenu.idDatabase})
                }
                MenuActionButton {
                    text: " FRUIZIONE RIPOSO"
                    onClicked: stack.push(fruizionePage, {"idDatabase": paginaMenu.idDatabase})
                }
                MenuActionButton {
                    text: " MODIFICA RIPOSO"
                    onClicked: stack.push(modificaPage, {"idDatabase": paginaMenu.idDatabase})
                }
                MenuActionButton {
                    text: " CANCELLA RIPOSO"
                    onClicked: stack.push(cancellaPage, {"idDatabase": paginaMenu.idDatabase})
                }
                MenuDangerButton {
                    text: " ESCI"
                    onClicked: stack.pop()
                }
            }
            Popup {
                id: popupNotifiche
                x: 6
                y: menuHeader.height + 8
                width: parent.width * 0.88
                modal: true
                focus: true
                closePolicy: Popup.NoAutoClose
                background: Rectangle {
                    radius: 10
                    border.color: "#2196F3"
                    border.width: 2
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 12

                    Label {
                        text: "🔔 NOTIFICHE"
                        font.bold: true
                        font.pixelSize: 16
                        color: "#2196F3"
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Rectangle { height: 1; Layout.fillWidth: true; color: "#2196F3"; opacity: 0.4 }

                    ListView {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.min((paginaMenu.listaNotifiche ? paginaMenu.listaNotifiche.length : 0) * 90, 300)
                        clip: true
                        model: paginaMenu.listaNotifiche
                        delegate: Rectangle {
                            width: parent.width
                            height: 85
                            color: index % 2 === 0 ? "#f5f9ff" : "white"
                            border.color: "#e0e0e0"
                            border.width: 1
                            radius: 4
                            Column {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 3
                                Label { text: modelData.messaggio; font.bold: true; font.pixelSize: 13; color: modelData.messaggio.indexOf("APPROVATO") !== -1 ? "#388E3C" : "#d32f2f" }
                                Label { text: "📅 Data fruizione: " + (modelData.dataFruizione !== "" ? modelData.dataFruizione : "N/D"); font.pixelSize: 11; color: "#555"}
                                Label { text: "👤 Validato da: " + modelData.validatoDa; font.pixelSize: 11; color: "#555" }
                                Label { text: "🕐 " + modelData.dataOra; font.pixelSize: 10; color: "#999" }
                            }
                        }
                    }

                    Button {
                        text: "✓  HO LETTO"
                        highlighted: true
                        Layout.fillWidth: true
                        onClicked: {
                            Backend.segnaNotificheComeLette(parseInt(paginaMenu.idDatabase))
                            window.haNotificheGlobal = false
                            window.notificheCount = 0
                            paginaMenu.listaNotifiche = []
                            popupNotifiche.close()
                        }
                    }
                }
            }
            Popup {
                id: popupProfilo
                anchors.centerIn: Overlay.overlay
                width: Math.min(parent.width * 0.92, 500)
                height: Math.min(parent.height * 0.88, 700)
                modal: true
                focus: true
                closePolicy: Popup.CloseOnEscape

                property var storicoBadge: []
                property var riposiAnnuali: []
                property double oreStrAnnuali: 0.0
                property var badgeAggregati: []
                property int meseFiltroSelezionato: -1  // -1 = anno intero
                property double oreStrMeseFiltrato: 0.0

                function aggiornaBadgeAggregati() {
                    var mappa = {}
                    var sorgente = meseFiltroSelezionato === -1
                        ? storicoBadge
                        : storicoBadge.filter(function(b) { return b.mese === meseFiltroSelezionato })
                    for (var i = 0; i < sorgente.length; i++) {
                        var b = sorgente[i]
                        if (!mappa[b.nome_badge])
                            mappa[b.nome_badge] = { nome: b.nome_badge, livello: b.livello, colore: b.colore, count: 0 }
                        mappa[b.nome_badge].count += (b.occorrenze || 1)
                    }
                    badgeAggregati = Object.values(mappa)
                }
                onStoricoBadgeChanged: aggiornaBadgeAggregati()
                onMeseFiltroSelezionatoChanged: {
                    aggiornaBadgeAggregati()
                    if (meseFiltroSelezionato !== -1) {
                        var oggi = new Date()
                        Backend.caricaOreStrMese(paginaMenu.idDatabase, oggi.getFullYear(), meseFiltroSelezionato)
                    } else {
                        oreStrMeseFiltrato = 0.0
                    }
                }
                Connections {
                    target: Backend
                    function onStoricoBadgeRicevuto(lista) {
                        console.log("STORICO BADGE RICEVUTO:", JSON.stringify(lista))
                        popupProfilo.storicoBadge = lista
                    }
                    function onRiposiAnnualiRicevuti(lista) { popupProfilo.riposiAnnuali = lista }
                    function onOreStrAnnualiRicevute(totale) { popupProfilo.oreStrAnnuali = totale }
                    function onOreStrMeseRicevute(totale) { popupProfilo.oreStrMeseFiltrato = totale }
                }

                background: Rectangle { radius: 12; color: "white"; border.color: "#1565C0"; border.width: 2 }
                
                ScrollView {
                    anchors.fill: parent
                    anchors.margins: 14
                    clip: true
                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 14

                        // INTESTAZIONE
                        Label {
                            text: " MIO PROFILO"
                            font.bold: true
                            font.pixelSize: 18
                            color: "#1565C0"
                            Layout.alignment: Qt.AlignHCenter
                        }
                        Rectangle { height: 1; Layout.fillWidth: true; color: "#1565C0"; opacity: 0.3 }

                        // BADGE MESE CORRENTE IN PRIMO PIANO
                        Rectangle {
                            Layout.fillWidth: true
                            height: 70
                            radius: 10
                            color: paginaMenu.badgeCorrente.colore !== "" ? paginaMenu.badgeCorrente.colore : "#eeeeee"
                            border.color: paginaMenu.badgeCorrente.livello === 3 ? "#00bcd4" : Qt.darker(paginaMenu.badgeCorrente.colore || "#aaa", 1.3)
                            border.width: 2
                            visible: paginaMenu.badgeCorrente.livello > 0

                            SequentialAnimation on border.color {
                                loops: Animation.Infinite
                                running: paginaMenu.badgeCorrente.livello === 3
                                ColorAnimation { to: "#00bcd4"; duration: 900 }
                                ColorAnimation { to: "#e0f7fa"; duration: 900 }
                            }

                            Row {
                                anchors.centerIn: parent
                                spacing: 12

                                AnimatedImage {
                                    width: 54; height: 54
                                    fillMode: Image.PreserveAspectFit
                                    playing: popupProfilo.visible
                                    source: popupProfilo.visible && paginaMenu.badgeCorrente.nome !== ""
                                            ? popupDettaglioBadge.gifPerBadge(paginaMenu.badgeCorrente.nome) : ""
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 2
                                    Text {
                                        text: paginaMenu.badgeCorrente.nome
                                        font.pixelSize: 20; font.bold: true
                                        color: paginaMenu.badgeCorrente.livello === 3 ? "#003344" : "white"
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                    Text {
                                        text: "BADGE DEL MESE  •  " + (
                                            paginaMenu.badgeCorrente.livello === 1 ? "▲ ARGENTO"
                                            : paginaMenu.badgeCorrente.livello === 2 ? "★ ORO"
                                            : "◆ DIAMANTE")
                                        font.pixelSize: 11
                                        color: paginaMenu.badgeCorrente.livello === 3 ? "#005577" : "white"
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        opacity: 0.9
                                    }
                                }
                            }
                        }

                        Rectangle { height: 1; Layout.fillWidth: true; color: "#e0e0e0" }

                        // STORICO BADGE ANNO
                        Label {
                            text: "BADGE GUADAGNATI QUEST'ANNO"
                            font.bold: true
                            font.pixelSize: 13
                            color: "#333"
                        }
                        ListView {
                            Layout.fillWidth: true
                            Layout.preferredHeight: Math.min(popupProfilo.badgeAggregati.length * 38 + 4, 120)
                            clip: true
                            model: popupProfilo.badgeAggregati
                            delegate: Rectangle {
                                width: parent.width
                                height: 34
                                radius: 6
                                color: index % 2 === 0 ? "#f5f8ff" : "white"
                                border.color: "#e0e0e0"
                                border.width: 1
                                Row {
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    spacing: 10
                                    Text { text: modelData.nome; font.bold: true; font.pixelSize: 13; color: "#222"; anchors.verticalCenter: parent.verticalCenter }
                                    Text { text: "x" + modelData.count + " volte"; font.pixelSize: 12; color: "#1565C0"; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        popupDettaglioBadge.nomeBadge = modelData.nome
                                        popupDettaglioBadge.livelloBadge = modelData.livello
                                        popupDettaglioBadge.coloreBadge = modelData.colore
                                        popupDettaglioBadge.open()
                                    }
                                }
                            }
                        }

                        Rectangle { height: 1; Layout.fillWidth: true; color: "#e0e0e0" }

                        // STRAORDINARI ANNUALI / MESE
                        Label {
                            text: popupProfilo.meseFiltroSelezionato === -1 ? "STRAORDINARI QUEST'ANNO" : "STRAORDINARI DEL MESE"
                            font.bold: true
                            font.pixelSize: 13
                            color: "#333"
                        }
                        Rectangle {
                            Layout.fillWidth: true
                            height: 40
                            radius: 8
                            color: "#E3F2FD"
                            border.color: "#2196F3"
                            border.width: 1
                            Text {
                                anchors.centerIn: parent
                                text: popupProfilo.meseFiltroSelezionato === -1
                                    ? popupProfilo.oreStrAnnuali.toFixed(1) + " ore totali"
                                    : popupProfilo.oreStrMeseFiltrato.toFixed(1) + " ore"
                                font.bold: true
                                font.pixelSize: 15
                                color: "#1565C0"
                            }
                        }

                        Rectangle { height: 1; Layout.fillWidth: true; color: "#e0e0e0" }

                        // RIPOSI PER TIPO — label + pulsante reset
                        RowLayout {
                            Layout.fillWidth: true
                            Label {
                                text: "RIPOSI FRUITI QUEST'ANNO PER TIPO"
                                font.bold: true
                                font.pixelSize: 13
                                color: "#333"
                                Layout.fillWidth: true
                            }
                            Rectangle {
                                visible: popupProfilo.meseFiltroSelezionato !== -1
                                width: 60
                                height: 22
                                radius: 5
                                color: "#e53935"
                                Text { anchors.centerIn: parent; text: "✕ TUTTI"; font.pixelSize: 10; font.bold: true; color: "white" }
                                MouseArea { anchors.fill: parent; onClicked: popupProfilo.meseFiltroSelezionato = -1 }
                            }
                        }

                        // GRIGLIA MESI
                        GridLayout {
                            Layout.fillWidth: true
                            columns: parent.width > 350 ? 6 : 4
                            rowSpacing: 4
                            columnSpacing: 4
                            Repeater {
                                model: [
                                    { n: 1,  label: "GEN" }, { n: 2,  label: "FEB" },
                                    { n: 3,  label: "MAR" }, { n: 4,  label: "APR" },
                                    { n: 5,  label: "MAG" }, { n: 6,  label: "GIU" },
                                    { n: 7,  label: "LUG" }, { n: 8,  label: "AGO" },
                                    { n: 9,  label: "SET" }, { n: 10, label: "OTT" },
                                    { n: 11, label: "NOV" }, { n: 12, label: "DIC" }
                                ]
                                delegate: Rectangle {
                                    Layout.fillWidth: true
                                    height: 28
                                    radius: 6
                                    color: popupProfilo.meseFiltroSelezionato === modelData.n ? "#1565C0" : "#E3F2FD"
                                    border.color: popupProfilo.meseFiltroSelezionato === modelData.n ? "#0D47A1" : "#90CAF9"
                                    border.width: 1
                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.label
                                        font.pixelSize: 11
                                        font.bold: popupProfilo.meseFiltroSelezionato === modelData.n
                                        color: popupProfilo.meseFiltroSelezionato === modelData.n ? "white" : "#1565C0"
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            if (popupProfilo.meseFiltroSelezionato === modelData.n)
                                                popupProfilo.meseFiltroSelezionato = -1
                                            else
                                                popupProfilo.meseFiltroSelezionato = modelData.n
                                        }
                                    }
                                }
                            }
                        }

                        // LABEL MESE ATTIVO
                        Label {
                            visible: popupProfilo.meseFiltroSelezionato !== -1
                            text: {
                                var nomi = ["","Gennaio","Febbraio","Marzo","Aprile","Maggio","Giugno",
                                            "Luglio","Agosto","Settembre","Ottobre","Novembre","Dicembre"]
                                return " Dati di " + nomi[popupProfilo.meseFiltroSelezionato]
                            }
                            font.pixelSize: 11
                            font.bold: true
                            color: "#1565C0"
                            Layout.alignment: Qt.AlignHCenter
                        }

                        // BADGE DEL MESE SELEZIONATO
                        Label {
                            visible: popupProfilo.meseFiltroSelezionato !== -1
                            text: "Badge del mese:"
                            font.pixelSize: 12
                            font.bold: true
                            color: "#555"
                        }
                        ListView {
                            visible: popupProfilo.meseFiltroSelezionato !== -1
                            Layout.fillWidth: true
                            Layout.preferredHeight: {
                                var n = popupProfilo.storicoBadge.filter(function(b) {
                                    return b.mese === popupProfilo.meseFiltroSelezionato
                                }).length
                                return n === 0 ? 30 : Math.min(n * 38 + 4, 120)
                            }
                            clip: true
                            model: popupProfilo.storicoBadge.filter(function(b) {
                                return b.mese === popupProfilo.meseFiltroSelezionato
                            })
                            delegate: Rectangle {
                                width: parent.width
                                height: 34
                                radius: 6
                                color: index % 2 === 0 ? "#f5f8ff" : "white"
                                border.color: "#e0e0e0"
                                border.width: 1
                                Row {
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    spacing: 10
                                    Rectangle {
                                        width: badgeTxt.width + 16
                                        height: 22
                                        radius: 5
                                        color: modelData.colore
                                        anchors.verticalCenter: parent.verticalCenter
                                        Text {
                                            id: badgeTxt
                                            anchors.centerIn: parent
                                            text: modelData.nome_badge
                                            font.pixelSize: 11
                                            font.bold: true
                                            color: modelData.livello === 3 ? "#003344" : "white"
                                        }
                                    }
                                    Text {
                                        text: modelData.livello === 1 ? "▲ ARGENTO"
                                            : modelData.livello === 2 ? "★ ORO"
                                            : "◆ DIAMANTE"
                                        font.pixelSize: 11
                                        color: "#888"
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        popupDettaglioBadge.nomeBadge = modelData.nome_badge
                                        popupDettaglioBadge.livelloBadge = modelData.livello
                                        popupDettaglioBadge.coloreBadge = modelData.colore
                                        popupDettaglioBadge.open()
                                    }
                                }
                            }
                            Label {
                                anchors.centerIn: parent
                                visible: popupProfilo.storicoBadge.filter(function(b) {
                                    return b.mese === popupProfilo.meseFiltroSelezionato
                                }).length === 0
                                text: "Nessun badge questo mese"
                                color: "gray"
                                font.pixelSize: 11
                            }
                        }

                        // RIPOSI PER TIPO (filtrati)
                        ListView {
                            Layout.fillWidth: true
                            Layout.preferredHeight: Math.max(popupProfilo.riposiAnnuali.length * 38 + 10, 60)
                            clip: true
                            model: {
                                var mappa = {}
                                var filtroMese = popupProfilo.meseFiltroSelezionato
                                for (var j = 0; j < popupProfilo.riposiAnnuali.length; j++) {
                                    var r = popupProfilo.riposiAnnuali[j]
                                    var nota = (r.a || "").toUpperCase()
                                    if (nota.includes("MAT") || nota.includes("CIT") ||
                                        nota.includes("POM") || nota.includes("SER")) continue
                                    if (filtroMese !== -1) {
                                        var parti = (r.data || "").split("-")
                                        if (parti.length < 2 || parseInt(parti[1]) !== filtroMese) continue
                                    }
                                    var tipo = r.tipo || "SCONOSCIUTO"
                                    mappa[tipo] = (mappa[tipo] || 0) + 1
                                }
                                return Object.keys(mappa).map(function(k) {
                                    return { tipo: k, count: mappa[k] }
                                })
                            }
                            delegate: Rectangle {
                                width: parent.width
                                height: 34
                                radius: 6
                                color: index % 2 === 0 ? "#f5f8ff" : "white"
                                border.color: "#e0e0e0"
                                border.width: 1
                                Row {
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    spacing: 10
                                    Text {
                                        text: modelData.tipo
                                        font.pixelSize: 12
                                        color: "#444"
                                        anchors.verticalCenter: parent.verticalCenter
                                        Layout.fillWidth: true
                                    }
                                    Text {
                                        text: modelData.count + " giorni"
                                        font.bold: true
                                        font.pixelSize: 12
                                        color: "#388E3C"
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }
                            }
                        }

                        Button {
                            text: "CHIUDI"
                            Layout.fillWidth: true
                            onClicked: popupProfilo.close()
                        }
                    }
                }
            }
        }
    }
    Component {
        id: reportPage
        Page {
            id: paginaReport
            property string idDatabase: ""
            property var listaReport: []

            header: ToolBar {
                RowLayout {
                    anchors.fill: parent
                    ToolButton { text: "‹"; onClicked: stack.pop() }
                    Label { text: "Report Riposi"; font.bold: true; Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; rightPadding: 40 }
                }
            }

            Connections {
                target: Backend
                function onRiposiRicevuti(lista) { paginaReport.listaReport = lista }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10

                Label { text: "FILTRA / ORDINA PER:"; font.bold: true; color: "#2196F3" }

                ComboBox {
                    id: comboFiltro
                    Layout.fillWidth: true
                    model: [
                        "Data (Recente → Vecchio)",
                        "Data (Vecchio → Recente)",
                        "Tipo Riposo",
                        "Stato",
                        "Solo DISPONIBILI",
                        "Solo FRUITI"
                    ]
                    onActivated: Backend.caricaReport(idDatabase, index + 1)
                    contentItem: Text {
                        leftPadding: 8
                        text: comboFiltro.displayText
                        font.pixelSize: 13
                        font.bold: true
                        color: "#1f2937"
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        radius: 6
                        color: comboFiltro.pressed ? "#dbeafe" : "#ffffff"
                        border.color: comboFiltro.activeFocus ? "#1565C0" : "#7f9fbd"
                        border.width: comboFiltro.activeFocus ? 2 : 1.5
                    }
                    delegate: ItemDelegate {
                        width: comboFiltro.width
                        contentItem: Text {
                            text: modelData
                            color: "#1f2937"
                            font.pixelSize: 13
                            verticalAlignment: Text.AlignVCenter
                            leftPadding: 8
                        }
                        background: Rectangle {
                            color: hovered ? "#dbeafe" : "#ffffff"
                        }
                    }
                }

                // Tabella dei risultati
                ListView {
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    clip: true
                    model: paginaReport.listaReport
                    header: Item { height: 10}

                    delegate: ItemDelegate {
                        width: parent.width
                        padding: 10
                        contentItem: ColumnLayout {
                            spacing: 4
                            RowLayout {
                                Layout.fillWidth: true
                                Label {
                                    text: "📅 DATA: " + modelData.dataITA
                                    font.bold: true
                                    Layout.fillWidth: true
                                }
                                Label {
                                    text: "📌 TIPO: " + modelData.tipo
                                    font.pixelSize: 13
                                    Layout.fillWidth: true
                                    wrapMode: Text.WordWrap }
                                Label {
                                    text: modelData.stato
                                    color: modelData.stato === "VALIDATO" ? "green" : "orange"
                                    font.pixelSize: 11
                                }
                            }
                            Label {
                                text: "📋 Fruizione: " + modelData.fruiz + (modelData.dataF !== "" ? " (" + modelData.dataF + ")" : "")
                                font.pixelSize: 12
                                color: "gray"
                            }
                            Rectangle {
                                height: 1
                                Layout.fillWidth: true
                                color: "#ddd"
                                Layout.topMargin: 5
                            }
                        }
                    }

                    Label {
                        anchors.centerIn: parent
                        text: "Nessun dato corrispondente"
                        visible: paginaReport.listaReport.length === 0
                        color: "gray"
                    }
                }
            }
            Component.onCompleted: Backend.caricaReport(idDatabase, 1)
        }
    }

    Component {
        id: specchioPage
        Page {
            id: paginaSpecchio
            objectName: "paginaSpecchio"
            property alias meseSelezionato: comboMese.valoreMese
            property alias annoSelezionato: comboAnno.currentText
            property var listaUtenti: []
            property var datiRiposi: []
            property int totalDays: 31
            property string idDatabase: ""
            property string utente: ""
            readonly property var adminIDs: ["1", "2", "3", "19"]

            function isFestivo(giorno, mese, anno) {
                let d = new Date(anno, mese - 1, giorno);
                if (d.getDay() === 0) return true;
                let festiviFissi = [
                    "01-01", // Capodanno
                    "06-01", // Epifania
                    "15-01",  //san mauro casoria
                    "25-04", // Liberazione
                    "01-05", // Lavoro
                    "02-06", // Repubblica
                    "15-08", // Ferragosto
                    "01-11", // Ognissanti
                    "08-12", // Immacolata
                    "25-12", // Natale
                    "26-12"  // S. Stefano
                ];
                let giornoMese = giorno.toString().padStart(2, '0') + "-" + mese.toString().padStart(2, '0');
                return festiviFissi.includes(giornoMese);
            }

            header: ToolBar {
                RowLayout {
                    anchors.fill: parent
                    ToolButton { text: "‹"; onClicked: stack.pop() }
                    Label {
                        text: "Specchio Dei Riposi";
                        font.bold: true;
                        Layout.fillWidth: true;
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }

            ColumnLayout {
                anchors.fill: parent; spacing: 0

                RowLayout {
                    Layout.margins: 10
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 10

                    ComboBox {
                        id: comboMese
                        Layout.preferredWidth: 120
                        model: ["Gennaio", "Febbraio", "Marzo", "Aprile", "Maggio", "Giugno",
                                "Luglio", "Agosto", "Settembre", "Ottobre", "Novembre", "Dicembre"]
                        readonly property string valoreMese: (currentIndex + 1).toString().padStart(2, '0')
                        Component.onCompleted: currentIndex = new Date().getMonth()
                        contentItem: Text {
                            leftPadding: 8
                            text: comboMese.displayText
                            font.pixelSize: 13
                            font.bold: true
                            color: "#1f2937"
                            verticalAlignment: Text.AlignVCenter
                        }
                        background: Rectangle {
                            radius: 6
                            color: comboMese.pressed ? "#dbeafe" : "#ffffff"
                            border.color: comboMese.activeFocus ? "#1565C0" : "#7f9fbd"
                            border.width: comboMese.activeFocus ? 2 : 1.5
                        }
                        delegate: ItemDelegate {
                            width: comboMese.width
                            contentItem: Text {
                                text: modelData
                                color: "#1f2937"
                                font.pixelSize: 13
                                verticalAlignment: Text.AlignVCenter
                                leftPadding: 8
                            }
                            background: Rectangle { color: hovered ? "#dbeafe" : "#ffffff" }
                        }
                    }
                    Label {text: "/" }
                    ComboBox {
                        id: comboAnno
                        Layout.preferredWidth: 100
                        model: {
                            let anni = [];
                            let annoCorrente = new Date().getFullYear();
                            for (let i = annoCorrente - 1; i <= annoCorrente + 2; i++) {
                                anni.push(i.toString());
                            }
                            return anni;
                        }
                        Component.onCompleted: {
                            let annoOggi = new Date().getFullYear().toString();
                            for(let i=0; i<model.length; i++) {
                                if(model[i] === annoOggi) { currentIndex = i; break; }
                            }
                        }
                        contentItem: Text {
                            leftPadding: 8
                            text: comboAnno.displayText
                            font.pixelSize: 13
                            font.bold: true
                            color: "#1f2937"
                            verticalAlignment: Text.AlignVCenter
                        }
                        background: Rectangle {
                            radius: 6
                            color: comboAnno.pressed ? "#dbeafe" : "#ffffff"
                            border.color: comboAnno.activeFocus ? "#1565C0" : "#7f9fbd"
                            border.width: comboAnno.activeFocus ? 2 : 1.5
                        }
                        delegate: ItemDelegate {
                            width: comboAnno.width
                            contentItem: Text {
                                text: modelData
                                color: "#1f2937"
                                font.pixelSize: 13
                                verticalAlignment: Text.AlignVCenter
                                leftPadding: 8
                            }
                            background: Rectangle { color: hovered ? "#dbeafe" : "#ffffff" }
                        }
                    }
                    Button {
                        text: "CARICA RIPOSI";
                        highlighted: true
                        onClicked: {
                            let m = comboMese.valoreMese;
                            let a = comboAnno.currentText;
                            let ultimo = new Date(a, m, 0).getDate();
                            paginaSpecchio.totalDays = ultimo;
                            Backend.caricaSpecchioAdmin("01-" + m + "-" + a, ultimo + "-" + m + "-" + a)
                        }
                    }
                }

                ScrollView {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOn
                    clip: true
                    Column {
                        spacing: 0
                        Row {
                            spacing: 0
                            Rectangle {
                                width: 150; height: 50; color: "#f0f0f0"; border.color: "#999";
                                Label {
                                    text: "UTENTI";
                                    anchors.left: parent.left; anchors.leftMargin: 10;
                                    anchors.verticalCenter: parent.verticalCenter;
                                    font.bold: true; font.pixelSize: 12
                                }
                            }

                            Item {
                                height: 50
                                width: paginaSpecchio.totalDays * 40
                                Row {
                                    anchors.fill: parent
                                    Repeater {
                                        model: paginaSpecchio.totalDays
                                        delegate: Rectangle {
                                            width: 40; height: 50; color: "#f0f0f0"; border.color: "#999"
                                            ColumnLayout {
                                                anchors.centerIn: parent
                                                spacing: 0
                                                Label {
                                                text: index + 1;
                                                font.bold: true;
                                                Layout.alignment: Qt.AlignHCenter
                                                }
                                            }
                                            Label {
                                                font.pixelSize: 10
                                                text: {
                                                    let a = parseInt(comboAnno.currentText);
                                                    let m = parseInt(comboMese.valoreMese) - 1;
                                                    let g = index + 1;
                                                    let d = new Date(a, m, g);
                                                    let giorni = ["DOM", "LUN", "MAR", "MER", "GIO", "VEN", "SAB"];
                                                    return giorni[d.getDay()];
                                                }
                                                Layout.alignment: Qt.AlignHCenter
                                            }
                                        }
                                    }
                                }
                                Rectangle {
                                    id: barraBlocco
                                    z: 2
                                    visible: Backend.bloccoAttivo
                                    height: 20
                                    radius: 4
                                    color: "#f44336"
                                    opacity: 0.8
                                    y: 38
                                    x: {
                                        let dataInizio = new Date(Backend.inizioBlocco);
                                        dataInizio.setHours(0, 0, 0, 0);
                                        let meseCorr = parseInt(comboMese.valoreMese);
                                        let annoCorr = parseInt(comboAnno.currentText);
                                        if (dataInizio.getFullYear() === annoCorr && (dataInizio.getMonth() + 1) === meseCorr) {
                                            return Math.max(0, (dataInizio.getDate() - 1) * 40);
                                        }
                                        return 0;
                                    }

                                    width: {
                                        let dInizio = new Date(Backend.inizioBlocco);
                                        let dFine = new Date(Backend.fineBlocco);
                                        dInizio.setHours(0, 0, 0, 0);
                                        dFine.setHours(23, 59, 59, 999);
                                        let meseCorr = parseInt(comboMese.valoreMese);
                                        let annoCorr = parseInt(comboAnno.currentText);
                                        let giorniVisibili = 0;
                                        for (let g = 1; g <= paginaSpecchio.totalDays; g++) {
                                            let dataGiorno = new Date(annoCorr, meseCorr - 1, g);
                                            dataGiorno.setHours(12, 0, 0, 0);
                                            if (dataGiorno >= dInizio && dataGiorno <= dFine) {
                                                giorniVisibili++;
                                            }
                                        }
                                        return giorniVisibili * 40;
                                    }

                                    Text {
                                        text: "BLOCCO"
                                        anchors.centerIn: parent
                                        color: "white"
                                        font.pixelSize: 9
                                        font.bold: true
                                    }
                                }
                            }
                        }
                                // Righe Utenti
                        Repeater {
                            model: paginaSpecchio.listaUtenti
                            delegate: Row {
                                spacing: 0
                                id: rigaDati
                                property string utenteDellaRiga: modelData
                                Rectangle {
                                    width: 150; height: 50; border.color: "#ccc"; color: "white"
                                    Label {
                                        text: utenteDellaRiga;
                                        anchors.left: parent.left; anchors.leftMargin: 8;
                                        anchors.verticalCenter: parent.verticalCenter;
                                        font.pixelSize: 11; font.bold: true
                                        color: "#1565C0"
                                        font.underline: true
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            // Trova l'id_reale di questo utente dai datiRiposi
                                            var idTrovato = ""
                                            for (var i = 0; i < paginaSpecchio.datiRiposi.length; i++) {
                                                if (paginaSpecchio.datiRiposi[i].u === utenteDellaRiga) {
                                                    idTrovato = String(paginaSpecchio.datiRiposi[i].id_reale)
                                                    break
                                                }
                                            }
                                            if (idTrovato === "" || idTrovato === paginaSpecchio.idDatabase) return
                                            var oggi = new Date()
                                            var oggiISO = oggi.getFullYear() + "-" +
                                                ("0"+(oggi.getMonth()+1)).slice(-2) + "-" +
                                                ("0"+oggi.getDate()).slice(-2)
                                            popupProfiloAltro.nomeUtente = utenteDellaRiga
                                            popupProfiloAltro.idUtente   = idTrovato
                                            popupProfiloAltro.storicoBadge   = []
                                            popupProfiloAltro.riposiAnnuali  = []
                                            popupProfiloAltro.oreStr         = 0
                                            popupProfiloAltro.caricamentoBadge   = true
                                            popupProfiloAltro.caricamentoRiposi  = true
                                            popupProfiloAltro.caricamentoOre     = true
                                            Backend.caricaProfiloAltroUtente(idTrovato, oggi.getFullYear(), oggiISO)
                                            popupProfiloAltro.open()
                                        }
                                    }
                                }
                                Repeater {
                                    model: paginaSpecchio.totalDays
                                    delegate: Rectangle {
                                        id: cellaDelegata
                                        width: 40
                                        height: 50
                                        border.color: "black"
                                        border.width: 1

                                        property bool festivo: isFestivo(index + 1, parseInt(comboMese.valoreMese), parseInt(comboAnno.currentText))
                                        color: {
                                            let giorno = index + 1;
                                            let mese = parseInt(comboMese.valoreMese);
                                            let anno = parseInt(comboAnno.currentText);

                                            if (isFestivo(giorno, mese, anno)) {
                                                return "#eeeeee"; // Grigio chiaro per festivi e domeniche
                                            } else {
                                                return "white";   // Bianco per i giorni feriali
                                            }
                                        }
                                        property int numeroGiorno: index + 1
                                        readonly property var helper: {
                                            return {
                                                cerca: function() {
                                                    let sorgente = paginaSpecchio.datiRiposi;
                                                    if (!sorgente) return null;
                                                    for (let i = 0; i < sorgente.length; i++) {
                                                        let elemento = sorgente[i];
                                                        if (elemento.u === utenteDellaRiga && Number(elemento.d) === Number(numeroGiorno)) {
                                                            return elemento;
                                                        }
                                                    }
                                                    return null;
                                                }
                                            }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            enabled: true
                                            onClicked: {
                                                let g = (index + 1).toString().padStart(2, '0');
                                                let m = comboMese.valoreMese;
                                                let a = comboAnno.currentText;
                                                let dataCliccataISO = a + "-" + m + "-" + g;
                                                let bloccoAttivoInQuestaData = Backend.isOperazioneBloccata(paginaSpecchio.idDatabase, dataCliccataISO);
                                                let trovato = cellaDelegata.helper.cerca();
                                                if (bloccoAttivoInQuestaData) {
                                                    if (trovato) {
                                                        globalErrorLabel.text = "RIPOSO INSERITO: In questo intervallo di tempo le modifiche sono bloccate dall'Admin.";
                                                        globalErrorPopup.open();
                                                    }
                                                    return;
                                                }
                                                let dataFinale = a + "-" + m + "-" + g;
                                                if (trovato) {
                                                    let tipo = trovato.tipo.toUpperCase();
                                                    if (tipo === "LICENZA") {
                                                        if (Number(trovato.id_reale) === Number(paginaSpecchio.idDatabase)) {
                                                            popupEliminaLicenza.dataSelezionata = dataFinale
                                                            popupEliminaLicenza.idUtenteSelezionato = trovato.id_reale
                                                            popupEliminaLicenza.open()
                                                        } else {
                                                            globalErrorLabel.text = "Questa è una Licenza di un altro utente.\nNon hai i permessi per rimuoverla.";
                                                            globalErrorPopup.open();
                                                        }
                                                    } else {
                                                        // Solo il proprietario può ritirare il proprio riposo RICHIESTO
                                                        let riga = utenteDellaRiga.trim().toUpperCase();
                                                        let loggato = paginaSpecchio.utente.trim().toUpperCase();
                                                        let paroleLoggato = loggato.split(" ");
                                                        let isProprietario = paroleLoggato.length > 0 && paroleLoggato.every(p => riga.includes(p));
                                                        let statoTrovato = trovato.stato ? trovato.stato.toUpperCase() : "";
                                                        if (isProprietario && statoTrovato === "RICHIESTO") {
                                                            popupRitiraRiposo.dataCella      = dataFinale
                                                            popupRitiraRiposo.dataMaturazione = trovato.maturato ? trovato.maturato : ""
                                                            popupRitiraRiposo.idRiposoTarget  = trovato.id_riposo ? trovato.id_riposo : 0
                                                            popupRitiraRiposo.open()
                                                        } else {
                                                            let dataMat = trovato.maturato ? trovato.maturato : "N.D.";
                                                            globalErrorLabel.text = "Attenzione: è presente un " + tipo + "\nmaturato il: " + dataMat + ".\nDevi prima rimuoverlo."
                                                            globalErrorPopup.open()
                                                        }
                                                    }
                                                } else {
                                                    let riga = utenteDellaRiga.trim().toUpperCase();
                                                    let loggato = paginaSpecchio.utente.trim().toUpperCase();
                                                    let paroleLoggato = loggato.split(" ");
                                                    let corrisponde = paroleLoggato.length > 0 && paroleLoggato.every(parola => riga.includes(parola));
                                                    if (corrisponde) {
                                                        popupSceltaAzione.dataSelezionata = dataFinale
                                                        popupSceltaAzione.open()
                                                    }
                                                }
                                            }
                                        }

                                        Label {
                                            id: labelTesto
                                            anchors.centerIn: parent;
                                            font.bold: true
                                            font.pixelSize: 14
                                            text: {
                                                let trovato = cellaDelegata.helper.cerca();
                                                return (trovato && trovato.a !== undefined) ? trovato.a : "";
                                            }

                                            color: {
                                                let trovato = cellaDelegata.helper.cerca();
                                                if (!trovato) return "#4CAF50";
                                                if (!trovato.tipo) return trovato.colore;
                                                let t = trovato.tipo.toUpperCase()
                                                if (t.indexOf("SETTIMANALE") !== -1) return "#F44336"; // Rosso
                                                if (t.indexOf("FESTIVO") !== -1)     return "#FF9800"; // Arancio
                                                if (t.indexOf("MEDICO") !== -1)      return "#2196F3"; // Blu
                                                if (t.indexOf("STUDIO") !== -1)      return "#333333"; // Nero
                                                if (t.indexOf("SANGUE") !== -1)      return "#8B4513"; // MARRONE
                                                if (t.indexOf("LICENZA") !== -1) {
                                                    let codA = trovato.a ? trovato.a.toUpperCase() : "";
                                                    if (codA === "MAT") return "#00BCD4"; 
                                                    if (codA === "POM") return "#00BCD4"; // Ciano acceso - Pomeriggio
                                                    return "#9C27B0"; // Viola - LICENZA generica
                                                }
                                                return "#4CAF50"; // Verde
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 120
                    color: "#f4f4f4"
                    visible: paginaSpecchio.adminIDs.includes(paginaSpecchio.idDatabase.toString()) // Visibile solo agli admin

                    Column {
                        anchors.centerIn: parent
                        spacing: 8

                        Label {
                            text: "Azioni Rapide per Admin"
                            font.bold: true
                            anchors.horizontalCenter: parent.horizontalCenter
                        }

                       Row {
                            spacing: 20
                            anchors.horizontalCenter: parent.horizontalCenter

                            Button {
                                text: "Approva Richieste Riposi"
                                font.bold: true
                                font.pixelSize: 13
                                contentItem: Text {
                                    text: parent.text
                                    font: parent.font
                                    color: "white"
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                                background: Rectangle {
                                    radius: 7
                                    color: parent.down ? "#1b5e20" : parent.hovered ? "#2e7d32" : "#388E3C"
                                    border.color: "#1b5e20"
                                    border.width: 2
                                }
                                onClicked: {
                                    let lista = [];
                                    function parseDataLocale(d) {
                                        if (!d) return null;
                                        let dateObj = new Date(d);
                                        if (typeof d === "string" && d.includes("-")) {
                                            let parti = d.split("-");
                                            if (parti[0].length === 4) {
                                                dateObj = new Date(parseInt(parti[0]), parseInt(parti[1]) - 1, parseInt(parti[2]));
                                            }
                                        }
                                        if (isNaN(dateObj.getTime())) return null;
                                        dateObj.setHours(0, 0, 0, 0);
                                        return dateObj;
                                    }
                                    let dInizio = parseDataLocale(Backend.inizioBlocco);
                                    let dFine = parseDataLocale(Backend.fineBlocco);
                                    for (let i = 0; i < paginaSpecchio.datiRiposi.length; i++) {
                                        let item = paginaSpecchio.datiRiposi[i];
                                        if (!item) continue;
                                        let annoCorrente = parseInt(comboAnno.currentText);
                                        let meseCorrente = parseInt(comboMese.valoreMese) - 1;
                                        let giornoCorrente = parseInt(item.d);
                                        let dataItem = new Date(annoCorrente, meseCorrente, giornoCorrente);
                                        dataItem.setHours(0, 0, 0, 0);
                                        let statoNormalizzato = item.stato ? item.stato.toString().toUpperCase() : "";
                                        let codA = (item.a || "").toUpperCase()
                                        let escluso = ["LS","CP","104","CIT"].indexOf(codA) >= 0 || codA.startsWith("LO")
                                        if (!escluso &&
                                            (statoNormalizzato === "RICHIESTO" || statoNormalizzato === "PENDENTE") &&
                                            dataItem >= dInizio && dataItem <= dFine && item.id_riposo) {
                                            lista.push({
                                                id_riposo:   Number(item.id_riposo),
                                                id_reale:    item.id_reale,
                                                utente:      item.u,
                                                giorno:      item.d,
                                                tipo:        item.tipo,
                                                codice_a:    item.a || "",
                                                selezionato: false
                                            });
                                        }
                                    }
                                    if (lista.length === 0) {
                                        globalErrorLabel.text = "Nessuna richiesta da approvare nel periodo blocco.";
                                        globalErrorPopup.open();
                                    } else {
                                        popupApprovaSelettivo.listaRichieste = lista;
                                        popupApprovaSelettivo.open();
                                    }
                                }
                            }
                            Button {
                                text: " Stampa PDF"
                                font.bold: true
                                font.pixelSize: 13
                                contentItem: Text {
                                    text: parent.text
                                    font: parent.font
                                    color: "white"
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                                background: Rectangle {
                                    radius: 7
                                    color: parent.down ? "#0d47a1" : parent.hovered ? "#1565C0" : "#1976D2"
                                    border.color: "#0d47a1"
                                    border.width: 2
                                }
                                onClicked: {
                                    let inizio = Backend.inizioBlocco
                                    let fine = Backend.fineBlocco
                                    console.log("DEBUG PDF - inizio:", inizio, "fine:", fine)
                                    console.log("DEBUG PDF - utenti:", paginaSpecchio.listaUtenti.length)
                                    console.log("DEBUG PDF - dati:", paginaSpecchio.datiRiposi.length)
                                    if (!inizio || inizio === "" || inizio === "2000-01-01") {
                                        globalErrorLabel.text = "Nessun periodo blocco attivo. Configura prima il blocco."
                                        globalErrorPopup.open()
                                        return
                                    }
                                    Backend.generaPDF (
                                        paginaSpecchio.listaUtenti,
                                        paginaSpecchio.datiRiposi,
                                        paginaSpecchio.totalDays,
                                        inizio,
                                        fine                                    
                                    )
                                }
                            }


                            Button {
                                text: "Rifiuta Richieste Riposi"
                                font.bold: true
                                font.pixelSize: 13
                                contentItem: Text {
                                    text: parent.text
                                    font: parent.font
                                    color: "white"
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                                background: Rectangle {
                                    radius: 7
                                    color: parent.down ? "#7f1d1d" : parent.hovered ? "#b91c1c" : "#dc2626"
                                    border.color: "#7f1d1d"
                                    border.width: 2
                                }
                                onClicked: {
                                    let lista = [];
                                    function resetTime(d) {
                                        if (!d) return null;
                                        let date = new Date(d);
                                        date.setHours(0, 0, 0, 0);
                                        return date;
                                    }
                                    let dInizio = resetTime(Backend.inizioBlocco);
                                    let dFine = resetTime(Backend.fineBlocco);
                                    for(let i=0; i < paginaSpecchio.datiRiposi.length; i++) {
                                        let item = paginaSpecchio.datiRiposi[i];
                                        if (!item) continue;
                                        let annoCorrente = parseInt(comboAnno.currentText);
                                        let meseCorrente = parseInt(comboMese.valoreMese) - 1; 
                                        let giornoCorrente = parseInt(item.d); 
                                        let dataItem = new Date(annoCorrente, meseCorrente, giornoCorrente);
                                        dataItem.setHours(0, 0, 0, 0);
                                        let statoN = item.stato ? item.stato.toString().toUpperCase() : "";
                                        let codARif = (item.a || "").toUpperCase()
                                        let esclusoRif = ["LS","CP","104","CIT"].indexOf(codARif) >= 0 || codARif.startsWith("LO")
                                        if (!esclusoRif &&
                                            (statoN === "RICHIESTO" || statoN === "PENDENTE") &&
                                            dataItem >= dInizio && dataItem <= dFine && item.id_riposo) {
                                            lista.push({
                                                id_riposo:  Number(item.id_riposo),
                                                id_reale:   item.id_reale,
                                                utente:     item.u,
                                                giorno:     item.d,
                                                tipo:       item.tipo,
                                                codice_a:    item.a || "",
                                                selezionato: false
                                            });
                                        }
                                    }
                                    if (lista.length === 0) {
                                        globalErrorLabel.text = "Nessuna richiesta da rifiutare nel periodo blocco.";;
                                        globalErrorPopup.open();
                                    } else {
                                        popupRifiutoSelettivo.listaRichieste = lista;
                                        popupRifiutoSelettivo.open();
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ===== POPUP SELEZIONE AZIONE =====
            Popup {
                id: popupSceltaAzione
                anchors.centerIn: parent
                width: Math.min(parent.width * 0.85, 300)
                modal: true
                focus: true
                closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
                property string dataSelezionata: ""

                background: Rectangle {
                    radius: 12; color: "white"
                    border.color: "#1565C0"; border.width: 2
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 10

                    Label {
                        text: "Cosa vuoi inserire?"
                        font.bold: true; font.pixelSize: 15; color: "#1565C0"
                        Layout.alignment: Qt.AlignHCenter
                    }
                    Label {
                        text: popupSceltaAzione.dataSelezionata
                        font.pixelSize: 11; color: "#888"
                        Layout.alignment: Qt.AlignHCenter
                    }
                    Rectangle { height: 1; Layout.fillWidth: true; color: "#e0e0e0" }

                    Button {
                        text: "  LICENZE"
                        Layout.fillWidth: true; implicitHeight: 44
                        font.bold: true; font.pixelSize: 14
                        contentItem: Text { text: parent.text; font: parent.font; color: "#1565C0"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        background: Rectangle { radius: 8; color: parent.down ? "#dbeafe" : parent.hovered ? "#eef6ff" : "white"; border.color: "#1565C0"; border.width: 2 }
                        onClicked: {
                            popupLicenza.dataSelezionata = popupSceltaAzione.dataSelezionata
                            popupLicenza.campoCodice.text = ""
                            popupSceltaAzione.close()
                            popupLicenza.open()
                        }
                    }

                    Button {
                        text: "  RIPOSI"
                        Layout.fillWidth: true; implicitHeight: 44
                        font.bold: true; font.pixelSize: 14
                        contentItem: Text { text: parent.text; font: parent.font; color: "#388E3C"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        background: Rectangle { radius: 8; color: parent.down ? "#e8f5e9" : parent.hovered ? "#f1fdf3" : "white"; border.color: "#388E3C"; border.width: 2 }
                        onClicked: {
                            popupSceltaAzione.close()
                            stack.push(fruizionePage, {
                                "idDatabase": paginaSpecchio.idDatabase,
                                "dataPreimpostata": popupSceltaAzione.dataSelezionata
                            })
                        }
                    }

                    Button {
                        text: "  PREFERENZE"
                        Layout.fillWidth: true; implicitHeight: 44
                        font.bold: true; font.pixelSize: 14
                        contentItem: Text { text: parent.text; font: parent.font; color: "#E65100"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        background: Rectangle { radius: 8; color: parent.down ? "#fff3e0" : parent.hovered ? "#fff8f0" : "white"; border.color: "#E65100"; border.width: 2 }
                        onClicked: {
                            popupPreferenze.dataSelezionata = popupSceltaAzione.dataSelezionata
                            popupSceltaAzione.close()
                            popupPreferenze.open()
                        }
                    }

                    Button {
                        text: "ANNULLA"
                        Layout.fillWidth: true; implicitHeight: 36
                        font.pixelSize: 13
                        onClicked: popupSceltaAzione.close()
                    }
                }
            }
            // ===== POPUP RITIRA RIPOSO (riporta RICHIESTO → ACQUISITO) =====
            Popup {
                id: popupRitiraRiposo
                anchors.centerIn: parent
                width: Math.min(parent.width * 0.85, 300)
                modal: true
                focus: true
                closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
                property string dataCella: ""
                property string dataMaturazione: ""
                property int    idRiposoTarget: 0

                background: Rectangle {
                    radius: 12; color: "white"
                    border.color: "#ef4444"; border.width: 2
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 10

                    Label {
                        text: "Ritira Richiesta Riposo"
                        font.bold: true; font.pixelSize: 15; color: "#ef4444"
                        Layout.alignment: Qt.AlignHCenter
                    }
                    Label {
                        text: "Data fruizione: " + popupRitiraRiposo.dataCella
                        font.pixelSize: 12; color: "#555"
                        Layout.alignment: Qt.AlignHCenter
                    }
                    Label {
                        text: "Maturato il: " + popupRitiraRiposo.dataMaturazione
                        font.pixelSize: 12; color: "#555"
                        Layout.alignment: Qt.AlignHCenter
                    }
                    Rectangle { height: 1; Layout.fillWidth: true; color: "#e0e0e0" }
                    Label {
                        text: "Il riposo tornerà DISPONIBILE nella pagina Fruizione."
                        font.pixelSize: 11; color: "#888"; font.italic: true
                        wrapMode: Text.WordWrap; Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                    }
                    Button {
                        text: "  CONFERMA RITIRO"
                        Layout.fillWidth: true; implicitHeight: 44
                        font.bold: true; font.pixelSize: 14
                        contentItem: Text { text: parent.text; font: parent.font; color: "white"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        background: Rectangle { radius: 8; color: parent.down ? "#b91c1c" : parent.hovered ? "#dc2626" : "#ef4444"; border.color: "#7f1d1d"; border.width: 2 }
                        onClicked: {
                            if (Backend.isOperazioneBloccata(paginaSpecchio.idDatabase, popupRitiraRiposo.dataCella)) {
                                popupRitiraRiposo.close()
                                return
                            }
                            Backend.modificaRiposo(paginaSpecchio.idDatabase, popupRitiraRiposo.dataMaturazione, 0, 0)
                            popupRitiraRiposo.close()
                        }
                    }
                    Button {
                        text: "ANNULLA"; Layout.fillWidth: true; implicitHeight: 36
                        font.pixelSize: 13
                        onClicked: popupRitiraRiposo.close()
                    }
                }
            }

            // ===== POPUP INSERIMENTO LICENZA (testo libero max 5 char) =====
            Popup {
                id: popupLicenza
                anchors.centerIn: parent
                width: Math.min(parent.width * 0.85, 280)
                modal: true; focus: true
                closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
                property string dataSelezionata: ""
                property alias campoCodice: inputCodice

                background: Rectangle { radius: 10; color: "white"; border.color: "#2196F3"; border.width: 2 }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 12

                    Label {
                        text: "Inserisci Licenza"
                        font.bold: true; font.pixelSize: 14
                        Layout.alignment: Qt.AlignHCenter
                    }
                    Label {
                        text: popupLicenza.dataSelezionata
                        font.pixelSize: 11; color: "#888"
                        Layout.alignment: Qt.AlignHCenter
                    }
                    TextField {
                        id: inputCodice
                        placeholderText: "Es: LO, LS ..."
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        maximumLength: 5
                        font.pixelSize: 16; font.bold: true
                    }
                    RowLayout {
                        Layout.fillWidth: true; spacing: 8
                        Button {
                            text: "SALVA"; Layout.fillWidth: true
                            font.bold: true
                            contentItem: Text { text: parent.text; font: parent.font; color: "white"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                            background: Rectangle { radius: 7; color: parent.down ? "#0d47a1" : parent.hovered ? "#1976D2" : "#1565C0"; border.color: "#0d47a1"; border.width: 2 }
                            onClicked: {
                                if (inputCodice.text.trim() === "") return
                                Backend.salvaLicenzaPersonale(paginaSpecchio.idDatabase, popupLicenza.dataSelezionata, inputCodice.text)
                                popupLicenza.close()
                            }
                        }
                        Button {
                            text: "ANNULLA"; Layout.fillWidth: true
                            onClicked: popupLicenza.close()
                        }
                    }
                }
            }

            // ===== POPUP PREFERENZE (MAT / POM) =====
            Popup {
                id: popupPreferenze
                anchors.centerIn: parent
                width: Math.min(parent.width * 0.85, 300)
                modal: true; focus: true
                closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
                property string dataSelezionata: ""

                background: Rectangle { radius: 12; color: "white"; border.color: "#E65100"; border.width: 2 }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    Label {
                        text: "Inserisci Preferenza"
                        font.bold: true; font.pixelSize: 15; color: "#E65100"
                        Layout.alignment: Qt.AlignHCenter
                    }
                    Label {
                        text: popupPreferenze.dataSelezionata
                        font.pixelSize: 11; color: "#888"
                        Layout.alignment: Qt.AlignHCenter
                    }
                    Label {
                        text: "Stato: PENDENTE (in attesa di approvazione)"
                        font.pixelSize: 11; color: "#F57C00"; font.italic: true
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                    }
                    Rectangle { height: 1; Layout.fillWidth: true; color: "#e0e0e0" }

                    Button {
                        text: "  MAT  (Mattino)"
                        Layout.fillWidth: true; implicitHeight: 48
                        font.bold: true; font.pixelSize: 15
                        contentItem: Text { text: parent.text; font: parent.font; color: "white"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        background: Rectangle { radius: 8; color: parent.down ? "#006064" : parent.hovered ? "#0097A7" : "#00BCD4"; border.color: "#006064"; border.width: 2 }
                        onClicked: {
                            Backend.salvaLicenzaPersonale(paginaSpecchio.idDatabase, popupPreferenze.dataSelezionata, "MAT")
                            popupPreferenze.close()
                        }
                    }

                    Button {
                        text: "  POM  (Pomeriggio)"
                        Layout.fillWidth: true; implicitHeight: 48
                        font.bold: true; font.pixelSize: 15
                        contentItem: Text { text: parent.text; font: parent.font; color: "white"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        background: Rectangle { radius: 8; color: parent.down ? "#006064" : parent.hovered ? "#0097A7" : "#00BCD4"; border.color: "#006064"; border.width: 2 }
                        onClicked: {
                            Backend.salvaLicenzaPersonale(paginaSpecchio.idDatabase, popupPreferenze.dataSelezionata, "POM")
                            popupPreferenze.close()
                        }
                    }

                    Button {
                        text: "ANNULLA"; Layout.fillWidth: true; implicitHeight: 36
                        font.pixelSize: 13
                        onClicked: popupPreferenze.close()
                    }
                }
            }
            Popup {
                id: popupProfiloAltro
                anchors.centerIn: Overlay.overlay
                width: Math.min(window.width * 0.92, 500)
                height: Math.min(window.height * 0.88, 700)
                modal: true
                focus: true
                closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

                property string nomeUtente: ""
                property string idUtente: ""
                property var storicoBadge: []
                property var riposiAnnuali: []
                property double oreStr: 0.0
                property bool caricamentoBadge: false
                property bool caricamentoRiposi: false
                property bool caricamentoOre: false
                readonly property bool isLoading: caricamentoBadge || caricamentoRiposi || caricamentoOre
                property var badgeMeseCorrente: ({ nome: "", livello: 0, colore: "#888" })
                property var badgeAggregati: []

                function aggiornaDati() {
                    var meseCor = new Date().getMonth() + 1
                    var best = { nome: "", livello: 0, colore: "#888" }
                    for (var i = 0; i < storicoBadge.length; i++) {
                        var b = storicoBadge[i]
                        if (b.mese === meseCor && b.livello >= best.livello) best = b
                    }
                    badgeMeseCorrente = best

                    var mappa = {}
                    for (var j = 0; j < storicoBadge.length; j++) {
                        var bj = storicoBadge[j]
                        if (!mappa[bj.nome_badge])
                            mappa[bj.nome_badge] = { nome: bj.nome_badge, livello: bj.livello, colore: bj.colore, count: 0 }
                        mappa[bj.nome_badge].count += (bj.occorrenze || 1)
                    }
                    badgeAggregati = Object.values(mappa)
                }

                onStoricoBadgeChanged: aggiornaDati()

                Connections {
                    target: Backend
                    function onProfiloAltroStoricoBadge(lista) {
                        popupProfiloAltro.storicoBadge = lista
                        popupProfiloAltro.caricamentoBadge = false
                    }
                    function onProfiloAltroRiposiAnnuali(lista) {
                        popupProfiloAltro.riposiAnnuali = lista
                        popupProfiloAltro.caricamentoRiposi = false
                    }
                    function onProfiloAltroOreStr(totale) {
                        popupProfiloAltro.oreStr = totale
                        popupProfiloAltro.caricamentoOre = false
                    }
                }

                background: Rectangle {
                    radius: 12
                    color: "white"
                    border.color: "#1565C0"
                    border.width: 2
                }
                ScrollView {
                    anchors.fill: parent
                    clip: true
                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 14

                        // INTESTAZIONE
                        Item {
                            Layout.fillWidth: true
                            height: nameLabel.implicitHeight
                            Label {
                                id: nameLabel
                                text: "  " + popupProfiloAltro.nomeUtente
                                font.bold: true
                                font.pixelSize: 18
                                color: "#1565C0"
                                anchors.horizontalCenter: parent.horizontalCenter
                                opacity: 0
                                y: -10
                                SequentialAnimation {
                                    running: popupProfiloAltro.visible
                                    ParallelAnimation {
                                        NumberAnimation { target: nameLabel; property: "opacity"; to: 1.0; duration: 400; easing.type: Easing.OutCubic }
                                        NumberAnimation { target: nameLabel; property: "y"; to: 0; duration: 400; easing.type: Easing.OutCubic }
                                    }
                                }
                            }
                        }
                        Rectangle { height: 1; Layout.fillWidth: true; color: "#1565C0"; opacity: 0.3 }

                        // LOADING
                        Label {
                            visible: popupProfiloAltro.isLoading
                            text: "⏳ Caricamento..."
                            color: "#888"
                            font.pixelSize: 13
                            Layout.alignment: Qt.AlignHCenter
                            SequentialAnimation on opacity {
                                loops: Animation.Infinite
                                running: popupProfiloAltro.isLoading
                                NumberAnimation { to: 0.3; duration: 500 }
                                NumberAnimation { to: 1.0; duration: 500 }
                            }
                        }

                        // BADGE MESE CORRENTE
                        Rectangle {
                            id: rectBadgeMese
                            Layout.fillWidth: true
                            height: 70
                            radius: 10
                            visible: !popupProfiloAltro.isLoading && popupProfiloAltro.badgeMeseCorrente.livello > 0
                            color: popupProfiloAltro.badgeMeseCorrente.colore !== ""
                                ? popupProfiloAltro.badgeMeseCorrente.colore : "#eeeeee"
                            border.color: popupProfiloAltro.badgeMeseCorrente.livello === 3 ? "#00bcd4"
                                        : Qt.darker(popupProfiloAltro.badgeMeseCorrente.colore || "#aaa", 1.3)
                            border.width: 2

                            SequentialAnimation on border.color {
                                loops: Animation.Infinite
                                running: popupProfiloAltro.visible && popupProfiloAltro.badgeMeseCorrente.livello === 3
                                ColorAnimation { to: "#00bcd4"; duration: 900 }
                                ColorAnimation { to: "#e0f7fa"; duration: 900 }
                            }
                            opacity: 1
                            SequentialAnimation on border.width {
                                loops: Animation.Infinite
                                running: popupProfiloAltro.visible && popupProfiloAltro.badgeMeseCorrente.livello > 0
                                NumberAnimation { to: 3; duration: 800; easing.type: Easing.InOutSine }
                                NumberAnimation { to: 1; duration: 800; easing.type: Easing.InOutSine }
                            }

                            Row {
                                anchors.centerIn: parent
                                spacing: 12

                                AnimatedImage {
                                    width: 54; height: 54
                                    fillMode: Image.PreserveAspectFit
                                    playing: popupProfiloAltro.visible
                                    source: popupProfiloAltro.visible && (popupProfiloAltro.badgeMeseCorrente.nome_badge || popupProfiloAltro.badgeMeseCorrente.nome || "") !== ""
                                            ? popupDettaglioBadge.gifPerBadge(popupProfiloAltro.badgeMeseCorrente.nome_badge || popupProfiloAltro.badgeMeseCorrente.nome || "") : ""
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 2
                                    Text {
                                        text: popupProfiloAltro.badgeMeseCorrente.nome_badge
                                            || popupProfiloAltro.badgeMeseCorrente.nome || ""
                                        font.pixelSize: 20; font.bold: true
                                        color: popupProfiloAltro.badgeMeseCorrente.livello === 3 ? "#003344" : "white"
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                    Text {
                                        text: "BADGE DEL MESE  •  " + (
                                            popupProfiloAltro.badgeMeseCorrente.livello === 1 ? "▲ ARGENTO"
                                            : popupProfiloAltro.badgeMeseCorrente.livello === 2 ? "★ ORO"
                                            : "◆ DIAMANTE")
                                        font.pixelSize: 11
                                        color: popupProfiloAltro.badgeMeseCorrente.livello === 3 ? "#005577" : "white"
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        opacity: 0.9
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    var b = popupProfiloAltro.badgeMeseCorrente
                                    popupDettaglioBadge.nomeBadge    = b.nome_badge || b.nome || ""
                                    popupDettaglioBadge.livelloBadge = b.livello
                                    popupDettaglioBadge.coloreBadge  = b.colore
                                    popupDettaglioBadge.open()
                                }
                            }
                        }

                        // Nessun badge mese
                        Label {
                            visible: !popupProfiloAltro.isLoading && popupProfiloAltro.badgeMeseCorrente.livello === 0
                            text: "Nessun badge questo mese"
                            color: "gray"; font.pixelSize: 12; font.italic: true
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Rectangle { height: 1; Layout.fillWidth: true; color: "#e0e0e0" }

                        // BADGE GUADAGNATI QUEST'ANNO
                        Label {
                            text: "BADGE GUADAGNATI QUEST'ANNO"
                            font.bold: true; font.pixelSize: 13; color: "#333"
                        }

                        ListView {
                            Layout.fillWidth: true
                            Layout.preferredHeight: popupProfiloAltro.badgeAggregati.length > 0 ? Math.min(popupProfiloAltro.badgeAggregati.length * 38 + 4, 150) : 0
                            clip: true
                            model: popupProfiloAltro.badgeAggregati
                            delegate: Rectangle {
                                width: parent.width
                                height: 34
                                radius: 6
                                color: index % 2 === 0 ? "#f5f8ff" : "white"
                                border.color: "#e0e0e0"; border.width: 1
                                opacity: 1
                                Row {
                                    anchors.fill: parent; anchors.margins: 8; spacing: 10
                                    Text {
                                        text: modelData.nome
                                        font.bold: true; font.pixelSize: 13; color: "#222"
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    Text {
                                        text: "x" + modelData.count + " volte"
                                        font.pixelSize: 12; color: "#1565C0"; font.bold: true
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        popupDettaglioBadge.nomeBadge    = modelData.nome
                                        popupDettaglioBadge.livelloBadge = modelData.livello
                                        popupDettaglioBadge.coloreBadge  = modelData.colore
                                        popupDettaglioBadge.open()
                                    }
                                }
                            }
                        }

                        Label {
                            visible: !popupProfiloAltro.isLoading && popupProfiloAltro.badgeAggregati.length === 0
                            text: "Nessun badge questo anno"
                            color: "gray"; font.pixelSize: 12; font.italic: true
                        }

                        Rectangle { height: 1; Layout.fillWidth: true; color: "#e0e0e0" }

                        // STRAORDINARI QUEST'ANNO
                        Label {
                            text: "STRAORDINARI QUEST'ANNO"
                            font.bold: true; font.pixelSize: 13; color: "#333"
                        }
                        Rectangle {
                            id: rectOreAltro
                            Layout.fillWidth: true; height: 40; radius: 8
                            color: "#E3F2FD"; border.color: "#2196F3"; border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: popupProfiloAltro.oreStr.toFixed(1) + " ore totali"
                                font.bold: true; font.pixelSize: 15; color: "#1565C0"
                            }
                        }

                        Rectangle { height: 1; Layout.fillWidth: true; color: "#e0e0e0" }

                        // RIPOSI PER TIPO
                        Label {
                            text: "RIPOSI FRUITI QUEST'ANNO PER TIPO"
                            font.bold: true; font.pixelSize: 13; color: "#333"
                        }

                        ListView {
                            Layout.fillWidth: true
                            Layout.preferredHeight: popupProfiloAltro.riposiAnnuali.length > 0 ? Math.min(popupProfiloAltro.riposiAnnuali.length * 38 + 4, 160) : 0
                            clip: true
                            model: {
                                var mappa = {}
                                for (var j = 0; j < popupProfiloAltro.riposiAnnuali.length; j++) {
                                    var r = popupProfiloAltro.riposiAnnuali[j]
                                    var nota = (r.a || "").toUpperCase()
                                    if (nota.includes("MAT") || nota.includes("CIT") ||
                                        nota.includes("POM") || nota.includes("SER")) continue
                                    var tipo = r.tipo || "SCONOSCIUTO"
                                    mappa[tipo] = (mappa[tipo] || 0) + 1
                                }
                                return Object.keys(mappa).map(function(k) { return { tipo: k, count: mappa[k] } })
                            }
                            delegate: Rectangle {
                                width: parent.width; height: 34; radius: 6
                                color: index % 2 === 0 ? "#f5f8ff" : "white"
                                border.color: "#e0e0e0"; border.width: 1
                                opacity: 1
                                Row {
                                    anchors.fill: parent; anchors.margins: 8; spacing: 10
                                    Text {
                                        text: modelData.tipo; font.pixelSize: 12; color: "#444"
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    Text {
                                        text: modelData.count + " giorni"
                                        font.bold: true; font.pixelSize: 12; color: "#388E3C"
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }
                            }
                        }

                        Label {
                            visible: !popupProfiloAltro.isLoading && popupProfiloAltro.riposiAnnuali.length === 0
                            text: "Nessun riposo registrato"
                            color: "gray"; font.pixelSize: 12; font.italic: true
                        }

                        Button {
                            text: "CHIUDI"
                            Layout.fillWidth: true
                            onClicked: popupProfiloAltro.close()
                        }
                    }
                }
            }

            Dialog {
                id: popupEliminaLicenza
                x: (parent.width - width) / 2
                y: (parent.height - height) / 2
                width: 300
                title: "Gestione Licenza"
                modal: true
                focus: true

                property string dataSelezionata: ""
                property var idUtenteSelezionato: 0// Variabile per memorizzare la data cliccata

                Column {
                    spacing: 20
                    width: parent.width
                    topPadding: 10

                    Text {
                        text: "Vuoi eliminare la licenza del \n" + popupEliminaLicenza.dataSelezionata + "?"
                        horizontalAlignment: Text.AlignHCenter
                        width: parent.width
                        font.pixelSize: 16
                    }

                    Row {
                        spacing: 10
                        anchors.horizontalCenter: parent.horizontalCenter

                        Button {
                            text: "ANNULLA"
                            onClicked: popupEliminaLicenza.close()
                        }

                        Button {
                            text: "ELIMINA"
                            highlighted: true
                            onClicked: {
                                // Chiamata al C++ (formattando la data se necessario)
                                console.log("Elimino per ID:", popupEliminaLicenza.idUtenteSelezionato)
                                Backend.cancellaLicenza(popupEliminaLicenza.idUtenteSelezionato.toString(), popupEliminaLicenza.dataSelezionata, "LICENZA")
                                popupEliminaLicenza.close()
                                // Opzionale: ricarica lo specchio dopo un breve delay
                            }
                        }
                    }
                }
            }
            Popup {
                id: popupRifiutoSelettivo
                anchors.centerIn: parent
                width: parent.width * 0.92
                modal: true
                focus: true
                closePolicy: Popup.NoAutoClose
                property var listaRichieste: []
                background: Rectangle {
                    radius: 10
                    border.color: "#d32f2f"
                    border.width: 2
                    color: "white"
                }
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    Label {
                        text: " Seleziona le richieste da RIFIUTARE"
                        font.bold: true
                        font.pixelSize: 14
                        color: "#d32f2f"
                        Layout.alignment: Qt.AlignHCenter
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                    }
                    Rectangle { height: 1; Layout.fillWidth: true; color: "#d32f2f"; opacity: 0.4 }
                    ListView {
                        id: listaRifiutoView
                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.min(popupRifiutoSelettivo.listaRichieste.length * 56, 280)
                        clip: true
                        model: popupRifiutoSelettivo.listaRichieste
                        delegate: Rectangle {
                            width: listaRifiutoView.width
                            height: 52
                            color: modelData.selezionato ? "#ffebee" : "white"
                            border.color: "#eee"
                            border.width: 1
                            radius: 4
                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 10
                                CheckBox {
                                    checked: modelData.selezionato
                                    onCheckedChanged: {
                                        let lista = popupRifiutoSelettivo.listaRichieste;
                                        lista[index].selezionato = checked;
                                        popupRifiutoSelettivo.listaRichieste = lista;
                                    }
                                }
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    Label {
                                        text: modelData.utente
                                        font.bold: true
                                        font.pixelSize: 12
                                        Layout.fillWidth: true
                                    }
                                    Label {
                                        text: "Giorno " + modelData.giorno + " — " +
                                            (modelData.tipo === "LICENZA" && modelData.codice_a
                                            ? modelData.codice_a
                                            : modelData.tipo)
                                        font.pixelSize: 11
                                        color: "#666"
                                    }
                                }
                            }
                        }
                    }
                    Rectangle { height: 1; Layout.fillWidth: true; color: "#eee" }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Button {
                            text: "Seleziona tutti"
                            font.pixelSize: 11
                            Layout.fillWidth: true
                            onClicked: {
                                let lista = popupRifiutoSelettivo.listaRichieste;
                                for (let i = 0; i < lista.length; i++) lista[i].selezionato = true;
                                popupRifiutoSelettivo.listaRichieste = lista.slice();
                            }
                        }
                        Button {
                            text: "Deseleziona tutti"
                            font.pixelSize: 11
                            Layout.fillWidth: true
                            onClicked: {
                                let lista = popupRifiutoSelettivo.listaRichieste;
                                for (let i = 0; i < lista.length; i++) lista[i].selezionato = false;
                                popupRifiutoSelettivo.listaRichieste = lista.slice();
                            }
                        }
                    }
                    Button {
                        text: "  RIFIUTA SELEZIONATE"
                        Layout.fillWidth: true
                        palette.button: "#d32f2f"
                        palette.buttonText: "white"
                        font.bold: true
                        onClicked: {
                            let idDaRifiutare = [];
                            let idDestinatario = -1;
                            let lista = popupRifiutoSelettivo.listaRichieste;
                            for (let i = 0; i < lista.length; i++) {
                                if (lista[i].selezionato) {
                                    idDaRifiutare.push(lista[i].id_riposo);
                                    idDestinatario = lista[i].id_reale;
                                }
                            }
                            if (idDaRifiutare.length === 0) {
                                globalErrorLabel.text = "Nessuna richiesta selezionata.";
                                globalErrorPopup.open();
                                return;
                            }
                            Backend.processaValidazioni(idDaRifiutare, false, paginaSpecchio.utente, idDestinatario);
                            popupRifiutoSelettivo.close();
                        }
                    }
                    Button {
                        text: "ANNULLA"
                        Layout.fillWidth: true
                        onClicked: popupRifiutoSelettivo.close()
                    }
                }
            }
            Popup {
                id: popupApprovaSelettivo
                anchors.centerIn: parent
                width: parent.width * 0.92
                modal: true
                focus: true
                closePolicy: Popup.NoAutoClose
                property var listaRichieste: []
                background: Rectangle {
                    radius: 10
                    border.color: "#2e7d32"
                    border.width: 2
                    color: "white"
                }
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    Label {
                        text: " Seleziona le richieste da APPROVARE"
                        font.bold: true
                        font.pixelSize: 14
                        color: "#2e7d32"
                        Layout.alignment: Qt.AlignHCenter
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                    }
                    Rectangle { height: 1; Layout.fillWidth: true; color: "#2e7d32"; opacity: 0.4 }
                    ListView {
                        id: listaApprovaView
                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.min(popupApprovaSelettivo.listaRichieste.length * 56, 280)
                        clip: true
                        model: popupApprovaSelettivo.listaRichieste
                        delegate: Rectangle {
                            width: listaApprovaView.width
                            height: 52
                            color: modelData.selezionato ? "#e8f5e9" : "white"
                            border.color: "#eee"
                            border.width: 1
                            radius: 4
                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 10
                                CheckBox {
                                    checked: modelData.selezionato
                                    onCheckedChanged: {
                                        let lista = popupApprovaSelettivo.listaRichieste;
                                        lista[index].selezionato = checked;
                                        popupApprovaSelettivo.listaRichieste = lista.slice();
                                    }
                                }
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    Label {
                                        text: modelData.utente
                                        font.bold: true
                                        font.pixelSize: 12
                                        Layout.fillWidth: true
                                    }
                                    Label {
                                        text: "Giorno " + modelData.giorno + " — " +
                                            (modelData.tipo === "LICENZA" && modelData.codice_a
                                            ? modelData.codice_a
                                            : modelData.tipo)
                                        font.pixelSize: 11
                                        color: "#666"
                                    }
                                }
                            }
                        }
                    }
                    Rectangle { height: 1; Layout.fillWidth: true; color: "#eee" }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Button {
                            text: "Seleziona tutti"
                            font.pixelSize: 11
                            Layout.fillWidth: true
                            onClicked: {
                                let lista = popupApprovaSelettivo.listaRichieste;
                                for (let i = 0; i < lista.length; i++) lista[i].selezionato = true;
                                popupApprovaSelettivo.listaRichieste = lista.slice();
                            }
                        }
                        Button {
                            text: "Deseleziona tutti"
                            font.pixelSize: 11
                            Layout.fillWidth: true
                            onClicked: {
                                let lista = popupApprovaSelettivo.listaRichieste;
                                for (let i = 0; i < lista.length; i++) lista[i].selezionato = false;
                                popupApprovaSelettivo.listaRichieste = lista.slice();
                            }
                        }
                    }
                    Button {
                        text: "  APPROVA SELEZIONATE"
                        Layout.fillWidth: true
                        palette.button: "#2e7d32"
                        palette.buttonText: "white"
                        font.bold: true
                        onClicked: {
                            let idDaApprovare = [];
                            let idDestinatario = -1;
                            let lista = popupApprovaSelettivo.listaRichieste;
                            for (let i = 0; i < lista.length; i++) {
                                if (lista[i].selezionato) {
                                    idDaApprovare.push(lista[i].id_riposo);
                                    idDestinatario = lista[i].id_reale;
                                }
                            }
                            if (idDaApprovare.length === 0) {
                                globalErrorLabel.text = "Nessuna richiesta selezionata.";
                                globalErrorPopup.open();
                                return;
                            }
                            Backend.processaValidazioni(idDaApprovare, true, paginaSpecchio.utente, idDestinatario);
                            popupApprovaSelettivo.close();
                        }
                    }
                    Button {
                        text: "ANNULLA"
                        Layout.fillWidth: true
                        onClicked: popupApprovaSelettivo.close()
                    }
                }
            }


            Connections {
                target: Backend
                function onSpecchioRicevuto(lista, giorniMese) {
                    paginaSpecchio.datiRiposi = lista
                    let ids = []
                    for (let i = 0; i < lista.length; i++) {
                        let idAttuale = lista[i].u;
                        if (ids.indexOf(idAttuale) === -1) {
                            ids.push(idAttuale)
                        }
                    }
                    paginaSpecchio.listaUtenti = ids
                    paginaSpecchio.totalDays = giorniMese
                }
                function onOperazioneCompletata(messaggio) {
                    let m = paginaSpecchio.meseSelezionato;
                    let a = paginaSpecchio.annoSelezionato;
                    let ultimo = new Date(a, m, 0).getDate();
                    Backend.caricaSpecchioAdmin("01-" + m + "-" + a, ultimo + "-" + m + "-" + a)
                    popupLicenza.close()
                    popupPreferenze.close()
                    popupEliminaLicenza.close()
                    popupRitiraRiposo.close()
                }
            }
        }
    }



    Component {
        id: inserimentoPage
        Page {
            id: paginaInserimento
            property string idDatabase: ""

            header: ToolBar {
                RowLayout {
                    anchors.fill: parent
                    ToolButton { text: "‹"; onClicked: stack.pop() }
                    Label { text: "Nuovo Riposo"; Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter }
                }
            }

            ColumnLayout {
                anchors.centerIn: parent
                width: parent.width * 0.85
                spacing: 20

                Label {
                    text: "INSERISCI DATA (GG-MM-AAAA):"
                    font.bold: true
                    font.pixelSize: 14
                    color: "#333"
                }

                DateMaskField {
                    id: campoDataNuova
                    Layout.fillWidth: true
                    font.pixelSize: 16
                    horizontalAlignment: Text.AlignLeft
                    background: Rectangle {
                        implicitHeight: 45
                        border.color: campoDataNuova.activeFocus ? "#2196F3" : "#bdbebf"
                        border.width: 2
                        radius: 4
                    }
                    verticalAlignment: Text.AlignVCenter
                }
            
                ComboBox {
                    id: comboTipoNuovo
                    model: ["SETTIMANALE", "FESTIVO", "MEDICO", "STUDIO", "SANGUE", "ALTRO"]
                    Layout.fillWidth: true
                    contentItem: Text {
                        leftPadding: 8
                        text: comboTipoNuovo.displayText
                        font.pixelSize: 13; font.bold: true; color: "#1f2937"
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        radius: 6; color: comboTipoNuovo.pressed ? "#dbeafe" : "#ffffff"
                        border.color: comboTipoNuovo.activeFocus ? "#1565C0" : "#7f9fbd"
                        border.width: comboTipoNuovo.activeFocus ? 2 : 1.5
                    }
                    delegate: ItemDelegate {
                        width: comboTipoNuovo.width
                        contentItem: Text {
                            text: modelData
                            color: "#1f2937"
                            font.pixelSize: 13
                            verticalAlignment: Text.AlignVCenter
                            leftPadding: 8
                        }
                        background: Rectangle {
                            color: hovered ? "#dbeafe" : "#ffffff"
                        }
                    }
                }

                Button {
                    text: "SALVA"
                    Layout.fillWidth: true
                    implicitHeight: 46
                    font.pixelSize: 15
                    font.bold: true
                    contentItem: Text {
                        text: parent.text
                        font: parent.font
                        color: "white"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        radius: 8
                        color: parent.down ? "#1b5e20" : parent.hovered ? "#2e7d32" : "#388E3C"
                        border.color: "#1b5e20"
                        border.width: 2
                    }
                    onClicked: Backend.aggiungiRiposo(idDatabase, campoDataNuova.text, comboTipoNuovo.currentIndex + 1)
                }
            }

            Connections {
                target: Backend
                function onOperazioneCompletata(messaggio) {
                    stack.pop() // Torna al menu dopo il salvataggio
                }
            }
        }
    }

    // --- PAGINA 3: LISTA RIPOSI ---
    Component {
            id: riposiPage
            Page {
                id: paginaRiposi
                objectName: "paginaRiposi"
                property string utente: ""
                property string idDatabase: ""
                property bool modalitaInserimento: false
                property var listaModello: []

                Connections {
                    target: Backend
                    function onRiposiRicevuti(lista) {
                        paginaRiposi.listaModello = lista
                    }
                }

                header: ToolBar {
                    RowLayout {
                        anchors.fill: parent
                        ToolButton {
                            text: "‹ Menu"
                            onClicked: stack.pop()
                        }
                        Label {
                            text: "Riposi di: " + utente
                            font.bold: true
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }

                Component.onCompleted: {
                    Backend.caricaRiposiDisponibili(idDatabase)
                    if (modalitaInserimento) popupData.open()
                }

                ListView {
                    id: listViewRiposi
                    anchors.fill: parent
                    anchors.margins: 10
                    model: listaModello // Collegato alla proprietà sopra

                    delegate: ItemDelegate {
                        width: listViewRiposi.width
                        text: "📅 " + modelData // modelData è la stringa della data
                        font.pixelSize: 16

                        background: Rectangle {
                            color: index % 2 === 0 ? "#f9f9f9" : "white"
                            border.color: "#eee"
                        }
                    }
                    Label {
                        anchors.centerIn: parent
                        text: "Nessun riposo trovato per questo CIP"
                        visible: listViewRiposi.count === 0
                        color: "gray"
                    }
                }

                Popup {
                    id: popupData
                    anchors.centerIn: parent; width: parent.width * 0.8; modal: true; focus: true
                    closePolicy: Popup.NoAutoClose // Obblighiamo l'utente a rispondere

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 10
                        Label { text: "Inserisci Data"; font.bold: true }
                        DateMaskField { id: campoData; Layout.fillWidth: true }
                        Label {text: "Tipo di riposo"}
                        ComboBox {
                            id: comboTipo
                            model: ["SETTIMANALE", "FESTIVO", "MEDICO", "STUDIO", "SANGUE", "ALTRO"]
                            Layout.fillWidth: true
                            delegate: ItemDelegate {
                                width: comboTipo.width
                                contentItem: Text {
                                    text: modelData
                                    color: "#1f2937"
                                    font.pixelSize: 13
                                    verticalAlignment: Text.AlignVCenter
                                    leftPadding: 8
                                }
                                background: Rectangle {
                                    color: hovered ? "#dbeafe" : "#ffffff"
                                }
                            }
                        }
                        Button {
                            text: "SALVA"
                            Layout.alignment: Qt.AlignHCenter
                            onClicked: {
                                Backend.aggiungiRiposo(paginaRiposi.idDatabase, campoData.text, comboTipo.currentIndex + 1)
                                popupData.close()
                            }
                        }
                        Button {
                            text: "ANNULLA"
                            onClicked: popupData.close()
                        }
                    }
                }
            }
    }

    Component {
        id: fruizionePage
        Page {
            id: paginaFruizione
            property string idDatabase: ""
            property string dataPreimpostata: ""
            property var listaDisponibili: []
            function formattaData(dataISO) {
                    if (!dataISO) return ""
                    var parti = dataISO.split("-") // Divide "2023-12-31"
                    if (parti.length !== 3) return dataISO
                    return parti[2] + "-" + parti[1] + "-" + parti[0] // Ricompone "31-12-2023"
            }

            header: ToolBar {
                RowLayout {
                    anchors.fill: parent
                    ToolButton { text: "‹"; onClicked: stack.pop() }
                    Label { text: "Seleziona Riposo da Fruire"; Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter }
                }
            }

            Connections {
                target: Backend
                function onRiposiRicevuti(lista) { paginaFruizione.listaDisponibili = lista }
            }

            Component.onCompleted: Backend.caricaRiposiDisponibili(idDatabase)

            ListView {
                anchors.fill: parent
                model: paginaFruizione.listaDisponibili
                delegate: ItemDelegate {
                    width: parent.width
                    height: 70
                    contentItem: Column {
                        spacing: 2
                        Label {
                            text: "Maturato il: " + modelData.dataITA
                            font.bold: true
                            font.pixelSize: 16
                        }
                        Label {
                            text: modelData.dataFruizioneITA !== "" ?
                                  "⚠️ Già richiesto per il: " + modelData.dataFruizioneITA :
                                  " Libero (Nessuna data assegnata)"
                            font.pixelSize: 13
                            color: modelData.dataFruizioneITA !== "" ? "#E64A19" : "#388E3C"
                        }
                    }
                    onClicked: {
                        selectedDataMaturazioneISO.text = modelData.dataISO
                        labelDataMaturazioneBella.text = "Riposo del: " + modelData.dataITA

                        if (paginaFruizione.dataPreimpostata !== "") {
                            // Flusso da SpecchioPage: salva subito con stato RICHIESTO senza popup
                            if (modelData.dataFruizioneITA !== "") {
                                globalErrorLabel.text = "ATTENZIONE: Questo riposo è già assegnato al " + modelData.dataFruizioneITA + ". Se prosegui, la data verrà sovrascritta."
                                var connDiretta = Qt.createQmlObject('import QtQuick; Connections {
                                    target: globalErrorPopup;
                                    function onClosed() {
                                        Backend.fruisciRiposo(paginaFruizione.idDatabase, modelData.dataISO, paginaFruizione.formattaData(paginaFruizione.dataPreimpostata), 1)
                                        stack.pop()
                                        this.destroy();
                                    }
                                }', paginaFruizione);
                                globalErrorPopup.open()
                            } else {
                                Backend.fruisciRiposo(paginaFruizione.idDatabase, modelData.dataISO, paginaFruizione.formattaData(paginaFruizione.dataPreimpostata), 1)
                                stack.pop()
                            }
                        } else {
                            // Flusso manuale: apri popup per inserire data
                            if (modelData.dataFruizioneITA !== "") {
                                dataFruizioneInput.text = modelData.dataFruizioneITA
                                globalErrorLabel.text = "ATTENZIONE: Questo riposo è già assegnato al " + modelData.dataFruizioneITA + ". Se prosegui, la data verrà sovrascritta."
                                var conn = Qt.createQmlObject('import QtQuick; Connections {
                                    target: globalErrorPopup;
                                    function onClosed() {
                                        popupFruisci.open();
                                        this.destroy();
                                    }
                                }', paginaFruizione);
                                globalErrorPopup.open()
                            } else {
                                dataFruizioneInput.text = ""
                                popupFruisci.open()
                            }
                        }
                    }
                }
            }

            Popup {
                id: popupFruisci
                anchors.centerIn: parent
                width: parent.width * 0.9
                modal: true
                background: Rectangle {
                    color: "white"; radius: 10
                    border.color: "#1565C0"; border.width: 2
                }
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 10
                    Text { id: selectedDataMaturazioneISO; visible: false }
                    Label { id: labelDataMaturazioneBella; font.bold: true; horizontalAlignment: Text.AlignHCenter }
                    Label { text: "In quale data vuoi usarlo?" }
                    DateMaskField {
                        id: dataFruizioneInput
                        Layout.fillWidth: true
                        background: Rectangle {
                            implicitHeight: 45
                            border.color: dataFruizioneInput.activeFocus ? "#2196F3" : "#bdbebf"
                            border.width: 2; radius: 4; color: "white"
                        }
                    }
                    ComboBox {
                        id: comboStato
                        model: ["RICHIESTO", "VALIDATO"]
                        Layout.fillWidth: true
                        contentItem: Text {
                            leftPadding: 8; text: comboStato.displayText
                            font.pixelSize: 13; font.bold: true; color: "#1f2937"
                            verticalAlignment: Text.AlignVCenter
                        }
                        background: Rectangle {
                            radius: 6; color: comboStato.pressed ? "#dbeafe" : "#ffffff"
                            border.color: comboStato.activeFocus ? "#1565C0" : "#7f9fbd"
                            border.width: comboStato.activeFocus ? 2 : 1.5
                        }
                        delegate: ItemDelegate {
                            width: comboStato.width
                            contentItem: Text {
                                text: modelData
                                color: "#1f2937"
                                font.pixelSize: 13
                                verticalAlignment: Text.AlignVCenter
                                leftPadding: 8
                            }
                            background: Rectangle {
                                color: hovered ? "#dbeafe" : "#ffffff"
                            }
                        }
                    }
                    Button {
                        text: "CONFERMA FRUIZIONE"
                        Layout.fillWidth: true
                        onClicked: {
                            // Controlla che la data inserita non sia nel passato
                            var parti = dataFruizioneInput.text.split("-")
                            if (parti.length !== 3) {
                                globalErrorLabel.text = "Inserisci una data valida nel formato GG-MM-AAAA."
                                globalErrorPopup.open()
                                return
                            }
                            var dataScelta = new Date(parseInt(parti[2]), parseInt(parti[1]) - 1, parseInt(parti[0]))
                            var oggi = new Date(); oggi.setHours(0,0,0,0)
                            if (dataScelta < oggi) {
                                globalErrorLabel.text = "Non puoi fruire di un giorno in data precedente a oggi."
                                globalErrorPopup.open()
                                return
                            }
                            Backend.fruisciRiposo(idDatabase, selectedDataMaturazioneISO.text, dataFruizioneInput.text, comboStato.currentIndex + 1)
                            popupFruisci.close()
                        }
                    }
                    Button { text: "ANNULLA"; Layout.fillWidth: true; onClicked: popupFruisci.close() }
                }
            }
            Connections {
                target: Backend
                function onOperazioneCompletata(messaggio) {
                    if (paginaFruizione.dataPreimpostata === "") {
                        Backend.caricaRiposiDisponibili(paginaFruizione.idDatabase)
                    }
                    // Se veniva da SpecchioPage, il pop() è già avvenuto nell'onClicked
                }
            }
        }
    }

    Component {
        id: modificaPage
        Page {
            id: paginaModifica
            property string idDatabase: ""

            header: ToolBar {
                RowLayout {
                    anchors.fill: parent
                    ToolButton { text: "‹"; onClicked: stack.pop() }
                    Label { text: "Modifica Riposo"; Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter }
                }
            }

            ColumnLayout {
                anchors.centerIn: parent
                width: parent.width * 0.85
                spacing: 15

                Label { text: "DATA DEL RIPOSO DA MODIFICARE:"; font.bold: true }
                DateMaskField {
                    id: dataDaModificare
                    Layout.fillWidth: true
                    background: Rectangle {
                        implicitHeight: 45
                        border.color: dataDaModificare.activeFocus ? "#2196F3" : "#bdbebf"
                        border.width: 2; radius: 4; color: "white"
                    }
                }

                Rectangle { height: 1; Layout.fillWidth: true; color: "#ccc" }

                Label { text: "NUOVI DATI:"; font.bold: true; color: "#2196F3" }

                ComboBox {
                    id: comboNuovoTipo
                    model: ["SETTIMANALE", "FESTIVO", "MEDICO", "STUDIO", "SANGUE", "ALTRO"]
                    Layout.fillWidth: true
                    contentItem: Text {
                        leftPadding: 8; text: comboNuovoTipo.displayText
                        font.pixelSize: 13; font.bold: true; color: "#1f2937"
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        radius: 6; color: comboNuovoTipo.pressed ? "#dbeafe" : "#ffffff"
                        border.color: comboNuovoTipo.activeFocus ? "#1565C0" : "#7f9fbd"
                        border.width: comboNuovoTipo.activeFocus ? 2 : 1.5
                    }
                    delegate: ItemDelegate {
                        width: comboNuovoTipo.width
                        contentItem: Text {
                            text: modelData
                            color: "#1f2937"
                            font.pixelSize: 13
                            verticalAlignment: Text.AlignVCenter
                            leftPadding: 8
                        }
                        background: Rectangle {
                            color: hovered ? "#dbeafe" : "#ffffff"
                        }
                    }
                }

                ComboBox {
                    id: comboNuovoStato
                    model: ["ACQUISITO", "RICHIESTO", "VALIDATO"]
                    Layout.fillWidth: true
                    contentItem: Text {
                        leftPadding: 8; text: comboNuovoStato.displayText
                        font.pixelSize: 13; font.bold: true; color: "#1f2937"
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        radius: 6; color: comboNuovoStato.pressed ? "#dbeafe" : "#ffffff"
                        border.color: comboNuovoStato.activeFocus ? "#1565C0" : "#7f9fbd"
                        border.width: comboNuovoStato.activeFocus ? 2 : 1.5
                    }
                    delegate: ItemDelegate {
                        width: comboNuovoStato.width
                        contentItem: Text {
                            text: modelData
                            color: "#1f2937"
                            font.pixelSize: 13
                            verticalAlignment: Text.AlignVCenter
                            leftPadding: 8
                        }
                        background: Rectangle {
                            color: hovered ? "#dbeafe" : "#ffffff"
                        }
                    }
                }

                Button {
                    text: "APPLICA MODIFICHE"
                    highlighted: true
                    Layout.fillWidth: true
                    onClicked: {
                        Backend.modificaRiposo(idDatabase,
                            dataDaModificare.text,
                            comboNuovoTipo.currentIndex,
                            comboNuovoStato.currentIndex)
                        }
                    }
                }

            Connections {
                target: Backend
                function onOperazioneCompletata(messaggio) { stack.pop() }
            }
        }
    }

    Component {
        id: cancellaPage
        Page {
            id: paginaCancella
            property string idDatabase: ""
            property var datiRiposoDaCancellare: null

            header: ToolBar {
                RowLayout {
                    anchors.fill: parent
                    spacing: 0
                    ToolButton {
                        text: "‹"
                        font.pixelSize: 24
                        onClicked: stack.pop() // Torna al Menu Principale
                    }
                    Label {
                        text: "Elimina Riposo"
                        font.bold: true
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        rightPadding: 40
                    }
                }
            }

            Connections {
                target: Backend
                function onConfermaCancellazioneRichiesta(dati) {
                    paginaCancella.datiRiposoDaCancellare = dati
                    popupConfermaElimina.open()
                }
            }

            ColumnLayout {
                anchors.centerIn: parent
                width: parent.width * 0.85
                spacing: 20

                Label {
                    text: "INSERISCI DATA DA ELIMINARE:"
                    font.bold: true
                    Layout.alignment: Qt.AlignHCenter
                }

                DateMaskField {
                    id: dataDaEliminare
                    placeholderText: "INSERISCI DATA"
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    background: Rectangle {
                        implicitHeight: 45
                        border.color: dataDaEliminare.activeFocus ? "#2196F3" : "#bdbebf"
                        border.width: 2; radius: 4; color: "white"
                    }
                }

                Button {
                    text: "ELIMINA"
                    Layout.fillWidth: true
                    implicitHeight: 46
                    font.pixelSize: 15
                    font.bold: true
                    contentItem: Text {
                        text: parent.text
                        font: parent.font
                        color: "white"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        radius: 8
                        color: parent.down ? "#7f1d1d" : parent.hovered ? "#b91c1c" : "#ef4444"
                        border.color: "#7f1d1d"
                        border.width: 2
                    }
                    onClicked: {
                        if (dataDaEliminare.text !== "") {
                            Backend.controllaEsistenzaEChiediConferma(idDatabase, dataDaEliminare.text)
                        }
                    }
                }
            }
            Popup {
                id: popupConfermaElimina
                anchors.centerIn: parent
                width: parent.width * 0.9
                modal: true
                focus: true
                background: Rectangle {
                    color: "white"; radius: 10
                    border.color: "#ef4444"; border.width: 2
                }
                ColumnLayout {
                    anchors.fill: parent; spacing: 15; anchors.margins: 10

                    Label {
                        text: "Sei sicuro di voler cancellare?";
                        font.bold: true; color: "red"; Layout.alignment: Qt.AlignHCenter
                    }

                    Column {
                        Layout.fillWidth: true; spacing: 5
                        Label { text: "<b>Data:</b> " + (paginaCancella.datiRiposoDaCancellare ? paginaCancella.datiRiposoDaCancellare.data : "") }
                        Label { text: "<b>Tipo:</b> " + (paginaCancella.datiRiposoDaCancellare ? paginaCancella.datiRiposoDaCancellare.tipo : "") }
                        Label { text: "<b>Stato:</b> " + (paginaCancella.datiRiposoDaCancellare ? paginaCancella.datiRiposoDaCancellare.stato : "") }
                    }

                    RowLayout {
                        Layout.fillWidth: true; spacing: 10
                        Button {
                            text: " ELIMINA"
                            Layout.fillWidth: true
                            implicitHeight: 44
                            font.pixelSize: 14
                            font.bold: true
                            contentItem: Text {
                                text: parent.text
                                font: parent.font
                                color: "white"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            background: Rectangle {
                                radius: 8
                                color: parent.down ? "#7f1d1d" : parent.hovered ? "#b91c1c" : "#ef4444"
                                border.color: "#7f1d1d"
                                border.width: 2
                            }
                            onClicked: {
                                Backend.cancellaRiposoEffettivo(idDatabase, dataDaEliminare.text)
                                popupConfermaElimina.close()
                            }
                        }
                        Button {
                            text: "ANNULLA"
                            Layout.fillWidth: true
                            implicitHeight: 44
                            font.pixelSize: 14
                            font.bold: true
                            contentItem: Text {
                                text: parent.text
                                font: parent.font
                                color: "#555555"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            background: Rectangle {
                                radius: 8
                                color: parent.down ? "#e0e0e0" : parent.hovered ? "#f0f0f0" : "white"
                                border.color: "#cccccc"
                                border.width: 2
                            }
                            onClicked: popupConfermaElimina.close()
                        }
                    }
                }
            }

            Connections {
                target: Backend
                function onOperazioneCompletata(messaggio) {
                    stack.pop()
                }
            }
        }
    }
    Component {
        id: straordinariPage
        Page {
            id: paginaStraordinari
            property string idDatabase: ""
            property var listaStraordinari: []
            property double totaleOre: 0.0

            function ricarica() {
                let anno = parseInt(comboAnnoStr.currentText)
                let mese = comboMeseStr.currentIndex + 1
                if (isNaN(anno)) return
                Backend.caricaStraordinariMese(idDatabase, anno, mese)
            }

            Connections {
                target: Backend
                function onStraordinariRicevuti(lista, totale) {
                    paginaStraordinari.listaStraordinari = lista
                    paginaStraordinari.totaleOre = totale
                }
                function onOperazioneCompletata(messaggio) {
                    paginaStraordinari.ricarica()
                }
            }

            Component.onCompleted: {
                let oggi = new Date()
                Backend.caricaStraordinariMese(idDatabase, oggi.getFullYear(), oggi.getMonth() + 1)
            }

            header: ToolBar {
                RowLayout {
                    anchors.fill: parent
                    ToolButton { text: "‹"; onClicked: stack.pop() }
                    Label {
                        text: "Straordinari"
                        font.bold: true
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                    }
                    ComboBox {
                        id: comboMeseStr
                        Layout.preferredWidth: 110
                        model: ["Gennaio","Febbraio","Marzo","Aprile","Maggio","Giugno",
                                "Luglio","Agosto","Settembre","Ottobre","Novembre","Dicembre"]
                        Component.onCompleted: currentIndex = new Date().getMonth()
                        onActivated: paginaStraordinari.ricarica()
                        delegate: ItemDelegate {
                            width: comboMeseStr.width
                            contentItem: Text {
                                text: modelData
                                color: "#1f2937"
                                font.pixelSize: 13
                                verticalAlignment: Text.AlignVCenter
                                leftPadding: 8
                            }
                            background: Rectangle {
                                color: hovered ? "#dbeafe" : "#ffffff"
                            }
                        }
                    }
                    ComboBox {
                        id: comboAnnoStr
                        Layout.preferredWidth: 80
                        model: {
                            let a = []; let y = new Date().getFullYear()
                            for (let i = y - 1; i <= y + 1; i++) a.push(i.toString())
                            return a
                        }
                        Component.onCompleted: {
                            let y = new Date().getFullYear().toString()
                            for (let i = 0; i < model.length; i++)
                                if (model[i] === y) { currentIndex = i; break }
                        }
                        onActivated: paginaStraordinari.ricarica()
                        delegate: ItemDelegate {
                            width: comboAnnoStr.width
                            contentItem: Text {
                                text: modelData
                                color: "#1f2937"
                                font.pixelSize: 13
                                verticalAlignment: Text.AlignVCenter
                                leftPadding: 8
                            }
                            background: Rectangle {
                                color: hovered ? "#dbeafe" : "#ffffff"
                            }
                        }
                    }
                }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10

                // --- BADGE ANIMATO ---
                Rectangle {
                    Layout.fillWidth: true
                    height: 100
                    radius: 12
                    color: {
                        let ore = paginaStraordinari.totaleOre
                        if (ore <= 0)   return "#eeeeee"
                        if (ore <= 5)   return "#f5deb3"
                        if (ore <= 15)  return "#e8e8e8"
                        if (ore <= 30)  return "#fff9c4"
                        return "#e0f7fa"
                    }
                    border.color: Qt.darker(color, 1.2)
                    border.width: 2

                    Row {
                        anchors.centerIn: parent
                        spacing: 12

                        AnimatedImage {
                            id: animalCanvasStr
                            width: 80
                            height: 80
                            fillMode: Image.PreserveAspectFit
                            playing: true
                            source: {
                                let ore = paginaStraordinari.totaleOre
                                if (ore <= 5)   return "https://media0.giphy.com/media/1xkMJIvxeKiDS/giphy.gif"
                                if (ore <= 15)  return "https://media1.giphy.com/media/v1.Y2lkPTc5MGI3NjExamJodGhxMWttcmJkcDIxYzZhYXoyM3h0dnFpOW55bjg3d3F2MXNrNiZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/l3fZPYrlEGoSLvq9O/giphy.gif"
                                if (ore <= 30)  return "https://media2.giphy.com/media/v1.Y2lkPTc5MGI3NjExOWhtdm45YW1kdDB2MThhZmdndDI5N2ZrM2hxZHFoc2NrYjQ0NGpwcyZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/R8bcfuGTZONyw/giphy.gif"
                                return          "https://media4.giphy.com/media/v1.Y2lkPTc5MGI3NjExbjl1ZXBkMHc3ZTdoNzYyb2tyYXdwbjFuaXF2dnd3NzVtc2FtcDd0YyZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/7lz6nPd56aHh6/giphy.gif"
                            }
                            SequentialAnimation on y {
                                loops: Animation.Infinite
                                running: true
                                NumberAnimation { to: -6; duration: 500; easing.type: Easing.InOutSine }
                                NumberAnimation { to: 0;  duration: 500; easing.type: Easing.InOutSine }
                            }
                        }

                        Column {
                            spacing: 2
                            anchors.verticalCenter: parent.verticalCenter
                            Text {
                                font.pixelSize: 20
                                font.bold: true
                                text: paginaStraordinari.totaleOre.toFixed(1) + " ore totali"
                                color: "#333"
                            }
                            Text {
                                font.pixelSize: 12
                                color: "#666"
                                text: {
                                    let ore = paginaStraordinari.totaleOre
                                    if (ore <= 0)   return "Nessuno straordinario questo mese"
                                    if (ore <= 5)   return "Livello: Bradipo (0-5h) - Rame"
                                    if (ore <= 15)  return "Livello: Cammello (6-15h) - Argento"
                                    if (ore <= 30)  return "Livello: Cavallo (16-30h) - Oro"
                                    return "Livello: Ghepardo (30+h) - Diamante"
                                }
                            }
                        }
                    }
                }

                // --- FORM INSERIMENTO ---
                Rectangle {
                    Layout.fillWidth: true
                    height: 170
                    radius: 8
                    color: "#f9f9f9"
                    border.color: "#ddd"
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 6

                        Label { text: "INSERISCI ORE GIORNALIERE"; font.bold: true; font.pixelSize: 12; color: "#2196F3" }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            DateMaskField {
                                id: campoDataStr
                                Layout.fillWidth: true
                                placeholderText: "GG-MM-AAAA"
                                Component.onCompleted: {
                                    let d = new Date()
                                    let gg = d.getDate().toString().padStart(2,'0')
                                    let mm = (d.getMonth()+1).toString().padStart(2,'0')
                                    let aa = d.getFullYear()
                                    text = gg + "-" + mm + "-" + aa
                                }
                            }

                            Label { text: "Dalle:" }
                            TextField {
                                id: campoOraInizio
                                Layout.preferredWidth: 75
                                placeholderText: "HH:MM"
                                inputMethodHints: Qt.ImhDigitsOnly
                                maximumLength: 5
                                onTextChanged: {
                                    let raw = text.replace(/[^0-9]/g, "")
                                    let masked = raw.length >= 3 ? raw.slice(0,2) + ":" + raw.slice(2,4) : raw
                                    if (text !== masked) text = masked
                                }
                            }

                            Label { text: "Alle:" }
                            TextField {
                                id: campoOraFine
                                Layout.preferredWidth: 75
                                placeholderText: "HH:MM"
                                inputMethodHints: Qt.ImhDigitsOnly
                                maximumLength: 5
                                onTextChanged: {
                                    let raw = text.replace(/[^0-9]/g, "")
                                    let masked = raw.length >= 3 ? raw.slice(0,2) + ":" + raw.slice(2,4) : raw
                                    if (text !== masked) text = masked
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            TextField {
                                id: campoNota
                                Layout.fillWidth: true
                                placeholderText: "Nota / motivazione (opzionale)"
                            }

                            // Preview ore calcolate in tempo reale
                            Label {
                                text: {
                                    let ini = campoOraInizio.text
                                    let fin = campoOraFine.text
                                    if (ini.length === 5 && fin.length === 5) {
                                        let [h1, m1] = ini.split(":").map(Number)
                                        let [h2, m2] = fin.split(":").map(Number)
                                        let minTot = (h2 * 60 + m2) - (h1 * 60 + m1)
                                        if (minTot > 0)
                                            return "= " + (minTot / 60).toFixed(2) + "h"
                                    }
                                    return ""
                                }
                                font.bold: true
                                color: "#2196F3"
                            }

                            Button {
                                text: "SALVA"
                                highlighted: true
                                onClicked: {
                                    let parti = campoDataStr.text.split("-")
                                    if (parti.length !== 3) {
                                        globalErrorLabel.text = "Inserisci una data valida."
                                        globalErrorPopup.open()
                                        return
                                    }
                                    if (campoOraInizio.text.length !== 5 || campoOraFine.text.length !== 5) {
                                        globalErrorLabel.text = "Inserisci orario di inizio e fine nel formato HH:MM."
                                        globalErrorPopup.open()
                                        return
                                    }
                                    let dataISO = parti[2] + "-" + parti[1] + "-" + parti[0]
                                    Backend.salvaOreStraordinario(
                                        idDatabase, dataISO,
                                        campoOraInizio.text,
                                        campoOraFine.text,
                                        campoNota.text
                                    )
                                    campoOraInizio.text = ""
                                    campoOraFine.text = ""
                                    campoNota.text = ""
                                }
                            }
                        }
                    }
                }

                // --- LISTA ---
                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: paginaStraordinari.listaStraordinari

                    header: Item { height: 4 }

                    delegate: Rectangle {
                        width: parent.width
                        height: modelData.nota !== "" || modelData.oraInizio !== "" ? 68 : 48
                        color: index % 2 === 0 ? "#fafafa" : "white"
                        border.color: "#eeeeee"
                        border.width: 1
                        radius: 4

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 8
                            anchors.topMargin: 4
                            anchors.bottomMargin: 4
                            spacing: 2

                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    text: "📅 " + modelData.dataITA
                                    font.pixelSize: 14
                                    font.bold: true
                                    color: "#333"
                                    Layout.fillWidth: true
                                }
                                Text {
                                    text: modelData.oraInizio !== "" ? modelData.oraInizio + " → " + modelData.oraFine : ""
                                    font.pixelSize: 12
                                    color: "#888"
                                }
                                Text {
                                    text: modelData.ore.toFixed(1) + " h"
                                    font.pixelSize: 16
                                    font.bold: true
                                    color: "#2196F3"
                                }
                                ToolButton {
                                    text: "🗑"
                                    font.pixelSize: 16
                                    onClicked: Backend.eliminaStraordinario(modelData.id)
                                }
                            }

                            Text {
                                visible: modelData.nota !== ""
                                text: "📝 " + modelData.nota
                                font.pixelSize: 11
                                color: "#666"
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }
                    }
                }

                Label {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Nessuno straordinario registrato"
                    visible: paginaStraordinari.listaStraordinari.length === 0
                    color: "gray"
                }

            }   // chiude ColumnLayout
        }   // chiude Page
    }   // chiude Component
    Popup {
        id: popupConfigBlocco
        anchors.centerIn: Overlay.overlay
        width: window.width * 0.9
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        background: Rectangle { radius: 10; border.color: "#FF9800"; border.width: 2 }
        ColumnLayout {
            anchors.fill: parent; anchors.margins: 15; spacing: 15
            Label { text: "CONFIGURAZIONE BLOCCO"; font.bold: true; Layout.alignment: Qt.AlignHCenter }
            Label { text: "Data Inizio Blocco:"; font.pixelSize: 12 }
            DateMaskField { id: dataInizioBlocco; Layout.fillWidth: true }

            Label { text: "Data Fine Blocco:"; font.pixelSize: 12 }
            DateMaskField { id: dataFineBlocco; Layout.fillWidth: true }
            RowLayout {
                Layout.fillWidth: true
                Button {
                    text: "ATTIVA"
                    Layout.fillWidth: true
                    highlighted: true
                    onClicked: {
                        Backend.aggiornaBloccoSistema(dataInizioBlocco.text, dataFineBlocco.text, true)
                        popupConfigBlocco.close()
                    }
                }
                Button {
                    text: "DISATTIVA"
                    Layout.fillWidth: true
                    onClicked: {
                        Backend.aggiornaBloccoSistema("01-01-2000", "01-01-2000", false)
                        popupConfigBlocco.close()
                    }
                }
            }
            Button { text: "ANNULLA"; Layout.fillWidth: true; onClicked: popupConfigBlocco.close() }
        }
    }

    // ── POPUP DETTAGLIO BADGE GLOBALE ─────────────────────────────────────
    Popup {
        id: popupDettaglioBadge
        anchors.centerIn: Overlay.overlay
        width: Math.min(window.width * 0.85, 500)
        height: Math.min(window.height * 0.75, 520)
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        property string nomeBadge: ""
        property int livelloBadge: 0
        property string coloreBadge: "#888888"

        function gifPerBadge(nome) {
            if (nome === "Mordi e fuggi")          return "https://media2.giphy.com/media/XZmjb11cwJdc7wotpe/giphy.gif"
            if (nome === "Il Camaleonte")           return "https://media2.giphy.com/media/Le5est4QxTgWynFs7l/giphy.gif"
            if (nome === "L'Architetto")            return "https://media2.giphy.com/media/A8WtEEVaoj1VVqE0I1/giphy.gif"
            if (nome === "Il Guerriero")            return "https://media2.giphy.com/media/odPv8LGSL0fTvigh1N/giphy.gif"
            if (nome === "Tetris")                  return "https://media2.giphy.com/media/MOSebUr4rvZS0/giphy.gif"
            if (nome === "Febbre del Sabato Sera")  return "https://media1.giphy.com/media/v1.Y2lkPTc5MGI3NjExNmtwaXluMHlkaWwwbnZqeWh2YTJncWdsMGZ4NmNzeTJyem90cHI3MSZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/Id67ff9s4Bc4O7M3fj/giphy.gif"
            if (nome === "Re dei Ponti")            return "https://media2.giphy.com/media/9cEyhVgNyeM9EYhOEC/giphy.gif"
            if (nome === "Turista per sempre")      return "https://media2.giphy.com/media/0gn0R3WCprTnIs9eB3/giphy.gif"
            if (nome === "Supereroe")               return "https://media2.giphy.com/media/kCd6XpV0TOMmmjqvo8/giphy.gif"
            if (nome === "Il Papa")                 return "https://media2.giphy.com/media/m2lzGNOPx2UgE74kB2/giphy.gif"
            if (nome === "Giornata da Leoni")       return "https://media3.giphy.com/media/v1.Y2lkPTc5MGI3NjExc3QxZTJ3YTBqejNsNGU1MDMzMWZ1MnNmdzU1Ymh3aDF6Zjh4b2k3dSZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/l1BUojJe4cno1U0CgL/giphy.gif"
            if (nome === "Sprint di Fuoco")         return "https://media0.giphy.com/media/v1.Y2lkPTc5MGI3NjExd2xybDdjMnIwazFpaWd5MmY0anA1cW4yczVhYWl2cWh5NGpleDZnaSZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/YA6dmVW0gfIw8/giphy.gif"
            if (nome === "Ufficio anagrafe")        return "https://media0.giphy.com/media/3o7TKTDn976rzVgky4/giphy.gif"
            if (nome === "Il vampiro")              return "https://media2.giphy.com/media/PA5pAhOp5Y2Qg/giphy.gif"
            return "https://media0.giphy.com/media/1xkMJIvxeKiDS/giphy.gif"
        }

        function commentoPerBadge(nome) {
            if (nome === "Mordi e fuggi")          return "Sei stato così veloce da non farti nemmeno salutare in Ufficio!\n[hai fatto riposo-lavoro-riposo]"
            if (nome === "Il Camaleonte")           return "Sei così abile nel mimetizzarti tra i riposi da riuscire ad aggiudicartelo in tempi difficili!\n[hai fatto riposo insieme ad altri 7 o più persone a riposo]"
            if (nome === "L'Architetto")            return "Abile nel costruire ponti e infrastrutture bi fine settimanali!\n[hai fatto 2 weekend completi di fila]"
            if (nome === "Il Guerriero")            return "Onore alla patria e al lavoro, esempio da seguire!\n[hai lavorato per 2 weekend completi di fila]"
            if (nome === "Tetris")                  return "Sei riuscito ad incastrare i riposi per crearti la settimana corta, un vero nerdone!\n[hai creato una sequenza da 2 giornate lavorative massime per ben 2 volte di fila]"
            if (nome === "Febbre del Sabato Sera")  return "Hai sbagliato lavoro, dovevi fare il dj o il buttafuori!\n[hai riposato per 4 sabati nel mese]"
            if (nome === "Re dei Ponti")            return "Senza di te sarebbe già crollato il mondo, sei il re in assoluto, grande lavoratore!\n[hai fatto 3 weekend completi anche non di fila]"
            if (nome === "Turista per sempre")      return "Hai vinto! Per te ogni mese è una vacanza alle Hawaii!\n[hai fatto riposo per ben 10 giorni di fila]"
            if (nome === "Supereroe")               return "È grazie a te se l'ufficio è ancora attivo, grazie sempre per quello che fai!\n[hai fatto 3 weekend senza riposare il fine settimana, non consecutivi]"
            if (nome === "Il Papa")                 return "La religione ormai ti ha conquistato, sei il chirichetto dell'Ufficio!\n[hai riposato per 4 domeniche nel mese]"
            if (nome === "Giornata da Leoni")       return "Che tu voglia o no il lavoro deve essere concluso!\n[hai fatto 4 ore di straordinario in domenica o festivo]"
            if (nome === "Sprint di Fuoco")         return "Vacci piano... abbiamo tutti mangiato la tua polvere!\n[hai maturato 10 ore di straordinario nella prima settimana completa del mese]"
            if (nome === "Ufficio anagrafe")        return "Pratiche archiviate, fascicoli allineati e MAT timbrate senza perdere il filo.\n[hai validato 3 licenze MAT nella stessa settimana lunedi-domenica]"
            if (nome === "Il vampiro")              return "Quando il turno scivola verso il pomeriggio o la sera, tu sei gia' li' con il mantello pronto.\n[hai validato 3 licenze SER/POM nella stessa settimana lunedi-domenica]"
            return ""
        }

        background: Rectangle {
            radius: 12
            color: "white"
            border.color: "#1565C0"
            border.width: 2

            // Shine animato che scorre dall'alto
            Rectangle {
                id: shineBar
                width: parent.width * 0.4
                height: parent.height
                radius: 12
                opacity: 0.06
                rotation: 15
                color: "white"
                x: -width
                SequentialAnimation on x {
                    loops: Animation.Infinite
                    running: popupDettaglioBadge.visible
                    PauseAnimation { duration: 2000 }
                    NumberAnimation { to: popupDettaglioBadge.width + shineBar.width; duration: 900; easing.type: Easing.InOutQuad }
                    PauseAnimation { duration: 1500 }
                }
            }

            // Bordo che pulsa di colore
            SequentialAnimation on border.color {
                loops: Animation.Infinite
                running: popupDettaglioBadge.visible
                ColorAnimation { to: "#1565C0"; duration: 1200 }
                ColorAnimation { to: "#42A5F5"; duration: 1200 }
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 10

            // ALONE / TITOLO BADGE
            Rectangle {
                Layout.fillWidth: true
                height: 44
                radius: 10
                color: popupDettaglioBadge.coloreBadge
                border.width: popupDettaglioBadge.livelloBadge === 3 ? 2 : 0
                border.color: "#00bcd4"

                SequentialAnimation on border.color {
                    loops: Animation.Infinite
                    running: popupDettaglioBadge.livelloBadge === 3
                    ColorAnimation { to: "#00bcd4"; duration: 900 }
                    ColorAnimation { to: "#e0f7fa"; duration: 900 }
                }

                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    running: true
                    NumberAnimation { to: 0.85; duration: 800; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1.0;  duration: 800; easing.type: Easing.InOutSine }
                }

                Column {
                    anchors.centerIn: parent
                    spacing: 2
                    Text {
                        text: popupDettaglioBadge.nomeBadge
                        font.pixelSize: Math.min(18, window.width * 0.045)
                        font.bold: true
                        color: popupDettaglioBadge.livelloBadge === 3 ? "#003344" : "white"
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    Text {
                        text: popupDettaglioBadge.livelloBadge === 1 ? "▲ ARGENTO"
                            : popupDettaglioBadge.livelloBadge === 2 ? "★ ORO"
                            : "◆ DIAMANTE"
                        font.pixelSize: 10
                        font.bold: true
                        color: popupDettaglioBadge.livelloBadge === 3 ? "#005577" : "white"
                        anchors.horizontalCenter: parent.horizontalCenter
                        opacity: 0.9
                    }
                }
            }

            // GIF
            AnimatedImage {
                Layout.alignment: Qt.AlignHCenter
                Layout.maximumWidth: Math.min(160, window.width * 0.25)
                Layout.maximumHeight: Math.min(160, window.width * 0.25)
                width: Layout.maximumWidth
                height: Layout.maximumHeight
                fillMode: Image.PreserveAspectFit
                clip: true
                playing: popupDettaglioBadge.visible
                source: popupDettaglioBadge.visible
                        ? popupDettaglioBadge.gifPerBadge(popupDettaglioBadge.nomeBadge)
                        : ""
            }

            // COMMENTO
            Rectangle {
                Layout.fillWidth: true
                radius: 8
                color: "#f5f8ff"
                border.color: {
                    var lv = popupDettaglioBadge.livelloBadge
                    return lv === 1 ? "#C0C0C0" : lv === 2 ? "#FFD700" : "#00bcd4"
                }
                border.width: 1
                height: commentoCol.implicitHeight + 24

                Column {
                    id: commentoCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 12
                    spacing: 6

                    Text {
                        width: parent.width
                        text: {
                            var raw = popupDettaglioBadge.commentoPerBadge(popupDettaglioBadge.nomeBadge)
                            return raw.split("\n")[0]
                        }
                        wrapMode: Text.WordWrap
                        font.pixelSize: 13
                        font.bold: true
                        color: {
                            var lv = popupDettaglioBadge.livelloBadge
                            return lv === 1 ? "#5c5c5c" : lv === 2 ? "#7a5c00" : "#005577"
                        }
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Text {
                        width: parent.width
                        text: {
                            var raw = popupDettaglioBadge.commentoPerBadge(popupDettaglioBadge.nomeBadge)
                            var parti = raw.split("\n")
                            return parti.length > 1 ? parti[1] : ""
                        }
                        wrapMode: Text.WordWrap
                        font.pixelSize: 11
                        font.italic: true
                        color: "#888"
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }

            Button {
                text: "CHIUDI"
                Layout.fillWidth: true
                onClicked: popupDettaglioBadge.close()
            }
        }
    }
}
