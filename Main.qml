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

    StackView {
        id: stack
        anchors.fill: parent
        initialItem: loginPage
    }
    
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


    // ============================
    // PAGINA LOGIN
    // ============================
    Component {
        id: loginPage
        Page {
            id: paginaLogin
            property bool loginInCorso: false

            Timer {
                id: loginTimeout
                interval: 20000
                repeat: false
                onTriggered: {
                    if (!paginaLogin.loginInCorso) return
                    paginaLogin.loginInCorso = false
                    globalErrorLabel.text = "Accesso non completato. Riprova."
                    globalErrorPopup.open()
                }
            }

            Connections {
                target: Backend
                function onLoginError(msg) {
                    paginaLogin.loginInCorso = false
                    loginTimeout.stop()
                }
                function onLoginSuccess(nomeCompleto, idSeriale) {
                    loginTimeout.stop()
                    stack.push(menuPage, {"utente": nomeCompleto, "idDatabase": idSeriale})
                }
            }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 20

                Label { text: "ACCESSO"; font.bold: true }

                TextField {
                    id: cipInput
                    placeholderText: "Inserisci CIP"
                    Layout.fillWidth: true
                    onTextChanged: {
                        var up = text.toUpperCase()
                        if (text !== up) text = up
                    }
                }

                Button {
                    text: paginaLogin.loginInCorso ? "ACCESSO..." : "ACCEDI"
                    enabled: !paginaLogin.loginInCorso && cipInput.text.trim() !== ""
                    Layout.fillWidth: true
                    onClicked: {
                        paginaLogin.loginInCorso = true
                        loginTimeout.restart()
                        Backend.login(cipInput.text.trim())
                    }
                }
            }
        }
    }

    // PAGINA MENU PRINCIPALE

    Component {
        id: menuPage
        Page {
            id: paginaMenu
            property string utente: ""
            property string idDatabase: ""
            property var listaRiposiCalendario: []
            property var listaLicenzeCalendario: []

            header: ToolBar {
                RowLayout {
                    anchors.fill: parent

                    // ── Bottone CALENDARIO (sinistra) ──────────────────
                    Rectangle {
                        width: 90
                        height: 36
                        radius: 6
                        color: "#2e7d32"
                        Layout.leftMargin: 6
                        Text {
                            anchors.centerIn: parent
                            text: "CALENDARIO"
                            color: "white"
                            font.pixelSize: 11
                            font.bold: true
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                let oggi = new Date()
                                popupCalendario.annoCorrente = oggi.getFullYear()
                                popupCalendario.meseCorrente = oggi.getMonth()
                                Backend.caricaReport(paginaMenu.idDatabase, 1)
                                Backend.caricaRiposiAnnualiPerTipo(
                                    paginaMenu.idDatabase,
                                    oggi.getFullYear(),
                                    oggi.toISOString().slice(0,10)
                                )
                                popupCalendario.open()
                            }
                        }
                    }

                    Label {
                        text: "MENU PRINCIPALE"
                        font.bold: true
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                    }

                    // ── Bottone MIO PROFILO (destra) ───────────────────
                    Rectangle {
                        width: 100
                        height: 36
                        radius: 6
                        color: "#1565C0"
                        Layout.rightMargin: 6
                        Text {
                            anchors.centerIn: parent
                            text: "MIO PROFILO"
                            color: "white"
                            font.pixelSize: 11
                            font.bold: true
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                let oggi = new Date()
                                let anno = oggi.getFullYear()
                                let oggiISO = oggi.toISOString().slice(0,10)
                                Backend.caricaRiposiAnnualiPerTipo(paginaMenu.idDatabase, anno, oggiISO)
                                Backend.caricaOreStrAnnuali(paginaMenu.idDatabase, anno, oggiISO)
                                popupProfilo.open()
                            }
                        }
                    }
                }
            }
            Connections {
                target: Backend
                function onRiposiRicevuti(lista) {
                    paginaMenu.listaRiposiCalendario = lista
                    paginaMenu.listaLicenzeCalendario = lista.filter(x =>
                        (x.tipo || "").toUpperCase().indexOf("LICEN") !== -1
                    ).map(x => {
                        var p = (x.dataF || "").split("-")
                        var iso = (p.length === 3) ? (p[2] + "-" + p[1] + "-" + p[0]) : ""
                        return Object.assign({}, x, { data: iso })
                    })
                }
                function onRiposiAnnualiRicevuti(lista) {
                    paginaMenu.listaLicenzeCalendario = paginaMenu.listaLicenzeCalendario
                }
                function onOperazioneCompletata(msg) {
                    popupCalendario.chiudiInserimentoLicenza()
                    let oggi = new Date()
                    Backend.caricaReport(paginaMenu.idDatabase, 1)
                    Backend.caricaRiposiAnnualiPerTipo(
                        paginaMenu.idDatabase, oggi.getFullYear(),
                        oggi.toISOString().slice(0,10)
                    )
                }
            }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 15
                width: parent.width * 0.8

                Label {
                    text: "Benvenuto, " + paginaMenu.utente
                    font.pixelSize: 18
                    horizontalAlignment: Text.AlignHCenter
                    Layout.fillWidth: true
                }

                Button { text: "REPORT"; Layout.fillWidth: true; onClicked: stack.push(reportPage, {"idDatabase": paginaMenu.idDatabase}) }
                Button { text: "STRAORDINARI"; Layout.fillWidth: true; onClicked: stack.push(straordinariPage, {"idDatabase": paginaMenu.idDatabase}) }
                Button { text: "INSERISCI NUOVO RIPOSO"; Layout.fillWidth: true; onClicked: stack.push(inserimentoPage, {"idDatabase": paginaMenu.idDatabase}) }
                Button { text: "FRUIZIONE RIPOSO"; Layout.fillWidth: true; onClicked: stack.push(fruizionePage, {"idDatabase": paginaMenu.idDatabase}) }
                Button { text: "MODIFICA RIPOSO"; Layout.fillWidth: true; onClicked: stack.push(modificaPage, {"idDatabase": paginaMenu.idDatabase}) }
                Button { text: "CANCELLA RIPOSO"; Layout.fillWidth: true; onClicked: stack.push(cancellaPage, {"idDatabase": paginaMenu.idDatabase}) }

                Button {
                    text: "ESCI"
                    Layout.fillWidth: true
                    onClicked: stack.pop()
                }
            }
            Popup {
                id: popupCalendario
                anchors.centerIn: parent
                width: parent.width
                height: Math.min(parent.height * 0.95, 720)
                modal: true
                focus: true
                closePolicy: Popup.CloseOnEscape

                property int meseCorrente: 0
                property int annoCorrente: 2026
                property string giornoSelezionato: ""   // formato yyyy-MM-dd
                property bool modalitaLicenza: false

                function chiudiInserimentoLicenza() {
                    modalitaLicenza = false
                    giornoSelezionato = ""
                }

                // Restituisce true se dataISO (yyyy-MM-dd) è un riposo fruito
                function isRiposoFruito(dataISO) {
                    for (var i = 0; i < paginaMenu.listaRiposiCalendario.length; i++) {
                        var r = paginaMenu.listaRiposiCalendario[i]
                        if (r.dataISO === dataISO || r.dataF !== "") {     
                            if (iso === dataISO)
                                return { trovato: true, tipo: r.tipo, stato: r.stato, isFruiz: false, dataMatISO: r.dataISO }
                            var parti = r.dataF.split("-")
                            if (parti.length === 3) {
                                var iso = parti[2] + "-" + parti[1] + "-" + parti[0]
                                if (iso === dataISO) return { trovato: true, tipo: r.tipo, stato: r.stato, isFruiz: true, dataMatISO: r.dataISO }
                            }
                        }
                    }
                    return { trovato: false }
                }

                // Restituisce la licenza per quel giorno (dataISO yyyy-MM-dd) se esiste
                function getLicenza(dataISO) {
                    for (var i = 0; i < paginaMenu.listaLicenzeCalendario.length; i++) {
                        var l = paginaMenu.listaLicenzeCalendario[i]
                        // data della licenza è in l.data (formato yyyy-MM-dd dal backend)
                        if (l.data === dataISO) return l
                    }
                    return null
                }
                function dowDelGiorno(y, m, d) {
                    var t = [0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4]
                    var ay = (m < 3) ? y - 1 : y
                    return (ay + Math.floor(ay/4) - Math.floor(ay/100) + Math.floor(ay/400) + t[m-1] + d) % 7
                }

                function giorniDelMese(y, m) {
                    var bisestile = (y % 4 === 0 && y % 100 !== 0) || (y % 400 === 0)
                    return [31, bisestile ? 29 : 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][m-1]
                }

                background: Rectangle { radius: 12; color: "white"; border.color: "#2e7d32"; border.width: 2 }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 6

                    // ── Titolo ──────────────────────────────────────────
                    Label {
                        text: " CALENDARIO RIPOSI"
                        font.bold: true
                        font.pixelSize: 16
                        color: "#2e7d32"
                        Layout.alignment: Qt.AlignHCenter
                    }

                    // ── Navigazione mese ────────────────────────────────
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Rectangle {
                            width: 36; height: 30; radius: 6; color: "#e8f5e9"
                            Text { anchors.centerIn: parent; text: "‹"; font.pixelSize: 18; color: "#2e7d32"; font.bold: true }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    if (popupCalendario.meseCorrente === 0) {
                                        popupCalendario.meseCorrente = 11
                                        popupCalendario.annoCorrente -= 1
                                    } else {
                                        popupCalendario.meseCorrente -= 1
                                    }
                                }
                            }
                        }

                        Label {
                            text: Qt.locale("it_IT").monthName(popupCalendario.meseCorrente, Locale.LongFormat).toUpperCase()
                                + " " + popupCalendario.annoCorrente
                            font.bold: true
                            font.pixelSize: 14
                            color: "#333"
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                        }

                        Rectangle {
                            width: 36; height: 30; radius: 6; color: "#e8f5e9"
                            Text { anchors.centerIn: parent; text: "›"; font.pixelSize: 18; color: "#2e7d32"; font.bold: true }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    if (popupCalendario.meseCorrente === 11) {
                                        popupCalendario.meseCorrente = 0
                                        popupCalendario.annoCorrente += 1
                                    } else {
                                        popupCalendario.meseCorrente += 1
                                    }
                                }
                            }
                        }
                    }

                    // ── Intestazione giorni settimana ───────────────────
                    GridLayout {
                        Layout.fillWidth: true
                        columns: 7
                        columnSpacing: 2
                        rowSpacing: 2
                        Repeater {
                            model: [
                                { giorno: "Lun", icona: "☀" },
                                { giorno: "Mar", icona: "☀" },
                                { giorno: "Mer", icona: "☀" },
                                { giorno: "Gio", icona: "☀" },
                                { giorno: "Ven", icona: "☀" },
                                { giorno: "Sab", icona: "☀" },
                                { giorno: "Dom", icona: "★" }
                            ]
                            delegate: Rectangle {
                                Layout.fillWidth: true
                                height: 36
                                radius: 6
                                color: (index === 6) ? "#ffcdd2" : "#f1f8f1"

                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: 0
                                    Text {
                                        text: modelData.icona
                                        font.pixelSize: 10
                                        color: (index === 6) ? "#ef5350" : "#2e7d32"
                                        Layout.alignment: Qt.AlignHCenter
                                    }
                                    Text {
                                        text: modelData.giorno
                                        font.pixelSize: 11
                                        font.bold: true
                                        color: (index === 6) ? "#c62828" : "#1b5e20"
                                        Layout.alignment: Qt.AlignHCenter
                                    }
                                }
                            }
                        }
                    }

                    // ── Griglia giorni ──────────────────────────────────
                    GridLayout {
                        id: grigliaCalendario
                        Layout.fillWidth: true
                        columns: 7
                        columnSpacing: 2
                        rowSpacing: 2

                        Repeater {
                            model: {
                                var anno = popupCalendario.annoCorrente
                                var mese = popupCalendario.meseCorrente + 1
                                var offset = Backend.offsetPrimoGiornoMese(anno, mese)
                                var giorniMese = Backend.giorniNelMese(anno, mese)
                                var celle = []
                                for (var i = 0; i < offset; i++) celle.push({ giorno: 0, dataISO: "" })
                                for (var g = 1; g <= giorniMese; g++) {
                                    var mm = String(mese).padStart(2, "0")
                                    var dd = String(g).padStart(2, "0")
                                    celle.push({ giorno: g, dataISO: anno + "-" + mm + "-" + dd })
                                }
                                while (celle.length % 7 !== 0) celle.push({ giorno: 0, dataISO: "" })
                                return celle
                            }

                            delegate: Rectangle {
                                Layout.fillWidth: true
                                height: 40
                                radius: 5

                                property var riposo: modelData.dataISO !== "" ? popupCalendario.isRiposoFruito(modelData.dataISO) : { trovato: false }
                                property var licenza: modelData.dataISO !== "" ? popupCalendario.getLicenza(modelData.dataISO) : null
                                property bool isOggi: {
                                    var oggi = new Date()
                                    var mm = String(oggi.getMonth()+1).padStart(2,"0")
                                    var dd = String(oggi.getDate()).padStart(2,"0")
                                    return modelData.dataISO === oggi.getFullYear()+"-"+mm+"-"+dd
                                }
                                property int dowIndex: {
                                    if (modelData.dataISO === "") return 0
                                    var p = modelData.dataISO.split("-")
                                    var d = new Date(parseInt(p[0]), parseInt(p[1])-1, parseInt(p[2])).getDay()
                                    return (d === 0) ? 6 : d - 1  // 0=Lun..6=Dom
                                }
                                property bool isWeekend: dowIndex === 5 || dowIndex === 6  // 5=Sab, 6=Dom

                                color: {
                                    if (!modelData.giorno) return "transparent"
                                    if (licenza) return "#fffde7"
                                    if (riposo.trovato) return "#fffde7"
                                    if (isOggi) return "#e8f5e9"
                                    return "transparent"
                                }
                                border.color: {
                                    if (isOggi && !riposo.trovato && !licenza) return "#2e7d32"
                                    if (licenza) return "#e0e0e0"
                                    return "#e0e0e0"
                                }
                                border.width: 1

                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: 0
                                    Label {
                                        text: modelData.giorno > 0 ? modelData.giorno : ""
                                        font.pixelSize: 13
                                        color: (dowIndex === 6) ? "#ef5350" : "#333"
                                        Layout.alignment: Qt.AlignHCenter
                                    }
                                    Label {
                                        visible: licenza !== null
                                        text: licenza ? (licenza.codice || licenza.a || "L") : ""
                                        font.pixelSize: 15
                                        font.bold: true
                                        color: "#7b1fa2"
                                        Layout.alignment: Qt.AlignHCenter
                                    }
                                    Label {
                                        visible: riposo.trovato && !licenza
                                        text: {
                                            if (!riposo.trovato || !riposo.isFruiz) return ""
                                            var t = (riposo.tipo || "").toUpperCase()

                                            if (t.indexOf("MEDIC") !== -1) return "RM"
                                            if (t.indexOf("SANG")  !== -1) return "RDS"
                                            if (t.indexOf("STUD")  !== -1) return "RSTD"
                                            if (t.indexOf("LICEN") !== -1) return "" 

                                            if (t.indexOf("SETT") !== -1 || t.indexOf("FEST") !== -1) {
                                                var oggi = new Date(modelData.dataISO)
                                                var dow = oggi.getDay() === 0 ? 6 : oggi.getDay() - 1
                                                var lunedi = new Date(oggi)
                                                lunedi.setDate(oggi.getDate() - dow)
                                                lunedi.setHours(0,0,0,0)
                                                var domenica = new Date(lunedi)
                                                domenica.setDate(lunedi.getDate() + 6)
                                                domenica.setHours(23,59,59,999)
                                                var dataMat = new Date(riposo.dataMatISO)
                                                var corrente = (dataMat >= lunedi && dataMat <= domenica)
                                                var dd = String(dataMat.getDate()).padStart(2,"0")
                                                var mm = String(dataMat.getMonth()+1).padStart(2,"0")
                                                var giornoMat = dd+"-"+mm+"-"+dataMat.getFullYear()
                                                if (t.indexOf("SETT") !== -1) return corrente ? "RS" : "RRS " + giornoMat
                                                if (t.indexOf("FEST") !== -1) return corrente ? "RF" : "RRF " + giornoMat
                                            }

                                            return "RAT"
                                        }

                                        color: {
                                            if (!riposo.isFruiz) return "#1565C0"
                                            var t = (riposo.tipo || "").toUpperCase()
                                            if (t.indexOf("MEDIC") !== -1) return "#6a1b9a"
                                            if (t.indexOf("SANG")  !== -1) return "#b71c1c"
                                            if (t.indexOf("STUD")  !== -1) return "#e65100"
                                            if (t.indexOf("FEST")  !== -1) return "#0277bd"
                                            if (t.indexOf("SETT")  !== -1) return "#2e7d32"
                                            return "#4e342e"
                                        }
                                        Layout.alignment: Qt.AlignHCenter
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        if (modelData.dataISO === "") return
                                        if (licenza) {
                                            popupConfermaLicenza.dataISO = modelData.dataISO
                                            popupConfermaLicenza.codice = licenza.codice || licenza.a || ""
                                            popupConfermaLicenza.open()
                                            return
                                        }
                                        if (riposo.trovato) {
                                            popupErroreRiposo.open()
                                            return
                                        }
                                        var oggi = new Date(); oggi.setHours(0,0,0,0)
                                        var cella = new Date(modelData.dataISO)
                                        if (cella < oggi) {
                                            popupErroreData.open()
                                            return
                                        }
                                        popupCalendario.giornoSelezionato = modelData.dataISO
                                        popupCalendario.modalitaLicenza = true
                                    }
                                }
                            }
                        }
                    }

                    // ── Pannello inserimento licenza ─────────────────────
                    Rectangle {
                        visible: popupCalendario.modalitaLicenza
                        Layout.fillWidth: true
                        height: pannelloLicenzaCol.implicitHeight + 20
                        radius: 8
                        color: "#fffde7"
                        border.color: "#f9a825"
                        border.width: 1.5

                        ColumnLayout {
                            id: pannelloLicenzaCol
                            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
                            spacing: 8

                            Label {
                                text: {
                                    if (!popupCalendario.giornoSelezionato) return ""
                                    var p = popupCalendario.giornoSelezionato.split("-")
                                    return " Licenza per il " + p[2] + "-" + p[1] + "-" + p[0]
                                }
                                font.bold: true
                                font.pixelSize: 13
                                color: "#7b1fa2"
                            }

                            ComboBox {
                                id: comboCodiceLicenza
                                Layout.fillWidth: true
                                model: ["LS", "CP", "104", "CIT", "LO", "MAT", "POM", "SER"]
                            }

                            TextField {
                                id: campoLicenzaLibera
                                placeholderText: "oppure scrivi codice libero (es. 3/5)"
                                Layout.fillWidth: true
                                font.pixelSize: 12
                            }

                            Label {
                                id: errLabelLicenza
                                text: ""
                                color: "red"
                                font.pixelSize: 11
                                visible: text !== ""
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Button {
                                    text: "SALVA LICENZA"
                                    Layout.fillWidth: true
                                    background: Rectangle { radius: 4; color: "#f9a825" }
                                    contentItem: Text {
                                        text: "SALVA LICENZA"
                                        color: "white"
                                        font.bold: true
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                    onClicked: {
                                        errLabelLicenza.text = ""
                                        var codice = campoLicenzaLibera.text.trim() !== ""
                                            ? campoLicenzaLibera.text.trim()
                                            : comboCodiceLicenza.currentText
                                        Backend.salvaLicenzaPersonale(
                                            paginaMenu.idDatabase,
                                            popupCalendario.giornoSelezionato,
                                            codice
                                        )
                                    }
                                }

                                Button {
                                    text: "ANNULLA"
                                    Layout.fillWidth: true
                                    onClicked: popupCalendario.chiudiInserimentoLicenza()
                                }
                            }

                            Connections {
                                target: Backend
                                function onErroreOperazione(msg) {
                                    errLabelLicenza.text = msg
                                }
                            }
                        }
                    }
                    Popup {
                        id: popupConfermaLicenza
                        anchors.centerIn: parent
                        modal: true
                        focus: true
                        property string dataISO: ""
                        property string codice: ""

                        background: Rectangle { radius: 10; color: "white"; border.color: "#f9a825"; border.width: 2 }

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 16
                            spacing: 14

                            Label {
                                text: "Rimuovere la licenza\n" + popupConfermaLicenza.codice + " del " + popupConfermaLicenza.dataISO + "?"
                                font.bold: true
                                font.pixelSize: 13
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignHCenter
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10

                                Button {
                                    text: "ANNULLA"
                                    Layout.fillWidth: true
                                    onClicked: popupConfermaLicenza.close()
                                }

                                Button {
                                    text: "RIMUOVI"
                                    Layout.fillWidth: true
                                    background: Rectangle { radius: 4; color: "#f9a825" }
                                    contentItem: Text {
                                        text: "RIMUOVI"
                                        color: "white"
                                        font.bold: true
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                    onClicked: {
                                        Backend.cancellaLicenza(paginaMenu.idDatabase, popupConfermaLicenza.dataISO, popupConfermaLicenza.codice)
                                        popupConfermaLicenza.close()
                                    }
                                }
                            }
                        }
                    }
                    Popup {
                        id: popupErroreRiposo
                        anchors.centerIn: parent
                        modal: true
                        focus: true

                        background: Rectangle { radius: 10; color: "white"; border.color: "#ef5350"; border.width: 2 }

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 16
                            spacing: 14

                            Label {
                                text: "⚠ Giorno già occupato da un riposo.\nNon è possibile inserire una licenza."
                                font.bold: true
                                font.pixelSize: 13
                                color: "#ef5350"
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignHCenter
                            }

                            Button {
                                text: "OK"
                                Layout.fillWidth: true
                                onClicked: popupErroreRiposo.close()
                            }
                        }
                    }
                    Popup {
                        id: popupErroreData
                        anchors.centerIn: parent
                        modal: true
                        focus: true
                        background: Rectangle { radius: 10; color: "white"; border.color: "#ef5350"; border.width: 2 }
                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 16
                            spacing: 14
                            Label {
                                text: "⚠ Non puoi inserire una licenza\nin una data passata."
                                font.bold: true
                                font.pixelSize: 13
                                color: "#ef5350"
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignHCenter
                            }
                            Button {
                                text: "OK"
                                Layout.fillWidth: true
                                onClicked: popupErroreData.close()
                            }
                        }
                    }

                    Button {
                        text: "CHIUDI"
                        Layout.fillWidth: true
                        onClicked: popupCalendario.close()
                    }
                }
            }
        }
    }
        // ============================
    // POPUP PROFILO (PULITO)
    // ============================
    Popup {
        id: popupProfilo
        anchors.centerIn: parent
        width: Math.min(parent.width * 0.92, 500)
        height: Math.min(parent.height * 0.88, 700)
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape

        property var riposiAnnuali: []
        property double oreStrAnnuali: 0.0
        property double oreStrMeseFiltrato: 0.0
        property int meseFiltroSelezionato: -1

        Connections {
            target: Backend
            function onRiposiAnnualiRicevuti(lista) { popupProfilo.riposiAnnuali = lista }
            function onOreStrAnnualiRicevute(tot) { popupProfilo.oreStrAnnuali = tot }
            function onOreStrMeseRicevute(tot) { popupProfilo.oreStrMeseFiltrato = tot }
        }

        background: Rectangle { radius: 12; color: "white"; border.color: "#1565C0"; border.width: 2 }

        ScrollView {
            anchors.fill: parent
            anchors.margins: 14

            ColumnLayout {
                anchors.fill: parent
                spacing: 14

                Label {
                    text: "MIO PROFILO"
                    font.bold: true
                    font.pixelSize: 18
                    color: "#1565C0"
                    Layout.alignment: Qt.AlignHCenter
                }

                Rectangle { height: 1; Layout.fillWidth: true; color: "#1565C0"; opacity: 0.3 }

                // ============================
                // STRAORDINARI
                // ============================
                Label { text: "STRAORDINARI ANNUALI"; font.bold: true; color: "#333" }
                Label {
                    text: popupProfilo.oreStrAnnuali.toFixed(1) + " ore totali"
                    font.pixelSize: 14
                    color: "#1565C0"
                }

                Label { text: "STRAORDINARI DEL MESE"; font.bold: true; color: "#333" }
                Label {
                    text: popupProfilo.oreStrMeseFiltrato.toFixed(1) + " ore"
                    font.pixelSize: 14
                    color: "#1565C0"
                }

                Rectangle { height: 1; Layout.fillWidth: true; color: "#e0e0e0" }

                // ============================
                // RIPOSI ANNUALI PER TIPO
                // ============================
                Label { text: "RIPOSI ANNUALI TOTALI"; font.bold: true; color: "#333" }

                Label {
                    text: {
                        var m = {}
                        for (var i=0; i<popupProfilo.riposiAnnuali.length; i++) {
                            var r = popupProfilo.riposiAnnuali[i]
                            var tipo = r.tipo || "SCONOSCIUTO"
                            m[tipo] = (m[tipo] || 0) + 1
                        }
                        var tot = Object.values(m).reduce((a,b)=>a+b,0)
                        return "Totale: " + tot
                    }
                    font.pixelSize: 14
                    color: "#1565C0"
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    Repeater {
                        model: {
                            var m = {}
                            for (var i=0; i<popupProfilo.riposiAnnuali.length; i++) {
                                var r = popupProfilo.riposiAnnuali[i]
                                var tipo = r.tipo || "SCONOSCIUTO"
                                m[tipo] = (m[tipo] || 0) + 1
                            }
                            return Object.keys(m).map(k => ({ tipo: k, count: m[k] }))
                        }
                        delegate: Label {
                            text: "• " + modelData.tipo + ": " + modelData.count
                            font.pixelSize: 13
                            color: "#444"
                        }
                    }
                }

                Rectangle { height: 1; Layout.fillWidth: true; color: "#e0e0e0" }

                // ============================
                // GRIGLIA MESI
                // ============================
                Label { text: "FILTRA PER MESE"; font.bold: true; color: "#333" }

                GridLayout {
                    Layout.fillWidth: true
                    columns: parent.width > 350 ? 6 : 4
                    Repeater {
                        model: [
                            {n:1,label:"GEN"},{n:2,label:"FEB"},{n:3,label:"MAR"},{n:4,label:"APR"},
                            {n:5,label:"MAG"},{n:6,label:"GIU"},{n:7,label:"LUG"},{n:8,label:"AGO"},
                            {n:9,label:"SET"},{n:10,label:"OTT"},{n:11,label:"NOV"},{n:12,label:"DIC"}
                        ]
                        delegate: Rectangle {
                            Layout.fillWidth: true
                            height: 28
                            radius: 6
                            color: popupProfilo.meseFiltroSelezionato === modelData.n ? "#1565C0" : "#E3F2FD"
                            Text {
                                anchors.centerIn: parent
                                text: modelData.label
                                color: popupProfilo.meseFiltroSelezionato === modelData.n ? "white" : "#1565C0"
                                font.pixelSize: 11
                                font.bold: popupProfilo.meseFiltroSelezionato === modelData.n
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    if (popupProfilo.meseFiltroSelezionato === modelData.n)
                                        popupProfilo.meseFiltroSelezionato = -1
                                    else {
                                        popupProfilo.meseFiltroSelezionato = modelData.n
                                        let oggi = new Date()
                                        Backend.caricaOreStrMese(stack.currentItem.idDatabase, oggi.getFullYear(), modelData.n)
                                    }
                                }
                            }
                        }
                    }
                }

                // ============================
                // RIPOSI MENSILI PER TIPO
                // ============================
                Label {
                    visible: popupProfilo.meseFiltroSelezionato !== -1
                    text: "RIPOSI DEL MESE SELEZIONATO"
                    font.bold: true
                    color: "#333"
                }

                ColumnLayout {
                    visible: popupProfilo.meseFiltroSelezionato !== -1
                    spacing: 4
                    Repeater {
                        model: {
                            if (popupProfilo.meseFiltroSelezionato === -1) return []
                            var m = {}
                            for (var i=0; i<popupProfilo.riposiAnnuali.length; i++) {
                                var r = popupProfilo.riposiAnnuali[i]
                                var parti = r.data.split("-")
                                if (parseInt(parti[1]) !== popupProfilo.meseFiltroSelezionato) continue
                                var tipo = r.tipo || "SCONOSCIUTO"
                                m[tipo] = (m[tipo] || 0) + 1
                            }
                            return Object.keys(m).map(k => ({ tipo: k, count: m[k] }))
                        }
                        delegate: Label {
                            text: "• " + modelData.tipo + ": " + modelData.count
                            font.pixelSize: 13
                            color: "#444"
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
                }

                ListView {
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    clip: true
                    model: paginaReport.listaReport

                    delegate: ItemDelegate {
                        width: parent.width
                        padding: 10
                        contentItem: ColumnLayout {
                            spacing: 4
                            RowLayout {
                                Layout.fillWidth: true
                                Label {
                                    text: " DATA: " + modelData.dataITA
                                    font.bold: true
                                    Layout.fillWidth: true
                                }
                                Label {
                                    text: " TIPO: " + modelData.tipo
                                    font.pixelSize: 13
                                    Layout.fillWidth: true
                                    wrapMode: Text.WordWrap
                                }
                                Label {
                                    text: modelData.stato
                                    color: modelData.stato === "VALIDATO" ? "green" : "orange"
                                    font.pixelSize: 11
                                }
                            }
                            Label {
                                text: " Fruizione: " + modelData.fruiz + (modelData.dataF !== "" ? " (" + modelData.dataF + ")" : "")
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
                }

                ComboBox {
                    id: comboTipoNuovo
                    model: ["SETTIMANALE", "FESTIVO", "MEDICO", "STUDIO", "SANGUE", "ALTRO"]
                    Layout.fillWidth: true
                }

                Button {
                    text: "SALVA"
                    Layout.fillWidth: true
                    onClicked: Backend.aggiungiRiposo(idDatabase, campoDataNuova.text, comboTipoNuovo.currentIndex + 1)
                }
            }

            Connections {
                target: Backend
                function onOperazioneCompletata(msg) { stack.pop() }
            }
        }
    }

    Component {
        id: fruizionePage
        Page {
            id: paginaFruizione
            property string idDatabase: ""
            property var listaDisponibili: []

            header: ToolBar {
                RowLayout {
                    anchors.fill: parent
                    ToolButton { text: "‹"; onClicked: stack.pop() }
                    Label {
                        text: "Fruizione Riposo"
                        font.bold: true
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }

            Connections {
                target: Backend
                function onRiposiRicevuti(lista) {
                    paginaFruizione.listaDisponibili = lista.filter(x =>
                        x.stato !== "VALIDATO" &&
                        x.stato !== "FRUITO" &&
                        (x.tipo || "").toUpperCase().indexOf("LICEN") === -1
                    )
                }
                function onOperazioneCompletata(msg) {
                    popupFruizione.close()
                    Backend.caricaReport(idDatabase, 1)
                }
                function onLoginError(msg) {
                    errLabelFruiz.text = msg
                }
            }

            Component.onCompleted: Backend.caricaReport(idDatabase, 1)

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 6

                Label {
                    text: paginaFruizione.listaDisponibili.length + " riposi da gestire"
                    font.pixelSize: 12
                    color: "#888"
                }

                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: paginaFruizione.listaDisponibili
                    spacing: 4

                    delegate: Rectangle {
                        width: ListView.view.width
                        height: rigaContent.implicitHeight + 20
                        radius: 8
                        color: "#ffffff"
                        border.color: modelData.stato === "RICHIESTO" ? "#ef9a9a" : "#a5d6a7"
                        border.width: 1.5

                        // Striscia colorata a sinistra
                        Rectangle {
                            width: 5
                            height: parent.height
                            radius: 8
                            color: modelData.stato === "RICHIESTO" ? "#ef5350" : "#43a047"
                        }

                        ColumnLayout {
                            id: rigaContent
                            anchors {
                                left: parent.left
                                right: badgeStato.left
                                top: parent.top
                                margins: 12
                                leftMargin: 16
                            }
                            spacing: 4

                            // Tipo + data maturazione
                            RowLayout {
                                spacing: 8
                                Label {
                                    text: modelData.tipo
                                    font.bold: true
                                    font.pixelSize: 13
                                    color: "#333"
                                }
                                Label {
                                    text: "· " + modelData.dataITA
                                    font.pixelSize: 12
                                    color: "#666"
                                }
                            }

                            // Stato fruizione
                            Label {
                                text: modelData.stato === "RICHIESTO"
                                    ? " Richiesto per il: " + modelData.dataF
                                    : " Libero — nessuna data assegnata"
                                font.pixelSize: 12
                                font.bold: true
                                color: modelData.stato === "RICHIESTO" ? "#c62828" : "#2e7d32"
                            }
                        }

                        // Badge stato
                        Rectangle {
                            id: badgeStato
                            anchors.right: parent.right
                            anchors.rightMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            width: 80
                            height: 26
                            radius: 13
                            color: modelData.stato === "RICHIESTO" ? "#ef5350" : "#43a047"

                            Text {
                                anchors.centerIn: parent
                                text: modelData.stato
                                color: "white"
                                font.pixelSize: 10
                                font.bold: true
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                popupFruizione.dataSelezionata = modelData.dataISO
                                popupFruizione.tipoRiposo     = modelData.tipo
                                popupFruizione.dataITA        = modelData.dataITA
                                popupFruizione.statoAttuale   = modelData.stato
                                campoFruizione.text = modelData.dataF !== "" ? modelData.dataF : ""
                                popupFruizione.open()
                            }
                        }
                    }

                    Label {
                        anchors.centerIn: parent
                        text: "Nessun riposo da gestire"
                        visible: paginaFruizione.listaDisponibili.length === 0
                        color: "gray"
                        font.pixelSize: 14
                    }
                }
            }

            Popup {
                id: popupFruizione
                anchors.centerIn: parent
                width: parent.width * 0.88
                modal: true
                focus: true
                closePolicy: Popup.CloseOnEscape
                onOpened: errLabelFruiz.text = ""

                property string dataSelezionata: ""
                property string tipoRiposo: ""
                property string dataITA: ""
                property string statoAttuale: ""

                background: Rectangle {
                    radius: 10
                    color: "white"
                    border.color: "#1565C0"
                    border.width: 2
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    Label {
                        text: "GESTISCI FRUIZIONE"
                        font.bold: true
                        font.pixelSize: 15
                        color: "#1565C0"
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Rectangle { height: 1; Layout.fillWidth: true; color: "#e0e0e0" }

                    Label {
                        text: " " + popupFruizione.tipoRiposo + "  ·   maturato il " + popupFruizione.dataITA
                        font.pixelSize: 13
                        color: "#333"
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }

                    Label {
                        text: "Stato attuale: " + popupFruizione.statoAttuale
                        font.pixelSize: 12
                        font.bold: true
                        color: popupFruizione.statoAttuale === "RICHIESTO" ? "#c62828" : "#2e7d32"
                    }

                    Rectangle { height: 1; Layout.fillWidth: true; color: "#e0e0e0" }

                    Label { text: "Data Fruizione (GG-MM-AAAA)"; font.bold: true }
                    DateMaskField {
                        id: campoFruizione
                        Layout.fillWidth: true
                    }

                    ComboBox {
                        id: comboStato
                        model: ["RICHIESTO", "VALIDATO"]
                        Layout.fillWidth: true
                        Component.onCompleted: {
                            currentIndex = popupFruizione.statoAttuale === "RICHIESTO" ? 0 : 1
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Label {
                            id: errLabelFruiz
                            text: ""
                            color: "red"
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                            visible: text !== ""
                        }

                        Button {
                            text: "ANNULLA"
                            Layout.fillWidth: true
                            onClicked: popupFruizione.close()
                        }

                        Button {
                            text: "CONFERMA"
                            Layout.fillWidth: true
                            enabled: campoFruizione.text.length === 10
                            background: Rectangle {
                                radius: 4
                                color: confermaBtn.pressed ? "#0d47a1" : "#1565C0"
                            }
                            id: confermaBtn
                            contentItem: Text {
                                text: "CONFERMA"
                                color: "white"
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            onClicked: {
                                Backend.fruisciRiposo(
                                    idDatabase,
                                    popupFruizione.dataSelezionata,
                                    campoFruizione.text,
                                    comboStato.currentIndex === 0 ? 1 : 0  // RICHIESTO=1, VALIDATO=0
                                )
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: modificaPage
        Page {
            id: paginaModifica
            property string idDatabase: ""
            property var listaModifica: []
            property bool fase2: false
            property int tipoIdxPendente: -1
            property int statoIdxPendente: -1
            property string dataISOPendente: ""
            property string dataITAPendente: ""

            header: ToolBar {
                RowLayout {
                    anchors.fill: parent
                    ToolButton { text: "‹"; onClicked: stack.pop() }
                    Label {
                        text: "Modifica Riposo"
                        font.bold: true
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }

            Connections {
                target: Backend
                function onRiposiRicevuti(lista) {
                    paginaModifica.listaModifica = lista.filter(x =>
                        x.stato !== "FRUITO" &&
                        (x.tipo || "").toUpperCase().indexOf("LICEN") === -1
                    )
                }
                function onOperazioneCompletata(msg) {
                    if (paginaModifica.fase2) {
                        // Fase 2: data_fruizione settata → aggiorna tipo/stato
                        paginaModifica.fase2 = false
                        Backend.modificaRiposo(
                            idDatabase,
                            paginaModifica.dataITAPendente,
                            paginaModifica.tipoIdxPendente,
                            paginaModifica.statoIdxPendente
                        )
                    } else {
                        popupModifica.close()
                        Backend.caricaReport(idDatabase, 1)
                    }
                }
                function onLoginError(msg) {
                    paginaModifica.fase2 = false
                    errLabelMod.text = msg
                }
            }

            Component.onCompleted: Backend.caricaReport(idDatabase, 1)

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 6

                Label {
                    text: paginaModifica.listaModifica.length + " riposi modificabili"
                    font.pixelSize: 12
                    color: "#888"
                }

                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: paginaModifica.listaModifica
                    spacing: 4

                    delegate: Rectangle {
                        width: ListView.view.width
                        height: contenutoRiga.implicitHeight + 18
                        radius: 8
                        color: "#ffffff"
                        border.color: {
                            if (modelData.stato === "VALIDATO") return "#ce93d8"
                            if (modelData.stato === "RICHIESTO") return "#ef9a9a"
                            return "#a5d6a7"
                        }
                        border.width: 1.5

                        Rectangle {
                            width: 5; height: parent.height; radius: 8
                            color: {
                                if (modelData.stato === "VALIDATO") return "#8e24aa"
                                if (modelData.stato === "RICHIESTO") return "#ef5350"
                                return "#43a047"
                            }
                        }

                        ColumnLayout {
                            id: contenutoRiga
                            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10; leftMargin: 16 }
                            spacing: 3

                            RowLayout {
                                Label { text: modelData.tipo; font.bold: true; font.pixelSize: 13; color: "#333" }
                                Label { text: "· " + modelData.dataITA; font.pixelSize: 12; color: "#666" }
                            }

                            RowLayout {
                                spacing: 6
                                Rectangle {
                                    width: statoText.implicitWidth + 10; height: 18; radius: 9
                                    color: {
                                        if (modelData.stato === "VALIDATO") return "#8e24aa"
                                        if (modelData.stato === "RICHIESTO") return "#ef5350"
                                        return "#43a047"
                                    }
                                    Text {
                                        id: statoText
                                        anchors.centerIn: parent
                                        text: modelData.stato
                                        color: "white"; font.pixelSize: 10; font.bold: true
                                    }
                                }
                                Label {
                                    visible: modelData.dataF !== ""
                                    text: " Fruizione: " + modelData.dataF
                                    font.pixelSize: 11; color: "#555"
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                popupModifica.dataISO    = modelData.dataISO
                                popupModifica.dataITA    = modelData.dataITA
                                popupModifica.dataFruizAttuale = modelData.dataF

                                // Preseleziona tipo
                                let tipiBrevi = ["SETTIMANALE","FESTIVO","MEDICO","STUDIO","SANGUE","ALTRO"]
                                let tipiLunghi = ["RIPOSO SETTIMANALE","RIPOSO FESTIVO","RIPOSO MEDICO","RIPOSO STUDIO","RIPOSO DONAZIONE SANGUE","RIPOSO DI ALTRO TIPO"]
                                let idxTipo = tipiLunghi.indexOf(modelData.tipo)
                                comboTipoMod.currentIndex = idxTipo >= 0 ? idxTipo : 0

                                // Preseleziona stato
                                let stati = ["ACQUISITO","RICHIESTO","VALIDATO"]
                                let idxStato = stati.indexOf(modelData.stato)
                                comboStatoMod.currentIndex = idxStato >= 0 ? idxStato : 0

                                // Precompila data fruizione
                                campoDataFruizMod.text = modelData.dataF !== "" ? modelData.dataF : ""
                                errLabelMod.text = ""
                                popupModifica.open()
                            }
                        }
                    }

                    Label {
                        anchors.centerIn: parent
                        text: "Nessun riposo modificabile"
                        visible: paginaModifica.listaModifica.length === 0
                        color: "gray"; font.pixelSize: 14
                    }
                }
            }

            Popup {
                id: popupModifica
                anchors.centerIn: parent
                width: parent.width * 0.9
                modal: true; focus: true
                closePolicy: Popup.CloseOnEscape

                property string dataISO: ""
                property string dataITA: ""
                property string dataFruizAttuale: ""

                background: Rectangle { radius: 10; color: "white"; border.color: "#1565C0"; border.width: 2 }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    Label {
                        text: "MODIFICA RIPOSO"
                        font.bold: true; font.pixelSize: 15; color: "#1565C0"
                        Layout.alignment: Qt.AlignHCenter
                    }
                    Label {
                        text: " Maturato il: " + popupModifica.dataITA
                        font.pixelSize: 13; color: "#333"
                    }

                    Rectangle { height: 1; Layout.fillWidth: true; color: "#e0e0e0" }

                    Label { text: "Tipo riposo"; font.bold: true }
                    ComboBox {
                        id: comboTipoMod
                        model: ["SETTIMANALE","FESTIVO","MEDICO","STUDIO","SANGUE","ALTRO"]
                        Layout.fillWidth: true
                    }

                    Label { text: "Stato"; font.bold: true }
                    ComboBox {
                        id: comboStatoMod
                        model: ["ACQUISITO","RICHIESTO","VALIDATO"]
                        Layout.fillWidth: true
                        onCurrentIndexChanged: {
                            if (currentIndex === 0) campoDataFruizMod.text = ""
                        }
                    }

                    // Data fruizione — visibile solo se RICHIESTO o VALIDATO
                    Label {
                        visible: comboStatoMod.currentIndex > 0
                        text: "Data Fruizione (GG-MM-AAAA)"
                        font.bold: true
                    }
                    DateMaskField {
                        id: campoDataFruizMod
                        visible: comboStatoMod.currentIndex > 0
                        Layout.fillWidth: true
                    }

                    Label {
                        id: errLabelMod
                        text: ""
                        color: "red"; wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                        visible: text !== ""
                    }

                    RowLayout {
                        Layout.fillWidth: true; spacing: 10

                        Button {
                            text: "ANNULLA"
                            Layout.fillWidth: true
                            onClicked: popupModifica.close()
                        }

                        Button {
                            text: "SALVA"
                            Layout.fillWidth: true
                            background: Rectangle { radius: 4; color: salvaBtn.pressed ? "#0d47a1" : "#1565C0" }
                            id: salvaBtn
                            contentItem: Text {
                                text: "SALVA"; color: "white"; font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            onClicked: {
                                errLabelMod.text = ""
                                let statoIdx = comboStatoMod.currentIndex
                                let tipoIdx  = comboTipoMod.currentIndex
                                let dataFruiz = campoDataFruizMod.text.trim()

                                if (statoIdx === 0) {
                                    // ACQUISITO → cancella data_fruizione e aggiorna
                                    Backend.modificaRiposo(idDatabase, popupModifica.dataITA, tipoIdx, 0)

                                } else if (dataFruiz.length === 10) {
                                    // RICHIESTO / VALIDATO con data fruizione
                                    // Fase 1: setta data_fruizione via fruisciRiposo
                                    paginaModifica.fase2            = true
                                    paginaModifica.tipoIdxPendente  = tipoIdx
                                    paginaModifica.statoIdxPendente = statoIdx
                                    paginaModifica.dataISOPendente  = popupModifica.dataISO
                                    paginaModifica.dataITAPendente  = popupModifica.dataITA

                                    // statoScelto: 1=RICHIESTO, 0=VALIDATO
                                    Backend.fruisciRiposo(
                                        idDatabase,
                                        popupModifica.dataISO,
                                        dataFruiz,
                                        statoIdx === 1 ? 1 : 0
                                    )
                                } else {
                                    errLabelMod.text = "Inserisci la data di fruizione per stato RICHIESTO o VALIDATO"
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: cancellaPage
        Page {
            id: paginaCancella
            property string idDatabase: ""
            property var listaRiposi: []

            header: ToolBar {
                RowLayout {
                    anchors.fill: parent
                    ToolButton { text: "‹"; onClicked: stack.pop() }
                    Label { text: "Cancella Riposo"; Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter }
                }
            }

            Connections {
                target: Backend
                function onRiposiRicevuti(lista) {
                    paginaCancella.listaRiposi = lista.filter(x =>
                        (x.tipo || "").toUpperCase().indexOf("LICEN") === -1
                    )
                }
                function onOperazioneCompletata(msg) {
                    popupConfermaCanc.close()
                    stack.pop()
                }
            }

            Component.onCompleted: Backend.caricaReport(idDatabase, 1)

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 6

                Label {
                    text: paginaCancella.listaRiposi.length + " riposi disponibili"
                    font.pixelSize: 12
                    color: "#888"
                }

                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: paginaCancella.listaRiposi
                    spacing: 4

                    delegate: Rectangle {
                        width: ListView.view.width
                        height: rigaCancContent.implicitHeight + 20
                        radius: 8
                        color: "#ffffff"
                        border.color: modelData.stato === "RICHIESTO" ? "#ef9a9a" : "#a5d6a7"
                        border.width: 1.5

                        Rectangle {
                            width: 5; height: parent.height; radius: 8
                            color: modelData.stato === "RICHIESTO" ? "#ef5350" : "#43a047"
                        }

                        ColumnLayout {
                            id: rigaCancContent
                            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12; leftMargin: 16 }
                            spacing: 4

                            RowLayout {
                                spacing: 8
                                Label { text: modelData.tipo; font.bold: true; font.pixelSize: 13; color: "#333" }
                                Label { text: "· " + modelData.dataITA; font.pixelSize: 12; color: "#666" }
                            }
                            Label {
                                text: modelData.stato === "RICHIESTO"
                                    ? "⚠ Richiesto per il: " + modelData.dataF
                                    : "✓ " + modelData.stato
                                font.pixelSize: 12
                                color: modelData.stato === "RICHIESTO" ? "#c62828" : "#2e7d32"
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                popupConfermaCanc.dati = modelData
                                popupConfermaCanc.open()
                            }
                        }
                    }

                    Label {
                        anchors.centerIn: parent
                        text: "Nessun riposo trovato"
                        visible: paginaCancella.listaRiposi.length === 0
                        color: "gray"
                        font.pixelSize: 14
                    }
                }
            }

            Popup {
                id: popupConfermaCanc
                anchors.centerIn: parent
                width: parent.width * 0.85
                modal: true
                focus: true
                closePolicy: Popup.CloseOnEscape
                property var dati: {}

                background: Rectangle { radius: 10; color: "white"; border.color: "#ef5350"; border.width: 2 }

                Connections {
                    target: Backend
                    function onConfermaCancellazioneRichiesta(info) {
                        popupConfermaCanc.dati = info
                        popupConfermaCanc.open()
                    }
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    Label {
                        text: "CONFERMA CANCELLAZIONE"
                        font.bold: true
                        font.pixelSize: 14
                        color: "#ef5350"
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Label { text: "Data: " + (popupConfermaCanc.dati.dataITA ?? popupConfermaCanc.dati.data ?? "") }
                    Label { text: "Tipo: " + (popupConfermaCanc.dati.tipo ?? "") }
                    Label { text: "Stato: " + (popupConfermaCanc.dati.stato ?? "") }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Button {
                            text: "ANNULLA"
                            Layout.fillWidth: true
                            onClicked: popupConfermaCanc.close()
                        }

                        Button {
                            id: btnCancellaConferma
                            text: "CANCELLA"
                            Layout.fillWidth: true
                            background: Rectangle { radius: 4; color: btnCancellaConferma.pressed ? "#c62828" : "#ef5350" }
                            contentItem: Text {
                                text: "CANCELLA"
                                color: "white"
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            onClicked: {
                                Backend.cancellaRiposoEffettivo(
                                    idDatabase,
                                    popupConfermaCanc.dati.dataITA
                                )
                            }
                        }
                    }
                }
            }
        }
    }
    Component {
        id: straordinariPage
        Page {
            id: paginaStraordinari
            property string idDatabase: ""
            property var listaStr: []
            property double totaleOre: 0.0
                            // ── Funzioni helper ──────────────────────────────
            function formattaOra(s) {
                let raw = s.replace(/[^0-9]/g, "")
                if (raw.length === 4) return raw.slice(0,2) + ":" + raw.slice(2)
                let parts = s.split(":")
                if (parts.length === 2 &&
                    parts[0].length >= 1 && parts[1].length === 2) return s
                return null
            }

            function ricalcolaOre() {
                let i = formattaOra(campoOraInizio.text)
                let f = formattaOra(campoOraFine.text)
                if (!i || !f) { oreCalcolate.text = ""; return }
                let [ih, im] = i.split(":").map(Number)
                let [fh, fm] = f.split(":").map(Number)
                let diff = (fh * 60 + fm) - (ih * 60 + im)
                if (diff <= 0) { oreCalcolate.text = "⚠ ora fine ≤ inizio"; return }
                let ore = Math.floor(diff / 60)
                let min = diff % 60
                oreCalcolate.text = " " + ore + "h " + (min > 0 ? min + "min" : "") + " (" + (diff/60).toFixed(2) + " ore)"
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
                    Rectangle {
                        height: 32
                        width: btnAggiungiLabel.implicitWidth + 20   // larghezza dinamica sul testo
                        radius: 8
                        color: "#1565C0"
                        Layout.rightMargin: 6

                        Rectangle {
                            anchors.fill: parent
                            radius: 8
                            color: "#ffffff"
                            opacity: 0.15
                        }

                        Text {
                            id: btnAggiungiLabel
                            anchors.centerIn: parent
                            text: "AGGIUNGI"
                            font.pixelSize: 13
                            font.bold: true
                            color: "#ffffff"
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onPressed: parent.color = "#1976D2"
                            onReleased: parent.color = "#1565C0"
                            onClicked: popupInserisciStr.open()
                        }
                    }
                }
            }

            Connections {
                target: Backend
                function onStraordinariRicevuti(lista, totale) {
                    paginaStraordinari.listaStr = lista
                    paginaStraordinari.totaleOre = totale
                }
                function onOperazioneCompletata(msg) {
                    popupInserisciStr.close()
                    popupConfermaElimina.close()   
                    let oggi = new Date()
                    Backend.caricaStraordinariMese(
                        idDatabase,
                        parseInt(comboAnnoStr.currentText),
                        comboMeseStr.currentIndex + 1
                    )
                }
                function onErroreOperazione(msg) {
                    errLabel.text = msg
                }
            }

            Component.onCompleted: {
                let oggi = new Date()
                comboMeseStr.currentIndex = oggi.getMonth()      // 0-based
                comboAnnoStr.currentIndex = comboAnnoStr.model.indexOf(oggi.getFullYear().toString())
                Backend.caricaStraordinariMese(idDatabase, oggi.getFullYear(), oggi.getMonth() + 1)
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10

                // ── Filtro mese / anno ───────────────────────────────────
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    ComboBox {
                        id: comboMeseStr
                        Layout.fillWidth: true
                        model: ["Gennaio","Febbraio","Marzo","Aprile","Maggio","Giugno",
                                "Luglio","Agosto","Settembre","Ottobre","Novembre","Dicembre"]
                        onActivated: Backend.caricaStraordinariMese(
                            idDatabase,
                            parseInt(comboAnnoStr.currentText),
                            currentIndex + 1
                        )
                    }

                    ComboBox {
                        id: comboAnnoStr
                        Layout.preferredWidth: 90
                        model: {
                            let anni = []
                            for (let a = 2028; a >= 2026; a--)
                                anni.push(a.toString())
                            return anni
                        }
                        onActivated: Backend.caricaStraordinariMese(
                            idDatabase,
                            parseInt(currentText),
                            comboMeseStr.currentIndex + 1
                        )
                    }
                }

                Label {
                    text: "Totale ore: " + paginaStraordinari.totaleOre.toFixed(1)
                    font.bold: true
                    color: "#1565C0"
                }

                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: paginaStraordinari.listaStr

                    delegate: ItemDelegate {
                        width: parent.width
                        padding: 0

                        contentItem: RowLayout {
                            spacing: 0

                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.margins: 10
                                spacing: 2

                                Label {
                                    text: " " + modelData.dataITA + "    " + modelData.oraInizio + " → " + modelData.oraFine + "   (" + modelData.ore + " ore)"
                                    font.pixelSize: 13
                                    font.bold: true
                                }
                                Label {
                                    visible: modelData.nota !== ""
                                    text: " " + modelData.nota
                                    font.pixelSize: 12
                                    color: "gray"
                                }
                            }

                            Rectangle {
                                width: 70
                                height: 34
                                color: eliminaArea.pressed ? "#c62828" : "#ef5350"
                                radius: 6
                                Layout.rightMargin: 8
                                Layout.alignment: Qt.AlignVCenter

                                Text {
                                    anchors.centerIn: parent
                                    text: "Elimina"
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: "white"
                                }

                                MouseArea {
                                    id: eliminaArea
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: popupConfermaElimina.apri(modelData.id, modelData.dataITA, modelData.ore)
                                }
                            }
                        }

                        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: "#ddd" }
                    }

                    Label {
                        anchors.centerIn: parent
                        text: "Nessuno straordinario questo mese"
                        visible: paginaStraordinari.listaStr.length === 0
                        color: "gray"
                    }
                }
            }

            // ── Popup inserimento ─────────────────────────────────
            Popup {
                id: popupInserisciStr
                anchors.centerIn: parent
                width: parent.width * 0.9
                modal: true
                focus: true
                closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

                onOpened: {
                    // default: data odierna in formato ISO
                    let oggi = new Date()
                    let mm = String(oggi.getMonth() + 1).padStart(2, "0")
                    let dd = String(oggi.getDate()).padStart(2, "0")
                    campoDataStr.text = dd + "-" + mm + "-" + oggi.getFullYear()
                    campoOraInizio.text = ""
                    campoOraFine.text  = ""
                    campoNota.text     = ""
                    oreCalcolate.text  = ""
                    errLabel.text      = ""
                }

                background: Rectangle { radius: 10; color: "white"; border.color: "#1565C0"; border.width: 2 }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    Label {
                        text: "INSERISCI STRAORDINARIO"
                        font.bold: true
                        font.pixelSize: 15
                        color: "#1565C0"
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Label { text: "Data (GG-MM-AAAA)"; font.bold: true }
                    DateMaskField {
                        id: campoDataStr
                        Layout.fillWidth: true
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        ColumnLayout {
                            Layout.fillWidth: true
                            Label { text: "Dalle ore (HH:MM)"; font.bold: true }
                            TextField {
                                id: campoOraInizio
                                placeholderText: "08:00"
                                maximumLength: 5
                                inputMethodHints: Qt.ImhDigitsOnly
                                Layout.fillWidth: true
                                property bool _applying: false
                                onTextChanged: {
                                    if (_applying) return
                                    _applying = true
                                    let raw = text.replace(/[^0-9]/g, "")
                                    let masked = raw.length >= 3 ? raw.slice(0,2) + ":" + raw.slice(2,4) : raw
                                    if (text !== masked) {
                                        let pos = cursorPosition
                                        text = masked
                                        cursorPosition = Math.min(pos <= 2 ? pos : pos + 1, masked.length)
                                    }
                                    _applying = false
                                    paginaStraordinari.ricalcolaOre()
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Label { text: "Alle ore (HH:MM)"; font.bold: true }
                            TextField {
                                id: campoOraFine
                                placeholderText: "10:00"
                                maximumLength: 5
                                inputMethodHints: Qt.ImhDigitsOnly
                                Layout.fillWidth: true
                                property bool _applying: false
                                onTextChanged: {
                                    if (_applying) return
                                    _applying = true
                                    let raw = text.replace(/[^0-9]/g, "")
                                    let masked = raw.length >= 3 ? raw.slice(0,2) + ":" + raw.slice(2,4) : raw
                                    if (text !== masked) {
                                        let pos = cursorPosition
                                        text = masked
                                        cursorPosition = Math.min(pos <= 2 ? pos : pos + 1, masked.length)
                                    }
                                    _applying = false
                                    paginaStraordinari.ricalcolaOre()
                                }
                            }
                        }
                    }

                    Label {
                        id: oreCalcolate
                        text: ""
                        color: "#1565C0"
                        font.pixelSize: 13
                        font.bold: true
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Label { text: "Nota (opzionale)"; font.bold: true }
                    TextField {
                        id: campoNota
                        placeholderText: "es. Piantone, Ordinanza..."
                        Layout.fillWidth: true
                    }

                    Label {
                        id: errLabel
                        text: ""
                        color: "red"
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                        visible: text !== ""
                    }

                    Button {
                        text: "SALVA"
                        Layout.fillWidth: true
                        enabled: campoDataStr.text.length === 10 &&
                                campoOraInizio.text.length === 5 &&
                                campoOraFine.text.length === 5
                        onClicked: {
                            errLabel.text = ""
                            // Converti data GG-MM-YYYY → YYYY-MM-DD
                            let parti = campoDataStr.text.split("-")
                            if (parti.length !== 3) { errLabel.text = "Data non valida"; return }
                            let dataISO = parti[2] + "-" + parti[1] + "-" + parti[0]

                            let inizio = paginaStraordinari.formattaOra(campoOraInizio.text)
                            let fine   = paginaStraordinari.formattaOra(campoOraFine.text)
                            if (!inizio || !fine) { errLabel.text = "Orario non valido (usa HH:MM)"; return }

                            Backend.salvaOreStraordinario(idDatabase, dataISO, inizio, fine, campoNota.text.trim())
                        }
                    }

                    Button {
                        text: "ANNULLA"
                        Layout.fillWidth: true
                        onClicked: popupInserisciStr.close()
                    }
                }
            }
            Popup {
                id: popupConfermaElimina
                anchors.centerIn: parent
                width: parent.width * 0.85
                modal: true
                focus: true

                property int idDaEliminare: -1

                function apri(id, data, ore) {
                    idDaEliminare = id
                    labelConferma.text = "Eliminare lo straordinario del\n" + data + " (" + ore + " ore)?"
                    open()
                }

                background: Rectangle { radius: 10; color: "white"; border.color: "#ef5350"; border.width: 2 }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 14

                    Label {
                        text: "⚠ CONFERMA ELIMINAZIONE"
                        font.bold: true
                        font.pixelSize: 14
                        color: "#ef5350"
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Label {
                        id: labelConferma
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: 13
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Button {
                            text: "ANNULLA"
                            Layout.fillWidth: true
                            onClicked: popupConfermaElimina.close()
                        }

                        Button {
                            text: "ELIMINA"
                            Layout.fillWidth: true
                            background: Rectangle { radius: 4; color: eliminaBtn.pressed ? "#c62828" : "#ef5350" }
                            id: eliminaBtn
                            contentItem: Text {
                                text: "ELIMINA"
                                color: "white"
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            onClicked: {
                                Backend.eliminaStraordinario(popupConfermaElimina.idDaEliminare)
                                popupConfermaElimina.close()
                            }
                        }
                    }
                }
            }
        }
    }
}