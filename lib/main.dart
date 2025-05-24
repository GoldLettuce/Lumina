import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/theme.dart';
import 'l10n/app_localizations.dart'; // Importa la clase generada para i18n
import 'package:flutter_localizations/flutter_localizations.dart'; // Importa localizaciones

import 'domain/entities/investment.dart';
import 'data/repositories_impl/investment_repository_impl.dart';
import 'ui/widgets/add_investment_dialog.dart';

// NUEVO: Provider e InvestmentModel
import 'package:provider/provider.dart';
import 'data/models/investment_model.dart';
import 'ui/screens/portfolio_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  Hive.registerAdapter(InvestmentAdapter());

  final investmentRepository = InvestmentRepositoryImpl();
  await investmentRepository.init();

  // Inyecta el Provider aquí
  runApp(
    ChangeNotifierProvider(
      create: (_) => InvestmentModel(investmentRepository),
      child: const PortfolioApp(),
    ),
  );
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
        AppLocalizations.delegate,
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
