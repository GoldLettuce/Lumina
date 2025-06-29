import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/currency_provider.dart';
import 'currency_selector_modal.dart';

class CurrencySelector extends StatelessWidget {
  const CurrencySelector({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CurrencyProvider>();

    final selectedName = provider.currencies[provider.currency] ?? provider.currency;

    return ListTile(
      title: const Text('Moneda base'),
      subtitle: Text('${provider.currency} – $selectedName'),
      enabled: !provider.isLoading,
      onTap: provider.isLoading
          ? null
          : () async {
        final selected = await showModalBottomSheet<String>(
          context: context,
          builder: (_) => CurrencySelectorModal(
            currencies: provider.currencies,
            selected: provider.currency,
          ),
        );

        if (selected != null && selected != provider.currency) {
          provider.setCurrency(selected);
        }
      },
    );
  }
}
