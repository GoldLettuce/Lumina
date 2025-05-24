import 'package:flutter/material.dart';
import '../../domain/entities/investment.dart';
import '../../data/repositories_impl/investment_repository_impl.dart';
import '../widgets/add_investment_dialog.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';

class PortfolioScreen extends StatefulWidget {
  final InvestmentRepositoryImpl investmentRepository;

  const PortfolioScreen({super.key, required this.investmentRepository});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  List<Investment> investments = [];
  String? _symbolToAdd;

  @override
  void initState() {
    super.initState();
    _loadInvestments();
  }

  Future<void> _loadInvestments() async {
    final data = await widget.investmentRepository.getAllInvestments();
    setState(() {
      investments = data;
    });
  }

  double calculateAvailableQuantity(List<Investment> investments, String symbol) {
    double total = 0.0;
    for (final inv in investments) {
      if (inv.symbol == symbol) {
        if (inv.operation == 'buy') {
          total += inv.quantity;
        } else if (inv.operation == 'sell') {
          total -= inv.quantity;
        }
      }
    }
    return total < 0 ? 0 : total;
  }

  Future<void> _openAddInvestmentDialog() async {
    final availableQuantity = _symbolToAdd == null
        ? 0.0
        : calculateAvailableQuantity(investments, _symbolToAdd!);

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => AddInvestmentDialog(
        onSave: (data) async {
          final newInvestment = Investment(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            type: data['type'],
            symbol: data['symbol'],
            quantity: data['quantity'],
            price: data['price'],
            date: data['date'],
            operation: data['operation'],  // Campo operation incluido aquí
          );
          await widget.investmentRepository.addInvestment(newInvestment);
          await _loadInvestments();
        },
        availableQuantity: availableQuantity,
      ),
    );

    if (result != null) {
      setState(() {
        _symbolToAdd = result['symbol']; // Actualizamos el símbolo para futuras ventas
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc?.appTitle ?? ''),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddInvestmentDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '€${investments.fold(0.0, (sum, inv) => sum + inv.price * inv.quantity).toStringAsFixed(2)}',
              style: theme.textTheme.headlineLarge,
            ),
            const SizedBox(height: 8),
            Text(
              loc?.dailyPL ?? '',
              style: theme.textTheme.bodyMedium,
            ),
            Text(
              loc?.openPL ?? '',
              style: theme.textTheme.bodyMedium!.copyWith(color: AppColors.positive),
            ),
            const SizedBox(height: 20),
            Container(
              height: 150,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.5),
                    AppColors.primary.withOpacity(0.1)
                  ],
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  loc?.graphPlaceholder ?? '',
                  style: TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: investments.isEmpty
                  ? Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Text(
                    loc?.emptyPortfolioMessage ??
                        'No tienes inversiones aún.\n¡Comienza añadiendo la primera!',
                    style: theme.textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                ),
              )
                  : ListView.separated(
                itemCount: investments.length,
                separatorBuilder: (context, index) =>
                    Divider(color: AppColors.border),
                itemBuilder: (context, index) {
                  final asset = investments[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      asset.symbol,
                      style: theme.textTheme.bodyLarge!
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${loc?.quantity ?? ''}: ${asset.quantity}',
                      style: theme.textTheme.bodyMedium,
                    ),
                    trailing: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '€${(asset.price * asset.quantity).toStringAsFixed(2)}',
                          style: theme.textTheme.bodyLarge!
                              .copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
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
