import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../domain/entities/investment.dart';
import '../widgets/add_investment_dialog.dart';
import '../../data/models/investment_model.dart';

class PortfolioSummaryMinimal extends StatelessWidget {
  const PortfolioSummaryMinimal({super.key});

  /// Mide el ancho de un texto con un estilo dado.
  double _measureTextWidth(String text, TextStyle style, BuildContext context) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    return tp.size.width;
  }

  /// Mide la línea base (baseline) de un texto con un estilo dado.
  double _measureBaseline(String text, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    final lm = tp.computeLineMetrics();
    return lm.first.baseline;
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<InvestmentModel>();
    final valorActual = model.valorActual;
    final rentabilidad = model.rentabilidadGeneral;
    final isPositivo = rentabilidad >= 0;

    final signo = isPositivo ? "+" : "-";
    final colorRent = isPositivo ? Colors.green : Colors.red;

    final valorText = '€${valorActual.toStringAsFixed(2)}';
    final percentText = '$signo${rentabilidad.abs().toStringAsFixed(2)}%';

    const valorStyle = TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      letterSpacing: -1.5,
      color: Colors.black87,
    );
    final percentStyle = TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: colorRent,
    );
    const spacing = 4.0;

    return SizedBox(
      height: 42,
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Medimos anchos y baselines:
          final valorWidth = _measureTextWidth(valorText, valorStyle, context);
          final valorBaseline = _measureBaseline(valorText, valorStyle);
          final percentBaseline = _measureBaseline(percentText, percentStyle);

          // Centro horizontal de la pantalla:
          final centerX = constraints.maxWidth / 2;

          // Posición left del valor para centrarlo:
          final valorLeft = centerX - valorWidth / 2;

          // Posición top del porcentaje para alinear baselines:
          final percentTop = valorBaseline - percentBaseline;

          return Stack(
            children: [
              // Texto del valor, centrado:
              Positioned(
                left: valorLeft,
                top: 0,
                child: Text(valorText, style: valorStyle),
              ),
              // Texto del porcentaje, pegado a la derecha y alineado por baseline:
              Positioned(
                left: valorLeft + valorWidth + spacing,
                top: percentTop,
                child: Text(percentText, style: percentStyle),
              ),
            ],
          );
        },
      ),
    );
  }
}

class PortfolioScreen extends StatelessWidget {
  const PortfolioScreen({super.key});

  Future<void> _openAddInvestmentDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (_) => const AddInvestmentDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final model = context.watch<InvestmentModel>();
    final investments = model.investments;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.appTitle ?? ''),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddInvestmentDialog(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const PortfolioSummaryMinimal(),
            Container(
              height: 150,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.5),
                    AppColors.primary.withOpacity(0.1),
                  ],
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  AppLocalizations.of(context)?.graphPlaceholder ?? '',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: investments.isEmpty
                  ? Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Text(
                    AppLocalizations.of(context)?.emptyPortfolioMessage ??
                        'No tienes inversiones aún.\n¡Comienza añadiendo la primera!',
                    style: theme.textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                ),
              )
                  : ListView.separated(
                itemCount: investments.length,
                separatorBuilder: (_, __) =>
                    Divider(color: AppColors.border),
                itemBuilder: (context, index) {
                  final asset = investments[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      asset.symbol,
                      style: theme.textTheme.bodyLarge!
                          .copyWith(fontWeight: FontWeight.bold),
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
                          style: theme.textTheme.bodyLarge!
                              .copyWith(fontWeight: FontWeight.w600),
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
