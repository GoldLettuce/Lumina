// lib/ui/widgets/asset_selector_modal.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import 'package:lumina/ui/providers/asset_list_provider.dart';
import '../../domain/entities/asset_type.dart';

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
  Debouncer _debouncer = Debouncer(delay: Duration(milliseconds: 500));

  @override
  void initState() {
    super.initState();
    _setupScrollListener();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AssetListProvider>();
      if (!provider.isLoading && provider.filteredSymbols.isEmpty) {
        provider.loadAllSymbols();
      }
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
              const SizedBox(height: 4),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.search, size: 20, color: Colors.grey),
                  border: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueAccent),
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
                    
                    return ListView.separated(
                      controller: _scrollController,
                      itemCount: prov.filteredSymbols.length + (prov.isLoadingMore ? 1 : 0),
                      separatorBuilder:
                          (_, __) => Divider(color: Colors.grey.shade300),
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
                        return ListTile(
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                coin.symbol,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                coin.name,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
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
