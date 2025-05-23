import 'package:flutter/material.dart';

void main() {
  runApp(const PortfolioApp());
}

class PortfolioApp extends StatelessWidget {
  const PortfolioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mi Portafolio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      home: const PortfolioScreen(),
    );
  }
}

class PortfolioScreen extends StatelessWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Datos estáticos ejemplo
    final totalValue = '€374528.47';
    final dailyPL = 'P/G diario | 0,00 € 0.00%';
    final openPL = 'Abrir P/G | 4328.47 € 1.17%';
    final assets = [
      {'name': 'AAPL', 'quantity': 2.0, 'value': '€0.47', 'change': '-90.76%', 'changeColor': Colors.red},
      {'name': 'bitcoin', 'quantity': 4.0, 'value': '€374528.00', 'change': '1.22%', 'changeColor': Colors.green},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Portafolio'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Acción añadir inversión (más adelante)
        },
        backgroundColor: Colors.lightBlueAccent,
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Total invertido
            Text(
              totalValue,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 8),

            // P/G diario
            Text(
              dailyPL,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),

            // Abrir P/G
            Text(
              openPL,
              style: TextStyle(fontSize: 14, color: Colors.green[600]),
            ),

            const SizedBox(height: 20),

            // Placeholder para gráfico
            Container(
              height: 150,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade200.withOpacity(0.5), Colors.green.shade50.withOpacity(0.1)],
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  'Gráfico placeholder',
                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Lista de activos
            Expanded(
              child: ListView.separated(
                itemCount: assets.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final asset = assets[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(asset['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Cantidad: ${asset['quantity']}'),
                    trailing: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(asset['value'] as String, style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(
                          asset['change'] as String,
                          style: TextStyle(color: asset['changeColor'] as Color, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
