import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';

import 'package:lumina/ui/providers/theme_mode_provider.dart';
import 'package:lumina/core/theme.dart';

/// ⚠️ Versión provisional combinando dos SVG en darkMono.
/// Se ha solicitado aprobación a CoinGecko.
/// Si no la conceden, revertir a los logos completos oficiales.
class CoinGeckoAttribution extends StatelessWidget {
  const CoinGeckoAttribution({super.key});

  @override
  Widget build(BuildContext context) {
    final mode = context.watch<ThemeModeProvider>().mode;

    /// Selecciona el logo (único SVG o combinación) según el modo elegido
    final Widget logo = switch (mode) {
      // ──────────────────── MODO LIGHT MONO ────────────────────
      AppThemeMode.lightMono => SvgPicture.asset(
        'assets/images/coingecko_mono.svg',
        height: 24,
      ),

      // ──────────────────── MODO DARK MONO ─────────────────────
      // Símbolo gris + texto blanco (provisional)
      AppThemeMode.darkMono => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            'assets/images/coingecko_mono_logo.svg', // símbolo gris
            height: 20,
          ),
          const SizedBox(width: 8),
          SvgPicture.asset(
            'assets/images/white_text_only.svg', // letras blancas
            height: 16,
          ),
        ],
      ),

      // ──────────────────── MODO LIGHT (color) ─────────────────
      AppThemeMode.light => SvgPicture.asset(
        'assets/images/coingecko_full_black.svg',
        height: 24,
      ),

      // ──────────────────── MODO DARK (color) ──────────────────
      AppThemeMode.dark => SvgPicture.asset(
        'assets/images/coingecko_full_white.svg',
        height: 24,
      ),

      // ──────────────────── MODO SYSTEM ────────────────────────
      AppThemeMode.system => SvgPicture.asset(
        Theme.of(context).brightness == Brightness.dark
            ? 'assets/images/coingecko_full_white.svg'
            : 'assets/images/coingecko_full_black.svg',
        height: 24,
      ),
    };

    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse('https://www.coingecko.com');
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.only(right: 16, top: 16, bottom: 16),
        alignment: Alignment.centerRight,
        child: logo,
      ),
    );
  }
}
