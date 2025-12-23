class SimpleIvaManager {
  // Mappa delle IVA con dipartimento e descrizione
  static final Map<String, Map<String, dynamic>> _ivaMap = {
    //  '00': {
    //   'department': 6,
    //   'rate': 00.0,
    //   'description': 'IVA Ordinaria 0%',
    // },
    '04': {
      'department': 3,
      'rate': 4.0,
      'description': 'IVA Super Ridotta 4%',
    },
    '05': {
      'department': 4,
      'rate': 5.0,
      'description': 'IVA Ridotta 5%',
    },
    '10': {
      'department': 2,
      'rate': 10.0,
      'description': 'IVA Ridotta 10%',
    },
    '22': {
      'department': 1,
      'rate': 22.0,
      'description': 'IVA Ordinaria 22%',
    },
  };

  /// Restituisce il dipartimento per un codice IVA
  static int getDepartment(String ivaCode) {
    return _ivaMap[ivaCode]?['department'] ?? 4; // Default a IVA 22%
  }

  /// Restituisce l'aliquota IVA
  static double getRate(String ivaCode) {
    return _ivaMap[ivaCode]?['rate'] ?? 22.0; // Default a 22%
  }

  /// Restituisce la descrizione IVA
  static String getDescription(String ivaCode) {
    return _ivaMap[ivaCode]?['description'] ?? 'IVA Ordinaria 22%';
  }

  /// Verifica se il codice IVA è valido
  static bool isValid(String ivaCode) {
    return _ivaMap.containsKey(ivaCode);
  }

  /// Restituisce tutte le IVA disponibili
  static List<String> getAllCodes() {
    return _ivaMap.keys.toList();
  }

  /// Restituisce tutte le IVA con i dati completi
  static List<Map<String, dynamic>> getAll() {
    return _ivaMap.entries.map((entry) {
      return {
        'code': entry.key,
        'department': entry.value['department'],
        'rate': entry.value['rate'],
        'description': entry.value['description'],
      };
    }).toList();
  }

  /// Restituisce il codice IVA basato sulla rate
  static String? getCodeByRate(double rate) {
    for (final entry in _ivaMap.entries) {
      if ((entry.value['rate'] as double).toStringAsFixed(1) == rate.toStringAsFixed(1)) {
        return entry.key;
      }
    }
    return null;
  }
}