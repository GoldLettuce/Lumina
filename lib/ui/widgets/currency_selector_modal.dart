import 'package:flutter/material.dart';

class CurrencySelectorModal extends StatelessWidget {
  final Map<String, String> currencies;
  final String selected;

  const CurrencySelectorModal({
    super.key,
    required this.currencies,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final sortedEntries =
        currencies.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          color: Colors.white,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            const Text(
              'Selecciona una moneda',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black, // ✅ Color claro
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: sortedEntries.length,
                itemBuilder: (context, index) {
                  final entry = sortedEntries[index];
                  final isSelected = entry.key == selected;

                  return InkWell(
                    onTap: () => Navigator.of(context).pop(entry.key),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${entry.key} – ${entry.value}',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black, // ✅ Texto oscuro
                              ),
                            ),
                          ),
                          if (isSelected)
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black, // ✅ Círculo oscuro
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
