import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';

class AssetSelectorModal extends StatefulWidget {
  final String type;

  const AssetSelectorModal({
    super.key,
    required this.type,
  });

  @override
  State<AssetSelectorModal> createState() => _AssetSelectorModalState();
}

class _AssetSelectorModalState extends State<AssetSelectorModal> {
  String query = '';

  late final List<String> _symbols;

  final Map<String, List<String>> _symbolsByType = {
    'crypto': ['BTC', 'ETH', 'ADA', 'SOL', 'DOT'],
    'stock': ['AAPL', 'TSLA', 'MSFT', 'GOOG', 'AMZN'],
    'etf': ['SPY', 'IVV', 'VOO', 'QQQ', 'VTI'],
    'commodity': ['GOLD', 'SILVER', 'OIL', 'COPPER', 'PLATINUM'],
  };

  @override
  void initState() {
    super.initState();
    _symbols = _symbolsByType[widget.type] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _symbols.where((s) => s.toLowerCase().contains(query.toLowerCase())).toList();

    return FractionallySizedBox(
      heightFactor: 0.45,
      child: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black26),
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)?.searchAsset ?? 'Buscar activo',
                    border: InputBorder.none,
                    prefixIcon: const Icon(Icons.search),
                    contentPadding: const EdgeInsets.only(top: 12),
                  ),
                  onChanged: (value) => setState(() => query = value),
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => Divider(color: Colors.grey.shade300, height: 1),
                  itemBuilder: (_, index) {
                    final symbol = filtered[index];
                    return ListTile(
                      title: Text(
                        symbol,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      onTap: () => Navigator.of(context).pop(symbol),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
