import 'package:flutter/material.dart';
import 'package:provider/provider.dart';          // sigue siendo necesario
import 'app_bootstrap.dart';                      // ⬅️  NUEVO

import 'core/theme.dart';
import 'l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'ui/providers/locale_provider.dart';
import 'ui/screens/portfolio_screen.dart';
import 'core/hive_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.initFlutterOnly();
  runApp(const AppBootstrap());                  // ⬅️  único widget de arranque
}

/// ---------- Tu widget raíz real (sin cambios) ----------
class PortfolioApp extends StatelessWidget {
  const PortfolioApp({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>().locale;

    return MaterialApp(
      title: 'Mi Portafolio',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('es')],
      home: const PortfolioScreen(),
    );
  }
}
