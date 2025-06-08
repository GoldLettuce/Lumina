import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lumina/domain/entities/investment.dart';

class AssetDetailScreen extends StatelessWidget {
  final Investment asset;

  const AssetDetailScreen({super.key, required this.asset});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormatter = NumberFormat.simpleCurrency(locale: 'en_US');

    return Scaffold(
      appBar: AppBar(
        title: Text(asset.symbol),
        centerTitle: true,
      ),
      body: asset.operations.isEmpty
          ? Center(
        child: Text(
          'No hay operaciones registradas.',
          style: theme.textTheme.bodyLarge,
        ),
      )
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        separatorBuilder: (_, __) => const Divider(),
        itemCount: asset.operations.length,
        itemBuilder: (context, index) {
          final op = asset.operations[index];
          final isBuy = op.type == OperationType.buy; // ✅ CORREGIDO
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
            trailing: Text(
              currencyFormatter.format(op.price),
              style: theme.textTheme.bodyMedium!.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        },
      ),
    );
  }
}
