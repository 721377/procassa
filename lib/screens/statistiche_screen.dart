import 'package:flutter/material.dart';

class StatisticheScreen extends StatelessWidget {
  const StatisticheScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiche'),
        backgroundColor: const Color(0xFF2D6FF1),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistiche di Vendita',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            _buildStatCard(
              title: 'Vendite Totali',
              value: '€ 2,450.50',
              subtitle: 'Questo mese',
              icon: Icons.trending_up,
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            _buildStatCard(
              title: 'Numero Transazioni',
              value: '142',
              subtitle: 'Ordini completati',
              icon: Icons.shopping_cart,
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
            _buildStatCard(
              title: 'Scontrino Medio',
              value: '€ 17.26',
              subtitle: 'Importo medio per transazione',
              icon: Icons.receipt,
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
            _buildStatCard(
              title: 'Articoli Venduti',
              value: '245',
              subtitle: 'Totale unità',
              icon: Icons.inventory_2,
              color: Colors.purple,
            ),
            const SizedBox(height: 32),
            Text(
              'Articoli Più Venduti',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ..._buildTopProducts(),
            const SizedBox(height: 32),
            Text(
              'Metodi di Pagamento',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ..._buildPaymentMethods(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTopProducts() {
    final products = [
      {'name': 'Beef Croissant', 'quantity': 45, 'revenue': '€ 247.50'},
      {'name': 'Butter Croissant', 'quantity': 38, 'revenue': '€ 152.00'},
      {'name': 'Chocolate Muffin', 'quantity': 32, 'revenue': '€ 112.00'},
      {'name': 'Club Sandwich', 'quantity': 28, 'revenue': '€ 182.00'},
    ];

    return products.map((product) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Card(
          child: ListTile(
            title: Text(product['name'] as String),
            subtitle: Text(
              '${product['quantity']} unità vendute',
            ),
            trailing: Text(
              product['revenue'] as String,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildPaymentMethods() {
    final methods = [
      {'name': 'Contanti', 'amount': '€ 1,230.45', 'percentage': 50},
      {'name': 'Carta di Credito', 'amount': '€ 982.30', 'percentage': 40},
      {'name': 'Assegno', 'amount': '€ 237.75', 'percentage': 10},
    ];

    return methods.map((method) {
      final percentage = method['percentage'] as int;
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      method['name'] as String,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      method['amount'] as String,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D6FF1),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    minHeight: 8,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF2D6FF1),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$percentage%',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }
}
