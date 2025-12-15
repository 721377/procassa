// models.dart
class Product {
  final String id;
  final String name;
  final String category;
  double price;
  final String description;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.description,
  });

  Product copyWith({
    String? id,
    String? name,
    String? category,
    double? price,
    String? description,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      description: description ?? this.description,
    );
  }
}

class Categoria {
  final int? id;
  final String descrizione;

  Categoria({
    this.id,
    required this.descrizione,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'descrizione': descrizione,
    };
  }

  factory Categoria.fromMap(Map<String, dynamic> map) {
    return Categoria(
      id: map['id'],
      descrizione: map['descrizione'],
    );
  }
}

class Articolo {
  final int? id;
  final String descrizione;
  final double prezzo;
  final double iva;
  final String codice;
  final int categoriaId;

  Articolo({
    this.id,
    required this.descrizione,
    required this.prezzo,
    required this.iva,
    required this.codice,
    required this.categoriaId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'descrizione': descrizione,
      'prezzo': prezzo,
      'iva': iva,
      'codice': codice,
      'categoria_id': categoriaId,
    };
  }

  factory Articolo.fromMap(Map<String, dynamic> map) {
    return Articolo(
      id: map['id'],
      descrizione: map['descrizione'],
      prezzo: map['prezzo'],
      iva: map['iva'],
      codice: map['codice'],
      categoriaId: map['categoria_id'],
    );
  }
}

class Stampante {
  int? id;
  String nome;
  String indirizzoIp;
  int porta;
  String tipoProtocollo;
  String? printerType; // 'Network' or 'Bluetooth'
  String? printerCategory; // 'Receipt' or 'Order'
  String? orderPrinterType; // For order printers: 'IP' or 'Bluetooth'
  String? bluetoothAddress; // For Bluetooth printers
  bool? isDefault; // Is this the default printer for its category
  String? printerModel; // Printer model: 'Sunmi Pro', 'Generic', etc.

  Stampante({
    this.id,
    required this.nome,
    required this.indirizzoIp,
    required this.porta,
    required this.tipoProtocollo,
    this.printerType = 'Network',
    this.printerCategory,
    this.orderPrinterType,
    this.bluetoothAddress,
    this.isDefault = false,
    this.printerModel,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'indirizzoIp': indirizzoIp, // Match database column name
      'porta': porta,
      'tipoProtocollo': tipoProtocollo, // Match database column name
      'printerType': printerType,
      'printerCategory': printerCategory,
      'orderPrinterType': orderPrinterType,
      'bluetoothAddress': bluetoothAddress,
      'isDefault': (isDefault ?? false) ? 1 : 0,
      'printerModel': printerModel,
    };
  }

  factory Stampante.fromMap(Map<String, dynamic> map) {
    return Stampante(
      id: map['id'],
      nome: map['nome'],
      indirizzoIp: map['indirizzoIp'],
      porta: map['porta'],
      tipoProtocollo: map['tipoProtocollo'],
      printerType: map['printerType'] ?? 'Network',
      printerCategory: map['printerCategory'],
      orderPrinterType: map['orderPrinterType'],
      bluetoothAddress: map['bluetoothAddress'],
      isDefault: (map['isDefault'] as int? ?? 0) == 1,
      printerModel: map['printerModel'],
    );
  }
}

class TipoPagamento {
  final int? id;
  final String descrizione;

  TipoPagamento({
    this.id,
    required this.descrizione,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'descrizione': descrizione,
    };
  }

  factory TipoPagamento.fromMap(Map<String, dynamic> map) {
    return TipoPagamento(
      id: map['id'],
      descrizione: map['descrizione'],
    );
  }
}

class CartItem {
  final Product product;
  int quantity;
  double get total => product.price * quantity;

  CartItem({
    required this.product,
    this.quantity = 1,
  });

  // Copy with method for CartItem
  CartItem copyWith({
    Product? product,
    int? quantity,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }
}

class Category {
  final String id;
  final String name;
  int itemCount;

  Category({
    required this.id,
    required this.name,
    required this.itemCount,
  });
}

class IVA {
  final int? id;
  final String nome;
  final double valore;

  IVA({
    this.id,
    required this.nome,
    required this.valore,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'valore': valore,
    };
  }

  factory IVA.fromMap(Map<String, dynamic> map) {
    return IVA(
      id: map['id'],
      nome: map['nome'],
      valore: map['valore'],
    );
  }
}