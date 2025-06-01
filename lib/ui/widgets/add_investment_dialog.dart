// lib/ui/widgets/add_investment_dialog.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/investment.dart';
import '../../data/models/investment_model.dart';
import '../../l10n/app_localizations.dart';
import 'asset_selector_modal.dart'; // Import del modal de selección dinámico

class AddInvestmentDialog extends StatefulWidget {
  const AddInvestmentDialog({super.key});

  @override
  State<AddInvestmentDialog> createState() => _AddInvestmentDialogState();
}

class _AddInvestmentDialogState extends State<AddInvestmentDialog> {
  final _formKey = GlobalKey<FormState>();

  String? _type;
  bool _isBuy = true;
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

    // Abrimos el modal dinámico que carga todos los símbolos (de CryptoCompare
    // u otras listas en función del tipo)
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

  void _submit() async {
    setState(() {
      _formSubmitted = true;
    });

    if (_formKey.currentState!.validate() &&
        _type != null &&
        _symbol != null &&
        _selectedDate != null) {
      final quantity = double.parse(_quantityController.text.trim());
      final price = double.parse(_priceController.text.trim());

      final operation = InvestmentOperation(
        quantity: _isBuy ? quantity : -quantity,
        price: price,
        date: _selectedDate!,
      );

      final newInvestment = Investment(
        symbol: _symbol!,
        name: _symbol!, // Usamos el símbolo como nombre por defecto
        operations: [operation],
      );

      await context.read<InvestmentModel>().addInvestment(newInvestment);
      Navigator.of(context).pop();
    }
  }

  InputDecoration _inputDecoration(String label) => InputDecoration(
    labelText: label,
    labelStyle:
    const TextStyle(color: Colors.black87, fontWeight: FontWeight.w400),
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
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 20),

                // Selección de tipo de activo
                DropdownButtonFormField<String>(
                  decoration:
                  _inputDecoration(loc?.assetType ?? 'Tipo de activo'),
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
                  validator: (val) => val == null
                      ? (loc?.selectAssetType ?? 'Seleccione un tipo')
                      : null,
                ),
                const SizedBox(height: 16),

                // Selector de símbolo (abre el modal dinámico)
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
                        padding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: (_symbol == null &&
                                  (_formSubmitted || _symbolTouched))
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
                              _symbol ??
                                  (loc?.selectSymbol ??
                                      'Selecciona un símbolo'),
                              style: TextStyle(
                                color: _symbol == null
                                    ? Colors.black38
                                    : Colors.black87,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down,
                                color: Colors.black54),
                          ],
                        ),
                      ),
                    ),
                    if ((_formSubmitted || _symbolTouched) &&
                        _symbol == null)
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

                // Selector de fecha
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

                // Campo cantidad
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
                    if (val == null || val.isEmpty)
                      return loc?.fieldRequired ?? 'Campo obligatorio';
                    final n = double.tryParse(val);
                    if (n == null || n <= 0)
                      return loc?.invalidQuantity ?? 'Cantidad inválida';
                    return null;
                  },
                  onChanged: (_) {
                    if (!_quantityTouched)
                      setState(() => _quantityTouched = true);
                  },
                ),
                const SizedBox(height: 16),

                // Campo precio unitario
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
                    if (val == null || val.isEmpty)
                      return loc?.fieldRequired ?? 'Campo obligatorio';
                    final n = double.tryParse(val);
                    if (n == null || n <= 0)
                      return loc?.invalidPrice ?? 'Precio inválido';
                    return null;
                  },
                  onChanged: (_) {
                    if (!_priceTouched) setState(() => _priceTouched = true);
                  },
                ),
                const SizedBox(height: 24),

                // Botones Cancelar / Guardar
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
