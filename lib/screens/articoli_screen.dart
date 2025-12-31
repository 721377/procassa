import 'dart:math';
import 'package:flutter/material.dart';
import '../models.dart';
import '../services/database_service.dart';
import '../services/iva_handler.dart';

class ArticoliScreen extends StatefulWidget {
  const ArticoliScreen({super.key});

  @override
  State<ArticoliScreen> createState() => _ArticoliScreenState();
}

class _ArticoliScreenState extends State<ArticoliScreen> {
  final DatabaseService _db = DatabaseService();
  late Future<List<Articolo>> _articoli;
  late Future<List<Categoria>> _categorie;
  late Future<List<IVA>> _ivas;

  final TextEditingController _descrizioneController = TextEditingController();
  final TextEditingController _prezzoController = TextEditingController();
  final TextEditingController _codiceController = TextEditingController();

  Articolo? _editingArticolo;
  int? _selectedCategoriaId;
  double? _selectedIvaValue;
  String? _selectedIvaCode;

  @override
  void initState() {
    super.initState();
    _articoli = _db.getArticoli();
    _categorie = _db.getCategorias();
    _ivas = _db.getIVAs();
  }

  void _resetForm() {
    _descrizioneController.clear();
    _prezzoController.clear();
    _codiceController.clear();
    _selectedCategoriaId = null;
    _selectedIvaValue = null;
    _selectedIvaCode = null;
    _editingArticolo = null;
  }

  void _openBottomSheet({Articolo? articolo}) {
    if (articolo != null) {
      _descrizioneController.text = articolo.descrizione;
      _prezzoController.text = articolo.prezzo.toString();
      _selectedIvaValue = articolo.iva;
      _selectedIvaCode = SimpleIvaManager.getCodeByRate(articolo.iva);
      _codiceController.text = articolo.codice;
      _selectedCategoriaId = articolo.categoriaId;
      _editingArticolo = articolo;
    } else {
      _resetForm();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  articolo != null ? 'Modifica Articolo' : 'Nuovo Articolo',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Descrizione
            Text(
              'Descrizione',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descrizioneController,
              decoration: InputDecoration(
                hintText: 'Inserisci descrizione',
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Codice
            Text(
              'Codice (Opzionale)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _codiceController,
              decoration: InputDecoration(
                hintText: 'Lascia vuoto per generare automaticamente',
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Prezzo e IVA in row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Prezzo',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _prezzoController,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          hintText: '0.00',
                          prefixText: '€ ',
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'IVA %',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      FutureBuilder<List<IVA>>(
                        future: _ivas,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Container(
                              height: 56,
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(child: CircularProgressIndicator()),
                            );
                          }

                          final ivas = snapshot.data ?? [];

                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<double>(
                                isExpanded: true,
                                value: _selectedIvaValue,
                                hint: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    'Seleziona IVA',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ),
                                items: ivas.map((iva) {
                                  return DropdownMenuItem<double>(
                                    value: iva.valore,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: Text('${iva.nome} (${iva.valore}%)'),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setDialogState(() {
                                    _selectedIvaValue = value;
                                    if (value != null) {
                                      _selectedIvaCode = SimpleIvaManager.getCodeByRate(value);
                                    }
                                  });
                                },
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Codice IVA
            Text(
              'Codice IVA (Opzionale)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  isExpanded: true,
                  value: _selectedIvaCode,
                  icon: const Icon(Icons.arrow_drop_down_rounded),
                  borderRadius: BorderRadius.circular(12),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  hint: const Text(
                    'Seleziona codice IVA',
                    style: TextStyle(color: Colors.grey),
                  ),
                  onChanged: (value) {
                    setDialogState(() {
                      _selectedIvaCode = value;
                      if (value != null && SimpleIvaManager.isValid(value)) {
                        _selectedIvaValue = SimpleIvaManager.getRate(value);
                      }
                    });
                  },
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Nessuno'),
                    ),
                    ...SimpleIvaManager.getAllCodes().map((code) {
                      final description = SimpleIvaManager.getDescription(code);
                      return DropdownMenuItem<String?>(
                        value: code,
                        child: Text('$code - $description'),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Categoria
            Text(
              'Categoria',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            FutureBuilder<List<Categoria>>(
              future: _categorie,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(child: CircularProgressIndicator()),
                  );
                }
                
                final categorie = snapshot.data ?? [];
                
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      isExpanded: true,
                      value: _selectedCategoriaId,
                      hint: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Seleziona categoria',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                      items: categorie.map((cat) {
                        return DropdownMenuItem<int>(
                          value: cat.id,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(cat.descrizione),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          _selectedCategoriaId = value;
                        });
                      },
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            
            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: Colors.grey[300]!),
                    ),
                    child: Text(
                      'Annulla',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveArticolo,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D6FF1),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Salva',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _generateRandomCode() {
    final random = Random();
    const chars = '0123456789';
    return List.generate(8, (index) => chars[random.nextInt(chars.length)]).join();
  }

  Future<void> _saveArticolo() async {
    if (_descrizioneController.text.isEmpty ||
        _prezzoController.text.isEmpty ||
        _selectedIvaValue == null ||
        _selectedCategoriaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Compila tutti i campi obbligatori'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
      return;
    }

    String codice = _codiceController.text.trim();
    
    // Check if code exists
    if (codice.isNotEmpty) {
      final existingArticolo = await _db.getArticoloByCodice(codice);
      if (existingArticolo != null && 
          (_editingArticolo == null || existingArticolo.id != _editingArticolo!.id)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Un articolo con codice "$codice" esiste già'),
            backgroundColor: Colors.orange[800],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        return;
      }
    } else {
      // Generate random code if not provided
      bool isUnique = false;
      while (!isUnique) {
        codice = _generateRandomCode();
        final existing = await _db.getArticoloByCodice(codice);
        if (existing == null) {
          isUnique = true;
        }
      }
    }

    try {
      final prezzo = double.parse(_prezzoController.text);

      if (_editingArticolo != null) {
        final updated = Articolo(
          id: _editingArticolo!.id,
          descrizione: _descrizioneController.text,
          prezzo: prezzo,
          iva: _selectedIvaValue!,
          codice: codice,
          categoriaId: _selectedCategoriaId!,
        );
        await _db.updateArticolo(updated);
      } else {
        final newArticolo = Articolo(
          descrizione: _descrizioneController.text,
          prezzo: prezzo,
          iva: _selectedIvaValue!,
          codice: codice,
          categoriaId: _selectedCategoriaId!,
        );
        await _db.insertArticolo(newArticolo);
      }

      _resetForm();
      setState(() {
        _articoli = _db.getArticoli();
      });
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _editingArticolo != null
                ? 'Articolo modificato'
                : 'Articolo aggiunto',
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore: $e'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  void _deleteArticolo(Articolo articolo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Elimina articolo',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Sei sicuro di voler eliminare "${articolo.descrizione}"?',
          style: TextStyle(color: Colors.grey[600]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[600],
            ),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _db.deleteArticolo(articolo.id!);
              setState(() {
                _articoli = _db.getArticoli();
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Articolo eliminato'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[50],
              foregroundColor: Colors.red,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.red[100]!),
              ),
            ),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openBottomSheet(),
        backgroundColor: const Color(0xFF2D6FF1),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 2,
        child: const Icon(Icons.add_rounded, size: 24),
      ),
      body: FutureBuilder<List<Articolo>>(
        future: _articoli,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF2D6FF1),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Errore nel caricamento',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          final articoli = snapshot.data ?? [];

          if (articoli.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 72,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nessun articolo',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Aggiungi il tuo primo articolo',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: articoli.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final articolo = articoli[index];
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D6FF1).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.inventory_2_outlined,
                      color: Color(0xFF2D6FF1),
                      size: 20,
                    ),
                  ),
                  title: Text(
                    articolo.descrizione,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        'Codice: ${articolo.codice}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            '€${articolo.prezzo.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'IVA ${articolo.iva}%',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => _openBottomSheet(articolo: articolo),
                        icon: Icon(
                          Icons.edit_outlined,
                          color: Colors.grey[600],
                          size: 20,
                        ),
                      ),
                      IconButton(
                        onPressed: () => _deleteArticolo(articolo),
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.red[400],
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _descrizioneController.dispose();
    _prezzoController.dispose();
    _codiceController.dispose();
    super.dispose();
  }
}