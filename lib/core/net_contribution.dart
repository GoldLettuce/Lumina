import 'package:lumina/domain/entities/investment.dart';

double netContributionUsd(Investment asset) {
  return asset.operations.fold<double>(0.0, (sum, op) {
    final cash = op.price * op.quantity; // USD
    final isSell = op.type.toString().toLowerCase().contains('sell');
    return isSell ? (sum - cash) : (sum + cash);
  });
}

