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
import 'package:lumina/ui/providers/investment_provider.dart';
import 'package:lumina/data/repositories_impl/investment_repository_impl.dart';
import 'package:lumina/ui/providers/currency_provider.dart';

/// Diálogo para añadir o editar una operación **solo de criptomonedas**.
class AddInvestmentDialog extends StatefulWidget {
  const AddInvestmentDialog({
    super.key,
    this.initialOperation,
    this.initialSymbol,
  });

  final InvestmentOperation? initialOperation;
  final String? initialSymbol;

  @override
  State<AddInvestmentDialog> createState() => _AddInvestmentDialogState();
}

class _AddInvestmentDialogState extends State<AddInvestmentDialog> {
  final _formKey = GlobalKey<FormState>();

  OperationType? _operationType;
  String? _displaySymbol;
  String? _coingeckoId;
  DateTime? _selectedDate = DateTime.now();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();

  bool _formSubmitted = false;
  bool _quantityTouched = false;
  bool _priceTouched = false;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final op = widget.initialOperation;
    if (op != null) {
      // Si venimos de editar, inicializamos también el símbolo y el ID
      _operationType     = op.type;
      _quantityController.text = op.quantity.toString();
      _selectedDate      = op.date;
      _displaySymbol     = widget.initialSymbol;
      _coingeckoId       = op.id;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.initialOperation != null && !_priceTouched) {
      final fx = context.read<CurrencyProvider>();
      // Convertimos el precio USD a moneda local
      final local = widget.initialOperation!.price * fx.exchangeRate;
      _priceController.text = local.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  // ────────────────────────────────────────────────────────────────────────
  // Pickers
  // ────────────────────────────────────────────────────────────────────────
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
    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const AssetSelectorModal(type: AssetType.crypto),
    );
    if (result != null) {
      setState(() {
        _displaySymbol = result['symbol'];
        _coingeckoId   = result['id'];
      });
    }
  }

  // ────────────────────────────────────────────────────────────────────────
  // Guardar
  // ────────────────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (_isSaving) return;

    setState(() {
      _formSubmitted = true;
      _isSaving = true;
    });

    // Validación: exigimos símbolo, ID, tipo y fecha
    if (!_formKey.currentState!.validate() ||
        _displaySymbol == null ||
        _coingeckoId   == null ||
        _operationType == null ||
        _selectedDate  == null) {
      setState(() => _isSaving = false);
      return;
    }

    final quantity   = double.tryParse(_quantityController.text.trim());
    final priceLocal = double.tryParse(_priceController.text.trim());
    if (quantity == null || priceLocal == null) return;
    
    // Guardar referencias antes del await
    final fx = context.read<CurrencyProvider>();
    final model = context.read<InvestmentProvider>();
    final chartProvider = context.read<ChartValueProvider>();
    final currencyCode = fx.currencyCode.toLowerCase();
    
    final priceUsd   = priceLocal / fx.exchangeRate;

    final operation = InvestmentOperation(
      id:       widget.initialOperation?.id ?? const Uuid().v4(),
      quantity: quantity,
      price:    priceUsd,
      date:     _selectedDate!,
      type:     _operationType!,
    );

    // Edición
    if (widget.initialOperation != null) {
      // 1) Actualiza la operación editada en el provider
      await model.editOperation(widget.initialSymbol!, operation);

      // Verificar si el widget sigue montado
      if (!mounted) return;

      // 2) Refresca gráfico con lista ya actualizada
      final investments = model.investments;
      await chartProvider.forceRebuildAndReload(investments);
      await chartProvider.updatePrices();
      chartProvider.updateTodayPoint();

      // 3) Devuelve la operación editada
      Navigator.of(context).pop(operation);
      return;
    }

    // Alta
    final repo = InvestmentRepositoryImpl();
    await repo.init();

    // Verificar si el widget sigue montado
    if (!mounted) return;

    // Crear Investment con símbolo, nombre, ID y vsCurrency
    final newInvestment = Investment(
      symbol:      _displaySymbol!,
      name:        _displaySymbol!,
      type:        AssetType.crypto,
      coingeckoId: _coingeckoId!,
      vsCurrency:  currencyCode,
    );

    await addOperationAndSync(
      investment: newInvestment,
      newOp:      operation,
      repo:       repo,
      chartProvider: chartProvider,
      model:         model,
    );

    // Verificar si el widget sigue montado
    if (!mounted) return;

    // Actualizar gráfico
    chartProvider.setVisibleSymbols(
      model.investments.map((e) => e.symbol).toSet(),
    );
    await chartProvider.forceRebuildAndReload(
      model.investments,
    );
    await chartProvider.updatePrices();
    chartProvider.updateTodayPoint();      // recalcula con precios ya actualizados

    Navigator.of(context).pop();
  }

  // ────────────────────────────────────────────────────────────────────────
  // UI
  // ────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final loc      = AppLocalizations.of(context)!;
    final dateText = _selectedDate == null
        ? loc.selectDate
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
                  widget.initialOperation != null
                      ? loc.editOperation
                      : loc.newOperation,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 20),

                // ─── Tipo BUY/SELL ────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSaving
                            ? null
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
                        child: Text(loc.buy),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSaving
                            ? null
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
                        child: Text(loc.sell),
                      ),
                    ),
                  ],
                ),
                if (_formSubmitted && _operationType == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 8),
                    child: Text(
                      loc.selectOperationType,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 16),

                // ─── Selector símbolo ────────────────────────────────
                if (widget.initialOperation == null)
                  InkWell(
                    onTap: _isSaving ? null : () {
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
                            _displaySymbol ?? loc.selectSymbol,
                            style: TextStyle(
                              color: (_formSubmitted &&
                                  (_displaySymbol == null || _displaySymbol!.isEmpty))
                                  ? Theme.of(context).colorScheme.error
                                  : Colors.black87,
                              fontSize: 17,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            size: 22,
                            color: (_formSubmitted &&
                                (_displaySymbol == null || _displaySymbol!.isEmpty))
                                ? Theme.of(context).colorScheme.error
                                : Colors.black54,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text(
                      _displaySymbol!,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),

                const SizedBox(height: 16),

                // ─── Fecha ───────────────────────────────────────────
                InkWell(
                  onTap: _isSaving ? null : _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            size: 18, color: Colors.black54),
                        const SizedBox(width: 8),
                        Text(
                          '${loc.dateLabel} $dateText',
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

                // ─── Cantidad ────────────────────────────────────────
                TextFormField(
                  controller: _quantityController,
                  keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
                  enabled: !_isSaving,
                  decoration: InputDecoration(
                      labelText: loc.quantity,
                      labelStyle: const TextStyle(
                          color: Colors.black, fontWeight: FontWeight.w500),
                      border: const UnderlineInputBorder(),
                      contentPadding:
                      const EdgeInsets.symmetric(vertical: 12)),
                  style: const TextStyle(color: Colors.black),
                  onChanged: (_) {
                    if (!_quantityTouched) {
                      setState(() => _quantityTouched = true);
                    }
                  },
                ),

                const SizedBox(height: 16),

                // ─── Precio ──────────────────────────────────────────
                TextFormField(
                  controller: _priceController,
                  keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                      labelText: loc.unitPrice,
                      labelStyle: const TextStyle(
                          color: Colors.black, fontWeight: FontWeight.w500),
                      border: const UnderlineInputBorder(),
                      contentPadding:
                      const EdgeInsets.symmetric(vertical: 12)),
                  style: const TextStyle(color: Colors.black),
                  autovalidateMode:
                  _priceTouched || _formSubmitted
                      ? AutovalidateMode.always
                      : AutovalidateMode.disabled,
                  validator: (val) {
                    if (!_priceTouched && !_formSubmitted) return null;
                    if (val == null || val.isEmpty) {
                      return loc.fieldRequired;
                    }
                    final n = double.tryParse(val);
                    if (n == null || n <= 0) {
                      return loc.invalidPrice;
                    }
                    return null;
                  },
                  onChanged: (_) {
                    if (!_priceTouched) setState(() => _priceTouched = true);
                  },
                ),

                const SizedBox(height: 24),

                // ─── Botones final ───────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                        _isSaving ? null : () => Navigator.of(context).pop(),
                        child: Text(loc.cancel),
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
                          foregroundColor: _operationType ==
                              OperationType.buy
                              ? Colors.green[800]
                              : _operationType ==
                              OperationType.sell
                              ? Colors.amber[900]
                              : Colors.black54,
                          padding:
                          const EdgeInsets.symmetric(vertical: 16),
                          shape: const StadiumBorder(),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.black87),
                          ),
                        )
                            : Text(loc.save),
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
