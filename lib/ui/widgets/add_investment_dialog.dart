// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/investment.dart';
import '../../domain/entities/asset_type.dart';
import '../../data/models/investment_model.dart';
import '../../l10n/app_localizations.dart';
import 'asset_selector_modal.dart';
import 'package:lumina/ui/providers/chart_value_provider.dart';
import 'package:lumina/data/repositories_impl/investment_repository_impl.dart';
import 'package:lumina/services/portfolio_sync_service.dart';

/// Diálogo para añadir una operación (compra / venta).
/// * Solo cripto por defecto.
/// * Activos avanzados (acciones, ETF, commodities) se habilitan pasando
///   [allowAdvancedAssets] = true (por ejemplo cuando el usuario define su API‑Key).
class AddInvestmentDialog extends StatefulWidget {
  const AddInvestmentDialog({
    super.key,
    required this.allowAdvancedAssets,
  });

  /// Si es `true`, se muestra el desplegable para elegir otro [AssetType].
  final bool allowAdvancedAssets;

  @override
  State<AddInvestmentDialog> createState() => _AddInvestmentDialogState();
}

class _AddInvestmentDialogState extends State<AddInvestmentDialog> {
  final _formKey = GlobalKey<FormState>();

  // ───── Campos de formulario ─────
  AssetType _type = AssetType.crypto; // crypto por defecto
  OperationType? _operationType;
  String? _symbol;
  DateTime? _selectedDate = DateTime.now();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();

  // ───── Flags de validación ─────
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

  // ──────────────────────────────────────────────────────────────
  // Helpers UI
  // ──────────────────────────────────────────────────────────────
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

  InputDecoration _inputDecoration(String label) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(
      color: Colors.black54,
      fontWeight: FontWeight.w500,
    ),
    filled: true,
    fillColor: Colors.grey[100],
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );


  // ──────────────────────────────────────────────────────────────
  // Submit – flujo en 5 pasos
  // ──────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    setState(() => _formSubmitted = true);

    if (!_formKey.currentState!.validate() ||
        _symbol == null ||
        _operationType == null ||
        _selectedDate == null) return;

    final quantity = double.parse(_quantityController.text.trim());
    final price = double.parse(_priceController.text.trim());

    final operation = InvestmentOperation(
      quantity: quantity,
      price: price,
      date: _selectedDate!,
      type: _operationType!,
    );

    final model = context.read<InvestmentModel>();
    final chartProvider = context.read<ChartValueProvider>();
    final repo = InvestmentRepositoryImpl();
    await repo.init();

    final newInvestment = Investment(
      symbol: _symbol!,
      name: _symbol!,
      type: _type, // ✅ nuevo campo obligatorio
    );

    // 1️⃣ Guardar y sincronizar
    await addOperationAndSync(
      investment: newInvestment,
      newOp: operation,
      repo: repo,
      chartProvider: chartProvider,
      model: model,
    );

    // 2️⃣ Actualizar símbolos visibles (por si el activo es nuevo)
    chartProvider.setVisibleSymbols(
      model.investments.map((e) => e.symbol).toSet(),
    );

    // 3️⃣ Reconstruir histórico completo
    await chartProvider.forceRebuildAndReload(model.investments);

    // 4️⃣ Descargar precios spot y recalcular valores
    await chartProvider.updatePrices();

    // 5️⃣ Cerrar el diálogo
    Navigator.of(context).pop();
  }

  // ──────────────────────────────────────────────────────────────
  // UI
  // ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
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
            autovalidateMode: _formSubmitted
                ? AutovalidateMode.always
                : AutovalidateMode.disabled,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Título ──
                Text(
                  loc?.newOperation ?? 'Nueva operación',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 20),

                // ── Selector AssetType (solo si se permiten avanzados) ──
                if (widget.allowAdvancedAssets) ...[
                  DropdownButtonFormField<AssetType>(
                    decoration:
                    _inputDecoration(loc?.assetType ?? 'Tipo de activo'),
                    value: _type,
                    onChanged: (val) => setState(() {
                      _type = val!;
                      _symbol = null;
                      _symbolTouched = false;
                    }),
                    items: AssetType.values
                        .map((e) => DropdownMenuItem(
                      value: e,
                      child: Text(e.name.toUpperCase()),
                    ))
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Botones Compra / Venta ──
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Tipo de operación',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () =>
                                setState(() => _operationType = OperationType.buy),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _operationType == OperationType.buy
                                  ? Colors.green[100]
                                  : Colors.grey[100],
                              foregroundColor: Colors.green[800],
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Compra'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => setState(
                                    () => _operationType = OperationType.sell),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _operationType == OperationType.sell
                                  ? Colors.red[100]
                                  : Colors.grey[100],
                              foregroundColor: Colors.red[800],
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Venta'),
                          ),
                        ),
                      ],
                    ),
                    if (_formSubmitted && _operationType == null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, left: 8),
                        child: Text(
                          'Seleccione tipo de operación',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Selector de símbolo ──
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      loc?.symbol ?? 'Símbolo',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () {
                        setState(() => _symbolTouched = true);
                        _selectSymbol();
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: (_symbol == null && (_formSubmitted || _symbolTouched))
                                ? Theme.of(context).colorScheme.error
                                : Colors.transparent,
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
                        child: Text(
                          loc?.selectSymbol ?? 'Selecciona un símbolo',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                // ── Fecha ──
// ── Fecha ──
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      loc?.date ?? 'Fecha',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              dateText,
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Icon(Icons.calendar_today_outlined, color: Colors.black45, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ── Cantidad ──
                TextFormField(
                  controller: _quantityController,
                  keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
                  decoration: _inputDecoration(loc?.quantity ?? 'Cantidad'),
                  autovalidateMode: _quantityTouched || _formSubmitted
                      ? AutovalidateMode.always
                      : AutovalidateMode.disabled,
                  validator: (val) {
                    if (!_quantityTouched && !_formSubmitted) return null;
                    if (val == null || val.isEmpty) {
                      return loc?.fieldRequired ?? 'Campo obligatorio';
                    }
                    final n = double.tryParse(val);
                    if (n == null || n <= 0) {
                      return loc?.invalidQuantity ?? 'Cantidad inválida';
                    }
                    return null;
                  },
                  onChanged: (_) {
                    if (!_quantityTouched) setState(() => _quantityTouched = true);
                  },
                ),
                const SizedBox(height: 16),

                // ── Precio ──
                TextFormField(
                  controller: _priceController,
                  keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
                  decoration:
                  _inputDecoration(loc?.unitPrice ?? 'Precio unitario (€)'),
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

                // ── Botones Guardar / Cancelar ──
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