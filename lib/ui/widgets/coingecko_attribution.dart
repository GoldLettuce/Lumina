import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:lumina/ui/providers/theme_mode_provider.dart';
import 'package:lumina/core/theme.dart';

class CoinGeckoAttribution extends StatelessWidget {
  const CoinGeckoAttribution({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeMode = context.watch<ThemeModeProvider>().mode;
    final isMono = themeMode == AppThemeMode.lightMono || themeMode == AppThemeMode.darkMono;

    String assetPath;
    if (isMono) {
      assetPath = isDark
          ? 'assets/images/coingecko_mono_white.svg'
          : 'assets/images/coingecko_mono_black.svg';
    } else {
      assetPath = isDark
          ? 'assets/images/coingecko_full_black.svg'
          : 'assets/images/coingecko_full_white.svg';
    }

    return GestureDetector(
      onTap: () async {
        final url = Uri.parse('https://www.coingecko.com');
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: SvgPicture.asset(
          assetPath,
          height: 24,
          semanticsLabel: 'CoinGecko logo',
        ),
      ),
    );
  }
} 