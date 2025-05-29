import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:lumina/data/models/asset_history_model.dart';
import 'package:lumina/domain/entities/asset_history.dart';
import 'package:lumina/data/repositories_impl/history_repository_impl.dart';
import 'package:lumina/data/datasources/coingecko_history_service.dart';

class DebugHistoryScreen extends StatefulWidget {
  const DebugHistoryScreen({super.key});

  @override
  State<DebugHistoryScreen> createState() => _DebugHistoryScreenState();
}

class _DebugHistoryScreenState extends State<DebugHistoryScreen> {
  final _repo = HistoryRepositoryImpl(CoinGeckoHistoryService());
  final _box = Hive.box<AssetHistoryModel>('asset_histories');
  late List<String> _symbols;

  @override
  void initState() {
    super.initState();
    _symbols = _box.keys.cast<String>().toList();
  }

  Future<void> _compact(String symbol) async {
    await _repo.compactHistoryIfNeeded(symbol);
    setState(() {});
  }

  AssetHistory _getEntity(String symbol) =>
      _box.get(symbol)!.toEntity();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Depuración de históricos')),
      body: ListView.builder(
        itemCount: _symbols.length,
        itemBuilder: (context, index) {
          final symbol = _symbols[index];
          final history = _getEntity(symbol);

          return Card(
            margin: const EdgeInsets.all(8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(symbol, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...['1D', '1W', '1M', '1Y', 'ALL'].map((r) {
                    final count = history.timeRanges[r]?.length ?? 0;
                    return Text('$r: $count puntos');
                  }),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => _compact(symbol),
                    child: const Text('Compactar manualmente'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
