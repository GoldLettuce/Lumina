// lib/ui/screens/asset_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:lumina/domain/entities/investment.dart';
import 'package:lumina/data/models/investment_model.dart';
import 'package:lumina/ui/widgets/add_investment_dialog.dart';

class AssetDetailScreen extends StatelessWidget {
  final Investment asset;

  const AssetDetailScreen({super.key, required this.asset});

  @override
  Widget build(BuildContext context) {
    // 1️⃣ Obtenemos el modelo y esperamos notificaciones
    final model = context.watch<InvestmentModel>();

    // 2️⃣ Buscamos el asset actualizado por su símbolo
    final currentAsset = model.investments
        .firstWhere((inv) => inv.symbol == asset.symbol);

    final theme = Theme.of(context);
    final currencyFormatter = NumberFormat.simpleCurrency(locale: 'en_US');

    return Scaffold(
      appBar: AppBar(
        title: Text(currentAsset.symbol),
        centerTitle: true,
      ),
      body: currentAsset.operations.isEmpty
          ? Center(
        child: Text(
          'No hay operaciones registradas.',
          style: theme.textTheme.bodyLarge,
        ),
      )
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        separatorBuilder: (_, __) => const Divider(),
        itemCount: currentAsset.operations.length,
        itemBuilder: (context, index) {
          final op = currentAsset.operations[index];
          final isBuy = op.type == OperationType.buy;
          final fecha = DateFormat('d MMM y – HH:mm').format(op.date);
          final color = isBuy ? Colors.green : Colors.red;

          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              isBuy ? Icons.arrow_upward : Icons.arrow_downward,
              color: color,
            ),
            title: Text(
              '${isBuy ? 'Compra' : 'Venta'} de ${op.quantity}',
              style: theme.textTheme.bodyLarge,
            ),
            subtitle: Text(fecha),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  currencyFormatter.format(op.price),
                  style: theme.textTheme.bodyMedium!
                      .copyWith(color: color, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () async {
                    final edited = await showDialog<InvestmentOperation>(
                      context: context,
                      builder: (_) => AddInvestmentDialog(
                        allowAdvancedAssets: false,
                        initialOperation: op,
                        initialSymbol: currentAsset.symbol,
                      ),
                    );
                    if (edited != null) {
                      await model.editOperation(currentAsset.symbol, edited);
                      // No es necesario setState aquí; el watch lo actualizará
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
