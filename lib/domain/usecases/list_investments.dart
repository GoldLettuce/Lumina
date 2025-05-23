import '../entities/investment.dart';
import '../repositories/investment_repository.dart';

class ListInvestments {
  final InvestmentRepository repository;

  ListInvestments(this.repository);

  Future<List<Investment>> call() async {
    return await repository.getAllInvestments();
  }
}
