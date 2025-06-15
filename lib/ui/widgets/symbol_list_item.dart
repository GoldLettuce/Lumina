import 'package:flutter/material.dart';

/// Widget para mostrar un símbolo con diseño minimalista:
/// - Nombre de la empresa en negrita.
/// - Símbolo en negrita menor.
/// - Nombre de mercado en gris, tamaño reducido.
class SymbolListItem extends StatelessWidget {
  final String companyName;
  final String symbol;
  final String marketName;
  final VoidCallback onTap;

  const SymbolListItem({
    Key? key,
    required this.companyName,
    required this.symbol,
    required this.marketName,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nombre de la empresa
            Text(
              companyName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 2),
            // Fila con símbolo y mercado
            Row(
              children: [
                Text(
                  symbol,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (marketName.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text(
                    '·  $marketName',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
