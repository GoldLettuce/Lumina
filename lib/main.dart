import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/theme.dart';
import 'l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'domain/entities/investment.dart';
import 'data/repositories_impl/investment_repository_impl.dart';
import 'ui/widgets/add_investment_dialog.dart';

import 'package:provider/provider.dart';
import 'data/models/investment_model.dart';
import 'ui/screens/portfolio_screen.dart';
import 'ui/providers/chart_value_provider.dart';
import 'ui/providers/asset_list_provider.dart';

import 'core/point.dart';
import 'data/models/local_history.dart';
import 'data/models/chart_cache.dart'; // ⬅️ Añadido
import 'package:lumina/domain/entities/asset_type.dart'; // ✅ CORRECTO

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  // Registro de adaptadores Hive
  Hive.registerAdapter(InvestmentAdapter());
  Hive.registerAdapter(InvestmentOperationAdapter());
  Hive.registerAdapter(PointAdapter());
  Hive.registerAdapter(LocalHistoryAdapter());
  Hive.registerAdapter(ChartCacheAdapter()); // ⬅️ Nuevo adaptador registrado
  Hive.registerAdapter(OperationTypeAdapter());
  Hive.registerAdapter(AssetTypeAdapter());

  final investmentRepository = InvestmentRepositoryImpl();
  await investmentRepository.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AssetListProvider()),
        ChangeNotifierProvider(create: (_) => InvestmentModel(investmentRepository)),
        ChangeNotifierProvider(create: (_) => ChartValueProvider()),
      ],
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
