import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CoinGeckoAsset {
  final String id;
  final String symbol;
  final String name;

  CoinGeckoAsset({
    required this.id,
    required this.symbol,
    required this.name,
  });

  factory CoinGeckoAsset.fromJson(Map<String, dynamic> json) {
    return CoinGeckoAsset(
      id: json['id'],
      symbol: json['symbol'],
      name: json['name'],
    );
  }
}

class CoinGeckoAssetSelectorModal extends StatefulWidget {
  final void Function(CoinGeckoAsset) onSelect;

  const CoinGeckoAssetSelectorModal({super.key, required this.onSelect});

  @override
  State<CoinGeckoAssetSelectorModal> createState() =>
      _CoinGeckoAssetSelectorModalState();
}

class _CoinGeckoAssetSelectorModalState
    extends State<CoinGeckoAssetSelectorModal> {
  List<CoinGeckoAsset> _allAssets = [];
  List<CoinGeckoAsset> _filteredAssets = [];
  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _fetchTopAssets();
  }

  Future<void> _fetchTopAssets() async {
    try {
      final uri = Uri.parse(
          'https://api.coingecko.com/api/v3/coins/markets?vs_currency=eur&order=market_cap_desc&per_page=250&page=1');
      final response = await http.get(uri);
      final List<dynamic> data = json.decode(response.body);

      final assets = data
          .map((e) => CoinGeckoAsset.fromJson(e))
          .where((a) => a.name.isNotEmpty && a.symbol.isNotEmpty)
          .toList();

      setState(() {
        _allAssets = assets;
        _filteredAssets = assets;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error loading assets: $e');
      setState(() {
        _loading = false;
      });
    }
  }

  void _filter(String query) {
    setState(() {
      _query = query;
      _filteredAssets = _allAssets
          .where((a) =>
      a.name.toLowerCase().contains(query.toLowerCase()) ||
          a.symbol.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding:
        EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SizedBox(
          height: 450,
          child: Column(
            children: [
              const SizedBox(height: 16),
              const Text(
                'Seleccionar activo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  onChanged: _filter,
                  decoration: const InputDecoration(
                    hintText: 'Buscar por nombre o símbolo...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredAssets.isEmpty
                    ? const Center(child: Text('No se encontraron activos'))
                    : ListView.builder(
                  itemCount: _filteredAssets.length,
                  itemBuilder: (_, i) {
                    final asset = _filteredAssets[i];
                    return ListTile(
                      title: Text(asset.name),
                      subtitle: Text(asset.symbol.toUpperCase()),
                      onTap: () {
                        widget.onSelect(asset);
                        Navigator.of(context).pop();
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
