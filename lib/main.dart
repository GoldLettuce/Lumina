import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'l10n/app_localizations.dart'; // Importa la clase generada
import 'package:flutter_localizations/flutter_localizations.dart'; // Importa localizaciones

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
      theme: AppTheme.lightTheme,
      localizationsDelegates: const [
        AppLocalizations.delegate, // Delegate generado automáticamente
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('es'),
      ],
      home: const PortfolioScreen(),
    );
  }
}

class PortfolioScreen extends StatelessWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final totalValue = '€374,528.47';
    final dailyPL = AppLocalizations.of(context)?.dailyPL ?? '';
    final openPL = AppLocalizations.of(context)?.openPL ?? '';
    final assets = [
      {'name': 'AAPL', 'quantity': 2.0, 'value': '€0.47', 'change': '-90.76%', 'changeColor': AppColors.negative},
      {'name': 'bitcoin', 'quantity': 4.0, 'value': '€374,528.00', 'change': '1.22%', 'changeColor': AppColors.positive},
    ];

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.appTitle ?? ''),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Acción añadir inversión (más adelante)
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              totalValue,
              style: theme.textTheme.headlineLarge,
            ),
            const SizedBox(height: 8),
            Text(
              dailyPL,
              style: theme.textTheme.bodyMedium,
            ),
            Text(
              openPL,
              style: theme.textTheme.bodyMedium!.copyWith(color: AppColors.positive),
            ),
            const SizedBox(height: 20),
            Container(
              height: 150,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary.withOpacity(0.5), AppColors.primary.withOpacity(0.1)],
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  AppLocalizations.of(context)?.graphPlaceholder ?? '',
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.separated(
                itemCount: assets.length,
                separatorBuilder: (context, index) => Divider(color: AppColors.border),
                itemBuilder: (context, index) {
                  final asset = assets[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      asset['name'] as String,
                      style: theme.textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${AppLocalizations.of(context)?.quantity ?? ''}: ${asset['quantity']}',
                      style: theme.textTheme.bodyMedium,
                    ),
                    trailing: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          asset['value'] as String,
                          style: theme.textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.w600),
                        ),
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
