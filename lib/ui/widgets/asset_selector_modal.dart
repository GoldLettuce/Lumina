// lib/ui/widgets/asset_selector_modal.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../providers/asset_list_provider.dart';
import '../../domain/entities/asset_type.dart'; // AÑADIR ESTO

class AssetSelectorModal extends StatefulWidget {
  final AssetType type; // CAMBIAR String → AssetType

  const AssetSelectorModal({super.key, required this.type});
  @override
  State<AssetSelectorModal> createState() => _AssetSelectorModalState();
}

class _AssetSelectorModalState extends State<AssetSelectorModal> {
  late AssetListProvider _assetProvider;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Cargar la lista de símbolos la primera vez que se muestre el modal
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _assetProvider = context.read<AssetListProvider>();
      if (!_assetProvider.isLoading && _assetProvider.filteredSymbols.isEmpty) {
        _assetProvider.loadAllSymbols();
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
    final loc = AppLocalizations.of(context);

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
              // Título
              Container(
                height: 48,
                alignment: Alignment.center,
                child: Text(
                  loc?.selectSymbol ?? 'Select a symbol',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Campo de búsqueda
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none
              ),
              onChanged: (value) {
                _assetProvider.filter(value);
              },
            ),
              const SizedBox(height: 12),

              // Lista scrollable
              Expanded(
                child: Consumer<AssetListProvider>(
                  builder: (context, prov, _) {
                    if (prov.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (prov.error != null) {
                      return Center(child: Text(prov.error!));
                    } else if (prov.filteredSymbols.isEmpty) {
                      // Texto literal en lugar de loc?.noSymbolsFound
                      return Center(
                        child: Text('No symbols found'),
                      );
                    }

                    return ListView.separated(
                      itemCount: prov.filteredSymbols.length,
                      separatorBuilder: (_, __) =>
                          Divider(color: Colors.grey.shade300),
                      itemBuilder: (context, index) {
                        final symbol = prov.filteredSymbols[index];
                        return ListTile(
                          title: Text(
                            symbol,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          onTap: () {
                            Navigator.of(context).pop(symbol);
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
