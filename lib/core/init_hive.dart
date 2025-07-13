import 'package:lumina/core/hive_service.dart';
import 'package:lumina/data/repositories_impl/investment_repository_impl.dart';

Future<InvestmentRepositoryImpl> initHive() async {
  // Inicializar todas las cajas de Hive usando el servicio centralizado
  await HiveService.init();

  // Crear y retornar el repositorio de inversiones
  final repository = InvestmentRepositoryImpl();
  await repository.init();

  return repository;
}
