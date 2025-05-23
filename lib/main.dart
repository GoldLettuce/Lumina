import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/theme.dart';
import 'l10n/app_localizations.dart'; // Importa la clase generada para i18n
import 'package:flutter_localizations/flutter_localizations.dart'; // Importa localizaciones

import 'domain/entities/investment.dart';
import 'data/repositories_impl/investment_repository_impl.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  Hive.registerAdapter(InvestmentAdapter());

  final investmentRepository = InvestmentRepositoryImpl();
  await investmentRepository.init();

  runApp(PortfolioApp(investmentRepository: investmentRepository));
}

class PortfolioApp extends StatelessWidget {
  final InvestmentRepositoryImpl investmentRepository;

  const PortfolioApp({super.key, required this.investmentRepository});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mi Portafolio',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('es'),
      ],
      home: PortfolioScreen(investmentRepository: investmentRepository),
    );
  }
}

class PortfolioScreen extends StatefulWidget {
  final InvestmentRepositoryImpl investmentRepository;

  const PortfolioScreen({super.key, required this.investmentRepository});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  List<Investment> investments = [];

  @override
  void initState() {
    super.initState();
    _loadInvestments();
  }

  Future<void> _loadInvestments() async {
    final data = await widget.investmentRepository.getAllInvestments();
    setState(() {
      investments = data;
    });
  }

  @override
  Widget build(BuildContext context) {
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
          // Aquí añadirás función para agregar una nueva inversión y refrescar la lista
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
              '€${investments.fold(0.0, (sum, inv) => sum + inv.price * inv.quantity).toStringAsFixed(2)}',
              style: theme.textTheme.headlineLarge,
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)?.dailyPL ?? '',
              style: theme.textTheme.bodyMedium,
            ),
            Text(
              AppLocalizations.of(context)?.openPL ?? '',
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
              child: investments.isEmpty
                  ? Center(child: Text(AppLocalizations.of(context)?.noInvestments ?? 'No investments'))
                  : ListView.separated(
                itemCount: investments.length,
                separatorBuilder: (context, index) => Divider(color: AppColors.border),
                itemBuilder: (context, index) {
                  final asset = investments[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      asset.symbol,
                      style: theme.textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${AppLocalizations.of(context)?.quantity ?? ''}: ${asset.quantity}',
                      style: theme.textTheme.bodyMedium,
                    ),
                    trailing: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '€${(asset.price * asset.quantity).toStringAsFixed(2)}',
                          style: theme.textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.w600),
                        ),
                        // Aquí podrías calcular y mostrar el cambio porcentual
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
