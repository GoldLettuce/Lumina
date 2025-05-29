import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:lumina/core/chart_range.dart';
import 'package:lumina/data/models/investment.dart';
import 'package:lumina/data/models/investment_model.dart';
import 'package:lumina/domain/repositories/history_repository.dart';
import 'package:lumina/domain/repositories/price_repository.dart';
import 'package:lumina/ui/providers/chart_value_provider.dart';

import '../../l10n/app_localizations.dart';
import 'asset_selector_modal.dart';
import 'coingecko_asset_selector_modal.dart';

class AddInvestmentDialog extends StatefulWidget {
  const AddInvestmentDialog({super.key});

  @override
  State<AddInvestmentDialog> createState() => _AddInvestmentDialogState();
}

class _AddInvestmentDialogState extends State<AddInvestmentDialog> {
  final _formKey = GlobalKey<FormState>();

  String? _type; // crypto, stock, etf, commodity
  bool _isBuy = true;
  String? _symbol;
  String? _idCoinGecko;
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  DateTime? _selectedDate = DateTime.now();

  bool _formSubmitted = false;

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  /* ─────────── helpers ─────────── */

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(2000),
      lastDate: now,
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _selectSymbol() async {
    if (_type == null) return;

    if (_type == 'crypto') {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => CoinGeckoAssetSelectorModal(
          onSelect: (asset) {
            setState(() {
              _symbol = asset.symbol.toUpperCase(); // BTC
              _idCoinGecko = asset.id;              // bitcoin
            });
          },
        ),
      );
    } else {
      final selected = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (context) => AssetSelectorModal(type: _type!),
      );
      if (selected != null) setState(() => _symbol = selected);
    }
  }

  InputDecoration _input(String lbl) => InputDecoration(
    labelText: lbl,
    enabledBorder:
    const UnderlineInputBorder(borderSide: BorderSide(color: Colors.black26)),
    focusedBorder:
    const UnderlineInputBorder(borderSide: BorderSide(color: Colors.black87)),
  );

  /* ─────────── submit ─────────── */

  Future<void> _submit() async {
    setState(() => _formSubmitted = true);

    /* Validaciones */
    if (!_formKey.currentState!.validate()) return;
    if (_type == 'crypto' && _idCoinGecko == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes seleccionar una criptomoneda válida.')),
      );
      return;
    }

    final qty   = double.parse(_quantityController.text.trim());
    final price = double.parse(_priceController.text.trim());

    final op = InvestmentOperation(
      quantity: _isBuy ? qty : -qty,
      price: price,
      date: _selectedDate!,
    );

    final inv = Investment(
      idCoinGecko:
      _idCoinGecko ?? 'manual-${DateTime.now().millisecondsSinceEpoch}',
      symbol: _symbol!,
      name: _symbol!,
      operations: [op],
    );

    final invModel  = context.read<InvestmentModel>();
    final priceRepo = context.read<PriceRepository>();
    final histRepo  = context.read<HistoryRepository>();
    final chartProv = context.read<ChartValueProvider>();

    try {
      await invModel.addInvestment(inv);

      final pts = await priceRepo.getHistory(
        symbol: inv.idCoinGecko, // ✅ CORREGIDO: usar idCoinGecko
        type: _type!,
        range: ChartRange.all,
      );

      await histRepo.mergeAndSaveHistory(
        symbol: inv.symbol,
        range: 'all',
        newPoints: pts,
      );

      chartProv.setVisibleIds(
        invModel.investments.map((e) => e.idCoinGecko).toSet(),
      );
      await chartProv.loadHistory(chartProv.range, invModel.investments);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e')),
      );
    } finally {
      if (mounted) Navigator.of(context).pop();
    }
  }

  /* ─────────── build ─────────── */

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final dateTxt = MaterialLocalizations.of(context).formatMediumDate(_selectedDate!);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            autovalidateMode:
            _formSubmitted ? AutovalidateMode.always : AutovalidateMode.disabled,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(loc?.newOperation ?? 'Nueva operación',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 20),

                /* tipo */
                DropdownButtonFormField<String>(
                  decoration: _input(loc?.assetType ?? 'Tipo de activo'),
                  items: ['crypto', 'stock', 'etf', 'commodity']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e.toUpperCase())))
                      .toList(),
                  value: _type,
                  onChanged: (v) => setState(() {
                    _type = v;
                    _symbol = null;
                    _idCoinGecko = null;
                  }),
                  validator: (v) => v == null ? 'Seleccione un tipo' : null,
                ),
                const SizedBox(height: 16),

                /* símbolo */
                GestureDetector(
                  onTap: _selectSymbol,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: (_symbol == null && _formSubmitted)
                              ? Theme.of(context).colorScheme.error
                              : Colors.black26,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _symbol ?? 'Selecciona un símbolo',
                          style: TextStyle(
                            color: _symbol == null ? Colors.black38 : Colors.black87,
                            fontSize: 16,
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                /* fecha */
                InkWell(
                  onTap: _pickDate,
                  child: Row(
                    children: [
                      Text('${loc?.date ?? 'Fecha'}: ',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(dateTxt),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                /* cantidad */
                TextFormField(
                  controller: _quantityController,
                  keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
                  decoration: _input(loc?.quantity ?? 'Cantidad'),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Campo obligatorio';
                    final n = double.tryParse(v);
                    if (n == null || n <= 0) return 'Cantidad inválida';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                /* precio */
                TextFormField(
                  controller: _priceController,
                  keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
                  decoration: _input(loc?.unitPrice ?? 'Precio unitario (€)'),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Campo obligatorio';
                    final n = double.tryParse(v);
                    if (n == null || n <= 0) return 'Precio inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(loc?.cancel ?? 'Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _submit,
                        child: Text(loc?.save ?? 'Guardar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
