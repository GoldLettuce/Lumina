// lib/ui/widgets/asset_selector_modal.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import 'package:lumina/ui/providers/asset_list_provider.dart';
import '../../domain/entities/asset_type.dart';

class AssetSelectorModal extends StatefulWidget {
  final AssetType type;
  const AssetSelectorModal({super.key, required this.type});

  @override
  State<AssetSelectorModal> createState() => _AssetSelectorModalState();
}

class _AssetSelectorModalState extends State<AssetSelectorModal> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AssetListProvider>();
      if (!provider.isLoading && provider.filteredSymbols.isEmpty) {
        provider.loadAllSymbols();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    if (widget.type != AssetType.crypto) {
      return const SizedBox.shrink();
    }

    return FractionallySizedBox(
      heightFactor: 0.65,
      child: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              SizedBox(
                height: 48,
                child: Center(
                  child: Text(
                    loc.selectSymbol,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: loc.searchAssetPlaceholder,
                  border: const OutlineInputBorder(),
                ),
                onChanged:
                    (value) => context.read<AssetListProvider>().filter(value),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Consumer<AssetListProvider>(
                  builder: (context, prov, _) {
                    if (prov.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (prov.error != null) {
                      return Center(child: Text(loc.loadSymbolsError));
                    }
                    if (prov.filteredSymbols.isEmpty) {
                      return Center(child: Text(loc.noSymbolsFound));
                    }
                    return ListView.separated(
                      itemCount: prov.filteredSymbols.length,
                      separatorBuilder:
                          (_, __) => Divider(color: Colors.grey.shade300),
                      itemBuilder: (context, index) {
                        final coin = prov.filteredSymbols[index];
                        return ListTile(
                          title: Text(
                            '${coin.symbol} – ${coin.name}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          onTap: () {
                            // Devuelve un Map<String,String> para no romper la lógica existente
                            Navigator.of(context).pop(<String, String>{
                              'id': coin.id,
                              'symbol': coin.symbol,
                              'name': coin.name,
                            });
                          },
                        );
                      },
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
