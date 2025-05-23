import '../entities/investment.dart';
import '../repositories/investment_repository.dart';

class AddInvestment {
  final InvestmentRepository repository;

  AddInvestment(this.repository);

  Future<void> call(Investment investment) async {
    await repository.addInvestment(investment);
  }
}
