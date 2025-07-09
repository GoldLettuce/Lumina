import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/init_hive.dart';
import 'data/repositories_impl/investment_repository_impl.dart';
import 'ui/providers/asset_list_provider.dart';
import 'ui/providers/investment_provider.dart';
import 'ui/providers/chart_value_provider.dart';
import 'ui/providers/settings_provider.dart';
import 'ui/providers/locale_provider.dart';
import 'ui/providers/currency_provider.dart';
import 'ui/screens/splash_screen.dart';
import 'main.dart' show PortfolioApp;   // reutilizamos tu widget raíz real

class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  InvestmentRepositoryImpl? _repo;           // ← será != null cuando Hive esté listo

  @override
  void initState() {
    super.initState();
    _init();                                 // arranca tras el primer frame
  }

  Future<void> _init() async {
    final repo = await initHive();           //   ① abre Hive
    if (!mounted) return;                    //   ② evita setState ↻ si se cerró
    setState(() => _repo = repo);            //   ③ re-pinta → MultiProvider
  }

  @override
  Widget build(BuildContext context) {
    // Hasta que Hive no esté listo, mostramos la Splash ultra-ligera
    if (_repo == null) return const SplashScreen();

    // Una vez listo, construimos todo el árbol habitual
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AssetListProvider()),
        ChangeNotifierProvider(create: (_) => InvestmentProvider(_repo!)),
        ChangeNotifierProvider(create: (_) => ChartValueProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => CurrencyProvider()),
      ],
      child: const PortfolioApp(),
    );
  }
}
