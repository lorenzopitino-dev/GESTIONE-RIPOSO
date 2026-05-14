window.generaPDFSpecchio = async function(utenti, dati, giorni, inizio, fine) {
    const jsPDFCtor = (window.jspdf && window.jspdf.jsPDF) ? window.jspdf.jsPDF : (window.jsPDF || null);
    if (!jsPDFCtor) {
        const start = Date.now();
        while (!((window.jspdf && window.jspdf.jsPDF) || window.jsPDF) && (Date.now() - start) < 5000) {
        await new Promise(r => setTimeout(r, 50));
        }
    }
    const jsPDFFinal = (window.jspdf && window.jspdf.jsPDF) ? window.jspdf.jsPDF : (window.jsPDF || null);
    if (!jsPDFFinal) {
        console.error("jspdf non disponibile");
        throw new Error("jspdf non disponibile");
    }

    const doc = new jsPDFFinal({ orientation: "landscape", unit: "mm", format: "a4" });

    // Prepara giorni del periodo
    const GIORNI_ITA = ['DOM','LUN','MAR','MER','GIO','VEN','SAB'];
    const giorniPeriodo = [];
    let cur = new Date(inizio + "T00:00:00");
    const fineDate = new Date(fine + "T00:00:00");
    while (cur <= fineDate) {
        giorniPeriodo.push({ giorno: cur.getDate(), nomeDayG: GIORNI_ITA[cur.getDay()] });
        cur.setDate(cur.getDate() + 1);
    }

    const coloreTesto = (tipo) => {
        if (!tipo) return [0, 0, 0];
        const t = tipo.toUpperCase();
        if (t.includes("SETTIMANALE")) return [244, 67,  54];
        if (t.includes("FESTIVO"))     return [255,152,   0];
        if (t.includes("MEDICO"))      return [ 33,150, 243];
        if (t.includes("STUDIO"))      return [ 50, 50,  50];
        if (t.includes("SANGUE"))      return [139, 69,  19];
        if (t.includes("LICENZA"))     return [156, 39, 176];
        return [76, 175, 80];
    };

    // Header grafico
    doc.setFillColor(21, 101, 192);
    doc.rect(0, 0, 297, 16, "F");
    doc.setTextColor(255, 255, 255);
    doc.setFontSize(12);
    try { doc.setFont(undefined, "bold"); } catch(e) {}
    doc.text("SPECCHIO RIPOSI - Periodo Blocco", 148, 8, { align: "center" });
    doc.setFontSize(8);
    try { doc.setFont(undefined, "normal"); } catch(e) {}
    doc.text("Dal: " + inizio + "   Al: " + fine, 148, 14, { align: "center" });
    doc.setTextColor(0, 0, 0);

    // Head e body per autoTable
    const headRow = [
        { content: "UTENTE", rowSpan: 1, styles: { halign: "left" } },
        ...giorniPeriodo.map(g => ({ content: g.giorno + "\n" + g.nomeDayG, styles: { halign: "center" } }))
    ];

    const listaUtenti = Array.isArray(utenti) && utenti.length > 0
        ? utenti
        : [...new Set(dati.map(item => item.u))];

    const body = listaUtenti.map(nomeUtente => {
        const celle = giorniPeriodo.map(g => {
            const trovato = dati.find(item => item.u === nomeUtente && Number(item.d) === g.giorno);
            return trovato ? (trovato.a || "") : "";
        });
        return [nomeUtente, ...celle];
    });

    const pageWidth   = doc.internal.pageSize.getWidth(); // 297 mm in landscape A4
    const marginLeft  = 10;
    const marginRight = 10;
    const usableWidth = pageWidth - marginLeft - marginRight; // 277 mm effettivi
    const nomeW       = 45;
    const disponibile = usableWidth - nomeW;                  // 232 mm per le celle giorno
    const MAX_CELL_W  = 12;
    const cellWCalc   = parseFloat((disponibile / Math.max(1, giorniPeriodo.length)).toFixed(3));
    const cellW       = Math.min(cellWCalc, MAX_CELL_W);
    const colStyles = { 0: { cellWidth: nomeW, halign: "left", fontStyle: "bold", fontSize: 7 } };
    for (let i = 1; i <= giorniPeriodo.length; i++)
        colStyles[i] = { cellWidth: cellW, halign: "center", fontSize: 6 };

    // Verifica che autoTable sia disponibile
    if (typeof doc.autoTable !== "function") {
        // Se non disponibile, log e proviamo a usare plugin globale (fallback)
        if (window.jspdf && typeof window.jspdf.autoTable === "function") {
            // alcuni bundle espongono autoTable come funzione globale che accetta (doc, options)
            window.jspdf.autoTable(doc, {
                head: [headRow],
                body: body,
                startY: 18,
                margin: { left: marginLeft, right: marginRight },
                tableWidth: "wrap",
                styles: { fontSize: 7, cellPadding: { top: 1.5, bottom: 1.5, left: 1, right: 1 }, lineColor: [180, 180, 180], lineWidth: 0.3, overflow: "ellipsize", minCellHeight: 8 },
                headStyles: { fillColor: [21, 101, 192], textColor: [255, 255, 255], fontStyle: "bold", fontSize: 7, halign: "center", minCellHeight: 12 },
                alternateRowStyles: { fillColor: [245, 248, 255] },
                columnStyles: colStyles,
                didParseCell: function(hookData) {
                    if (hookData.section !== "body" || hookData.column.index === 0) return;
                    const idx = hookData.row.index;
                    const colIdx = hookData.column.index - 1;
                    if (colIdx >= giorniPeriodo.length) return;
                    const nomeU = listaUtenti[idx];
                    const g = giorniPeriodo[colIdx];
                    const trovato = dati.find(item => item.u === nomeU && Number(item.d) === g.giorno);
                    if (trovato && trovato.tipo && hookData.cell.raw !== "") {
                        const [r, gv, b] = coloreTesto(trovato.tipo);
                        hookData.cell.styles.textColor = [r, gv, b];
                        hookData.cell.styles.fontStyle = "bold";
                    }
                }
            });
        } else {
            console.error("autoTable non disponibile");
            throw new Error("autoTable non disponibile");
        }
    } else {
        // Uso normale doc.autoTable
        doc.autoTable({
            head: [headRow],
            body: body,
            startY: 18,
            margin: { left: marginLeft, right: marginRight },
            styles: { fontSize: 7, cellPadding: { top: 1.5, bottom: 1.5, left: 1, right: 1 }, lineColor: [180, 180, 180], lineWidth: 0.3, overflow: "ellipsize", minCellHeight: 8 },
            headStyles: { fillColor: [21, 101, 192], textColor: [255, 255, 255], fontStyle: "bold", fontSize: 7, halign: "center", minCellHeight: 12 },
            alternateRowStyles: { fillColor: [245, 248, 255] },
            columnStyles: colStyles,
            didParseCell: function(hookData) {
                if (hookData.section !== "body" || hookData.column.index === 0) return;
                const idx = hookData.row.index;
                const colIdx = hookData.column.index - 1;
                if (colIdx >= giorniPeriodo.length) return;
                const nomeU = listaUtenti[idx];
                const g = giorniPeriodo[colIdx];
                const trovato = dati.find(item => item.u === nomeU && Number(item.d) === g.giorno);
                if (trovato && trovato.tipo && hookData.cell.raw !== "") {
                    const [r, gv, b] = coloreTesto(trovato.tipo);
                    hookData.cell.styles.textColor = [r, gv, b];
                    hookData.cell.styles.fontStyle = "bold";
                }
            }
        });
    }
    const pdfBlob = doc.output("blob");
    const blobUrl = URL.createObjectURL(pdfBlob);
    const link = document.createElement("a");
    link.href = blobUrl;
    link.download = "specchio_riposi_" + inizio + "_" + fine + ".pdf";
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    setTimeout(() => URL.revokeObjectURL(blobUrl), 2000);
    return pdfBlob;
};
window.pdfJsReady = true;