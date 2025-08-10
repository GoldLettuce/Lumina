// lib/ui/widgets/asset_selector_modal.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import 'package:lumina/ui/providers/asset_list_provider.dart';
import '../../domain/entities/asset_type.dart';
import 'package:lumina/ui/providers/settings_provider.dart';

class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({required this.delay});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void dispose() {
    _timer?.cancel();
  }
}

class AssetSelectorModal extends StatefulWidget {
  final AssetType type;
  const AssetSelectorModal({super.key, required this.type});

  @override
  State<AssetSelectorModal> createState() => _AssetSelectorModalState();
}

class _AssetSelectorModalState extends State<AssetSelectorModal> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Debouncer _debouncer = Debouncer(delay: Duration(milliseconds: 500));

  @override
  void initState() {
    super.initState();
    _searchController.clear();
    _setupScrollListener();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AssetListProvider>();
      if (!provider.isLoading && provider.filteredSymbols.isEmpty) {
        provider.loadAllSymbols();
      }
      provider.resetSearch();
    });
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= 
          _scrollController.position.maxScrollExtent - 100) {
        final provider = context.read<AssetListProvider>();
        if (provider.isFiltering) return;
        if (provider.hasMorePages && !provider.isLoadingMore) {
          provider.loadNextPage();
        }
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debouncer.dispose();
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
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
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
              const SizedBox(height: 4),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.search, size: 20, color: Theme.of(context).iconTheme.color),
                  border: UnderlineInputBorder(
                    borderSide: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                  ),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                ),
                style: TextStyle(fontSize: 14),
                onChanged: (value) {
                  _debouncer.run(() {
                    context.read<AssetListProvider>().searchRemote(value);
                  });
                },
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
                    
                    // Obtener la preferencia de iconos una sola vez fuera del itemBuilder
                    final showIcons = context.select<SettingsProvider, bool>((s) => s.showAssetIcons);
                    
                    return ListView.separated(
                      controller: _scrollController,
                      itemCount: prov.filteredSymbols.length + (prov.isLoadingMore ? 1 : 0),
                      separatorBuilder: (_, __) => Divider(
                        color: Theme.of(context).dividerColor,
                        height: 1,
                        thickness: 0.5,
                      ),
                      itemBuilder: (context, index) {
                        // Mostrar loading indicator al final si está cargando más
                        if (index == prov.filteredSymbols.length && prov.isLoadingMore) {
                          return const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        
                        final coin = prov.filteredSymbols[index];
                        
                        return InkWell(
                          onTap: () {
                            // Devuelve un Map<String,String> para no romper la lógica existente
                            Navigator.of(context).pop(<String, String>{
                              'id': coin.id,
                              'symbol': coin.symbol,
                              'name': coin.name,
                              'imageUrl': coin.imageUrl ?? '',
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            child: Row(
                              children: [
                                // Icono del activo (opcional)
                                if (showIcons && coin.imageUrl != null && coin.imageUrl!.isNotEmpty) ...[
                                  CircleAvatar(
                                    backgroundImage: NetworkImage(coin.imageUrl!),
                                    backgroundColor: Colors.transparent,
                                    radius: 14,
                                  ),
                                  const SizedBox(width: 12),
                                ],
                                // Contenido principal
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Símbolo (ticker) - mantener tamaño y peso actual
                                      Text(
                                        coin.symbol,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      // Nombre completo - reducir tamaño y opacidad
                                      Text(
                                        coin.name,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Theme.of(context).brightness == Brightness.light
                                              ? Colors.grey[600]
                                              : Colors.grey[400],
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                // Icono de flecha para indicar que es seleccionable
                                Icon(
                                  Icons.chevron_right,
                                  size: 20,
                                  color: Theme.of(context).iconTheme.color?.withOpacity(0.6),
                                ),
                              ],
                            ),
                          ),
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
