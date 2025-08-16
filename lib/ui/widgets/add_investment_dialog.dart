// lib/ui/widgets/add_investment_dialog.dart
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import 'package:lumina/services/portfolio_sync_service.dart';
import 'package:intl/intl.dart';
import 'package:lumina/core/num_parser.dart';

import '../../domain/entities/investment.dart';
import '../../domain/entities/asset_type.dart';
import '../../l10n/app_localizations.dart';
import 'asset_selector_modal.dart';
import 'package:provider/provider.dart';
import 'package:lumina/ui/providers/spot_price_provider.dart';
import 'package:lumina/ui/providers/history_provider.dart';
import 'package:lumina/ui/providers/investment_provider.dart';
import 'package:lumina/data/repositories_impl/investment_repository_impl.dart';
import 'package:lumina/ui/providers/currency_provider.dart';
import 'package:lumina/data/repositories_impl/history_repository_impl.dart';
import 'package:lumina/core/point.dart';
import 'package:lumina/core/chart_range.dart';
import 'package:lumina/core/colors.dart';

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
  String? _imageUrl;
  DateTime? _selectedDate = DateTime.now();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();

  bool _formSubmitted = false;
  bool _quantityTouched = false;
  bool _priceTouched = false;

  bool _isSaving = false;

  // Variables para el botón Sell all
  bool _isSell = false;
  double _availableQty = 0;

  // Función auxiliar para formatear cantidades de manera consistente
  String _formatQuantity(double quantity) {
    return quantity
        .toStringAsFixed(8)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  @override
  void initState() {
    super.initState();
    final op = widget.initialOperation;
    if (op != null) {
      // Si venimos de editar, inicializamos también el símbolo y el ID
      _operationType = op.type;
      _quantityController.text = op.quantity.toString();
      _selectedDate = op.date;
      _displaySymbol = widget.initialSymbol;
      _coingeckoId = op.id;
      
      // Inicializar _isSell basado en el tipo de operación
      _isSell = op.type == OperationType.sell;
      
      // Si es una edición, también necesitamos obtener la cantidad disponible
      if (_coingeckoId != null) {
        // Usar Future.microtask para evitar llamar context.read en initState
        Future.microtask(() => _onAssetSelected());
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.initialOperation != null && !_priceTouched) {
      final fx = context.read<CurrencyProvider>();
      // Convertimos el precio USD a moneda local
      final local = widget.initialOperation!.price * fx.exchangeRate;
      final locStr = Localizations.localeOf(context).toString();
      _priceController.text = NumberFormat('0.00', locStr).format(local);
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
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
        return AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(bottom: bottomInset),
          child: const AssetSelectorModal(type: AssetType.crypto),
        );
      },
    );
    if (result != null) {
      setState(() {
        _displaySymbol = result['symbol'];
        _coingeckoId = result['id'];
        _imageUrl = result['imageUrl'] ?? '';
      });
      
      // Obtener el asset seleccionado y calcular cantidad disponible
      _onAssetSelected();
    }
  }

  void _onAssetSelected() {
    if (_coingeckoId != null) {
      final model = context.read<InvestmentProvider>();
      final asset = model.investments.firstWhere(
        (inv) => inv.coingeckoId == _coingeckoId,
        orElse: () => Investment(
          symbol: _displaySymbol ?? '',
          name: _displaySymbol ?? '',
          type: AssetType.crypto,
          coingeckoId: _coingeckoId!,
        ),
      );
      
      setState(() {
        // Usar la cantidad actual en posesión del modelo
        final q = asset.totalQuantity;
        _availableQty = q < 0 ? 0 : q;
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
        _coingeckoId == null ||
        _operationType == null ||
        _selectedDate == null) {
      setState(() => _isSaving = false);
      return;
    }

    final quantity   = parseFlexibleDouble(_quantityController.text);
    final priceLocal = parseFlexibleDouble(_priceController.text);
    if (quantity == null || priceLocal == null) return;

    // Guardar referencias antes del await
    final fx = context.read<CurrencyProvider>();
    final model = context.read<InvestmentProvider>();
    final currencyCode = fx.currency.toLowerCase();

    final priceUsd = priceLocal / fx.exchangeRate;

    final operation = InvestmentOperation(
      id: widget.initialOperation?.id ?? const Uuid().v4(),
      quantity: quantity,
      price: priceUsd,
      date: _selectedDate!,
      type: _operationType!,
    );

    // Edición
    if (widget.initialOperation != null) {
      // 1) Actualiza la operación editada en el provider
      await model.editOperation(widget.initialSymbol!, operation);

      // Verificar si el widget sigue montado
      if (!mounted) return;

      // 2) Refresca gráfico con lista ya actualizada
      final investments = model.investments;
      _loadHistory(context, investments);

      // 3) Devuelve true para indicar que se editó exitosamente
      Navigator.of(context).pop(true);
      return;
    }

    // Alta
    final repo = InvestmentRepositoryImpl();
    await repo.init();

    // Verificar si el widget sigue montado
    if (!mounted) return;

    // Crear Investment con símbolo, nombre, ID, vsCurrency e imageUrl
    final newInvestment = Investment(
      symbol: _displaySymbol!,
      name: _displaySymbol!,
      type: AssetType.crypto,
      coingeckoId: _coingeckoId!,
      vsCurrency: currencyCode,
      imageUrl: _imageUrl,
    );

    await addOperationAndSync(
      investment: newInvestment,
      newOp: operation,
      repo: repo,
      model: model,
    );

    // Verificar si el widget sigue montado
    if (!mounted) return;

    // Actualizar gráfico y precios usando la función loadHistory
    _loadHistory(context, model.investments);

    Navigator.of(context).pop(true);
  }

  void _loadHistory(BuildContext context, List<Investment> investments) async {
    final histRepo = HistoryRepositoryImpl();
    final spotProv = context.read<SpotPriceProvider>();
    final histProv = context.read<HistoryProvider>();

    await histRepo.downloadAndStoreIfNeeded(
      range: ChartRange.all,
      investments:
          investments.where((e) => e.type == AssetType.crypto).toList(),
    );

    // Usar directamente los datos del provider centralizado
    final prices = spotProv.spotPrices;

    final history = await histRepo.getHistory(
      range: ChartRange.all,
      investments: investments,
      spotPrices: prices,
    );

    // Calcular P/L TOTAL para hoy usando la misma lógica que el gráfico
    final today = DateTime.now();
    double totalValue = 0;
    double totalCost = 0;
    double totalRealized = 0;
    double totalNetContrib = 0;
    
    for (final inv in investments) {
      final qty = inv.operations
          .where((op) => !op.date.isAfter(today))
          .fold<double>(0, (s, op) => s + op.quantity);
      final price = prices[inv.symbol];
      
      if (qty > 0 && price != null) {
        totalValue += price * qty;
        
        // Calcular coste acumulado y P/L realizado
        double cost = 0;
        double realized = 0;
        double netContrib = 0;
        
        for (final op in inv.operations.where((op) => !op.date.isAfter(today))) {
          if (op.type.toString().toLowerCase().contains('sell')) {
            // Para ventas, calcular P/L realizado
            realized += op.quantity * (op.price - (cost / (cost > 0 ? cost : 1)));
            netContrib -= op.price * op.quantity;
          } else {
            // Para compras, acumular coste
            cost += op.price * op.quantity;
            netContrib += op.price * op.quantity;
          }
        }
        
        totalCost += cost;
        totalRealized += realized;
        totalNetContrib += netContrib;
      }
    }
    
    // Calcular P/L TOTAL del día
    final pnlTotalUsd = totalRealized + (totalValue - totalCost);
    final pctTotal = (totalNetContrib.abs() > 0)
        ? (pnlTotalUsd / totalNetContrib.abs()) * 100.0
        : 0.0;
    
    histProv.updateHistory(history);
    histProv.updateToday(Point(
      time: today, 
      value: totalValue,
      gainUsd: pnlTotalUsd,
      gainPct: pctTotal,
    ));
  }

  // ────────────────────────────────────────────────────────────────────────
  // UI
  // ────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final dateText =
        _selectedDate == null
            ? loc.selectDate
            : MaterialLocalizations.of(
              context,
            ).formatMediumDate(_selectedDate!);

    return Dialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 12,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            autovalidateMode:
                _formSubmitted
                    ? AutovalidateMode.always
                    : AutovalidateMode.disabled,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.initialOperation != null
                      ? loc.editOperation
                      : loc.newOperation,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 20),

                // ─── Tipo BUY/SELL ────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed:
                            _isSaving
                                ? null
                                : () => setState(() {
                                  _operationType = OperationType.buy;
                                  _isSell = false;
                                }),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _operationType == OperationType.buy
                                  ? Theme.of(context).colorScheme.tertiary.withAlpha(77)
                                  : Theme.of(context).colorScheme.tertiary.withAlpha(26),
                          foregroundColor: Theme.of(context).colorScheme.tertiary,
                          elevation: _operationType == OperationType.buy ? 2 : 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(loc.buy),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: () {
                        final isDark = Theme.of(context).brightness == Brightness.dark;
                        final sellColor = _operationType == OperationType.sell
                            ? (isDark ? sellButtonSelectedDark : sellButtonSelectedLight)
                            : (isDark ? sellButtonNeutralDark : sellButtonNeutralLight);
                        
                        return ElevatedButton(
                          onPressed: _isSaving
                              ? null
                              : () => setState(() {
                                _operationType = OperationType.sell;
                                _isSell = true;
                              }),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: sellColor,
                            foregroundColor: isDark ? Colors.white : Colors.black,
                            elevation: _operationType == OperationType.sell ? 2 : 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(loc.sell),
                        );
                      }(),
                    ),
                  ],
                ),
                if (_formSubmitted && _operationType == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 8),
                    child: Text(
                      loc.selectOperationType,
                      style: TextStyle(
                        color: AppColors.textNegative(context),
                        fontSize: 12,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),

                // ─── Selector símbolo ────────────────────────────────
                if (widget.initialOperation == null)
                  InkWell(
                    onTap:
                        _isSaving
                            ? null
                            : () {
                              _selectSymbol();
                            },
                    borderRadius: BorderRadius.circular(12),
                    highlightColor: Theme.of(context).colorScheme.surface.withAlpha(26),
                    splashColor: AppColors.transparent,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _displaySymbol ?? loc.selectSymbol,
                            style: TextStyle(
                              color:
                                  (_formSubmitted &&
                                          (_displaySymbol == null ||
                                              _displaySymbol!.isEmpty))
                                      ? AppColors.textNegative(context)
                                      : Theme.of(context).colorScheme.onSurface,
                              fontSize: 17,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            size: 22,
                            color:
                                (_formSubmitted &&
                                        (_displaySymbol == null ||
                                            _displaySymbol!.isEmpty))
                                    ? Theme.of(context).colorScheme.error
                                    : Theme.of(context).colorScheme.onSurface.withAlpha(153),
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
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 16,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 18,
                          color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${loc.dateLabel} $dateText',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ─── Cantidad ────────────────────────────────────────
                TextFormField(
                  controller: _quantityController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,\- ]')),
                  ],
                  enabled: !_isSaving,
                  decoration: InputDecoration(
                    labelText: loc.quantity,
                    hintText: null,
                    labelStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    suffixIcon: (_isSell && _availableQty > 0)
                        ? TextButton(
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(64, 36), // compacto y minimalista
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () {
                              // Rellena con toda la posición disponible, recortando ceros finales
                              final txt = _formatQuantity(_availableQty);
                              _quantityController.text = txt;
                              // si hay validación onChanged, dispara un setState ligero
                              setState(() {});
                            },
                            child: Text(loc.sellAll),
                          )
                        : null,
                  ),
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                  onChanged: (_) {
                    if (!_quantityTouched) {
                      setState(() => _quantityTouched = true);
                    }
                  },
                  autovalidateMode: _quantityTouched || _formSubmitted ? AutovalidateMode.always : AutovalidateMode.disabled,
                  validator: (val) {
                    if (!_quantityTouched && !_formSubmitted) return null;
                    if (val == null || val.isEmpty) return loc.fieldRequired;
                    final n = parseFlexibleDouble(val);
                    if (n == null || n <= 0) return loc.invalidQuantity;
                    
                    // Validación adicional para modo venta: verificar que no se exceda la cantidad disponible
                    if (_isSell && n > _availableQty) {
                      return '${loc.holdingsLabel}: ${_formatQuantity(_availableQty)}';
                    }
                    
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // ─── Precio ──────────────────────────────────────────
                TextFormField(
                  controller: _priceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,\- ]')),
                  ],
                  decoration: InputDecoration(
                    labelText: loc.unitPrice,
                    hintText: null,
                    labelStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                  ),
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                  autovalidateMode:
                      _priceTouched || _formSubmitted
                          ? AutovalidateMode.always
                          : AutovalidateMode.disabled,
                  validator: (val) {
                    if (!_priceTouched && !_formSubmitted) return null;
                    if (val == null || val.isEmpty) {
                      return loc.fieldRequired;
                    }
                    final n = parseFlexibleDouble(val);
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
                      child: () {
                        final isDark = Theme.of(context).brightness == Brightness.dark;
                        final cancelColor = isDark ? cancelButtonDark : cancelButtonLight;
                        final cancelTextColor = isDark ? cancelButtonTextDark : cancelButtonTextLight;

                        return ElevatedButton(
                          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: cancelColor,
                            foregroundColor: cancelTextColor,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(loc.cancel),
                        );
                      }(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: () {
                            final isDark = Theme.of(context).brightness == Brightness.dark;
                            return _operationType == OperationType.buy
                                ? Theme.of(context).colorScheme.tertiary.withAlpha(77)
                                : _operationType == OperationType.sell
                                    ? (isDark ? sellButtonSelectedDark : sellButtonSelectedLight)
                                    : Theme.of(context).colorScheme.surface.withAlpha(128);
                          }(),
                          foregroundColor: () {
                            final isDark = Theme.of(context).brightness == Brightness.dark;
                            return _operationType == OperationType.buy
                                ? Theme.of(context).colorScheme.tertiary
                                : _operationType == OperationType.sell
                                    ? (isDark ? Colors.white : Colors.black)
                                    : Theme.of(context).colorScheme.onSurface.withAlpha(153);
                          }(),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: const StadiumBorder(),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child:
                            _isSaving
                                ? SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Theme.of(context).colorScheme.onSurface,
                                    ),
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
