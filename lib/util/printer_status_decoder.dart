class FpStatusDecoder {
  static String decodeFpStatus(String fpStatus) {
    String printer;
    String ej;
    String cashDrawer;
    String receipt;
    String mode;

    switch (fpStatus.substring(0, 1)) {
      case "0":
        printer = "OK";
        break;
      case "2":
        printer = "Carta in esaurimento";
        break;
      case "3":
        printer = "Stampante offline (fine carta o coperchio aperto)";
        break;
      default:
        printer = "Stato stampante sconosciuto";
    }

    switch (fpStatus.substring(1, 2)) {
      case "0":
        ej = "Giornale elettronico OK";
        break;
      case "1":
        ej = "Giornale prossimo ad esaurimento";
        break;
      case "2":
        ej = "Giornale da formattare";
        break;
      case "3":
        ej = "Giornale precedente";
        break;
      case "4":
        ej = "Giornale di altro misuratore";
        break;
      case "5":
        ej = "Giornale esaurito";
        break;
      default:
        ej = "Stato giornale elettronico sconosciuto";
    }

    switch (fpStatus.substring(2, 3)) {
      case "0":
        cashDrawer = "Cassetto aperto";
        break;
      case "1":
        cashDrawer = "Cassetto chiuso";
        break;
      default:
        cashDrawer = "Stato cassetto sconosciuto";
    }

    switch (fpStatus.substring(3, 4)) {
      case "0":
        receipt = "Scontrino fiscale aperto";
        break;
      case "1":
        receipt = "Scontrino chiuso";
        break;
      case "2":
        receipt = "Scontrino non fiscale aperto";
        break;
      case "3":
        receipt = "Pagamento in corso";
        break;
      case "4":
        receipt = "Errore comando ESC/POS con scontrino chiuso";
        break;
      case "5":
        receipt = "Scontrino in negativo";
        break;
      case "6":
        receipt = "Errore comando ESC/POS con scontrino aperto";
        break;
      case "7":
        receipt = "Attesa chiusura scontrino (modalità JAVAPOS)";
        break;
      case "8":
        receipt = "Documento fiscale aperto";
        break;
      case "A":
        receipt = "Titolo aperto";
        break;
      case "2":
        receipt = "Titolo chiuso";
        break;
      default:
        receipt = "Stato scontrino sconosciuto";
    }

    switch (fpStatus.substring(4, 5)) {
      case "0":
        mode = "Stato: Registrazione";
        break;
      case "1":
        mode = "Stato: X";
        break;
      case "2":
        mode = "Stato: Z";
        break;
      case "3":
        mode = "Stato: Set";
        break;
      default:
        mode = "Modalità sconosciuta";
    }

    return "$printer | $ej | $cashDrawer | $receipt | $mode";
  }
  static Map<String, String> decodeFpStatusSegments(String fpStatus) {
  final segments = decodeFpStatus(fpStatus).split('|').map((e) => e.trim()).toList();

  return {
    'printer': segments.isNotEmpty ? segments[0] : '',
    'ej': segments.length > 1 ? segments[1] : '',
    'cashDrawer': segments.length > 2 ? segments[2] : '',
    'receipt': segments.length > 3 ? segments[3] : '',
    'mode': segments.length > 4 ? segments[4] : '',
  };
}

}
