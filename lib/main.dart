import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'ui/screens/portfolio_screen.dart';
import 'ui/providers/app_initialization_provider.dart';
import 'ui/providers/fx_notifier.dart';
import 'ui/providers/spot_price_provider.dart';
import 'package:lumina/provider_setup.dart';
import 'ui/providers/locale_provider.dart';
import 'ui/providers/theme_mode_provider.dart';
import 'ui/providers/settings_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  assert(() {
    debugProfileBuildsEnabled = true;
    return true;
  }());

  // Eliminado: HiveService se inicializa en AppInitializationProvider

  runApp(const PortfolioApp());
}

class PortfolioApp extends StatelessWidget {
  const PortfolioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: buildAppProviders(),
      child: Builder(
        builder: (context) {
          final locale = context.watch<LocaleProvider>().locale;
          final themeModeProvider = context.watch<ThemeModeProvider>();
          final themeMode = themeModeProvider.mode;

          return MaterialApp(
            title: 'Lumina',
            debugShowCheckedModeBanner: false,
            theme:
                themeMode == AppThemeMode.lightMono
                    ? AppTheme.lightMonoTheme
                    : AppTheme.lightTheme,
            darkTheme:
                themeMode == AppThemeMode.darkMono
                    ? AppTheme.darkMonoTheme
                    : AppTheme.darkTheme,
            themeMode: themeModeProvider.flutterThemeMode,
            themeAnimationDuration: Duration.zero,
            themeAnimationCurve: Curves.linear,
            locale: locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en'), Locale('es')],
            home: const PortfolioGate(),
          );
        },
      ),
    );
  }
}

class PortfolioGate extends StatefulWidget {
  const PortfolioGate({super.key});

  @override
  State<PortfolioGate> createState() => _PortfolioGateState();
}

class _PortfolioGateState extends State<PortfolioGate> {
  bool _hasInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitialized) {
      _hasInitialized = true;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        final appInit = context.read<AppInitializationProvider>();
        if (!appInit.isAppReady) {
          appInit.initialize();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appInit = context.watch<AppInitializationProvider>();
    if (!appInit.isAppReady) return const SkeletonView();

    final fxNotifier = context.read<FxNotifier>();
    final fxValue = appInit.preloadedData['fx'];
    if (fxValue != null) {
      fxNotifier.setFx(fxValue);
    }

    // Cargar precios desde Hive cache
    final spotPriceProvider = context.read<SpotPriceProvider>();
    final themeModeProvider = context.read<ThemeModeProvider>();
    final settingsProvider = context.read<SettingsProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppInitializationProvider.loadFromHive(spotPriceProvider);
      AppInitializationProvider.initializeThemeMode(themeModeProvider);
      settingsProvider.loadFromHive();
    });

    return const PortfolioScreen();
  }
}

class SkeletonView extends StatelessWidget {
  const SkeletonView({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              t.loading,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
