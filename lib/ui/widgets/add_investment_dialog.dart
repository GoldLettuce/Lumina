import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_localizations.dart';

class AddInvestmentDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onSave;
  final double availableQuantity;

  const AddInvestmentDialog({
    super.key,
    required this.onSave,
    this.availableQuantity = 0,
  });

  @override
  State<AddInvestmentDialog> createState() => _AddInvestmentDialogState();
}

class _AddInvestmentDialogState extends State<AddInvestmentDialog> {
  final _formKey = GlobalKey<FormState>();

  String? _type;
  bool _isBuy = true;
  String? _symbol;
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  DateTime? _selectedDate = DateTime.now();

  final Map<String, List<String>> _symbolsByType = {
    'crypto': ['BTC', 'ETH', 'ADA', 'SOL', 'DOT'],
    'stock': ['AAPL', 'TSLA', 'MSFT', 'GOOG', 'AMZN'],
    'etf': ['SPY', 'IVV', 'VOO', 'QQQ', 'VTI'],
    'commodity': ['GOLD', 'SILVER', 'OIL', 'COPPER', 'PLATINUM'],
  };

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
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: Colors.black87,
            onPrimary: Colors.white,
            onSurface: Colors.black87,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: Colors.black87),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectSymbol() async {
    if (_type == null) return;

    final symbols = _symbolsByType[_type!] ?? [];

    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final loc = AppLocalizations.of(context);
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: symbols.length,
          separatorBuilder: (_, __) => Divider(
            thickness: 0.3,
            color: Colors.grey.shade300,
            height: 0.3,
          ),
          itemBuilder: (context, index) {
            final symbol = symbols[index];
            return ListTile(
              title: Text(symbol, style: const TextStyle(fontWeight: FontWeight.w500)),
              onTap: () => Navigator.of(context).pop(symbol),
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            );
          },
        );
      },
    );

    if (selected != null) {
      setState(() => _symbol = selected);
    }
  }

  void _submit() {
    final loc = AppLocalizations.of(context);
    if (_formKey.currentState!.validate() && _type != null && _symbol != null && _selectedDate != null) {
      final data = {
        'type': _type!,
        'symbol': _symbol!,
        'quantity': double.parse(_quantityController.text.trim()),
        'price': double.parse(_priceController.text.trim()),
        'date': _selectedDate!,
        'operation': _isBuy ? 'buy' : 'sell',
      };
      widget.onSave(data);
      Navigator.of(context).pop(data);
    } else {
      // Aquí podrías mostrar alerta si quieres
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
    final dateText = _selectedDate == null ? loc?.selectDate ?? 'Seleccionar fecha' : DateFormat.yMd().format(_selectedDate!);

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 12,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(loc?.newOperation ?? 'Nueva operación', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                decoration: _inputDecoration(loc?.assetType ?? 'Tipo de activo'),
                items: _symbolsByType.keys
                    .map((type) => DropdownMenuItem(value: type, child: Text(type.toUpperCase())))
                    .toList(),
                value: _type,
                onChanged: (val) => setState(() {
                  _type = val;
                  _symbol = null;
                }),
                validator: (val) => val == null ? (loc?.selectAssetType ?? 'Seleccione un tipo') : null,
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _type == null ? null : _selectSymbol,
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: _inputDecoration(loc?.symbol ?? 'Símbolo').copyWith(
                      hintText: _symbol ?? loc?.selectSymbol ?? 'Toca para seleccionar',
                      suffixIcon: const Icon(Icons.arrow_drop_down, color: Colors.black54),
                    ),
                    validator: (val) => _symbol == null ? (loc?.selectSymbol ?? 'Selecciona un símbolo') : null,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => setState(() => _isBuy = true),
                      style: TextButton.styleFrom(
                        foregroundColor: _isBuy ? Colors.green : Colors.black54,
                      ),
                      child: Text(
                        loc?.buy ?? 'Compra',
                        style: TextStyle(
                          fontWeight: _isBuy ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: () => setState(() => _isBuy = false),
                      style: TextButton.styleFrom(
                        foregroundColor: !_isBuy ? Colors.red : Colors.black54,
                      ),
                      child: Text(
                        loc?.sell ?? 'Venta',
                        style: TextStyle(
                          fontWeight: !_isBuy ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantityController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: _inputDecoration(loc?.quantity ?? 'Cantidad'),
                validator: (val) {
                  if (val == null || val.isEmpty) return loc?.fieldRequired ?? 'Campo obligatorio';
                  final n = double.tryParse(val);
                  if (n == null || n <= 0) return loc?.invalidQuantity ?? 'Cantidad inválida';

                  if (!_isBuy && n > widget.availableQuantity) {
                    return loc?.exceedQuantity ?? 'Cantidad mayor que disponible';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: _inputDecoration(loc?.unitPrice ?? 'Precio unitario (€)'),
                validator: (val) {
                  if (val == null || val.isEmpty) return loc?.fieldRequired ?? 'Campo obligatorio';
                  final n = double.tryParse(val);
                  if (n == null || n <= 0) return loc?.invalidPrice ?? 'Precio inválido';
                  return null;
                },
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
            ]),
          ),
        ),
      ),
    );
  }
}
