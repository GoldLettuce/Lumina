import '../entities/investment.dart';

abstract class InvestmentRepository {
  Future<void> addInvestment(Investment investment);
  Future<List<Investment>> getAllInvestments();
  Future<void> deleteInvestment(String id);
}
