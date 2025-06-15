// lib/ui/widgets/add_investment_dialog.dart
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:lumina/services/portfolio_sync_service.dart';

import '../../domain/entities/investment.dart';
import '../../domain/entities/asset_type.dart';
import '../../l10n/app_localizations.dart';
import 'asset_selector_modal.dart';
import 'package:provider/provider.dart';
import 'package:lumina/ui/providers/chart_value_provider.dart';
import 'package:lumina/data/models/investment_model.dart';
import 'package:lumina/data/repositories_impl/investment_repository_impl.dart';
import 'package:lumina/ui/providers/settings_provider.dart';


/// Diálogo para añadir o editar una operación (compra / venta).
class AddInvestmentDialog extends StatefulWidget {
  const AddInvestmentDialog({
    super.key,
    required this.allowAdvancedAssets,
    this.initialOperation,
    this.initialSymbol,
  });

  final bool allowAdvancedAssets;
  final InvestmentOperation? initialOperation;
  final String? initialSymbol;

  @override
  State<AddInvestmentDialog> createState() => _AddInvestmentDialogState();
}

class _AddInvestmentDialogState extends State<AddInvestmentDialog> {
  final _formKey = GlobalKey<FormState>();

  AssetType _type = AssetType.crypto;
  OperationType? _operationType;
  String? _symbol;
  DateTime? _selectedDate = DateTime.now();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();

  bool _formSubmitted = false;
  bool _symbolTouched = false;
  bool _quantityTouched = false;
  bool _priceTouched = false;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final op = widget.initialOperation;
    if (op != null) {
      _operationType = op.type;
      _quantityController.text = op.quantity.toString();
      _priceController.text = op.price.toString();
      _selectedDate = op.date;
      _symbol = widget.initialSymbol;
      _symbolTouched = widget.initialSymbol != null;
    }
  }

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
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _selectSymbol() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => AssetSelectorModal(type: _type),
    );
    if (selected != null) {
      setState(() {
        _symbol = selected;
        _symbolTouched = true;
      });
    }
  }

  Future<void> _submit() async {
    if (_isSaving) return; // ✅ Evita doble guardado

    setState(() {
      _formSubmitted = true;
      _isSaving = true;
    });
    if (!_formKey.currentState!.validate() ||
        _symbol == null ||
        _operationType == null ||
        _selectedDate == null) {
      setState(() => _isSaving = false); // ✅ Liberamos el bloqueo
      return;
    }

    final quantity = double.parse(_quantityController.text.trim());
    final price = double.parse(_priceController.text.trim());

    final operation = InvestmentOperation(
      id: widget.initialOperation?.id ?? const Uuid().v4(),
      quantity: quantity,
      price: price,
      date: _selectedDate!,
      type: _operationType!,
    );

    // ✅ Si es edición, devolvemos la operación modificada
    if (widget.initialOperation != null) {
      Navigator.of(context).pop(operation);
      return;
    }

    // ✅ Si es creación, guardamos y sincronizamos el nuevo activo
    final model = context.read<InvestmentModel>();
    final chartProvider = context.read<ChartValueProvider>();
    final repo = InvestmentRepositoryImpl();
    await repo.init();

    final newInvestment = Investment(
      symbol: _symbol!,
      name: _symbol!,
      type: _type,
    );

    await addOperationAndSync(
      investment: newInvestment,
      newOp: operation,
      repo: repo,
      chartProvider: chartProvider,
      model: model,
    );

    chartProvider.setVisibleSymbols(
      model.investments.map((e) => e.symbol).toSet(),
    );

    await chartProvider.forceRebuildAndReload(model.investments);
    await chartProvider.updatePrices();

    Navigator.of(context).pop(); // No devolvemos nada, ya está todo sincronizado
  }


  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final settings = Provider.of<SettingsProvider>(context);
    final allowAdvancedAssets = settings.advancedModeEnabled;
    final dateText = _selectedDate == null
        ? (loc?.selectDate ?? 'Seleccionar fecha')
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
            autovalidateMode:
            _formSubmitted ? AutovalidateMode.always : AutovalidateMode.disabled,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.initialOperation != null
                      ? 'Editar operación'
                      : (loc?.newOperation ?? 'Nueva operación'),
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSaving
                            ? () {}
                            : () => setState(() => _operationType = OperationType.buy),

                        style: ElevatedButton.styleFrom(
                          backgroundColor: _operationType == OperationType.buy
                              ? Colors.green[200]
                              : Colors.green[50],
                          foregroundColor: Colors.green[800],
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Compra'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSaving
                            ? () {}
                            : () => setState(() => _operationType = OperationType.sell),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _operationType == OperationType.sell
                              ? Colors.yellow[100]
                              : Colors.yellow[50],
                          foregroundColor: Colors.amber[900],
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Venta'),
                      ),
                    ),
                  ],
                ),
                if (allowAdvancedAssets)
                  Padding(
                    padding: const EdgeInsets.only(top: 20, bottom: 16),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: AssetType.values.map((t) {
                        final selected = _type == t;

                        return ChoiceChip(
                          label: Text(
                            t.name.toUpperCase(),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: selected ? Colors.white : Colors.blue.shade700,
                            ),
                          ),
                          selected: selected,
                          showCheckmark: false,
                          backgroundColor: Colors.blue.shade50,
                          selectedColor: Theme.of(context).colorScheme.primary,
                          shape: StadiumBorder(
                            side: selected
                                ? BorderSide.none
                                : BorderSide(color: Colors.blue.shade100),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          onSelected: (_) {
                            setState(() {
                              _type = t;
                              _symbol = null;
                              _symbolTouched = false;
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),

                if (_formSubmitted && _operationType == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 8),
                    child: Text(
                      'Seleccione tipo de operación',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 16),

                if (widget.initialOperation == null)
                  InkWell(
                    onTap: _isSaving
                        ? null
                        : () {
                      setState(() => _symbolTouched = true);
                      _selectSymbol();
                    },
                    borderRadius: BorderRadius.circular(12),
                    highlightColor: Colors.grey[100],
                    splashColor: Colors.transparent,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _symbol ??
                                (loc?.selectSymbol ??
                                    'Selecciona un símbolo'),
                            style: TextStyle(
                              color: (_formSubmitted &&
                                  (_symbol == null || _symbol!.isEmpty))
                                  ? Theme.of(context)
                                  .colorScheme
                                  .error
                                  : Colors.black87,
                              fontSize: 17,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            size: 22,
                            color: (_formSubmitted &&
                                (_symbol == null || _symbol!.isEmpty))
                                ? Theme.of(context)
                                .colorScheme
                                .error
                                : Colors.black54,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text(_symbol!, style: Theme.of(context).textTheme.bodyLarge),
                  ),

                const SizedBox(height: 16),

                InkWell(
                  onTap: _isSaving ? null : _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 16),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            size: 18, color: Colors.black54),
                        const SizedBox(width: 8),
                        Text(
                          'Fecha: $dateText',
                          style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 15,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _quantityController,
                  keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
                  enabled: !_isSaving,
                  decoration: InputDecoration(
                      labelText: loc?.quantity ?? 'Cantidad',
                      labelStyle: const TextStyle(
                          color: Colors.black, fontWeight: FontWeight.w500),
                      border: const UnderlineInputBorder(),
                      contentPadding:
                      const EdgeInsets.symmetric(vertical: 12)),
                  style: const TextStyle(color: Colors.black),
                  onChanged: (_) {
                    if (!_quantityTouched) setState(() => _quantityTouched = true);
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _priceController,
                  keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                      labelText: loc?.unitPrice ?? 'Precio por unidad (€)',
                      labelStyle: const TextStyle(
                          color: Colors.black, fontWeight: FontWeight.w500),
                      border: const UnderlineInputBorder(),
                      contentPadding:
                      const EdgeInsets.symmetric(vertical: 12)),
                  style: const TextStyle(color: Colors.black),
                  autovalidateMode: _priceTouched || _formSubmitted
                      ? AutovalidateMode.always
                      : AutovalidateMode.disabled,
                  validator: (val) {
                    if (!_priceTouched && !_formSubmitted) return null;
                    if (val == null || val.isEmpty) {
                      return loc?.fieldRequired ?? 'Campo obligatorio';
                    }
                    final n = double.tryParse(val);
                    if (n == null || n <= 0) {
                      return loc?.invalidPrice ?? 'Precio inválido';
                    }
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
                        onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                        child: Text(loc?.cancel ?? 'Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _operationType == OperationType.buy
                              ? Colors.green[200]
                              : _operationType == OperationType.sell
                              ? Colors.yellow[100]
                              : Colors.grey[200],
                          foregroundColor: _operationType == OperationType.buy
                              ? Colors.green[800]
                              : _operationType == OperationType.sell
                              ? Colors.amber[900]
                              : Colors.black54,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: const StadiumBorder(),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),                       child: _isSaving
                          ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.black87),
                        ),
                      )
                          : Text(loc?.save ?? 'Guardar'),

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

  InputDecoration _inputDecoration(String label) => InputDecoration(
    labelText: label,
    labelStyle:
    const TextStyle(color: Colors.black54, fontWeight: FontWeight.w500),
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );
}
