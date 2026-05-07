import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Window {
    id: window
    width: 360
    height: 640
    visible: true
    title: "Gestore Riposi"

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
        function onLoginSuccess(nomeCompleto, idSeriale) {
            stack.push(menuPage, {"utente": nomeCompleto, "idDatabase": idSeriale})
        }
        function onOperazioneCompletata(messaggio) {
            let currentPage = stack.currentItem; // Dichiarazione corretta della variabile

            if (currentPage && currentPage.objectName === "paginaSpecchio") {
                console.log("Aggiornamento specchio in corso...");

                    // Recupero mese e anno dalle proprietà esposte della pagina
                let m = currentPage.meseSelezionato.padStart(2, '0');
                let a = currentPage.annoSelezionato;

                    // Calcolo dinamico dell'ultimo giorno del mese
                let ultimoGiorno = new Date(a, m, 0).getDate();

                Backend.caricaSpecchioAdmin("01-" + m + "-" + a, ultimoGiorno + "-" + m + "-" + a);
            }
            else if (currentPage && currentPage.objectName === "paginaRiposi") {
                Backend.caricaRiposi(currentPage.idDatabase);
            }
            else {
                // Torna al menu solo se non siamo in una delle pagine sopra
                stack.pop();
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

            // Quando il login va a buon fine, "spingiamo" la nuova pagina nello stack
            Connections {
                target: Backend
                function onLoginSuccess(nomeCompleto, idSeriale) {
                    stack.push(menuPage, {"utente": nomeCompleto, "idDatabase": idSeriale})
                }
            }
        }
    }

    // --- PAGINA 2: MENU PRINCIPALE ---
    Component {
        id: menuPage
        Page {
            id: paginaMenu
            property string utente: ""
            property string idDatabase: ""

            header: ToolBar {
                Label {
                    text: "MENU PRINCIPALE"
                    font.bold: true
                    anchors.centerIn: parent
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

                Button {
                    text: "📊 REPORT"
                    Layout.fillWidth: true
                    onClicked: stack.push(reportPage, {"idDatabase": paginaMenu.idDatabase})
                }

                Button {
                    text: "📅 VISUALIZZA SPECCHIO"
                    Layout.fillWidth: true
                    onClicked: stack.push(specchioPage, {
                                    "idDatabase": idDatabase,
                                    "utente": utente
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
            property alias meseSelezionato: txtMese.text // Espone il testo del TextField mese
            property alias annoSelezionato: txtAnno.text
            property var listaUtenti: []
            property var datiRiposi: []
            property int totalDays: 31
            property string idDatabase: ""
            property string utente: ""

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
                    TextField { id: txtMese; placeholderText: "MM"; Layout.preferredWidth: 60; horizontalAlignment: Text.AlignHCenter }
                    Label {text: "/" }
                    TextField { id: txtAnno; placeholderText: "AAAA"; Layout.preferredWidth: 80; horizontalAlignment: Text.AlignHCenter }
                    Button {
                        text: "CARICA RIPOSI";
                        onClicked: {
                            let m = txtMese.text;
                            let a = txtAnno.text;
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
                                        Label {
                                            text: {
                                                let d = new Date(txtAnno.text, txtMese.text - 1, index + 1);
                                                let giorni = ["DOM", "LUN", "MAR", "MER", "GIO", "VEN", "SAB"];
                                                return giorni[d.getDay()];
                                            }
                                            font.pixelSize: 9; color: "#666";
                                            Layout.alignment: Qt.AlignHCenter
                                        }
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
                                        width: 40; height: 50; color: utenteDellaRiga === paginaSpecchio.idDatabase ? "#FFF9C4" : "white"; border.color: "#ccc"
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
                                                let trovato = cellaDelegata.helper.cerca();
                                                let g = (index + 1).toString().padStart(2, '0');
                                                let m = txtMese.text.padStart(2, '0');
                                                let a = txtAnno.text;
                                                let dataFinale = a + "-" + m + "-" + g;
                                                console.log("PROVA INVIO DATA: " + dataFinale);
                                                if (trovato) {
                                                    let tipo = trovato.tipo.toUpperCase();
                                                    if (tipo === "LICENZA") {
                                                        popupEliminaLicenza.dataSelezionata = dataFinale
                                                        popupEliminaLicenza.idUtenteSelezionato = trovato.id_reale
                                                        popupEliminaLicenza.open()
                                                    } else {
                                                        let dataMat = trovato.maturato ? trovato.maturato : "N.D.";
                                                        globalErrorLabel.text = "Attenzione: è presente un " + tipo + "\nmaturato il: " + dataMat + ".\nDevi prima rimuoverlo."
                                                        globalErrorPopup.open()
                                                    }
                                                } else {
                                                    popupLicenza.utenteSelezionato = paginaSpecchio.idDatabase
                                                    popupLicenza.dataSelezionata = dataFinale
                                                    popupLicenza.open()
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
                                                if (!trovato || !trovato.tipo) return "transparent";
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
                    Backend.caricaSpecchioAdmin(txtMese.text, txtAnno.text)
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

                TextField {
                    id: campoDataNuova;
                    Layout.fillWidth: true
                    font.pixelSize: 16;
                    horizontalAlignment: Text.AlignLeft
                    placeholderText: "INSERISCI DATA";
                    background: Rectangle{
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
                        TextField { id: campoData; placeholderText: "GG-MM-YYYY"; Layout.fillWidth: true }
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
                    TextField { id: dataFruizioneInput; placeholderText: "GG-MM-YYYY"; Layout.fillWidth: true }
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
                        }
                    }
                    Button { text: "ANNULLA"; Layout.fillWidth: true; onClicked: popupFruisci.close() }
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
                TextField {
                    id: dataDaModificare
                    placeholderText: "GG-MM-YYYY"
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

                TextField {
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
}