import QtQuick
import QtQuick.Controls
import QtQuick.Layouts



Window {
    id: window
    width: 360
    height: 640
    visible: true
    title: "Gestore Riposi"
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
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 20

                Label { text: "ACCESSO"; font.bold: true; Layout.alignment: Qt.AlignHCenter }

                TextField { id: cipInput; placeholderText: "Inserisci CIP"; Layout.fillWidth: true }

                Button {
                    text: "ACCEDI"
                    onClicked: Backend.login(cipInput.text)
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
            readonly property var adminIDs: ["1", "2", "3", "19"]

            header: ToolBar {
                id: menuHeader
                Text {
                    id: txtNewPlus
                    text: "NOTIFICHE"
                    color: "red"
                    font.bold: true
                    visible: paginaMenu.mostraNotifica
                    anchors.left: parent.left
                    anchors.leftMargin: 15
                    anchors.verticalCenter: parent.verticalCenter
                    SequentialAnimation on opacity {
                        loops: Animation.Infinite
                        NumberAnimation { to: 0; duration: 500 }
                        NumberAnimation { to: 1; duration: 500 }
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
            }
            Component.onCompleted: {
                Qt.callLater(function() {
                    if (idDatabase !== "") {
                        Backend.contaNotificheNonLette(parseInt(idDatabase));
                    }
                });
            }
            Timer {
                id: notificheTimer
                interval: 30000  
                repeat: true
                running: true    
                onTriggered: {
                    if (idDatabase !== "") {
                        Backend.contaNotificheNonLette(parseInt(idDatabase))
                    }
                }
            }
            Connections {
                target: Backend
                function onMostraNotificaChanged() { 
                    if (Backend.mostraNotifica) {
                        popupNotifica.open(); 
                    }
                }
                function onNotificheRicevute(lista) {
                    paginaMenu.listaNotifiche = lista
                }
            }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 15
                width: parent.width * 0.8

                Label {
                    text: "Benvenuto, " + paginaMenu.utente
                    horizontalAlignment: Text.AlignHCenter
                    Layout.fillWidth: true
                    font.pixelSize: 18
                    color: "#333"
                }
                Label {
                    text: "⚠️ MODIFICHE BLOCCATE DALL'ADMIN"
                    color: "red"
                    font.bold: true
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    visible: false // Potrai collegarlo a una property del Backend se vuoi automatizzarlo
                }

                Button {
                    text: "REPORT"
                    Layout.fillWidth: true
                    onClicked: stack.push(reportPage, {"idDatabase": paginaMenu.idDatabase})
                }

                Button {
                    text: "VISUALIZZA SPECCHIO"
                    Layout.fillWidth: true
                    onClicked: stack.push(specchioPage, {
                                    "idDatabase": paginaMenu.idDatabase,
                                    "utente": paginaMenu.utente
                                })
                }

                Button {
                    text: " INSERISCI NUOVO RIPOSO"
                    Layout.fillWidth: true
                    onClicked: stack.push(inserimentoPage, {"idDatabase": paginaMenu.idDatabase})
                }
                Button {
                    text: " FRUIZIONE RIPOSO"
                    Layout.fillWidth: true
                    onClicked: stack.push(fruizionePage, {"idDatabase": paginaMenu.idDatabase})
                }
                Button {
                    text: " MODIFICA RIPOSO"
                    Layout.fillWidth: true
                    onClicked: stack.push(modificaPage, {"idDatabase": paginaMenu.idDatabase})
                }
                Button {
                    text: " CANCELLA RIPOSO"
                    Layout.fillWidth: true
                    onClicked: stack.push(cancellaPage, {"idDatabase": paginaMenu.idDatabase})
                }
                Button {
                    text: " ESCI"
                    Layout.fillWidth: true
                    palette.button: "red"
                    palette.buttonText: "white"
                    onClicked: stack.pop()
                }
            }
            Popup {
                id: popupNotifiche
                anchors.centerIn: parent
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
                        Component.onCompleted: currentIndex = new Date().getMonth() // Imposta mese corrente
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
                                                        let dataMat = trovato.maturato ? trovato.maturato : "N.D.";
                                                        globalErrorLabel.text = "Attenzione: è presente un " + tipo + "\nmaturato il: " + dataMat + ".\nDevi prima rimuoverlo."
                                                        globalErrorPopup.open()
                                                    }
                                                } else {
                                                    let riga = utenteDellaRiga.trim().toUpperCase();
                                                    let loggato = paginaSpecchio.utente.trim().toUpperCase();
                                                    let paroleLoggato = loggato.split(" ");
                                                    let corrisponde = paroleLoggato.length > 0 && paroleLoggato.every(parola => riga.includes(parola));
                                                    if (corrisponde) {
                                                        popupLicenza.utenteSelezionato = paginaSpecchio.idDatabase
                                                        popupLicenza.dataSelezionata = dataFinale
                                                        popupLicenza.campoCodice.text = "";
                                                        popupLicenza.open()
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
                                                if (!trovato || !trovato.tipo) return trovato.colore;
                                                let t = trovato.tipo.toUpperCase()
                                                if (t.indexOf("SETTIMANALE") !== -1) return "#F44336"; // Rosso
                                                if (t.indexOf("FESTIVO") !== -1)     return "#FF9800"; // Arancio
                                                if (t.indexOf("MEDICO") !== -1)      return "#2196F3"; // Blu
                                                if (t.indexOf("STUDIO") !== -1)      return "#333333"; // Nero
                                                if (t.indexOf("SANGUE") !== -1)      return "#8B4513"; // MARRONE
                                                if (t.indexOf("LICENZA") !== -1)     return "#9C27B0";
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
                            anchors.horizontalCenter: parent
                        }

                       Row {
                            spacing: 20
                            anchors.horizontalCenter: parent

                            Button {
                                text: "Approva Richieste Riposi"
                                onClicked: {
                                    let listaDaInviare = [];
                                    let idDestinatario = -1;
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
                                    console.log("DEBUG FILTRO: Da", dInizio.toLocaleDateString(), "A", dFine.toLocaleDateString());
                                    for(let i=0; i < paginaSpecchio.datiRiposi.length; i++) {
                                        let item = paginaSpecchio.datiRiposi[i];
                                        if (!item) continue;
                                        let annoCorrente = parseInt(comboAnno.currentText);
                                        let meseCorrente = parseInt(comboMese.valoreMese) - 1;
                                        let giornoCorrente = parseInt(item.d);
                                        let dataItem = new Date(annoCorrente, meseCorrente, giornoCorrente);
                                        dataItem.setHours(0, 0, 0, 0);
                                        let statoNormalizzato = item.stato ? item.stato.toString().toUpperCase() : "";
                                        if (item.id_riposo === 741) {
                                            console.log("PITINO RICOSTRUITO:", dataItem.toLocaleDateString());
                                        }
                                        if(statoNormalizzato === "RICHIESTO" || statoNormalizzato === "PENDENTE") {
                                            if (dataItem >= dInizio && dataItem <= dFine) {
                                                if (item.id_riposo) {
                                                    listaDaInviare.push(Number(item.id_riposo));
                                                    idDestinatario = item.id_reale;
                                                }
                                            }
                                        }
                                    }
                                    if(listaDaInviare.length > 0) {
                                        console.log("ID TROVATI:", listaDaInviare);
                                        Backend.processaValidazioni(listaDaInviare, true, paginaSpecchio.utente, idDestinatario)
                                    } else {
                                        console.log("Nessun riposo da approvare trovato nell'array datiRiposi")
                                    }
                                }
                            }
                            Button {
                                text: "📄 Stampa PDF"
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
                                contentItem: Text {
                                    text: parent.text
                                    color: "#d32f2f" 
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    font.bold: true
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
                                        if ((statoN === "RICHIESTO" || statoN === "PENDENTE") &&
                                            dataItem >= dInizio && dataItem <= dFine && item.id_riposo) {
                                            lista.push({
                                                id_riposo:  Number(item.id_riposo),
                                                id_reale:   item.id_reale,
                                                utente:     item.u,
                                                giorno:     item.d,
                                                tipo:       item.tipo,
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

            Popup {
                id: popupLicenza
                width: 250
                height: 200
                modal: true
                focus: true
                anchors.centerIn: parent
                closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

                property string utenteSelezionato: ""
                property string dataSelezionata: ""
                property alias campoCodice: inputCodice
                background: Rectangle {
                    radius: 10
                    border.color: "#2196F3"
                    border.width: 2
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 15
                    Label {
                        text: "Inserisci Licenza"
                        font.bold: true
                        Layout.alignment: Qt.AlignHCenter
                    }
                    TextField {
                        id: inputCodice
                        placeholderText: "Es: LO, LS ..."
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        maximumLength: 5 // Opzionale: evita testi troppo lunghi
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Button {
                            text: "SALVA"
                            Layout.fillWidth: true
                            onClicked: {
                                console.log("Valore inserito nel popup: " + inputCodice.text)
                                if (paginaSpecchio.idDatabase === "" || paginaSpecchio.idDatabase === undefined) {
                                    console.error("ERRORE: idDatabase è vuoto!")
                                    return
                                }
                                Backend.salvaLicenzaPersonale(paginaSpecchio.idDatabase, popupLicenza.dataSelezionata, inputCodice.text)
                                popupLicenza.close()
                                Backend.caricaSpecchioAdmin(txtMese.text, txtAnno.text)
                            }
                        }
                        Button {
                            text: "CHIUDI"
                            Layout.fillWidth: true
                            onClicked: {
                            popupLicenza.close()
                            }
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
                        text: "❌ Seleziona le richieste da RIFIUTARE"
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
                                        text: "Giorno " + modelData.giorno + " — " + modelData.tipo
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
                        text: "❌  RIFIUTA SELEZIONATE"
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
                    popupEliminaLicenza.close()
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
                    id: comboTipoNuovo;
                    model: ["SETTIMANALE", "FESTIVO", "MEDICO", "STUDIO", "SANGUE", "ALTRO"];
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
                                  "✅ Libero (Nessuna data assegnata)"
                            font.pixelSize: 13
                            color: modelData.dataFruizioneITA !== "" ? "#E64A19" : "#388E3C"
                        }
                    }
                    onClicked: {
                        selectedDataMaturazioneISO.text = modelData.dataISO
                        labelDataMaturazioneBella.text = "Riposo del: " + modelData.dataITA

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

            Popup {
                id: popupFruisci
                anchors.centerIn: parent
                width: parent.width * 0.9
                modal: true
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 10
                    Text { id: selectedDataMaturazioneISO; visible: false }
                    Label { id: labelDataMaturazioneBella; font.bold: true; horizontalAlignment: Text.AlignHCenter }
                    Label { text: "In quale data vuoi usarlo?" }
                    DateMaskField { id: dataFruizioneInput; Layout.fillWidth: true }
                    ComboBox {
                        id: comboStato
                        model: ["RICHIESTO", "VALIDATO"]
                        Layout.fillWidth: true
                    }
                    Button {
                        text: "CONFERMA FRUIZIONE"
                        Layout.fillWidth: true
                        onClicked: {
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
                    Backend.caricaRiposiDisponibili(paginaFruizione.idDatabase)
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
                }

                Rectangle { height: 1; Layout.fillWidth: true; color: "#ccc" }

                Label { text: "NUOVI DATI:"; font.bold: true; color: "#2196F3" }

                ComboBox {
                    id: comboNuovoTipo
                    model: ["SETTIMANALE", "FESTIVO", "MEDICO", "STUDIO", "SANGUE", "ALTRO"]
                    Layout.fillWidth: true
                }

                ComboBox {
                    id: comboNuovoStato
                    model: ["ACQUISITO", "RICHIESTO", "VALIDATO"]
                    Layout.fillWidth: true
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
                }

                Button {
                    text: "ELIMINA"
                    Layout.fillWidth: true
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
                            text: "ELIMINA"
                            Layout.fillWidth: true
                            palette.button: "red"; palette.buttonText: "red"
                            onClicked: {
                                Backend.cancellaRiposoEffettivo(idDatabase, dataDaEliminare.text)
                                popupConfermaElimina.close()
                            }
                        }
                        Button {
                            text: "ANNULLA"
                            Layout.fillWidth: true
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

    Popup {
        id: popupConfigBlocco
        anchors.centerIn: parent
        width: parent.width * 0.9
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
}