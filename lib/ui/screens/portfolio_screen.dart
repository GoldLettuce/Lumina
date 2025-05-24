import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../domain/entities/investment.dart';
import '../widgets/add_investment_dialog.dart';
import '../../data/models/investment_model.dart';

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
    final investments = context.watch<InvestmentModel>().investments;

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
