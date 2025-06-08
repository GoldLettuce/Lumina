// lib/ui/widgets/add_investment_dialog.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/investment.dart';
import '../../data/models/investment_model.dart';
import '../../l10n/app_localizations.dart';
import 'asset_selector_modal.dart';
import 'package:lumina/ui/providers/chart_value_provider.dart';
import 'package:lumina/data/repositories_impl/investment_repository_impl.dart';
import 'package:lumina/services/portfolio_sync_service.dart';

class AddInvestmentDialog extends StatefulWidget {
  const AddInvestmentDialog({super.key});

  @override
  State<AddInvestmentDialog> createState() => _AddInvestmentDialogState();
}

class _AddInvestmentDialogState extends State<AddInvestmentDialog> {
  final _formKey = GlobalKey<FormState>();

  String? _type;
  OperationType? _operationType; // ✅ nuevo campo
  String? _symbol;
  DateTime? _selectedDate = DateTime.now();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();

  bool _formSubmitted = false;
  bool _symbolTouched = false;
  bool _quantityTouched = false;
  bool _priceTouched = false;

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(2000),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectSymbol() async {
    if (_type == null) return;

    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => AssetSelectorModal(type: _type!),
    );

    if (selected != null) {
      setState(() {
        _symbol = selected;
        _symbolTouched = true;
      });
    }
  }

  Future<void> _submit() async {
    setState(() {
      _formSubmitted = true;
    });

    if (_formKey.currentState!.validate() && _type != null && _symbol != null && _selectedDate != null && _operationType != null) {
      final quantity = double.parse(_quantityController.text.trim());
      final price = double.parse(_priceController.text.trim());

      final operation = InvestmentOperation(
        quantity: quantity,
        price: price,
        date: _selectedDate!,
        type: _operationType!, // ✅ usar el nuevo campo
      );

      final model = context.read<InvestmentModel>();
      final chartProvider = context.read<ChartValueProvider>();
      final repo = InvestmentRepositoryImpl();
      await repo.init();

      final newInvestment = Investment(
        symbol: _symbol!,
        name: _symbol!,
      );

      await addOperationAndSync(
        investment: newInvestment,
        newOp: operation,
        repo: repo,
        chartProvider: chartProvider,
        model: model,
      );

      // ✅ ACTUALIZA símbolos visibles tras añadir operación
      final inv = model.investments;
      chartProvider.setVisibleSymbols(inv.map((e) => e.symbol).toSet());

      Navigator.of(context).pop();
    }
  }

  InputDecoration _inputDecoration(String label) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w400),
    enabledBorder: const UnderlineInputBorder(
      borderSide: BorderSide(color: Colors.black26),
    ),
    focusedBorder: const UnderlineInputBorder(
      borderSide: BorderSide(color: Colors.black87),
    ),
    contentPadding: const EdgeInsets.symmetric(vertical: 12),
  );

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final dateText = _selectedDate == null
        ? loc?.selectDate ?? 'Seleccionar fecha'
        : MaterialLocalizations.of(context).formatMediumDate(_selectedDate!);

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 12,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            autovalidateMode: _formSubmitted
                ? AutovalidateMode.always
                : AutovalidateMode.disabled,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  loc?.newOperation ?? 'Nueva operación',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 20),

                DropdownButtonFormField<String>(
                  decoration: _inputDecoration(loc?.assetType ?? 'Tipo de activo'),
                  items: ['crypto', 'stock', 'etf', 'commodity']
                      .map((type) => DropdownMenuItem(
                    value: type,
                    child: Text(type.toUpperCase()),
                  ))
                      .toList(),
                  value: _type,
                  onChanged: (val) => setState(() {
                    _type = val;
                    _symbol = null;
                    _symbolTouched = false;
                  }),
                  validator: (val) => val == null ? (loc?.selectAssetType ?? 'Seleccione un tipo') : null,
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<OperationType>(
                  decoration: _inputDecoration('Tipo de operación'),
                  value: _operationType,
                  onChanged: (op) => setState(() => _operationType = op),
                  items: OperationType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type == OperationType.buy ? 'Compra' : 'Venta'),
                    );
                  }).toList(),
                  validator: (val) => val == null ? 'Seleccione tipo de operación' : null,
                ),
                const SizedBox(height: 16),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      loc?.symbol ?? 'Símbolo',
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w400,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: _type == null
                          ? null
                          : () {
                        setState(() => _symbolTouched = true);
                        _selectSymbol();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: (_symbol == null && (_formSubmitted || _symbolTouched))
                                  ? Theme.of(context).colorScheme.error
                                  : Colors.black26,
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _symbol ?? (loc?.selectSymbol ?? 'Selecciona un símbolo'),
                              style: TextStyle(
                                color: _symbol == null ? Colors.black38 : Colors.black87,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down, color: Colors.black54),
                          ],
                        ),
                      ),
                    ),
                    if ((_formSubmitted || _symbolTouched) && _symbol == null)
                      Padding(
                        padding: const EdgeInsets.only(left: 8, top: 4),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            loc?.selectSymbol ?? 'Selecciona un símbolo',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${loc?.date ?? 'Fecha'}: ',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          dateText,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _quantityController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: _inputDecoration(loc?.quantity ?? 'Cantidad'),
                  autovalidateMode: _quantityTouched || _formSubmitted ? AutovalidateMode.always : AutovalidateMode.disabled,
                  validator: (val) {
                    if (!_quantityTouched && !_formSubmitted) return null;
                    if (val == null || val.isEmpty) return loc?.fieldRequired ?? 'Campo obligatorio';
                    final n = double.tryParse(val);
                    if (n == null || n <= 0) return loc?.invalidQuantity ?? 'Cantidad inválida';
                    return null;
                  },
                  onChanged: (_) {
                    if (!_quantityTouched) setState(() => _quantityTouched = true);
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _priceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: _inputDecoration(loc?.unitPrice ?? 'Precio unitario (€)'),
                  autovalidateMode: _priceTouched || _formSubmitted ? AutovalidateMode.always : AutovalidateMode.disabled,
                  validator: (val) {
                    if (!_priceTouched && !_formSubmitted) return null;
                    if (val == null || val.isEmpty) return loc?.fieldRequired ?? 'Campo obligatorio';
                    final n = double.tryParse(val);
                    if (n == null || n <= 0) return loc?.invalidPrice ?? 'Precio inválido';
                    return null;
                  },
                  onChanged: (_) {
                    if (!_priceTouched) setState(() => _priceTouched = true);
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