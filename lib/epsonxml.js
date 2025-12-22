/* I-20190222-VMS-Inizio */
/******************************************************************************
 * Modifiche:                                                                 *
 *  21/02/2019 Valter - Aggiunto gestione data scontrino fiscale.             *
 *  03/03/2020 Valter - Contabilizzazione automatica corrispettivi con dati   *
 *                       reperiti da RT epson.                                *
 *  28/01/2021 Valter - Aggiunto metodo itemAdjSconto.                        *
 *                                                                            *
 ******************************************************************************
 */
/* I-20190221-VMS-Fine   */


// ##tmp_numsf_missing##
// provvisorio, database sotto monitoraggio per problema nr. scontrino fiscale non registrato (demo_generico serve a noi per fare dei test)
//var DB_NUMSF_MISSING = ["grumeza_diana","lvv_distribuzione","felissimo","demo_generico"];


/*
 * La classe epsonxml si occupa di creare la stringa in formato XML
 * da inviare ad una cassa di rete con web server con il protocollo epson
 */


// NOTA: per impartire direttamente un comando attraverso la console javascript, si puo' usare del codice tipo:
//   sessionStorage["cassa_ip_cgi"] = "192.168.16.91";   ex = new epsonxml();  ex.sendData(ex.printerStatus());
//   sessionStorage["cassa_ip_cgi"] = "192.168.16.91";   (new epsonxml()).sendData("<printerCommand><directIO command='2050' data='2800'/></printerCommand>");
// esempio di comando per annullare uno scontrino:
//   sessionStorage["cassa_ip_cgi"] = "192.168.16.91";   ex = new epsonxml();  ex.sendData(ex.annulloDirettoScontrino(46,3,"4/9/2024","99IEB040473"));


// verifica che siano stati inclusi i files necessari
if (typeof varDecisamenteNonValida != "function" || varDecisamenteNonValida(COD_PAG_CONTANTI)) {
   window.alert("ATTENZIONE ! Non sono stati inclusi tutti i files necessari per epsonxml.js !!");
} 


// luca - 20170614 - aggiunto il metodo itemAdjScForBuono dedicato alla stampa di righe di sconto
// ex.data     = des_scontrino
// ex.prezzo   = Math.abs(rS["mov_timpon"]);

var EPSON_XML_SCRIPT_PATH = "/cgi-bin/fpmate.cgi";
var ALERT_MSG_CASSA_NON_RISPONDE = "Il registratore di cassa non risponde. Controllare che sia acceso e collegato.";
var ALERT_MSG_CASSA_PARSER_ERROR = "File XML malformato";
var ALERT_MSG_CASSA_EPTR_REC_EMPTY = "Il registratore di cassa potrebbe essere aperto, offline oppure il rotolo di carta non inserito correttamente. Impossibile emettere scontrini.";
var ALERT_MSG_CASSA_GENERIC = "Il registratore di cassa non puo' emettere lo scontrino o la funzionalita' non puo' essere eseguita. Codice di errore: ";
var ALERT_MSG_CASSA_POS_ERROR = "Pagamento con POS **NON** effettuato";
// i millisecondi necessari per far scattare il timeout di nessuna risposta ricevuta
// Bruno   il 30/10/2019 sperimentalmente avevo allungato il timeout da 5000 a 15000 su Ellegi in quanto andava in timeout un po' troppo spesso
//         il 19/05/2020 lo stesso problema si e' avuto su Sport Store, allora ho deciso di metterlo a 15000 indistintamente a tutti
var EPSON_XML_TIMEOUT_STAMPA = 15000;

var EPSON_XML_RIF_TOT_SCO = "TOT. VENDITA euro";
var EPSON_XML_RIF_SCONTO_SCO = "SC. euro -";
var EPSON_XML_RIF_SC_ACC = "SCONTR.";
var EPSON_XML_BUONO_INCASSO = "Incasso BUONO NUMERO:";
var EPSON_XML_BUONO_RIF_SCO = "RIF.";
var EPSON_XML_BUONO_TOT_SCO = "SALDO";
// codici pagamento per epsonxml e non (al momento)
/*
case 0:descr_pagamento = "CONTANTI";
case 1:descr_pagamento = "ASSEGNI";
case 2:descr_pagamento = "CARTE";
case 3:descr_pagamento = "TICKET";
*/
var EPSON_XML_COD_PAG_CONTANTI     = 0;
var EPSON_XML_COD_PAG_ASSEGNI      = 1;
var EPSON_XML_COD_PAG_CARTE        = 2;
var EPSON_XML_COD_PAG_TICKET       = 3;
var EPSON_XML_COD_PAG_NON_RISCOSSO = 5;
// al pari delle grandi catene applichiamo sul pagamento buoni / gift card la cablatura sul non riscosso
var EPSON_XML_COD_PAG_BUONO      = 22;
var EPSON_XML_COD_PAG_SCONTO_PAGARE = 6;
// etichette pagamento per epsonxml e non (al momento)
var EPSON_XML_DESCR_PAG_CONTANTI          = "CONTANTI";
var EPSON_XML_DESCR_PAG_ASSEGNI           = "ASSEGNI";
var EPSON_XML_DESCR_PAG_CARTE             = "CARTE";
var EPSON_XML_DESCR_PAG_TICKET            = "TICKET";
var EPSON_XML_DESCR_PAG_BUONO             = "BUONO/GIFT CARD";
var EPSON_XML_DESCR_PAG_SCONTO_PAGARE     = "SCONTO A PAGARE";
var EPSON_XML_DESCR_NON_RISCOSSO          = "NON RISCOSSO";
var EPSON_XML_DESCR_NON_RISCOSSO_BENI     = "NON RISCOSSO BENI";
var EPSON_XML_DESCR_NON_RISCOSSO_SERVIZI  = "NON RISCOSSO SERVIZI";
var EPSON_XML_DESCR_NON_RISCOSSO_FATTURA  = "NON RISCOSSO FATTURA";
// associo il tipo di pagamento alla modalita` buono/git card
// quando invio in cassa la riga di totale il paymentType sara` inizializzato con questo valore
// in quando non e` possibile definire un nuovo tipo di pagamento ma soltanto un index alternativo
// al metodo di pagamento originale
// e` stato scelto contante per cui in cassa la voce incrementata alla spesa di un buono sara` contante
// quello che cambia e` la descrizione del metodo di pagamento in fondo allo scontrino fiscale
var EPSON_XML_COD_PAG_BUONO_MASTER = 3;

// Gestione indici di pagamento 
// Protocollo XML 7
var EPSON_XML_INDEX_CONTANTI = 0;
var EPSON_XML_INDEX_BANCOMAT = 1;
var EPSON_XML_INDEX_CARTE_CREDITO = 2;
var EPSON_XML_INDEX_BONIFICO = 3;
var EPSON_XML_INDEX_SATISPAY = 4;
var EPSON_XML_INDEX_ECOMMERCE = 5;

var EPSON_XML_INDEX_GENERIC_TICKET = 1;
var EPSON_XML_INDEX_BUONO = 2;
var EPSON_XML_INDEX_CONTANTI_DOMICILIO = 1;

var EPSON_XML_INDEX_NON_RISCOSSO_ALL = 0;
var EPSON_XML_INDEX_NON_RISCOSSO_BENI = 1;
var EPSON_XML_INDEX_NON_RISCOSSO_SERVIZI = 2;
var EPSON_XML_INDEX_NON_RISCOSSO_FATTURA = 3;

var EPSON_XML_INDEX_DESCR_BANCOMAT = "BANCOMAT";
var EPSON_XML_INDEX_DESCR_CARTE_CREDITO = "CARTA DI CREDITO";
var EPSON_XML_INDEX_DESCR_BONIFICO = "BONIFICO";
var EPSON_XML_INDEX_DESCR_SATISPAY = "SATISPAY";
var EPSON_XML_INDEX_DESCR_ECOMMERCE = "E-COMMERCE";
var EPSON_XML_INDEX_DESCR_CONTANTI_DOMICILIO = "CONTANTI DOMICILIO";

var EPSON_SYMBOL_EURO = EURO_SYMBOL_UNICODE; 

// dicitura di default per printRecMessage reso merce in scontrino
var RT_DICITURA_RESO_MERCE = "REFUND";

// dicitura di default per printRecMessage annullamento in scontrino
var RT_DICITURA_ANNULLO = "VOID";

// dicitura di default per printRecTotal reso merce in scontrino
var RT_DESCR_ITEM_REFUND = "Rimborso merce";

// dicitura di default per printRecTotal annullamento in scontrino
var RT_DESCR_ITEM_VOID = "Cancellazione scontrino";

// necessario per effettuare resi "non consentiti" ovvero che per la cassa sono stati fatti in periodo ancora "non RT"
// e` una soluzione adottata per stampare i nostri resi "secchi" ma per gestire gli scontrini misti con negativi e positivi
// che altrimenti andrebbero in cassa come non fiscale e quindi non registrati
var RT_NUM_MATRICOLA_TAROCCO = "99MEY999999";

// flag che attesta lo stato della cassa EPSON in RT
var RT_FLAG_STATO_ON = 2;

// flag paramentro errato sintomo che dietro c'e` una MF che non accetta il status type
var RT_FLAG_SONO_MF = 16;

// il valore corretto per valutare il periodo di inattivita' della cassa
var RT_NOT_WORKING_PERIOD_OK = 0;

// quanti numeri assume dal progressivo partendo da destra per numerare il reso di giornata
var RT_NUM_DIGIT_RESO_DX = 4;

// quanti numeri dello zRepNumber si devono assumere dalla fine della stringa
var RT_NUM_DIGIT_ZREP_DX = 4;

// flag per controllare DirectIO controllo se scontrino e` refundabile
var RT_REFUND_SCO_FLAG = 1;

// flag per controllare DirectIO controllo se scontrino e` annullabile
var RT_VOIDABLE_SCO_FLAG = 2;


const EPSON_MODE_MF = 0;
const EPSON_MODE_RT_NO_ATTIVA = -1;
const EPSON_MODE_RT_ATTIVA = 1;


/*
   fpmateVersion => versione protocollo FPMATE
   rtType => tipo dispositivo RT
   rtMainStatus => main status
   rtSubStatus => sub status
   rtActStatus + rtSubStatus = actual status
   rtDailyOpen => giorno di apertura corrente (da associare agli scontrini oltre al numero fiscale)
   rtNoWorkingPeriod => periodo inattivo
   rtFileToSend => numero file da inviare all'agenzia delle entrate
   rtOldFileToSend => numero file vecchi da inviare all'agenzia delle entrate
   rtFileRejected => numero di file rifiutati dell'agenzia delle entrate
   rtExpiryCD => data scadenza certificato dispositivo
   rtExpiryCA => data scadenza certificato CA AE
   rtTrainingMode => modalita' demo
   rtSerialNumber => Matricola fiscale della cassa
   rtZRepNumber => numero di giornata fiscale della cassa
*/
var RT_PER_SESSION_KEY = [
   "fpmateVersion",
   "rtType",
   "rtMainStatus",
   "rtSubStatus",
   "rtActStatus",
   "rtDailyOpen",
   "rtNoWorkingPeriod",
   "rtFileToSend",
   "rtOldFileToSend",
   "rtFileRejected",
   "rtExpiryCD",
   "rtExpiryCA",
   "rtNumDaysThres",
   "rtTrainingMode",
   "rtSerialNumber",
   "rtZRepNumber",
   "isRtMode",
   "cpuRel",
   "mfRel",
   "mfStatus"
];




// contatore di comandi in attesa di risposta
var epsonXmlComandiInCorso = 0;

var epsonXmlUltimaStringa = "";

/*
   Gli stati di errore della cassa direttamente da manuale EPSON
   Aggiunto il caso dell'apertura cassetto che restituisce un INCOMPLETE FILE
   con status 0 che in realta' non sarebbe neppure un errore
*/
function decodificaErroriCassa(retMsg, retStats) {

   // in certe casistiche di errore, retMsg e' undefined: lo normalizzo a stringa
   retMsg = NormalizzaStringa(retMsg);
   
   // uso substr per gestire sia FP_NO_ANSWER che FP_NO_ANSWER_NETWORK
   if (retMsg.substr(0,12) == "FP_NO_ANSWER" /*&& !window.SonoInAmbienteSviluppo()*/)
      return ALERT_MSG_CASSA_NON_RISPONDE;
   else if (retMsg == "PARSER_ERROR")
      return ALERT_MSG_CASSA_PARSER_ERROR;
   else if (retMsg == "EPTR_REC_EMPTY")
      return ALERT_MSG_CASSA_EPTR_REC_EMPTY;
   else if (retMsg == "INCOMPLETE FILE" && retStats == 0)
      return "";
   else if (retMsg == "EFT_POS_ERROR")
      return ALERT_MSG_CASSA_POS_ERROR;
   else
      return ALERT_MSG_CASSA_GENERIC + retMsg;

}









function epsonxml() {
   var data = ""; // testo o articolo
   var pagamento = ""; // codice pagamento
   var indicePagamento = undefined; // indice di pagamento in base al codice pagamento
   var qta = ""; // qta acquistata
   var prezzo = ""; // prezzo unitario
   var reparto = ""; // reparto vendita
   var importoPagato = ""; // denaro consegnato
   var descr_totale_reso_rt = ""; // la descrizione impostata quando viene effettuato un reso
   //var index = "";
   var number = "";
   var stringa = "";
   
   this.operatore = "1";    // numero operatore (ci metto 1 come default)
   this.font      = "1";    // numero font (ci metto 1 come default)
   this.recMesNextIndex = 1;     // prossimo valore da utilizzare per attributo index di printRecMessage


   // ip cassa (la preimposto con il default)
   this.ip      = window.GetCassaIpCgi();

   this.timeOut = EPSON_XML_TIMEOUT_STAMPA;     // valore default
   
   this.objEpsonRcv = {};
   
   //this.importoCarta = 0;  // importo pagato con carta
   
   // visto che adesso il file e' condiviso tra VB e ProRisto e utilizzato in N posti diversi, non fa male
   // controllare che sia stato incluso il fiscalPrint.js della Epson
   if (typeof window.epson != "object" || typeof window.epson.fiscalPrint != "function") {
      window.alert("Attenzione non e' stato incluso il file javascript di gestione Epson (fiscalPrint.js)");
      return;
   }





   this.StandardOnReceive = function(result, tag_names_array, add_info, callback, errorCallback)
   {
      var add_info_text = "";
      var numScontrino  = "";
      var numZRep       = "";
      var dtScontrino   = "";
   
   
      // reimposta il valore default del timeout, necessario qualora il timeOut
      // fosse stato allungato per questo specifico comando (tipicamente: la comunicazione
      // con il POS per pagamenti con carta)
      this.timeOut = EPSON_XML_TIMEOUT_STAMPA;
      
      if (!result.success) {
   
         // epsonXmlComandiInCorso viene decrementato da StandardOnError
         
         this.StandardOnError(result, "Errore epsonxml 1:", errorCallback);
   
         //var lllog = "Errore epsonxml: la cassa ha restituito il seguente errore: Status = " + result.status + " Code = " + result.code;
         //console.log(lllog);
         //if (typeof WriteLogMessage == "function")
         // WriteLogMessage(lllog);
         // sessionStorage["epsonXmlNumScontrino"] = "errore";
         /*if (result.code == "FP_NO_ANSWER" && !window.SonoInAmbienteSviluppo())   // in ambiente sviluppo questo alert rompe le balle inutilmente.....
            window.alert(ALERT_MSG_CASSA_NON_RISPONDE);
            Eseguo un controllo un pelo piu' articolato degli stati di risposta della cassa se non e' di successo
         */
         // var pErrore = decodificaErroriCassa(result.code, result.status);
         // if (pErrore != "")
         //    window.alert(pErrore);
   
      } else {
   
         epsonXmlComandiInCorso--;
         
         // ##tmp_numsf_missing##
         // -----  Bruno  17/5/2025  codice provvisorio per cercare di capire come mai da qualche giorno non viene registrato sporadicamente il numero di scontrino
         //                          voglio innanzitutto capire se l'evento scatta, e poi a che punto si interrompe 
         /*if (DB_NUMSF_MISSING.indexOf(sessionStorage["db"]) >= 0 && !varDecisamenteNonValida(add_info["zRepNumber"]) && !varDecisamenteNonValida(add_info["fiscalReceiptNumber"])) {
            if (IsLocalVarEmpty("tmp_check_2_fiscal_receipt_numbers_of_znum_"+add_info["zRepNumber"]))
               localStorage["tmp_check_2_fiscal_receipt_numbers_of_znum_"+add_info["zRepNumber"]] = "";
            localStorage["tmp_check_2_fiscal_receipt_numbers_of_znum_"+add_info["zRepNumber"]] = localStorage["tmp_check_2_fiscal_receipt_numbers_of_znum_"+add_info["zRepNumber"]] + add_info["fiscalReceiptNumber"] + ",";
         }
         */
         // ----- fine codice provvisorio
   
   
         if (typeof WriteLogMessage == "function")
            WriteLogMessage("Ricevuta risposta da registratore di cassa: " + JSON.stringify(add_info));
   
         // ##tmp_numsf_missing##
         // -----  Bruno  17/5/2025  codice provvisorio per cercare di capire come mai da qualche giorno non viene registrato sporadicamente il numero di scontrino
         //                          voglio innanzitutto capire se l'evento scatta, e poi a che punto si interrompe 
         /*
         if (DB_NUMSF_MISSING.indexOf(sessionStorage["db"]) >= 0 && !varDecisamenteNonValida(add_info["zRepNumber"]) && !varDecisamenteNonValida(add_info["fiscalReceiptNumber"])) {
            if (IsLocalVarEmpty("tmp_check_3_fiscal_receipt_numbers_of_znum_"+add_info["zRepNumber"]))
               localStorage["tmp_check_3_fiscal_receipt_numbers_of_znum_"+add_info["zRepNumber"]] = "";
            localStorage["tmp_check_3_fiscal_receipt_numbers_of_znum_"+add_info["zRepNumber"]] = localStorage["tmp_check_3_fiscal_receipt_numbers_of_znum_"+add_info["zRepNumber"]] + add_info["fiscalReceiptNumber"] + ",";
         }
         */
         // ----- fine codice provvisorio
   
   
   
         if (tag_names_array.length > 0) {
            add_info_text = "Additional Information<br>";
   
            for (var i = 0; i < tag_names_array.length; i++) {
               add_info_text =   add_info_text + tag_names_array[i] + " = ";
               add_info_text =   add_info_text + add_info[tag_names_array[i]] + "<br>";
   
               if (tag_names_array[i] == "fiscalReceiptNumber") {
                  if (!isNaN(add_info[tag_names_array[i]])) {
                     if (parseInt(add_info[tag_names_array[i]]) > 0) {
                        numScontrino = add_info[tag_names_array[i]];
                     }
                  }
               }
   
               // numero giornata da memorizzare a seguito dello scontrino
               // esclusivo per cassa epson in cui e' stato abilitato l'RT
               if (tag_names_array[i] == "zRepNumber") {
                  if (!isNaN(add_info[tag_names_array[i]])) {
                     if (parseInt(add_info[tag_names_array[i]]) > 0) {
                        numZRep = add_info[tag_names_array[i]];
                     }
                  }
               }
   
               /* I-20190221-VMS-Inizio */
               if (tag_names_array[i] == "fiscalReceiptDate") {
                  var DtSco = add_info[tag_names_array[i]].split('/');
                  dtScontrino = [DtSco[2], String("00" + DtSco[1]).slice(-2), String("00" + DtSco[0]).slice(-2)].join('-');
               }
               /* I-20190221-VMS-Fine   */
   
            }
   
   
            // se la cassa mi ha mandato le info sullo scontrino fiscale, vado ad aggiornare le sessionStorage
            // e salvo i valori sul DB, altrimenti lascio le sessionStorage invariate (ma NON le azzero ! questa potrebbe
            // trattarsi della risposta ad un comando non fiscale, che quindi non contiene le info fiscali, ma non
            // devo perdere le info, salvate in sessionStorage, dell'ultimo scontrino emesso)
   
            // lo zRepNumber lo tratto separatamente in quanto esso viene restituito anche dai comandi
            // di lettura o chiusura fiscale, nei quali invece il num.scontrino non e' presente
            if (numZRep != "")
               window.sessionStorage["epsonXmlzRepNumber"] = numZRep;
            
            
            if (numScontrino != "") {     // come "discriminante" per salvare o meno, utilizzo solo numScontrino - le altre info, se anche non ci fossero, non importa
   
               window.sessionStorage["epsonXmlNumScontrino"] = numScontrino;
               window.sessionStorage["epsonXmlDtSco"] = dtScontrino;
   
               if (typeof SalvaNumScontrinoEpsonXml == "function") {
                  // sono nella vendita al banco
   
                  // in caso di scontrino di annullamento, sessionStorage["last_mov_progre"] e' vuota
                  // (non devo salvare il numero dello scontrino di annullamento)
                  // in caso di scontrino normale, e' impostata 
                  if (!window.IsSessionVarEmpty("last_mov_progre")) {
   
                     SalvaNumScontrinoEpsonXml(window.sessionStorage["last_mov_progre"],
                                               window.sessionStorage["pv"],
                                               numScontrino,
                                               numZRep,
                                               dtScontrino,
                                               function() {
                                                  // se esiste una callback come parametro la chiamo
                                                  if (typeof callback == "function")
                                                     callback(result, tag_names_array, add_info);
                                               });
   
                 } else {
                    // se esiste una callback come parametro la chiamo
                    if (typeof callback == "function")
                       callback(result, tag_names_array, add_info);
                 }
   
               } else {
                  // sono in ProRisto
                  // chiamo solamente, se esiste, la callback
                  if (typeof callback == "function")
                     callback(result, tag_names_array, add_info);
               }
   
            } else {
               //console.log(add_info_text);
   
              // se esiste una callback come parametro la chiamo
              if (typeof callback == "function")
                 callback(result, tag_names_array, add_info);
   
            }
   
         } else {
            add_info_text = "No Additional Information";
   
            // se esiste una callback come parametro la chiamo
            if (typeof callback == "function")
               callback(result, tag_names_array, add_info);
   
         }
   
   
         //console.log(add_info_text);
   
      }
   
   
      // in vista di una futura riunificazione con ProRisto, verifico se esiste l'oggetto storage utilizzato in ProRisto
      if (typeof storage == "object" && typeof storage.fn == "object")
         storage.fn.scriviLog("epsonxml", [result, add_info]);
   
   
   
   }






   this.StandardOnError = function(result, pAdditionalMessage, errorCallback)
   {
      // reimposta il valore default del timeout, necessario qualora il timeOut
      // fosse stato allungato per questo specifico comando (tipicamente: la comunicazione
      // con il POS per pagamenti con carta)
      this.timeOut = EPSON_XML_TIMEOUT_STAMPA;
   
      if (typeof pAdditionalMessage == "undefined" || pAdditionalMessage == null || !pAdditionalMessage)
         pAdditionalMessage = "";
   
      if (pAdditionalMessage != "")
         pAdditionalMessage = pAdditionalMessage + " ";
   
      // il campo status e' sempre presente in tutte le casistiche di risposta: non serve controllarlo con varDecisamenteNonValida
      var lllog = pAdditionalMessage + "La cassa ha restituito il seguente errore: Status = " + result.status +
                                       " code = "         + (varDecisamenteNonValida(result.code)         ? "(null)" : result.code) + 
                                       " statusText = "   + (varDecisamenteNonValida(result.statusText)   ? "(null)" : result.statusText) + 
                                       " responseText = " + (varDecisamenteNonValida(result.responseText) ? "(null)" : result.responseText);
   
      console.log(lllog);
   
      // quando si verificano errori di timeout (connessione fallita) il modulo fiscalprint.js lancia due volte l'evento di errore:
      // una sull'evento "ontimeout", e una sull'evento "onreadystatechange" : in tal caso evitiamo di dare due volte lo stesso messaggio di errore, e usciamo qui
      if (epsonXmlComandiInCorso <= 0)
         return;
      
      epsonXmlComandiInCorso--;
   
      if (typeof WriteLogMessage == "function")
         WriteLogMessage(lllog);
   
      if (typeof error == 'function')
         error(lllog);
   
      // se siamo in ProRisto, scrive il log utilizzando l'apposito oggetto storage
      if (typeof storage == "object" && typeof storage.fn == "object")
        storage.fn.scriviLog("epsonxml", lllog);
   
      window.sessionStorage["epsonXmlNumScontrino"] = "errore";
      window.sessionStorage["epsonXmlzRepNumber"] = "errore";
   
      var lllogDecoded = decodificaErroriCassa(result.code, result.status);
      
      // in ambiente sviluppo mostro anche il messaggio tecnico dettagliato
      if (typeof window.SonoInAmbienteSviluppo == "function" && window.SonoInAmbienteSviluppo()) {
         if (lllogDecoded != "")
            lllogDecoded = lllogDecoded + " ";
         lllogDecoded += lllog;   
      }
         
   
      // se siamo sul kiosk, noi non mostriamo alcun messaggio:
      // ci pensa l'applicativo kiosk 
      if (lllogDecoded != "" && (typeof window.InQualeApplicazioneSono != "function" || window.InQualeApplicazioneSono() != 4)) {
         if (typeof displayCheckMessaggioSuErroreCassa == "function")      // Vendita al banco
            displayCheckMessaggioSuErroreCassa(lllogDecoded);
         else if (typeof confirm_alert == "function")       // ProRisto
            confirm_alert("ATTENZIONE", lllogDecoded);
         else                                            // RistoComande
            window.alert("ATTENZIONE: " + lllogDecoded);
      }
   
      if (typeof errorCallback == 'function')
         errorCallback(lllogDecoded);
   
   
   }






   this.beginNonFiscal = function() {
      var stringa = "<printerNonFiscal>\n";
      stringa += "<beginNonFiscal operator='"+this.operatore+"' />\n";
      return stringa;
   }

   this.textNonFiscal = function() {
      var stringa = "<printNormal operator='"+this.operatore+"' font='"+this.font+"' data='"+this.ReplaceInvalidChars(this.data)+"' />\n";
      return stringa;
   }

   this.endNonFiscal = function() {
      var stringa = "<endNonFiscal operator='"+this.operatore+"' />\n";
      stringa += "</printerNonFiscal>";
      return stringa;
   }

   this.beginFiscal = function() {
      this.recMesNextIndex = 1;   // reset dell'attributo index di printRecMessage
      var stringa = "<printerFiscalReceipt>\n";
      stringa += "<beginFiscalReceipt operator='"+this.operatore+"' />\n";
      return stringa;
   }

   this.itemFiscal = function() {
      var stringa = "<printRecItem operator='"+this.operatore+"' description='"+this.ReplaceInvalidChars(this.data)+"' quantity='"+this.qta+"' unitPrice='"+this.prezzo+"' department='"+this.reparto+"' />\n";
      return stringa;
   }

   this.refundFiscal = function() {
      var stringa = "<printRecRefund operator='"+this.operatore+"' description='"+this.ReplaceInvalidChars(this.data)+"' quantity='"+this.qta+"' unitPrice='"+this.prezzo+"' department='"+this.reparto+"' />\n";
      return stringa;
   }

   this.subtotalAdj = function() {
      var stringa = "<printRecSubtotalAdjustment operator='"+this.operatore+"' description='OMAGGIO' type='1' amount='"+this.prezzo+"' department='"+this.reparto+"' />\n";
      stringa += "<printRecSubtotal operator='"+this.operatore+"' type='1' />\n";
      return stringa;
   }

   this.itemAdj = function() {
      var stringa = "<printRecItemAdjustment operator='"+this.operatore+"' description='SCONTO' type='1' amount='"+this.prezzo+"' department='"+this.reparto+"' />\n";
      return stringa;
   }

   this.itemAdjDescr = function() {
      var stringa = "<printRecItemAdjustment operator='"+this.operatore+"' description='"+this.ReplaceInvalidChars(this.data)+"' type='1' amount='"+this.prezzo+"' department='"+this.reparto+"' />\n";
      return stringa;
   }

	/**
	 * Dascos Gestione "acconto
	 */
	this.itemAcconto = function(){
		var stringa = "<printRecItemAdjustment operator='" + this.operatore + "' description='" + this.ReplaceInvalidChars(this.data) + "' adjustmentType='10'"+
		" amount='" + this.prezzo + "' department='" + this.reparto + "' justification='1' />\n";
		return stringa
	}

   // Bruno  7/4/2022  per visualizzare la % di sconto sullo scontrino fiscale
   this.itemAdjWithPerc = function(pPerc) {
      this.data = "SCONTO " + pPerc + "%";  
      return this.itemAdjDescr();
   }

   this.itemAdjScForBuono = function() {
      var stringa = "<printRecSubtotalAdjustment operator='"+this.operatore+"' description='"+this.ReplaceInvalidChars(this.data)+"' adjustmentType='2' amount='"+this.prezzo+"'  />\n";
      return stringa;
   }

   /* I-20210128-VMS-Inizio */
   this.itemAdjSconto = function() {
      var stringa = "<printRecItemAdjustment operator='"+this.operatore+"' description='"+this.ReplaceInvalidChars(this.data)+"' adjustmentType='3' amount='"+this.prezzo+"' department='"+this.reparto+"' />\n";
      return stringa;
   }
   /* I-20210128-VMS-Fine   */

   /*
	 * Sconto su totale per modalita' RT in realta' usabile anche in versione MF
   */
   this.itemAdjDescrSubTotal = function() {
      // da documentazione Epson: "The department attribute is ignored and can be null or the attribute itself can be omitted"
      // tuttavia ho timore che su certi firmware piu' vecchi possa non essere ignorato e allora ce lo lascio
      var stringa = "<printRecSubtotalAdjustment operator='"+this.operatore+"' description='"+this.ReplaceInvalidChars(this.data)+"' adjustmentType='1' amount='"+this.prezzo+"' department='"+this.reparto+"' />\n";
      return stringa;
   }

   /**
    * Sconto o sovrapprezo in base al valore dell'arrotondamento
    * @param {number} arro Valore dell'arrotondamento
    * @returns {string}
    */
   this.itemAdjArroDL502017_old = function(arro) {
      var adjType = arro < 0 ? 1 : 6 ;
      arro = Math.abs(arro);
      var stringa = "<printRecSubtotalAdjustment operator='"+this.operatore+"' description='"+MOV_DES_ARRO_DL_50_2017+"' adjustmentType='"+adjType+"' amount='"+arro+"' />\n";
      return stringa;
   }

   /**
    * NUOVA IMPLEMENTAZIONE
    * Ora gli arrotondamenti per difetto vengono trattati come sconto a pagare
    * gli arrotondamenti per eccesso invece rimangono una maggiorazione sul totale
    * @param {number} arro 
    * @returns {string}
    */
   this.itemAdjArroDL502017 = function(arro) {
      // da testare su firmware piu' vecchi !
      var metodo = 1;
      if(metodo == 0){
         // vecchio metodo
         return this.itemAdjArroDL502017_old(arro);
      }
      // nuovo metodo con sconto a pagare
      if(arro < 0){
         // sconto a pagare
         arro = Math.abs(arro);
         var stringa = "<printRecTotal operator='"+this.operatore+"' description='"+MOV_DES_ARRO_DL_50_2017+"' payment='"+arro+"' paymentType='6' index='0' />\n";
      }else{
         // maggiorazione
         var stringa = "<printRecSubtotalAdjustment operator='"+this.operatore+"' description='"+MOV_DES_ARRO_DL_50_2017+"' adjustmentType='6' amount='"+arro+"' />\n";
      }
      return stringa;
   }

   this.totalFiscal = function() {
      var descr_pagamento = "";
      var paymentType;     
      var paymentIndex;
      
      if (!IsStringNumeric(this.pagamento))
         paymentType = EPSON_XML_COD_PAG_CONTANTI; 
      else
         paymentType = parseInt(this.pagamento);       
      
      if (!IsStringNumeric(this.indicePagamento))
         paymentIndex = EPSON_XML_INDEX_CONTANTI; 
      else
         paymentIndex = parseInt(this.indicePagamento);       
      
      //var totale_pagamento = parseFloat(this.importoPagato);
      //if(cod_pag == 0 && totale_pagamento == 0){
         //return "";
      //}

      if (indiciPagamentoAbilitato()) {
         if (!IsSessionVarEmpty('indice_pagamento_applicato') && IsStringNumeric(sessionStorage['indice_pagamento_applicato'])) {
            paymentIndex = parseInt(sessionStorage['indice_pagamento_applicato']);
         } else {
            paymentIndex = EPSON_XML_INDEX_CONTANTI;
         }
      }
      
      descr_pagamento = EpsonXmlDescrPagamento(paymentType, paymentIndex);
      
      /*
      Per RT
      necessario cambio indice in caso di pagamento con carte di credito o ticket
      Saragel lamentava blocchi scontrino in emissione la causa era il pagamento con ticket che se inviato con index='0'
      bloccava l'emissione dello scontrino
      Da manuale EPSON
      Cash 0-5
      Credit 0
      Credit card 1-10
      Ticket 1-10
      Gestione modalita' di pagamento buono / gift card che sara' conteggiata come un sottoindice di contanti
      quindi paymentIndex = 1 mentre il codice pagamento deve essere 0
      */
		if (
            (
               typeof siamoInModalitaRT == "function" && 
               siamoInModalitaRT()                    &&
               (
                  (!indiciPagamentoAbilitato() && paymentType == EPSON_XML_COD_PAG_CARTE)
                  || 
                  paymentType == EPSON_XML_COD_PAG_BUONO
               ) 
			   )
            ||
				paymentType == EPSON_XML_COD_PAG_SCONTO_PAGARE
            ||
            paymentType == EPSON_XML_COD_PAG_TICKET
         )
         paymentIndex = 1;

      /*
		 * Se il codice di pagamento e' quello dei buoni / gift card il paymentType deve essere cambiato in uno dei pagamenti "master"
      */
/*      if (typeof siamoInModalitaRT == "function"
            && siamoInModalitaRT()
            && paymentType == EPSON_XML_COD_PAG_BUONO)
         this.pagamento = EPSON_XML_COD_PAG_BUONO_MASTER.toString();  */
      
      // determino l'importo che va al POS
      //if (paymentType == EPSON_XML_COD_PAG_CARTE) 
      //   this.importoCarta += UnformatNumber(this.importoPagato);

      var stringa = "<printRecTotal operator='"+this.operatore+"' description='"+descr_pagamento+"' payment='"+this.importoPagato+"' paymentType='"+paymentType+"' index='" + paymentIndex + "' />\n";
      return stringa;
   }

/*   
   this.totalFiscalMultiple = function() {

      var retVal = "";
      var arrModPag = EpsonXmlElaboraModPag(1);
      
      for (var i = 0; i < arrModPag.length; i++) {
         if (arrModPag[i].importo > 0) {                                                                                                                                                                              
            this.pagamento       = ModalitaPag2Epson(arrModPag[i].modalita);
            this.indicePagamento = applicaIndicePagamento(arrModPag[i].modalita);
            this.importoPagato   = number_format(Math.abs(arrModPag[i].importo),2,",","");
            retVal += this.totalFiscal();
         }
      }
   
      return retVal;
   }
*/   
   
   
   /*
   Per il totale di resi e annullo scontino in modalita' RT
   Come da documentazione fornita da tecnico epson
   */
   this.totalFiscalShort = function() {
      var stringa = "<printRecTotal operator='"+this.operatore+"' />\n";
      return stringa;
   }

   this.endFiscal = function() {
      var stringa = "<endFiscalReceipt operator='"+this.operatore+"' />\n";
      stringa += "</printerFiscalReceipt>";
      return stringa;
   }

   this.recMessage = function() {
      var stringa = "<printRecMessage operator='"+this.operatore+"' message='"+this.ReplaceInvalidChars(this.data)+"' type='1' font='"+this.font+"' messageType='4' />\n";
      return stringa;
   }

   this.recMessageIndex = function() {
      var stringa = "<printRecMessage operator='"+this.operatore+"' message='"+this.ReplaceInvalidChars(this.data)+"' type='1' font='"+this.font+"' messageType='2' index='"+this.recMesNextIndex.toString()+"' />\n";
      this.recMesNextIndex++;
      return stringa;
   }

   this.cassetto = function() {
      var stringa = "<printerFiscalReceipt>\n";
      stringa += "<openDrawer operator='"+this.operatore+"' />\n";
      stringa += "</printerFiscalReceipt>";
      return stringa;
   }

   this.lettura = function() {
      var stringa = "<printerFiscalReport>\n";
      stringa += "<printXReport operator='"+this.operatore+"' />\n";
      stringa += "</printerFiscalReport>";
      return stringa;
   }

   this.chiusura = function() {
      var stringa = "<printerFiscalReport>\n";
      stringa += "<printZReport operator='"+this.operatore+"' />\n";
      stringa += "</printerFiscalReport>";
      return stringa;
   }

   this.chiusuraTot = function() {
      var stringa = "<printerFiscalReport>\n";
      stringa += "<printXZReport operator='"+this.operatore+"' />\n";
      stringa += "</printerFiscalReport>";
      return stringa;
   }

   this.code39 = function() {
      var stringa = "<printBarCode operator='1' Position='901' Pos='901' Width='2' Height='66' Hri='TWICE' Font='FontA' codeType='CODE39' code='"+this.data+"' />\n";
      return stringa;
   }

   this.displayText = function() {
      var stringa = "<printerCommand>\n";
      stringa += "<Printer Num='1' />\n";
      stringa += "<displayText operator='"+this.operatore+"' data='"+this.ReplaceInvalidChars(this.data)+"' />\n";
      stringa += "</printerCommand>";
      return stringa;
   }

   this.subtotal = function() {
      var stringa = "<printRecSubtotal operator='"+this.operatore+"' prnOption='2' />\n";
      return stringa;
   }


   this.beginInvoice = function() {
      var stringa = "<printerFiscalDocument>\n";
      stringa += "<beginFiscalDocument operator='"+this.operatore+"' documentAmount='"+this.data+"' documentType='freeInvoice' documentNumber='"+this.number+"' />";
      return stringa;
   }

   this.endInvoice = function() {
      var stringa = "<endFiscalDocument operator='"+this.operatore+"' operationType='0'/>\n";
      stringa += "</printerFiscalDocument>";
      return stringa;
   }

   this.invoiceDocumentLine = function() {
      var stringa = "<printFiscalDocumentLine operator='"+this.operatore+"' font='"+this.font+"' documentLine='"+this.ReplaceInvalidChars(this.data)+"' />\n";
      return stringa;
   }


   this.printContentByDate = function(fromDay, fromMonth, fromYear, toDay, toMonth, toYear) {
      var stringa = "<printerCommand>";
      stringa += "<directIO command='3103' data='" + lpad(this.operatore, 2, "0").slice(0,2) + "00" +
                                                     lpad(fromDay.toString(),2,"0") +
                                                     lpad(fromMonth.toString(),2,"0") +
                                                     fromYear.toString().slice(2) +
                                                     lpad(toDay.toString(),2,"0") +
                                                     lpad(toMonth.toString(),2,"0") +
                                                     toYear.toString().slice(2) + "000' />"
      stringa += "</printerCommand>";
      return stringa;
   }

   this.setDateTime = function(day,month,year,hour,minute) {
      var stringa = "<printerCommand>";
      stringa += "<setDate day='"+day+"' month='"+month+"' year='"+year+"' hour='"+hour+"' minute='"+minute+"' />";
      stringa += "</printerCommand>";
      return stringa;
   }

   this.setMessageOnDisplayTimeout = function(pMsg) {
      stringa  = "<printerCommand>";
      stringa += "<directIO command='1062' data='013" + rpad(this.ReplaceInvalidChars(pMsg), 40, " ").substr(0, 40) + "00' />"
      stringa += "</printerCommand>";

      return stringa;
   }

   this.rtResoMerceAnnulloBegin = function() {
      /*
         this.data es -> RESO MERCE N.0279-0010 del 08-03-2018
      */
      this.recMesNextIndex = 1;   // reset dell'attributo index di printRecMessage
      var stringa = "<printerFiscalReceipt>\n";
      stringa += "<printRecMessage operator='"+this.operatore+"' message='"+this.ReplaceInvalidChars(this.data)+"' messageType='4' />\n";
      //stringa += "<beginFiscalReceipt operator='"+this.operatore+"' />\n";

      return stringa;
   }

   this.checkPerResoAnnullo = function(pCmd) {

      /*
         Comando per controllare se un documento e' rimborsabile o annullabile
         Il parametro command e' il medesimo 9205
         La differenza la fa il primo bit passato a data
         1 = Refund
         2 = Void
         il resto della stringa e'
         NNAAANNNNNN RT Serial Number
         DDMMYYYY La data originale del documento
         NNNN Il numero di scontrino
         ZZZZ Il numero di Z report
      */

      stringa  = "<printerCommand>";
      stringa += "<directIO command='9205' data='" + pCmd + "' />";
      stringa += "</printerCommand>";

      return stringa;
   }

   
   // Bruno  05/09/2024   completamente riscritta
   this.annulloDirettoScontrino = function(pNumZRep, pNumScontrino, pDataScontrino, pMatricolaCassa) {

      /*
         Comando per annullare seccamente uno scontrino senza per forza esplicitarne il corpo
         Basta indicare la giornata fiscale, il numero di scontrino e la data
         es. N.0112-0015 del 07-11-2019
         Lo 0140001 e' presente a manuale epson senza indicazioni quindi si presume sia un parametro fisso tipo il data di setMessageOnDisplayTimeout
      */
      /*var stringa = "<printerCommand>";
      stringa += "<directIO command='1078' data='0140001ANNULLAMENTO N." + pCmd + "' timeout='5000'/>";
      stringa += "</printerCommand>";
      */
      
      
      pNumZRep      = lpad(NormalizzaStringa(pNumZRep),     4,"0");
      pNumScontrino = lpad(NormalizzaStringa(pNumScontrino),4,"0");
      
      var formattedDate = "";
      
      if (pDataScontrino instanceof Date) {
         formattedDate = stringItalyToEpsonDate(dateToStringItaly(pDataScontrino),true); 
      } else if (IsValidDateSql(pDataScontrino)) {
         formattedDate = stringItalyToEpsonDate(dateToData(pDataScontrino),true);
      } else {
         formattedDate = stringItalyToEpsonDate(pDataScontrino,true);
      }
      
      if (varDecisamenteNonValida(pMatricolaCassa))
         pMatricolaCassa = RT_NUM_MATRICOLA_TAROCCO;
      
      this.data = RT_DICITURA_ANNULLO + " " + pNumZRep + " " + pNumScontrino + " " + formattedDate + " " + pMatricolaCassa;
      
      var retVal = this.rtResoMerceAnnulloBegin();
      retVal += this.totalFiscalShort();
      retVal += this.endFiscal();      
      
      return retVal;

   }

   this.printerStatus = function(pStatusType) {
      return "<printerCommand><queryPrinterStatus statusType='" + (pStatusType ? "1" : "0") + "' /></printerCommand>";
   }

   this.fpMateConfig = function() {
      return "<fpMateConfiguration><readVersion /></fpMateConfiguration>";
   }

   this.getNumDaysThreshold = function() {
      return "<printerCommand><directIO command='4215' data='25' /></printerCommand>";
   }

   this.SendCommandGetNumDaysThreshold = function(pCallback) {
      this.sendData(this.getNumDaysThreshold(), function (res, tag_list_names, add_info) {
         if (res && res.success == true && parseInt(res.status) == RT_FLAG_STATO_ON && add_info && add_info.responseData) {
            if (typeof pCallback == "function")
               pCallback(parseInt(add_info.responseData.substring(2)));
         }
      });
   }

   this.getZRepNumber = function(pCallback) {
   
      var dataEposGetZRepNumber = '<printerCommand><directIO  command="2052" /></printerCommand>';
   
      /*
         Necessario fix volante..fortuna che e` stato provato su proristo
         Il reale ritorno dello zRepNumer e` una stringa del tipo 000000291992440416
         e non l'indice incrementale 000000000000000001 come nella versione demo...
      */
      
      this.sendData(dataEposGetZRepNumber, function (res, tag_list_names, add_info) {
   
         var repNum = 0;
         
         if (tag_list_names.length > 0) {
            for (var i = 0; i < tag_list_names.length; i++) {
               if (tag_list_names[i] == "responseData") {
   
                  var pTmp = add_info[tag_list_names[i]];
                  pTmp = pTmp.substr(pTmp.length - RT_NUM_DIGIT_ZREP_DX);
   
                  repNum = parseInt(pTmp);
   
               }
            }
         }
   
         if (typeof pCallback == "function")
            pCallback(repNum);
   
      });
   
   }


   this.getRTStatus = function(pCallback) {
   
      var dataEposGetRTStatus = '<printerCommand><directIO command="1138" data="01" timeout="3000" /></printerCommand>';
      this.sendData(dataEposGetRTStatus, function (res, tag_list_names, add_info) {
   
         var retVal = "";
         
         if (tag_list_names.length > 0) {
            for (var i = 0; i < tag_list_names.length; i++) {
               if (tag_list_names[i] == "responseData") {
                  retVal = add_info[tag_list_names[i]].substring(2, 3); 
               }
            }
         }
   
         if (typeof pCallback == "function")
            pCallback(retVal);
   
      });
   
   }



   this.getFiscalSerialNumber = function(pCallback) {

      var dataEposFiscalSerialNumber = '<printerCommand><directIO command="3217" data="01" timeout="3000" /></printerCommand>';
      this.sendData(dataEposFiscalSerialNumber, function (res, tag_list_names, add_info) {
   
         var serNum = "";
         
         if (res.success == true && tag_list_names.length > 0) {
            for (var i = 0; i < tag_list_names.length; i++) {
               if (tag_list_names[i] == "responseData") {
                  serNum = add_info[tag_list_names[i]].substring(10,12);
                  serNum += "_"; // Riservato per la risposta al comando 1138.
                  serNum += add_info[tag_list_names[i]].substring(8, 10);
                  serNum += add_info[tag_list_names[i]].substring(2, 8);
               }
            }
         }
   
         if (typeof pCallback == "function")
            pCallback(serNum);
   
      });
   
   }


   this.GetFullEpsonStatus = function(pOkCallback, pErrCallback) {

      var myRTServerSerialNumber = "";
      var epsonxmlObj = this;      // dentro la callback di sendData "this" si riferisce a Window, e per poter invece accedere a noi stessi (oggetto epsonxml) occorre una variabile di appoggio
      
      this.sendData(this.printerStatus(0), function (res, tag_list_names, add_info) {
   
         epsonxmlObj.objEpsonRcv.cpuRel   = add_info.cpuRel;
         epsonxmlObj.objEpsonRcv.mfRel    = add_info.mfRel;
         epsonxmlObj.objEpsonRcv.mfStatus = add_info.mfStatus;
         
         epsonxmlObj.sendData(epsonxmlObj.printerStatus(1), function(res, tag_list_names, add_info) {
   
            epsonxmlObj.objEpsonRcv.resCode    = res.code;
            epsonxmlObj.objEpsonRcv.resStatus  = res.status;
            epsonxmlObj.objEpsonRcv.resSuccess = res.success;
   
            // la risposta proveniente dallo status RT comprendere rtType e rtDailyOpen
            // se contenute siamo in regime di Epson RT
            if ('rtType'      in add_info &&
                'rtDailyOpen' in add_info) { // modalita RT
   
               // tipo dispositivo RT
               epsonxmlObj.objEpsonRcv.rtType = add_info.rtType;
               // stato main
               epsonxmlObj.objEpsonRcv.rtMainStatus = add_info.rtMainStatus;
               // stato sub
               epsonxmlObj.objEpsonRcv.rtSubStatus = add_info.rtSubStatus;
               // stato attuale
               epsonxmlObj.objEpsonRcv.rtActStatus = EpsonDecodeStatoRT(add_info.rtMainStatus, add_info.rtSubStatus);
               // day opened
               epsonxmlObj.objEpsonRcv.rtDailyOpen = add_info.rtDailyOpen;
               // periodo inattivo
               epsonxmlObj.objEpsonRcv.rtNoWorkingPeriod = add_info.rtNoWorkingPeriod;
               // numero file da inviare
               epsonxmlObj.objEpsonRcv.rtFileToSend = parseInt(add_info.rtFileToSend, 10);
               // numero file vecchi
               epsonxmlObj.objEpsonRcv.rtOldFileToSend = parseInt(add_info.rtOldFileToSend, 10);
               // numero file rifiutati
               epsonxmlObj.objEpsonRcv.rtFileRejected = parseInt(add_info.rtFileRejected, 10);
               // data scadenza certificato dispositivo
               epsonxmlObj.objEpsonRcv.rtExpiryCD = EpsonDecodeExpiryCD(add_info.rtExpiryCD);
               // Data scadenza  certificato CA AE
               // CA = Certificate Authority
               // AE = Agenzia Entrate
               epsonxmlObj.objEpsonRcv.rtExpiryCA = EpsonDecodeExpiryCA(add_info.rtExpiryCA);
               // Modalita' Demo / Training / Simulatore
               epsonxmlObj.objEpsonRcv.rtTrainingMode = add_info.rtTrainingMode;
   
               // così non va bene, devono essere controllati gli stati Main e Sub prima di asserire che la cassa e` funzionante in modalita' RT
               //epsonxmlObj.objEpsonRcv.isRtMode = EPSON_MODE_RT_ATTIVA;
   
               // Verifica se sono in stato RT
               // Assumiamo che la cassa puo' funzionare in modalita' RT soltanto se In Servizio
               // quindi MainStatus = 02 e SubStatus = qualsiasi
               /*
                  ' "Mancano Certificati"    MN == 01 e SB == 02
                  ' "Certificati Incompleti" MN == 01 e (SB == 03 || SB == 04)
                  ' "Certificati Caricati"   MN == 01 e SB == 05
                  ' "Censito"                MN == 01 e SB == 06
                  ' "Attivato"               MN == 01 e SB == 07
                  ' "Pre Servizio"           MN == 01 e SB == 08
                  ' "In Servizio"            MN == 02 e SB == qualsiasi
               */
               
               
               if (add_info.rtMainStatus == "02") {
            
                  var lllog = "Cassa in modalita RT!";
               
                  if (!IsSessionVarEmpty("db"))
                     lllog = lllog + "\n database: " + sessionStorage["db"];
               
                  if (!IsSessionVarEmpty("pv"))
                     lllog = lllog + "\n punto vendita: " + sessionStorage["pv"];
               
                  if (typeof WriteLogMessage == "function")
                     WriteLogMessage(lllog);
            
                  epsonxmlObj.objEpsonRcv.isRtMode = EPSON_MODE_RT_ATTIVA;
   
               } else {
                  epsonxmlObj.objEpsonRcv.isRtMode = EPSON_MODE_RT_NO_ATTIVA;
               }
               
   
               
   
               epsonxmlObj.getFiscalSerialNumber(function (pSerNum) {
   
                  myRTServerSerialNumber = pSerNum;
                  
                  epsonxmlObj.getRTStatus(function (pVal) {
   
                     if (!varDecisamenteNonValida(pVal) && !varDecisamenteNonValida(myRTServerSerialNumber))
                        myRTServerSerialNumber = myRTServerSerialNumber.replace("_", pVal);
                     
                     if (!varDecisamenteNonValida(myRTServerSerialNumber))
                        epsonxmlObj.objEpsonRcv.rtSerialNumber = myRTServerSerialNumber;
   
                     epsonxmlObj.getZRepNumber(function (pRepNumber) {
   
                        // al valore restituito va sommato 1 per ottenere il ZRepNumer corrente,
                        // come da documentazione epson
                        if (!varDecisamenteNonValida(pRepNumber))
                           epsonxmlObj.objEpsonRcv.rtZRepNumber = pRepNumber+1;
   
                        epsonxmlObj.SendCommandGetNumDaysThreshold(function (pNumDays) {
                           epsonxmlObj.objEpsonRcv.rtNumDaysThres = pNumDays;
   
   
                           //epsonxmlObj.sendData(epsonxmlObj.fpMateConfig(), function (res, tag_list_names, add_info) {
                           //   epsonxmlObj.objEpsonRcv.fpmateVersion = add_info.fpmateVersion;
   
                              // aggiorno i valori delle sessionStorage
                              CopiaObjEpsonInStorage(epsonxmlObj.objEpsonRcv);

                              if (typeof pOkCallback == "function")
                                 pOkCallback(epsonxmlObj.objEpsonRcv);

   
                           //});
   
   
                        });
   
                     });
   
                  });
   
               });
   
            } else {
               /*
                * modalita non RT - il che da luglio non e` un bene e forse sarebbe meglio bloccare l'utilizzo della cassa ma quando mai...non
                * capisco come ho fatto a pensare questa cosa!
                */
   
               epsonxmlObj.objEpsonRcv.cpuRel = add_info.cpuRel;
               epsonxmlObj.objEpsonRcv.mfRel = add_info.mfRel;
               epsonxmlObj.objEpsonRcv.mfStatus = add_info.mfStatus;
   
               epsonxmlObj.objEpsonRcv.isRtMode = EPSON_MODE_MF;
   
               // aggiorno i valori delle sessionStorage
               CopiaObjEpsonInStorage(epsonxmlObj.objEpsonRcv);
               
               if (typeof pOkCallback == "function")
                  pOkCallback(epsonxmlObj.objEpsonRcv);

   
            }
   
         } );
   
   
      }, pErrCallback);

   
   }
   
   
   
   
   this.aggiungiCodiceLotteria = function(pCodiceLotteria) {
      // il Codice Lotteria si compone di 8 caratteri alfanumerici con distinzione tra lettere maiuscole e minuscole, e va paddato con spazi
      return "<directIO command='1135' data='" + lpad(this.operatore,2,"0").substr(-2) + rpad(pCodiceLotteria,20," ").substr(0,20) + "' />";
   }

   // aggiunto callback ed error per gestire le chiamate
   // che attendono una risposta della stampa
   this.sendData = function(str, callback, errorCallback) {
      var epos = new window.epson.fiscalPrint();
      var epsonxmlObj = this;    // dentro epos.onreceive e epos.onerror, "this" punta all'oggetto epos e non a epsonxml 

      if (epsonXmlComandiInCorso > 0) {
         // comando in corso : se fosse una banale visualizzazione sul display, ce ne freghiamo, altrimenti diamo errore
         // INUTILE: LA CASSA EPSON E' IN GRADO DI ACCODARE I COMANDI QUINDI POSSIAMO ANCHE MANDARE IL SUCCESSIVO
         //console.log("Comando in corso: "  + epsonXmlUltimaStringa);
         //console.log("Comando richiesto: " + str);
         //if (str.indexOf("<displayText") < 0)
         //   GenericConfirmAlert("Impossibile inviare comando alla cassa: e' ancora in esecuzione il precedente comando !", "ERRORE");
         //return;
      }
      
      
      if (window.varDecisamenteNonValida(this.ip)) {
         this.ip = window.GetCassaIpCgi();
      }
                                                           
      window.sessionStorage["epsonXmlNumScontrino"] = "";
      window.sessionStorage["epsonXmlzRepNumber"] = "";
      /* I-20190221-VMS-Inizio */
      CurDat = new Date()
      window.sessionStorage["epsonXmlDtSco"] = [CurDat.getFullYear(), String("00" + (CurDat.getMonth()+1)).slice(-2), String("00" + CurDat.getDate()).slice(-2)].join('-');
      /* I-20190221-VMS-Fine   */

      epos.onreceive = function(result, tag_names_array, add_info) {
         // ##tmp_numsf_missing##
         // -----  Bruno  17/5/2025  codice provvisorio per cercare di capire come mai da qualche giorno non viene registrato sporadicamente il numero di scontrino
         //                          voglio innanzitutto capire se l'evento scatta, e poi a che punto si interrompe 
         /*
         if (DB_NUMSF_MISSING.indexOf(sessionStorage["db"]) >= 0 && !varDecisamenteNonValida(add_info["zRepNumber"]) && !varDecisamenteNonValida(add_info["fiscalReceiptNumber"])) {
            if (IsLocalVarEmpty("tmp_check_1_fiscal_receipt_numbers_of_znum_"+add_info["zRepNumber"]))
               localStorage["tmp_check_1_fiscal_receipt_numbers_of_znum_"+add_info["zRepNumber"]] = "";
            localStorage["tmp_check_1_fiscal_receipt_numbers_of_znum_"+add_info["zRepNumber"]] = localStorage["tmp_check_1_fiscal_receipt_numbers_of_znum_"+add_info["zRepNumber"]] + add_info["fiscalReceiptNumber"] + ",";
         }
         */
         // ----- fine codice provvisorio
         epsonxmlObj.StandardOnReceive(result, tag_names_array, add_info, callback, errorCallback);
      }

      epos.onerror = function(result) {
         epsonxmlObj.StandardOnError(result, "Errore epsonxml 2:", errorCallback);
      }

      // paracadute di emergenza nel caso la variabile fosse male impostata dal chiamante
      if (!window.IsStringNumericPositive(this.timeOut))
         this.timeOut = EPSON_XML_TIMEOUT_STAMPA;


      // abbiamo due timeout diversi:
      // 1) il timeout della chiamata ajax, gestito da browser, che viene passato come 3^ parametro nella epos.send
      // 2) il timeout interno alla cassa (tra servizio fpmate.cgi e firmware fiscale), che viene passato nella query string della URL
      //    (il massimo possibile e' 1 minuto: se viene passato un valore superiore, verra' ignorato e il timeout scattera' comunque a 1 minuto) 
      // faccio in modo che questi due timeout siano allineati, se non identici  
      var queryString = "?timeout=" + this.timeOut; 
      
      var epsonXmlScriptPath = window.EpsonXmlScriptPath(str,this);  
      
      // se sto utilizzando il simulatore, gli passo come parametri il DB e il punto vendita in modo che il simulatore possa generare
      // delle risposte "su misura" per noi
      if (epsonXmlScriptPath.substr(-4) == ".php" && !IsSessionVarEmpty("db")) {
         queryString += ("&db=" + sessionStorage["db"]);
         if (!IsSessionVarEmpty("pv"))
            queryString += ("&pv=" + sessionStorage["pv"]); 
      }       
      
      epos.send(epsonXmlScriptPath + queryString, str, this.timeOut);

      //scriviLog("Trasmessa stampa scontrino con protocollo EPSON-XML");
      if (typeof WriteLogMessage == "function") {
         //console.log(str);
         WriteLogMessage("Inviato comando a registratore di cassa: " + str);
      }

      if (typeof storage == "object" && typeof storage.fn == "object")
         storage.fn.scriviLog("epsonxml", str);

      epsonXmlComandiInCorso++;
      epsonXmlUltimaStringa = str;
   }


   this.ReplaceInvalidChars = function(pStr) {
      if (varDecisamenteNonValida(pStr))
        return "";
      pStr = pStr.toString();
      pStr = pStr.replace(/&/g, "&amp;");
      pStr = pStr.replace(/'/g, "`");
      pStr = pStr.replace(/</g, "&lt;");
      pStr = pStr.replace(/>/g, "&gt;");
      
      // elimina i caratteri con codice ASCII maggiore di 127 oppure minore di 4 (possono capitare nei messaggi che arrivano dal POS)
      // [NEW 27/12/2024] eccetto il simbolo dell'euro
      pStr = pStr.replace(new RegExp(`[^\\x04-\\x7F\\u${EPSON_SYMBOL_EURO.charCodeAt(0).toString(16).toUpperCase()}]`, 'g'), "");     
      
      return pStr;
   }

   /* I-20200303-VMS-Inizio */
   /******************************************************************************
    * Comando direct I/O a RT Epson xml.                                         *
    *----------------------------------------------------------------------------*
    *                                                                            *
    * Parametri ricevuti.                                                        *
    *   - Cmd  Comando (H1 + H2).                                                *
    *   - Idx  Indice.                                                           *
    *   - Nbr  Numero (sottoparametro).                                          *
    *                                                                            *
    * Valori restituiti.                                                         *
    *   - RtnVal  Comando da inviare al RT.                                      *
    *                                                                            *
    *----------------------------------------------------------------------------*
    *                                                                            *
    ******************************************************************************
    */
   this.SndDirectIORqs = function(Cmd, Idx, Nbr) {
      RtnVal = "<printerCommand>";
      RtnVal += "<directIO command='" + Cmd + "' data='" + Idx + Nbr + "' />";
      RtnVal += "</printerCommand>";

      return RtnVal;
   }
   /* I-20200303-VMS-Fine   */

   /* I-20200309-VMS-Inizio */
   /******************************************************************************
    * Comando reperimento data ed ora RT Epson XML.                              *
    *----------------------------------------------------------------------------*
    *                                                                            *
    * Parametri ricevuti.                                                        *
    *   Nessuno.                                                                 *
    *                                                                            *
    * Valori restituiti.                                                         *
    *   - RtnVal  Comando da inviare al RT.                                      *
    *                                                                            *
    *----------------------------------------------------------------------------*
    *                                                                            *
    ******************************************************************************
    */
   this.RtvDtTimeRT = function() {
      RtnVal = "<printerCommand>";
      RtnVal += "<directIO command='4201'/>";
      RtnVal += "</printerCommand>";

      return RtnVal;
   }
   /* I-20200309-VMS-Fine   */


   // --------------------------------------------------------------------------
   //
   // Bruno  21/09/2021  nuovo comando per gestione pagamento con POS
   //
   // --------------------------------------------------------------------------
   this.CmdImportoPOS = function(pImportoCarta) {
      return "<printerCommand><authorizeSales operator='"+this.operatore+"' amount='" + number_format(pImportoCarta, 2, ",", "") + "'/></printerCommand>";
   }


   this.ClearPOSBuffer = function() {
      //var stringa = "<printRecMessage operator='"+this.operatore+"' message='' type='8' clearEFTPOSBuffer='1' />\n";
      var stringa = "<printRecMessage  operator='"+this.operatore+"' messageType='8' clearEFTPOSBuffer='1' />\n";
      return stringa;
   }

   

}





// converte la modalita' pagamento codificata secondo Risto nella modalita' pagamento riconosciuta dalle stampanti Epson
function ModalitaPag2Epson(pCod) {
   // Bruno  22/7/2022  novita': in ProRisto esiste il nuovo file pag_helper.js che viene auto-generato da PHP
   //                   in modo da essere sempre allineato, che ridefinisce la funzione ModalitaPag2Epson
   //                   se esiste la funzione ridefinita, utilizziamo codesta 
   //                   
   //                   per fare eventualmente un confronto tra vecchia e nuova function, occorre innanzitutto
   //                   commentare la sottostante chiamata PagHelperModalitaPag2Epson (altrimenti il confronto
   //                   non avrebbe senso perche' lo faremmo tra PagHelperModalitaPag2Epson e se stessa.....)
   //                   e poi lanciare un ciclo for come il seguente: 
   //                         for (var i=0; i<200; i++) {  if (ModalitaPag2Epson(i) != PagHelperModalitaPag2Epson(i)) console.error("ahia " + i);  }
   //                   il controllo potra' ovviamente dare degli errori, da valutare di volta in volta, sino a che anche la vendita al banco
   //                   non si appoggera' anch'essa su pag_helper.js
   if (typeof PagHelperModalitaPag2Epson == "function")
      return PagHelperModalitaPag2Epson(pCod);
   
   var currAppl = (typeof window.InQualeApplicazioneSono != "function" ? 1 : InQualeApplicazioneSono()); 
   
   switch (pCod) {
      case COD_PAG_CONTANTI:              return EPSON_XML_COD_PAG_CONTANTI;        // contante
      case COD_PAG_BANCOMAT:              return EPSON_XML_COD_PAG_CARTE;           // bancomat
      case COD_PAG_CARTE_DI_CREDITO:      return EPSON_XML_COD_PAG_CARTE;           // american express
      case COD_PAG_CREDITO:               if (currAppl != 2)
                                             return EPSON_XML_COD_PAG_TICKET;       // in VB credito
                                          else 
                                             return EPSON_XML_COD_PAG_CARTE;        // in ProRisto deliveroo carte 
      case COD_PAG_VISA:                  return EPSON_XML_COD_PAG_CARTE;           // visa
      case COD_PAG_SATISPAY:              return EPSON_XML_COD_PAG_CARTE;           // diners
      case COD_PAG_ASSEGNI:               if (currAppl != 2)
                                             return EPSON_XML_COD_PAG_ASSEGNI;      // in VB assegno
                                          else 
                                             return EPSON_XML_COD_PAG_CONTANTI;     // in ProRisto deliveroo contanti
      case COD_PAG_MASTERCARD:            return EPSON_XML_COD_PAG_CARTE;           // mastercard
      case COD_PAG_TICKET:                return EPSON_XML_COD_PAG_TICKET;          // ticket
      case COD_PAG_BUONO:                 return EPSON_XML_COD_PAG_TICKET;          // buono
      case COD_PAG_SCONTO_PAGARE:         return EPSON_XML_COD_PAG_SCONTO_PAGARE;   // sconto a pagare
      case COD_PAG_GLOVO_E:               return EPSON_XML_COD_PAG_CARTE            // glovo carte
      case COD_PAG_GLOVO_C:               return EPSON_XML_COD_PAG_CONTANTI;        // glovo contanti
      case COD_PAG_CREDITO_RICAR:         return EPSON_XML_COD_PAG_CARTE;           // credito ricaricabile
      case COD_PAG_BONIFICO:              return EPSON_XML_COD_PAG_CARTE;           // bonifico
      case COD_PAG_E_COMMERCE:            return EPSON_XML_COD_PAG_CARTE;           // e-commerce
      case COD_PAG_CONTANTI_DOMICILIO:    return EPSON_XML_COD_PAG_CONTANTI;        // contante domicilio
      case COD_PAG_NON_RISCOSSO_GENERICO: return EPSON_XML_COD_PAG_NON_RISCOSSO;    // non riscosso generico
      case COD_PAG_NON_RISCOSSO_BENI:     return EPSON_XML_COD_PAG_NON_RISCOSSO;    // non riscosso beni
      case COD_PAG_NON_RISCOSSO_SERVIZI:  return EPSON_XML_COD_PAG_NON_RISCOSSO;    // non riscosso servizi
      case COD_PAG_NON_RISCOSSO_FATTURA:  return EPSON_XML_COD_PAG_NON_RISCOSSO;    // non riscosso fattura
      case COD_PAG_NON_RISCOSSO_TICKET:   return EPSON_XML_COD_PAG_NON_RISCOSSO;    // nuovo bottone ticket per ProRisto, che sul fiscale va su "non riscosso generico"
      default:                            return EPSON_XML_COD_PAG_CONTANTI;        // valore non valido
   }
}

// determina il valore del campo index in funzione della modalita' di pagamento
function ModalitaPag2Index(pCod)
{
   // Bruno  18/4/2025  tutte le logiche sugli indici di pagamento sono state concentrate in 
   //                   applicaIndicePagamento; la funzione ModalitaPag2Index e' diventata un semplice
   //                   wrapper, da tenere per non rompere il funzionamento di certi applicativi che
   //                   ancora la potrebbero chiamare (es: ProRisto)  
   return applicaIndicePagamento(pCod);
}







function EpsonXmlDescrPagamento(pPaymentType, pPaymentIndex)
{
   var descr_pagamento = "";
   
	/**
	 * Dascos Aggiunta dicitura corretta per "Sconto a Pagare"
	 */
   switch (pPaymentType) {
		case EPSON_XML_COD_PAG_SCONTO_PAGARE:
			descr_pagamento = EPSON_XML_DESCR_PAG_SCONTO_PAGARE;
			break;
      case EPSON_XML_COD_PAG_CONTANTI: 
         descr_pagamento = EPSON_XML_DESCR_PAG_CONTANTI;
         if (indiciPagamentoAbilitato()) {
            switch (pPaymentIndex) {
               case EPSON_XML_INDEX_CONTANTI_DOMICILIO:
                  descr_pagamento = EPSON_XML_INDEX_DESCR_CONTANTI_DOMICILIO;
                  break;
            }
         }
         break;
      case EPSON_XML_COD_PAG_ASSEGNI:  
         descr_pagamento = EPSON_XML_DESCR_PAG_ASSEGNI;
         break;
      case EPSON_XML_COD_PAG_CARTE:
         descr_pagamento = EPSON_XML_DESCR_PAG_CARTE;
         if (indiciPagamentoAbilitato()) {
            switch (pPaymentIndex) {
               case EPSON_XML_INDEX_BANCOMAT:
                  descr_pagamento = EPSON_XML_INDEX_DESCR_BANCOMAT;
                  break;
               case EPSON_XML_INDEX_CARTE_CREDITO:
                  descr_pagamento = EPSON_XML_INDEX_DESCR_CARTE_CREDITO;
                  break;
               case EPSON_XML_INDEX_BONIFICO:
                  descr_pagamento = EPSON_XML_INDEX_DESCR_BONIFICO;
                  break;
               case EPSON_XML_INDEX_SATISPAY:
                  descr_pagamento = EPSON_XML_INDEX_DESCR_SATISPAY;
                  break;
               case EPSON_XML_INDEX_ECOMMERCE:
                  descr_pagamento = EPSON_XML_INDEX_DESCR_ECOMMERCE;
                  break;
            }
         }
         break;
      case EPSON_XML_COD_PAG_TICKET:
         descr_pagamento = EPSON_XML_DESCR_PAG_TICKET;
         break;
      case EPSON_XML_COD_PAG_BUONO:
         descr_pagamento = EPSON_XML_DESCR_PAG_BUONO;
         break;
      case EPSON_XML_COD_PAG_NON_RISCOSSO:
         descr_pagamento = EPSON_XML_DESCR_NON_RISCOSSO;
         if (indiciPagamentoAbilitato()) {
            switch (pPaymentIndex) {
               case EPSON_XML_INDEX_NON_RISCOSSO_BENI:
                  descr_pagamento = EPSON_XML_DESCR_NON_RISCOSSO_BENI;
                  break;
               case EPSON_XML_INDEX_NON_RISCOSSO_SERVIZI:
                  descr_pagamento = EPSON_XML_DESCR_NON_RISCOSSO_SERVIZI;
                  break;
               case EPSON_XML_INDEX_NON_RISCOSSO_FATTURA:
                  descr_pagamento = EPSON_XML_DESCR_NON_RISCOSSO_FATTURA;
                  break;
            }
         }
         break;
      default:                         
         descr_pagamento = EPSON_XML_DESCR_PAG_CONTANTI;
         break;
   }
   
   return descr_pagamento;
}







// ........................................
function descr_pagamento (mode) {
    switch (mode) {
        case 0: return "CONTANTI"
        case 1: return "ASSEGNI"
        case 2: return "CARTE"
        case 3: return "TICKET"
        default: return "CONTANTI"
    }
}




// ........................................
function stampa_nf_gen_xml(pArrayRigheScontrino, pOkCallback, pErrCallback)
{
   var ex = new epsonxml();
   ex.ip = window.GetCassaIpCgi();
   ex.operatore = '1';
   ex.font = '1';
   var stringa = ex.beginNonFiscal();
   for (var r in pArrayRigheScontrino) {
    	ex.data = pArrayRigheScontrino[r];
    	stringa += ex.textNonFiscal();
	}
   stringa += ex.endNonFiscal();
   ex.sendData(stringa, pOkCallback, pErrCallback);
}

// ........................................
function stampa_nf_gen_xml_multi_copia(pArrayRigheScontrino, pCopie, pOkCallback, pErrCallback, pAdditionalRigheCopia2, pQuestaCopia)
{
   if (!IsStringNumericPositive(pCopie))
      pCopie = 1;

   if (!IsStringNumericPositive(pQuestaCopia))
      pQuestaCopia = 1;

   // se sono alla copia 2, aggiunge le eventuali righe aggiuntive
   // se fossero richiesta piu' di 2 copie, non devo aggiungere ulteriormente
   // le righe aggiuntive per la copia 3,4 ecc. in quanto l'array pArrayRigheScontrino, gia'
   // modificato, viene poi passato a tutte le successive chiamate
   if (!varDecisamenteNonValida(pAdditionalRigheCopia2) && pAdditionalRigheCopia2.length && pAdditionalRigheCopia2.length > 0 && pQuestaCopia == 2)
      pArrayRigheScontrino = pArrayRigheScontrino.concat(pAdditionalRigheCopia2);
   
   stampa_nf_gen_xml(pArrayRigheScontrino, 
                     function() {
                        if (pQuestaCopia >= pCopie) {
                           if (typeof pOkCallback == "function")
                              pOkCallback();
                        } else {
                           stampa_nf_gen_xml_multi_copia(pArrayRigheScontrino, pCopie, pOkCallback, pErrCallback, pAdditionalRigheCopia2, pQuestaCopia+1);                        
                        } 
                     }, pErrCallback);    // se la stampa va in errore, chiamiamo la pErrCallback e ovviamente ci fermiamo anche se avevamo ancora copie da stampare

}







//------------------------------------------------------------------------
//
//  ritorna null se non c'e' acconto
//  ritorna un numero float se c'e' acconto
//
//        ATTENZIONE ESISTE IL CASO DI ACCONTO DI IMPORTO 0 QUINDI PER
//        PER NON CONFONDERE ACCONTO 0 E ASSENZA DI ACCONTO OCCORRE FARE:
//             ValoreAccontoVenditaCorrente() === null
//             ValoreAccontoVenditaCorrente() !== null
//
//------------------------------------------------------------------------
function ValoreAccontoVenditaCorrente()
{
   var tmpAcconto;

   if (IsSessionVarEmpty("acconto"))
      tmpAcconto = $("#acconto").val();
   else
      tmpAcconto = window.sessionStorage["acconto"];

   if (IsStringNumericOrFloat(tmpAcconto))
      return UnformatNumber(tmpAcconto);
   else
      return null;
}





function getAccontoVenditaOTotale()
{
   var a = ValoreAccontoVenditaCorrente();
   return ((a !== null && a >= 0) ? a : (window.IsSessionVarEmpty("totale") ? 0 : UnformatNumber(window.sessionStorage["totale"])));
}





//
//  pWhat == 1   restituisce array di oggetti mod_pag
//  pWhat == 2   ritorna true se ci sono modalita' multiple
//  pWhat == 3   controlla se gli importi sono sufficienti
//               ritorna "" se ok, altrimenti ritorna messaggio di errore
//   
function EpsonXmlElaboraModPag(pWhat, pIdAltroCampoContante)
{
   if (varDecisamenteNonValida(arrayCodPags) || !arrayCodPags.length || arrayCodPags.length <= 0) {
      window.alert("EpsonXmlElaboraModPag() - errore arrayCodPags non e' definita o e' vuota");
      return [];
   }
   if (varDecisamenteNonValida(arrayCodPagsPos) || !arrayCodPagsPos.length || arrayCodPagsPos.length <= 0) {
      window.alert("EpsonXmlElaboraModPag() - errore arrayCodPagsPos non e' definita o e' vuota");
      return [];
   }
   
   var mioTotale = getAccontoVenditaOTotale(); 
   var mioTotaleArroDL = SommaArrotonda(mioTotale, ( window.IsSessionVarEmpty("valore_arro_dl_50_2017") ? 0 : UnformatNumber(window.sessionStorage["valore_arro_dl_50_2017"]) ));
    
   var arrModPag = ElaboraModPag(mioTotaleArroDL, null, pIdAltroCampoContante);
   var contaNonZero;
   var sommaCaselle;
   var sommaCasellePos;
   var sommaCaselleNoResto;
   var sommaCaselleTicket;
   var i; 
   
   if (pWhat == 1) {
   
      return arrModPag;
   
   } else {
   
      contaNonZero        = 0;
      sommaCaselle        = 0;
      sommaCasellePos     = 0;
      sommaCaselleNoResto = 0;
      sommaCaselleTicket  = 0;
      
      for (i = 0; i < arrModPag.length; i++) {
         if (arrModPag[i].importo > 0) {                                                                                                                                                                       
            contaNonZero++;
            sommaCaselle += arrModPag[i].importo; 
            if (arrayCodPagsPos.indexOf(arrModPag[i].modalita) >= 0) {
               sommaCasellePos += arrModPag[i].importo;
            }
            if (arrModPag[i].modalita != COD_PAG_CONTANTI && arrModPag[i].modalita != COD_PAG_CONTANTI_DOMICILIO) {
               sommaCaselleNoResto += arrModPag[i].importo;
            }
            if (arrModPag[i].modalita == COD_PAG_TICKET) {
               sommaCaselleTicket += arrModPag[i].importo;
            }
         }   
      }
      
      sommaCaselle        = round(sommaCaselle,       2);
      sommaCasellePos     = round(sommaCasellePos,    2);
      sommaCaselleNoResto = round(sommaCaselleNoResto,2);
      sommaCaselleTicket  = round(sommaCaselleTicket, 2);

      if (pWhat == 2) {
         return (contaNonZero > 1);
      } else if (pWhat == 3) {

         if (mioTotale < 0) {
            //  ---->   resi: evitiamo di incasinarci con le modalita' di pagamento, e diamo OK a prescindere
            return "";
         } else if (sommaCaselleTicket > 0 && sommaCaselleTicket > mioTotale) {
            //  ---->   non e' ammesso pagare con piu' ticket del totale
            return "La somma dei ticket (" + MostUsedNumberFormat(sommaCaselleTicket) + ") e' superiore al totale (" + MostUsedNumberFormat(mioTotale) + ")"
         } else if (contaNonZero <= 0) {
            //  ---->   se non ci sono caselle valorizzate, per compatibilita' con il passato non diamo mai errore: andiamo di default su contanti
            return "";
         } else {
            //   ---->   se sono coinvolti i tickets, siamo super-severi e pretendiamo uguaglianza esatta perche' parrebbe che la Epson vada spesso e volentieri in blocco 
            //           (consentiamo comunque che la somma degli importi digitati corrisponda sia al totale arrotondato che non arrotondato)
            if (sommaCaselleTicket > 0 && sommaCaselle != mioTotaleArroDL && sommaCaselle != mioTotale) {
               return "La somma degli importi delle varie modalita' di pagamento (" + MostUsedNumberFormat(sommaCaselle) + ") " + 
                      "non corrisponde al totale (" + MostUsedNumberFormat(mioTotale) + (mioTotaleArroDL != mioTotale ? " arrotondato a " + MostUsedNumberFormat(mioTotaleArroDL) : "") + ")";
            } else {
               //if (contaNonZero == 1) {
                  // ---->    se finisco qui significa che:
                  //             - pago con tickets e ho superato il soprastante controllo (c'e' uguaglianza esatta)
                  //          oppure
                  //             - c'e' una sola casella valorizzata e non si tratta di tickets, e per non rischiare di incasinare le abitudini di tutti, diamo via libera a qualsiasi cosa
               //   return "";
               //} else {
                  if (sommaCaselle >= mioTotale || sommaCaselle >= mioTotaleArroDL) {
                     // ---->   se il maggior importo indicato e' dato da pagamenti che permettono il resto (contanti), tutto normale: sara' dato il resto come usuale
                     //         ma se il maggior importo risiede nelle caselle degli altri pagamenti, allora non va bene, come facciamo a dare il resto ?
                     if (sommaCaselleNoResto > mioTotale || sommaCaselleNoResto > mioTotaleArroDL)
                        return "La somma degli importi delle modalita' di pagamento \"no contante\" (" + MostUsedNumberFormat(sommaCaselleNoResto) + ") e' superiore al totale (" + MostUsedNumberFormat(sommaCaselleNoResto > mioTotale ? mioTotale : mioTotaleArroDL) + ")"
                     else  
                        return "";
                  } else {
                     // ---->   la somma degli importi nelle caselle non e' sufficiente
                     return "La somma degli importi delle varie modalita' di pagamento (" + MostUsedNumberFormat(sommaCaselle) + ") e' inferiore al totale (" + MostUsedNumberFormat(mioTotale) + ")"
                  }
               //} 
            }
         } 
      
      } else {
         window.alert("EpsonXmlElaboraModPag() - valore parametro non valido pWhat=" + pWhat);
         return 0;
      }
   }
   
}





// --------------------------------------------------------------------------
function NecessarioEseguirePagamentoPOS()
{
   var cassa_protocollo = '';
   var collegamentoCassaPos;
   
   if (!window.IsLocalVarEmpty("cassa_protocollo")) {
      cassa_protocollo = window.localStorage['cassa_protocollo'];
   } else if(!window.IsSessionVarEmpty("cassa_protocollo")) {
      cassa_protocollo = window.sessionStorage['cassa_protocollo'];
   }
	
   if (cassa_protocollo != 'epsonxml' && window.IsSessionVarEmpty('pos_usa_software_esterno'))
		return 0;
   

   // la localStorage e' utilizzata in ristoComande, che utilizza epsonxml.js per la stampa scontrino fiscale da palmare
   if (!window.IsLocalVarEmpty("collegamento_cassa_pos"))
      collegamentoCassaPos = window.localStorage["collegamento_cassa_pos"];
   else if (!window.IsSessionVarEmpty("collegamento_cassa_pos"))
      collegamentoCassaPos = window.sessionStorage["collegamento_cassa_pos"];
   else
      collegamentoCassaPos = 0;

   //window.alert("temp PROVVISORIAMENTE HO cablato collegamentoCassaPos = 1");
   //collegamentoCassaPos = 1;
   
   var importoCarta = 0;
   
   // Bruno  19/11/2021
   //    arrayCodPags e arrayCodPagsPos sono variabili globali che devono essere definite dall'applicativo
   //    - in ProRisto sono create in master.blade.php
   //    - nella VB sono inizializzate in uno dei files .js
   //    - in RistoComande sono al momento undefined: in questo caso inutile proseguire con i ragionamenti
   //      (non possiamo sapere se usare il POS o no!) e usciamo subito
   if (typeof arrayCodPags == "undefined" || typeof arrayCodPagsPos == "undefined")
      return 0;    
   
   var arrModPag = EpsonXmlElaboraModPag(1);
   
   for (var i = 0; i < arrModPag.length; i++) {
      if (arrModPag[i].importo > 0 && arrayCodPagsPos.indexOf(arrModPag[i].modalita) >= 0) {                                                                                                                                                                       
         importoCarta += arrModPag[i].importo;
      }
   }


   if (collegamentoCassaPos == 0 || collegamentoCassaPos == "0" || !collegamentoCassaPos || importoCarta <= 0)
      return 0;
   else
      return importoCarta;
}





// --------------------------------------------------------------------------
//
// Bruno  21/09/2021  nuovo comando per stampare scontrino fiscale e
//                    contestualmente inviare pagamento al POS
//
// --------------------------------------------------------------------------
function SeNecessarioEseguiPagamentoPOS(pOkCallback, pErrCallback) {

   var importoCarta = NecessarioEseguirePagamentoPOS();

   if (importoCarta <= 0) {
      // normale situazione: postazione senza collegamento con il POS
      // oppure pagamenti non con carte: chiamiamo la callback senza fare nulla

      if (typeof pOkCallback == "function")
         pOkCallback();

      
   } else {

      
      //  invia il comando di pagamento al POS
      //
      //  aumenta di brutto il timeout perche' dobbiamo dare il tempo al cliente
      //  di prendere la carta, digitare il PIN ecc. ecc.
      var ex = new epsonxml();
      ex.timeOut = 90000;
      
      if(window.IsSessionVarEmpty('pos_usa_software_esterno')){
         // mostro l'alert senza alcun bottone per la chiusura, in quanto dovra' per forza verificarsi un evento di "fine pagamento"
         // (che sia OK oppure errore), e sara' tale evento a chiudere l'alert
         var alertIddd = GenericConfirmAlert("Avvicinare / inserire la carta al POS ed effettuare il pagamento", "Pagamento con carta", "");
         
         ex.sendData(ex.CmdImportoPOS(importoCarta), 
                        
            function(result, tag_names_array, add_info) {

                  GenericRemoveDiv(alertIddd);
                  
                  // se il POS non stampa lo scontrino di conferma, manda a noi le stringhe da stampare
                  
                  if (add_info.lineCount > 0) {

                     stampa_nf_gen_xml(add_info.linesArray, pOkCallback, pErrCallback);
                  
                  } else { 
                  
                     if (typeof pOkCallback == "function")
                        pOkCallback();
                  
                  }
            
            },

            function () {
                  
               GenericRemoveDiv(alertIddd);
                  
               if (typeof pErrCallback == "function")
                     pErrCallback();
            }
         
         );
      }else{
         // Utilizzo software esterno tramite ws-sco
         if (sessionStorage['pos_usa_software_esterno'] == POS_SOFTWARE_DOREMIPOS && window.IsSessionVarEmpty('pos_cartella_condivisa')) {
            confirm_alert("ERRORE","Configurazioni errate per l\'utilizzo del POS. Richiedere assistenza.");
            return;
         }
                                        
         POS_ExecutePaymentWithCallbacks(importoCarta,pOkCallback,pErrCallback);
      }
   
   }


}






function InnerEstrazioneDGFE(pDataDaEpson,
                             pDataAEpson,
                             pNumeroDa,
                             pNumeroA,            
                             pOutputItemId,
                             pInc,
                             pEx,
                             pOkCallback,
                             pErrCallback)
{
   var ccmd;
   var ddata;
   
   ddata = "01" + pDataDaEpson;
   
   if (pDataDaEpson == pDataAEpson) {
      // faccio estrazione per numero
      ccmd = "3100";
      ddata += pNumeroDa;
      ddata += pNumeroA;
      //ccmd = "3104";
      //ddata += "1";  // read
      //ddata += "0";  // all
      //ddata += pDataDaEpson;
      //ddata += "00030004";  //"00019999";
   } else {
      // faccio estrazione per data
      ccmd = "3101";
      ddata += pDataAEpson 
   }
   
   ddata += pInc;
   
   //if (pDataDaEpson == pDataAEpson) {
     // ddata += "00";    // not used
   //} 
   
   
   pEx.sendData("<printerCommand><directIO command='" + ccmd + "' data='" + ddata + "'/></printerCommand>", 
                        
         function(result, tag_names_array, add_info) {
            
            if (result.success) {
            
               if (add_info.responseCommand == ccmd) {
               
                  var rigaDgfe = add_info.responseData.substr(16);
                  
                  if (!window.varDecisamenteNonValida(pOutputItemId)) {
                     var outItem = document.getElementById(pOutputItemId);
                     outItem.innerHTML += rigaDgfe;
                     outItem.innerHTML += "\r\n";
                     if (outItem.type != "textarea")
                        outItem.innerHTML += "<br/>";
                  } else if (typeof pOkCallback != "function") {
                     console.log(rigaDgfe);
                  }
               
                  EstrazioneDGFE_result += rigaDgfe;
                  EstrazioneDGFE_result += "\r\n";
                  
                  //setTimeout(function() {   
                     InnerEstrazioneDGFE(pDataDaEpson,
                                         pDataAEpson,
                                         pNumeroDa,
                                         pNumeroA,            
                                         pOutputItemId,
                                         "1",
                                         pEx,
                                         pOkCallback,
                                         pErrCallback);   
                  //}, pWaitTime);
            
               } else {
                  if (typeof pOkCallback == "function")
                     pOkCallback(EstrazioneDGFE_result);
                  else
                     window.alert("Finito")
               }
               
            } else {
               if (typeof pErrCallback == "function")
                  pErrCallback();
               window.alert("Errore EstrazioneDGFE !result.success");
            }

            
         },
   
         function() {
            if (typeof pErrCallback == "function")
               pErrCallback();
         }
   
   );

}



var EstrazioneDGFE_result;



// attenzione: estrarre il DGFE della data odierna mentre nel contempo vengono emessi scontrini puo' portare a risultati fuorvianti
// e' opportuno operare a cassa ferma oppure estrarre il DGFE dei giorni precedenti
function EstrazioneDGFE(pDataDa,
                        pDataA,
                        pNumeroDa,
                        pNumeroA,
                        pOutputItemId,
                        pOkCallback,
                        pErrCallback)
{
   if (window.sessionStorage["cassa_protocollo"] != "epsonxml") {
      window.alert("Operazione possibile solo con protocollo Epson-XML");
      return;
   }
   
   if (window.varDecisamenteNonValida(pDataDa))
      pDataDa = window.dateToStringItaly(null);     // data di oggi

   if (window.varDecisamenteNonValida(pDataA))
      pDataA = window.dateToStringItaly(null);      // data di oggi

   if (window.varDecisamenteNonValida(pNumeroDa) || !window.IsStringNumericPositive(pNumeroDa))
      pNumeroDa = 1;

   if (window.varDecisamenteNonValida(pNumeroA) || !window.IsStringNumericPositive(pNumeroA))
      pNumeroA = 9999;
   
   pNumeroDa = window.lpad(pNumeroDa, 4, "0");
   pNumeroA  = window.lpad(pNumeroA,  4, "0");
   
   //if (window.varDecisamenteNonValida(pWaitTime) || !window.IsStringNumericPositive(pWaitTime)) {
   //   pWaitTime = 1;
   //}
   
   EstrazioneDGFE_result = "";
   
   if (!window.varDecisamenteNonValida(pOutputItemId)) {
      if (document.getElementById(pOutputItemId) != null) {
         document.getElementById(pOutputItemId).innerHTML = "";
      } else {
         window.alert("Errore: non esiste l'elemento " + pOutputItemId + " - operazione lettura DGFE interrotta");
         return;
      } 
   }

   InnerEstrazioneDGFE(window.stringItalyToEpsonDate(pDataDa),
                       window.stringItalyToEpsonDate(pDataA),
                       pNumeroDa,
                       pNumeroA,            
                       pOutputItemId,
                       "0",   //  flag che indica se prima richiesta oppure successiva
                       new epsonxml(),
                       pOkCallback,
                       pErrCallback);   
}




function ApriPaginaWebChiusureFiscali()
{
   if (window.sessionStorage["cassa_protocollo"] != "epsonxml") {
      window.alert("Operazione possibile solo con protocollo Epson-XML");
      return;
   }

   window.open(str_replace("cgi-bin/fpmate.cgi","www/dati-rt",window.EpsonXmlScriptPath())+"/");
}



function GetCassaIpCgi()
{
   if (!window.IsSessionVarEmpty("cassa_ip_cgi"))
      return window.sessionStorage["cassa_ip_cgi"];
   else if (!window.IsLocalVarEmpty("cassa_ip_cgi"))     // la localStorage e' utilizzata in ristoComande, che utilizza epsonxml.js per la stampa scontrino fiscale da palmare
      return window.localStorage["cassa_ip_cgi"];
   else
      return "";
}

function GetCassaPortaIpCgi(){
	if (!window.IsSessionVarEmpty("cassa_porta_eth"))
	      return ":" + window.sessionStorage["cassa_porta_eth"];
	   else if (!window.IsLocalVarEmpty("cassa_porta_eth"))     // la localStorage e' utilizzata in ristoComande, che utilizza epsonxml.js per la stampa scontrino fiscale da palmare
	      return ":" + window.localStorage["cassa_porta_eth"];
	   else
	      return "";
}
// BRUNO   10/7/2023
// FUNZIONE CREATA PER ANALISI PRELIMINARE DI FATTIBILILTA' HTTPS
// al momento non esiste alcuna colonna DB per salvare questa impostazione
// per fare dei test https occorre impostare a mano:
//     sessionStorage["cassa_https"] = "1"    
function IsCassaHttps()
{
   if (!window.IsSessionVarEmpty("cassa_https"))
      return (window.sessionStorage["cassa_https"] == "1");
   else if (!window.IsLocalVarEmpty("cassa_https"))     // la localStorage e' utilizzata in ristoComande, che utilizza epsonxml.js per la stampa scontrino fiscale da palmare
      return (window.localStorage["cassa_https"] == "1");
   else
      return false;
}





// Bruno  12/5/2022  taroccamento del path epson-xml se siamo in sviluppo e utilizziamo il simulatore di cassa
function EpsonXmlScriptPath(pComandoXml, pEx)
{
   if (window.varDecisamenteNonValida(pComandoXml))
      pComandoXml = "";

   if (typeof pEx == "undefined")
      pEx = { ip : "" };
   
   if (window.varDecisamenteNonValida(pEx.ip)) {
      pEx.ip = window.GetCassaIpCgi();
   }

   // Bruno  10/7/2023  inizio a introdurre un minimo di configurabilita' e possibilita' di scelta tra http e https
   var xmlHTTPProtocol;
   if (IsCassaHttps())
      xmlHTTPProtocol = "https:";
   else
      xmlHTTPProtocol = "http:";
   
   var xmlHTTPRequestURL = EPSON_XML_SCRIPT_PATH;
   var portaCassa = "";
   // Bruno  9/8/2019  taroccamento del path epson-xml se siamo in sviluppo e utilizziamo il simulatore di cassa
   //
   //                  settando   localStorage["simula_pos_fpmate_cgi_php"] = 1   e' possibile simulare la comunicazione con
   //                  il POS:  in tal caso, tutti i comandi eccetto authorizeSales vanno verso il registratore di cassa
   //                  mentre il solo comando authorizeSales va al simulatore fpmate.cgi.php 
   if (  (
            // Bruno  21/7/2022  ho deciso di consentire il simulatore di epson anche in ambiente di produzione
            //                   perche' non c'e' nessun rischio di confondersi: una cassa Epson reale non 
            //                   potra' mai rispondere dall'indirizzo "127.0.0.1" oppure "proyes.it", quindi
            //                   se indico codesti valori per forza significa che intendo proprio usare il
            //                   simulatore
            /*( 
               (typeof window.SonoInAmbienteSviluppo == "function" && window.SonoInAmbienteSviluppo())
               ||
               (!window.IsSessionVarEmpty("db") && window.sessionStorage["db"]=="demo_generico")
            )
            &&*/
            window.GetCassaIpCgi() != ""
            &&
            (
               window.GetCassaIpCgi()             == window.location.hostname  || 
               window.GetCassaIpCgi()             == window.location.host      ||
               window.GetCassaIpCgi()             == "localhost"      ||
               window.GetCassaIpCgi().substr(0,9) == "127.0.0.1"        ||
               (
                  !window.IsLocalVarEmpty("ristows")     // --> sono su ristocomande
                  &&
                  window.GetCassaIpCgi() == window.localStorage["ristows"].replace("https:","").replace("http:","").replace(/\//g,"")  
               )
            )
         )
         ||
         (
            (typeof window.SonoInAmbienteSviluppo == "function"            && 
                    window.SonoInAmbienteSviluppo()                        &&
                    pComandoXml.indexOf("<authorizeSales ") > 10           &&
                    !window.IsLocalVarEmpty("simula_pos_fpmate_cgi_php")   && 
                    window.localStorage["simula_pos_fpmate_cgi_php"] == 1  )
         )
      ) {
      
      
      if (!window.IsLocalVarEmpty("ristows")) {
         // sono su ristocomande
         pEx.ip = window.GetCassaIpCgi();
         if (pEx.ip.indexOf(":") < 0 && window.location.port != "")
            pEx.ip += (":" + window.location.port) 
      } else {     
         pEx.ip = window.location.host;    // qui ci scrivo location.host perche' cosi' c'e' anche la porta
      }
      var portaCassa = GetCassaPortaIpCgi();
      xmlHTTPRequestURL = window.location.pathname.replace(/\/[a-z\_]+\.html/i,"/fpmate.cgi.php");
      // il suddetto replace va bene nella Vendita al banco
      // se il suddetto replace non ha funzionato, significa che siamo in Risto
      // e allora facciamo un taroccamento diverso
      if (xmlHTTPRequestURL.indexOf("fpmate.cgi.php") < 0)
         xmlHTTPRequestURL = "/fpmate.cgi.php";
      
      xmlHTTPProtocol = window.location.protocol;
   
   }
   
   
   xmlHTTPRequestURL = xmlHTTPProtocol + "//" + pEx.ip + xmlHTTPRequestURL; // + query_string;

   //        window.alert(xmlHTTPRequestURL);
   //        console.log(xmlHTTPRequestURL);


   return xmlHTTPRequestURL;

}



function EpsonXmlChiusuraFiscale(callback)
{
   var ex = new epsonxml();
   //ex.ip = sessionStorage["cassa_ip_cgi"];
   //ex.operatore = "1";
   //ex.font = "1";
   ex.sendData(ex.chiusura(),callback);
}



// indici di pagamento implementati solo nella VB
// in ProRisto la seguente function ritorna sempre false
// poiche' non esiste sessionStorage['abilita_indici_pagamento']
function indiciPagamentoAbilitato()
{
   return (
            !IsSessionVarEmpty('cassa_protocollo') && 
            sessionStorage['cassa_protocollo'] == 'epsonxml' && 
            !IsSessionVarEmpty('abilita_indici_pagamento') && 
            sessionStorage['abilita_indici_pagamento'] == 1
         ); 
}



function applicaIndicePagamento(pCodPag){
   
   if (!indiciPagamentoAbilitato()) {
      
      switch (parseInt(pCodPag)) {
         case COD_PAG_CONTANTI:              
            indice = EPSON_XML_INDEX_CONTANTI;
            break;
         case COD_PAG_BANCOMAT:              
            indice = EPSON_XML_INDEX_BANCOMAT;
            break;
         case COD_PAG_CARTE_DI_CREDITO:      
            indice = EPSON_XML_INDEX_CARTE_CREDITO;
            break;
         case COD_PAG_CREDITO:               
            indice = EPSON_XML_INDEX_CARTE_CREDITO;
            break;
         case COD_PAG_VISA:                  
            indice = EPSON_XML_INDEX_CARTE_CREDITO;
            break;
         case COD_PAG_SATISPAY:              
            indice = EPSON_XML_INDEX_SATISPAY;
            break;
         case COD_PAG_ASSEGNI:               
            indice = EPSON_XML_INDEX_CONTANTI;
            break;
         case COD_PAG_MASTERCARD:            
            indice = EPSON_XML_INDEX_CARTE_CREDITO;
            break;
         case COD_PAG_TICKET:                
            indice = EPSON_XML_INDEX_GENERIC_TICKET;
            break;
         case COD_PAG_BUONO:                 
            indice = EPSON_XML_INDEX_BUONO;
            break;
         case COD_PAG_SCONTO_PAGARE:         
            indice = EPSON_XML_INDEX_CARTE_CREDITO;
            break;
         case 11:                            
            indice = EPSON_XML_INDEX_CARTE_CREDITO;
            break;
         case 12:                            
            indice = EPSON_XML_INDEX_CONTANTI;
            break;
         case 13:                            
            indice = EPSON_XML_INDEX_CARTE_CREDITO;
            break;
         case COD_PAG_BONIFICO:              
            indice = EPSON_XML_INDEX_BONIFICO;
            break;
         case COD_PAG_E_COMMERCE:            
            indice = EPSON_XML_INDEX_ECOMMERCE;
            break;
         case COD_PAG_CONTANTI_DOMICILIO:    
            indice = EPSON_XML_INDEX_CONTANTI_DOMICILIO;
            break;
         case COD_PAG_NON_RISCOSSO_GENERICO: 
            indice = EPSON_XML_INDEX_NON_RISCOSSO_ALL;
            break;
         case COD_PAG_NON_RISCOSSO_BENI:     
            indice = EPSON_XML_INDEX_NON_RISCOSSO_BENI;
            break;
         case COD_PAG_NON_RISCOSSO_SERVIZI:  
            indice = EPSON_XML_INDEX_NON_RISCOSSO_SERVIZI;
            break;
         case COD_PAG_NON_RISCOSSO_FATTURA:  
            indice = EPSON_XML_INDEX_NON_RISCOSSO_FATTURA;
            break;
         case COD_PAG_NON_RISCOSSO_TICKET: 
            indice = EPSON_XML_INDEX_NON_RISCOSSO_ALL;
            break;
         default:                            
            indice = 1;
            break;
      }

   } else {

      switch (parseInt(pCodPag)) {
         case COD_PAG_BANCOMAT:
            indice = EPSON_XML_INDEX_BANCOMAT;
            break;
         case COD_PAG_AMERICAN_EXPRESS:
         case COD_PAG_VISA:
         case COD_PAG_MASTERCARD:
            indice = EPSON_XML_INDEX_CARTE_CREDITO;
            break;
         case COD_PAG_SATISPAY:
            indice = EPSON_XML_INDEX_SATISPAY;
            break;
         case COD_PAG_BONIFICO:
            indice = EPSON_XML_INDEX_BONIFICO;
            break;
         case COD_PAG_E_COMMERCE:
            indice = EPSON_XML_INDEX_ECOMMERCE;
            break;
         case COD_PAG_CONTANTI_DOMICILIO:
            indice = EPSON_XML_INDEX_CONTANTI_DOMICILIO;
            break;
         case COD_PAG_TICKET:
            indice = EPSON_XML_INDEX_GENERIC_TICKET;
            break;
         case COD_PAG_BUONO:
            indice = EPSON_XML_INDEX_BUONO;
            break;
         case COD_PAG_NON_RISCOSSO_GENERICO:
            indice = EPSON_XML_INDEX_NON_RISCOSSO_ALL;
            break;
         case COD_PAG_NON_RISCOSSO_BENI:
            indice = EPSON_XML_INDEX_NON_RISCOSSO_BENI;
            break;
         case COD_PAG_NON_RISCOSSO_SERVIZI:
            indice = EPSON_XML_INDEX_NON_RISCOSSO_SERVIZI;
            break;
         case COD_PAG_NON_RISCOSSO_FATTURA:
            indice = EPSON_XML_INDEX_NON_RISCOSSO_FATTURA;
            break;
         case COD_PAG_NON_RISCOSSO_TICKET: 
            indice = EPSON_XML_INDEX_NON_RISCOSSO_ALL;
            break;
         default:
            indice = EPSON_XML_INDEX_CONTANTI;
            break;
      }
   
   }
      
   // dobbiamo parcheggiare il valore in una sessionStorage poiche' quando viene chiamata totalFiscal
   // non abbiamo in mano il valore di pCodPag e quindi non riusciamo a determinare l'indice  
   
   // console.log('indice di pagamento applicato',indice);
   //if(!isNaN(indice = parseInt(indice))){
      sessionStorage['indice_pagamento_applicato'] = indice;
   //}
   
   return indice;
}




function CopiaObjEpsonInStorage(objEpsonRcv) {

   // se l'oggetto e` vuoto non faccio nulla
   if (Object.keys(objEpsonRcv).length == 0)
      return;

   // altrimenti eseguo loop e prendo soltanto quello che mi interessa
   // popolando le variabili di sessione
   for (var key in objEpsonRcv) {

      // isRtMode lo memorizzo nelle localStorage. la modalita' RT "idealmente" e` un parametro che restera' fisso nel tempo
      if (RT_PER_SESSION_KEY.indexOf(key) > -1) {
         if (key === "isRtMode")
            localStorage.setItem(key, objEpsonRcv[key]);
         else
            sessionStorage.setItem(key, objEpsonRcv[key]);
      }
   }

}




function EpsonDecodeStatoRT(pMainStatus, pSubStatus) {

   if (pMainStatus == "01" &&
      pSubStatus == "02")
      return "Mancano Certificati";

   if (pMainStatus == "01" &&
      (pSubStatus == "03" || pSubStatus == "04")
      )
      return "Certificati Incompleti";

   if (pMainStatus == "01" &&
      pSubStatus == "05")
      return "Certificati Caricati";

   if (pMainStatus == "01" &&
      pSubStatus == "06")
      return "Censito";

   if (pMainStatus == "01" &&
      pSubStatus == "07")
      return "Attivato";

   if (pMainStatus == "01" &&
      pSubStatus == "08")
      return "Pre Servizio";

   if (pMainStatus == "02")
      return "In Servizio";

   return "Stato indeterminato";
}



// Periodo inattivo
function EpsonDecodeNoWorkingPeriod(pRtNoWorkingPeriod) {

   var rtNoWorkingPeriod = "";

   switch (pRtNoWorkingPeriod) {
        case "1":
         rtNoWorkingPeriod = "In attesa della chiusura giornaliera";
      break;
      case "0":
         rtNoWorkingPeriod = "False";
         break;
      default:
         rtNoWorkingPeriod = "Stato indeterminato";
   }

   return rtNoWorkingPeriod;

}

// Data scadenza certificato dispositivo
function EpsonDecodeExpiryCD(pRtExpiryCD) {

   if (pRtExpiryCD != null) {

      if ((pRtExpiryCD).length == 8)
         return (pRtExpiryCD).substring(6, 8) + "/" + (pRtExpiryCD).substring(4, 6) + "/" + (pRtExpiryCD).substring(0, 4);
      else
         return "Parametro errato";

   } else
      return "Parametro non letto";

}

// Data scadenza certificato certificato CA AE
function EpsonDecodeExpiryCA(pRtExpiryCA) {

   if (pRtExpiryCA != null) {

      if ((pRtExpiryCA).length == 8)
         return (pRtExpiryCA).substring(6, 8) + "/" + (pRtExpiryCA).substring(4, 6) + "/" + (pRtExpiryCA).substring(0, 4);
      else
         return "Parametro errato";
   } else
      return "Parametro non letto";

}

// Modalita' Demo / Training / Simulatore
function EpsonDecodeTrainingMode(pRtTrainingMode) {

   if (pRtTrainingMode != null)
       return pRtTrainingMode;
   else
       return "Parametro non letto";

}



// Tipo dispositivo RT
function EpsonDecodeRtType(pRtType) {

   var rtType = "";

   switch (pRtType) {
      case "I":
         rtType = "Interno (Negozio / locale fisso)";
           break;
      case "E":
         rtType = "Esterno (mercato, strada, porta-a-porta e stagionale)";
           break;
      case "P":
         rtType = "Palmtop";
           break;
      case "M":
           rtType = "Misuratore fiscale modificato in RT";
          break;
      case "S":
         rtType = "Server RT";
           break;
      default:
         rtType = "Tipo " + pRtType + " non definito";
   }

   return rtType

}





/*
 * 
*/
function siamoInModalitaRT() {
   if (!IsLocalVarEmpty("isRtMode") && localStorage.getItem("isRtMode") == EPSON_MODE_RT_ATTIVA)
      return true;

   return false;
}







function IsCassaInPeriodoInattivo()
{

   if (!IsSessionVarEmpty("cassa_protocollo") &&
       sessionStorage["cassa_protocollo"] == "epsonxml" &&
       siamoInModalitaRT() &&
       !IsSessionVarEmpty("rtNoWorkingPeriod") &&
       sessionStorage.getItem("rtNoWorkingPeriod") != RT_NOT_WORKING_PERIOD_OK) {

      return true;

   } else {
      return false;
   }

}








// Bruno  11/5/2022  ho adattato questo e altri files javascript in modo che possano essere eseguiti
//                   sia in ambiente NODE che nel browser, senza alcuna modifica
if (window.UsingNodeJs()) {
   window.EpsonXmlScriptPath  =   EpsonXmlScriptPath;
   window.EstrazioneDGFE      =   EstrazioneDGFE;
   window.GetCassaIpCgi       =   GetCassaIpCgi;
}


function testEpsonPagamenti(tipo_pagamento,indice){
   var e = new epsonxml();
   var vatID = "";
   if(tipo_pagamento == 5){
      vatID = "vatId='1'";
   }
   e.sendData(
      "<printerFiscalReceipt>"+
      "<beginFiscalReceipt operator='1' />"+
      "<printRecItem operator='1' description='OGGETTO DI TEST' quantity='1,000' unitPrice='1,00' department='1' />"+
      "<printRecItem operator='1' description='OGGETTO DI TEST' quantity='1,000' unitPrice='1,00' department='2' />"+
      "<printRecTotal operator='1' paymentType='"+tipo_pagamento+"' index='"+indice+"' "+vatID+" />"+
      "<endFiscalReceipt operator='1' />"+
      "</printerFiscalReceipt>"
   );
  
}

function testEpsonPagamentoMisto(tipo_1,importo_1,tipo_2,importo_2){
   var e = new epsonxml();
   var vatID_1 = "";
   var vatID_2 = "";
   if(tipo_1 == 5){
      vatID_1 = "vatId='1'";
   }
   if(tipo_2 == 5){
      vatID_2 = "vatId='1'";
   }
   e.importoPagato = importo_1;
   e.pagamento = tipo_1;
   var tot_1 = e.totalFiscal();
   e.importoPagato = importo_2;
   e.pagamento = tipo_2;
   var tot_2 = e.totalFiscal();
   e.sendData(
      "<printerFiscalReceipt>"+
      "<beginFiscalReceipt operator='1' />"+
      "<printRecItem operator='1' description='OGGETTO DI TEST' quantity='1,000' unitPrice='"+importo_1+"' department='1' />"+
      "<printRecItem operator='1' description='OGGETTO DI TEST' quantity='1,000' unitPrice='"+importo_2+"' department='2' />"+
      tot_1+
      tot_2+
      "<endFiscalReceipt operator='1' />"+
      "</printerFiscalReceipt>"
   );
}
