import 'package:flutter/material.dart';
import 'articoli_screen.dart';
import 'categorie_screen.dart';
import 'iva_screen.dart';

class AnagraficaScreen extends StatefulWidget {
  const AnagraficaScreen({super.key});

  @override
  State<AnagraficaScreen> createState() => _AnagraficaScreenState();
}

class _AnagraficaScreenState extends State<AnagraficaScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, 
              color: Colors.grey[700], size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Anagrafica',
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!, width: 1),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorWeight: 3,
              indicatorColor: const Color(0xFF2D6FF1),
              labelColor: const Color(0xFF2D6FF1),
              unselectedLabelColor: const Color(0xFF6B7280),
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              tabs: const [
                Tab(text: 'Articoli'),
                Tab(text: 'Categorie'),
                Tab(text: 'IVA'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          ArticoliScreen(),
          CategorieScreen(),
          IVAScreen(),
        ],
      ),
    );
  }
}