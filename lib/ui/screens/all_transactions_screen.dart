import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'asset_detail_screen.dart';
import '../../domain/entities/investment.dart';
import '../providers/investment_provider.dart';
import '../../core/number_formatting.dart';
import '../providers/currency_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../core/colors.dart';

class AllTransactionsScreen extends StatelessWidget {
  const AllTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc?.allTransactions ?? 'All transactions'),
      ),
      body: const _AllTransactionsList(),
    );
  }
}

class _AllTransactionsList extends StatelessWidget {
  const _AllTransactionsList();

  @override
  Widget build(BuildContext context) {
    final invProv = context.watch<InvestmentProvider>();
    final currencyProv = context.watch<CurrencyProvider>();
    final theme = Theme.of(context);

    // Aplanar operaciones de todas las inversiones
    final items = <_OpItem>[];
    for (final inv in invProv.investments) {
      for (final op in inv.operations) {
        items.add(_OpItem(inv: inv, op: op));
      }
    }

    // Ordenar por fecha descendente
    items.sort((a, b) => b.op.date.compareTo(a.op.date));

    if (items.isEmpty) {
      return Center(
        child: Text(
          'No transactions',
          style: theme.textTheme.bodyLarge,
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 8, thickness: 0),
      itemBuilder: (context, i) {
        final item = items[i];
        final isBuy = item.op.type == OperationType.buy;

        // Cantidad
        final qtyStr = formatQuantity(item.op.quantity, context, maxDecimals: 8);

        // Importe en moneda local
        final totalUsd = item.op.price * item.op.quantity;
        final totalLocal = totalUsd * currencyProv.exchangeRate;
        final amountStr = formatMoney(totalLocal, currencyProv.currency, context);

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          leading: Icon(
            isBuy ? Icons.arrow_upward : Icons.arrow_downward,
            color: isBuy 
                ? AppColors.textPositive(context)
                : AppColors.textNegative(context),
          ),
          title: Text(
            '${isBuy ? "Buy" : "Sell"} of $qtyStr ${item.inv.symbol.toUpperCase()}',
            style: theme.textTheme.bodyLarge,
          ),
          subtitle: Text(
            _fmtDate(item.op.date, context),
            style: theme.textTheme.bodyMedium,
          ),
          trailing: Text(
            amountStr,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: isBuy 
                  ? AppColors.textPositive(context)
                  : AppColors.textNegative(context),
            ),
            textAlign: TextAlign.right,
          ),
          onTap: () {
            // Ir al detalle del asset
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AssetDetailScreen(asset: item.inv)),
            );
          },
        );
      },
    );
  }

  String _fmtDate(DateTime d, BuildContext context) {
    return DateFormat(
      'd MMM y',
      Localizations.localeOf(context).toString(),
    ).format(d);
  }
}

class _OpItem {
  final Investment inv;
  final InvestmentOperation op;
  
  _OpItem({required this.inv, required this.op});
}
