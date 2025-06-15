// lib/ui/widgets/asset_selector_modal.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/asset_type.dart';
import '../../l10n/app_localizations.dart';
import '../../services/portfolio_sync_service.dart';
import '../providers/asset_list_provider.dart';
import 'symbol_list_item.dart';
import '../../core/known_markets.dart';
import '../providers/settings_provider.dart'; // ✅ vuelve a añadirla

class AssetSelectorModal extends StatefulWidget {
  final AssetType type;
  const AssetSelectorModal({super.key, required this.type});

  @override
  State<AssetSelectorModal> createState() => _AssetSelectorModalState();
}

class _AssetSelectorModalState extends State<AssetSelectorModal> {
  final TextEditingController _searchController = TextEditingController();

  bool _usesRemoteSearch(AssetType type) => type != AssetType.crypto;

  @override
  void initState() {
    super.initState();
    if (!_usesRemoteSearch(widget.type)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadSymbols());
    }
  }

  Future<void> _loadSymbols() async {
    final provider = Provider.of<AssetListProvider>(context, listen: false);
    provider.clear();
    try {
      final service = PortfolioSyncService('');

      final symbols = await service.fetchCryptoSymbols();

      // Mapea crypto (sin marketName)
      final mapped = symbols.map((e) => {
        'symbol'     : e,
        'description': '',
        'mic'        : '',
        'marketName' : '',
      }).toList();

      provider.setSymbols(mapped);
    } catch (e) {
      provider.setError('Error al cargar símbolos: $e');
    }
  }

  void _handleSearch(String query) async {
    final provider = Provider.of<AssetListProvider>(context, listen: false);
    if (!_usesRemoteSearch(widget.type)) {
      provider.filter(query);
      return;
    }

    if (query.length < 2) {
      provider.setFilteredSymbols([]);
      return;
    }

    provider.setLoading(true);
    try {
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      final apiKey = settings.apiKey;

      if (apiKey == null) {
        provider.setError('No se ha configurado la API key.');
        return;
      }

      final service = PortfolioSyncService(apiKey);
      final raw = await service.searchSymbols(query);

      final mapped = raw.map((e) {
        final micCode = e['mic'] ?? e['exchange'] ?? '';
        return {
          'symbol': e['symbol'] ?? '',
          'description': e['description'] ?? '',
          'mic': micCode,
          'marketName': kKnownMarkets[micCode.toUpperCase()] ?? 'Bolsa ($micCode)',
        };
      }).toList();

      provider.setSymbols(mapped);
    } catch (e) {
      provider.setError('Error en la búsqueda: $e');
    }

  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

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
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  border: InputBorder.none,
                  hintText: 'Buscar por símbolo o nombre',
                ),
                onChanged: _handleSearch,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Consumer<AssetListProvider>(
                  builder: (_, prov, __) {
                    if (prov.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (prov.error != null) {
                      return Center(child: Text(prov.error!));
                    }
                    final list = prov.filteredSymbols;
                    if (list.isEmpty) {
                      return const Center(child: Text('No se encontraron símbolos'));
                    }
                    return ListView.separated(
                      itemCount: list.length,
                      separatorBuilder: (_, __) => Divider(color: Colors.grey.shade300),
                      itemBuilder: (context, i) {
                        final item = list[i];
                        return SymbolListItem(
                          companyName: item['description']!.isNotEmpty
                              ? item['description']!
                              : item['symbol']!,
                          symbol: item['symbol']!,
                          marketName: item['marketName']!,
                          onTap: () => Navigator.of(context).pop(item['symbol']),
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
