class epson_string {

	function apri_fiscale() {
		stringa = "printerFiscalReceipt";
		stringa += "\n";
		stringa += "Printer|1";
		stringa += "\n";
		return stringa;
	}

	function omaggio(importo, reparto) {
		stringa = "printRecSubtotalAdjustment|1|OMAGGIO|0|" + number_format(Math.abs(importo), 2, ",", "") + "|" + reparto +
			"|1|";
		stringa += "\n";
		stringa += "printRecSubtotal|3|1";
		stringa += "\n";
		return stringa;
	}

	function sconto(importo, reparto) {
		stringa = "printRecItemAdjustment|3|SCONTO|0|" + number_format(round(importo, 2), 2, ",", "") + "|" + reparto +
			"|1|";
		stringa += "\n";
		return stringa;
	}

	function acconto_non_fiscale(acccontoNonFiscale) {
		stringa = "printRecMessage|1|4|1|1|" + acccontoNonFiscale.substr(0, 30);
		return stringa;
	}

	function sconto_su_totale(descrizione, totale, reparto) {
		stringa = "printRecItemAdjustment|1|" + descrizione.substr(0, 30) + "|1|" +
			number_format(Math.abs(totale), 2, ",", "") + "|" + reparto + "|1|";
		return stringa;
	}

	function sconto_scaglione(descrizione) {
		stringa = "printRecMessage|1|4|1|1|" + descrizione.substr(0, 30);
		return stringa;
	}

	function rimborso(descrizione, quantita, importo, reparto) {
		stringa = "printRecRefund|1|" + descrizione.substr(0, 30) + "|" + number_format(quantita, 3, ",", "") + "|" +
			number_format(Math.abs(importo), 2, ",", "") + "|" + reparto + "|1";
		stringa += "\n";
		return stringa;
	}

	function riga_articolo(descrizione, quantita, importo, reparto) {
		stringa = "printRecItem|1|" + descrizione + "|" + number_format(quantita, 3, ",", "") + "|" +
			number_format(Math.abs(importo), 2, ",", "") + "|" + reparto + "|1";
		stringa += "\n";
		return stringa;
	}
}