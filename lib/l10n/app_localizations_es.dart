// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Mi Portafolio';

  @override
  String get dailyPL => 'P/G diario | 0,00 € 0.00%';

  @override
  String get openPL => 'Abrir P/G | 4,328.47 € 1.17%';

  @override
  String get graphPlaceholder => 'Marcador de gráfico';

  @override
  String get quantity => 'Cantidad';

  @override
  String get noInvestments => 'No hay inversiones';

  @override
  String get emptyPortfolioMessage => 'No tienes inversiones aún.\n¡Comienza añ,adiendo la primera!';

  @override
  String get newOperation => 'Nueva operación';

  @override
  String get assetType => 'Tipo de activo';

  @override
  String get selectAssetType => 'Seleccione un tipo';

  @override
  String get symbol => 'Símbolo';

  @override
  String get selectSymbol => 'Selecciona un símbolo';

  @override
  String get buy => 'Compra';

  @override
  String get sell => 'Venta';

  @override
  String get fieldRequired => 'Campo obligatorio';

  @override
  String get invalidQuantity => 'Cantidad inválida';

  @override
  String get unitPrice => 'Precio unitario (€)';

  @override
  String get invalidPrice => 'Precio inválido';

  @override
  String get date => 'Fecha';

  @override
  String get selectDate => 'Seleccionar fecha';

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Guardar';

  @override
  String get sellAll => 'Vender todo';

  @override
  String get exceedQuantity => 'Cantidad mayor que disponible';

  @override
  String get searchAsset => 'Buscar activo';

  @override
  String get notEnoughChartData => 'No hay suficientes datos para mostrar el gráfico';

  @override
  String get archivedAssetsTitle => 'Activos sin posiciones';

  @override
  String get noArchivedAssets => 'No hay activos sin posición actualmente.';

  @override
  String get settings => 'Ajustes';

  @override
  String get language => 'Idioma';

  @override
  String get loadSymbolsError => 'No se pudieron cargar los símbolos';

  @override
  String get noSymbolsFound => 'No se encontraron símbolos';

  @override
  String get deleteOperations => 'Eliminar operaciones';

  @override
  String get deleteOperationsMessage => '¿Estás seguro de que quieres eliminar las operaciones seleccionadas? Esta acción no se puede deshacer.';

  @override
  String get delete => 'Eliminar';

  @override
  String get noOperations => 'No hay operaciones registradas.';

  @override
  String get editOperation => 'Editar operación';

  @override
  String get selectOperationType => 'Seleccione tipo de operación';

  @override
  String get dateLabel => 'Fecha:';

  @override
  String get spanish => 'Español';

  @override
  String get english => 'Inglés';

  @override
  String get confirmResetTitle => '¿Estás seguro?';

  @override
  String get confirmResetMessage => 'Esta acción eliminará todas tus inversiones.';

  @override
  String get baseCurrency => 'Moneda base';

  @override
  String get selectCurrency => 'Selecciona una moneda';

  @override
  String get exportOperationsToCsv => 'Exportar operaciones a CSV';

  @override
  String get deleteAllPortfolioData => 'Eliminar todos los datos del portafolio';

  @override
  String get portfolioDeletedSuccess => '✅ Portafolio eliminado';

  @override
  String get searchAssetPlaceholder => 'Ej. BTC, Ethereum…';

  @override
  String get operationQuantitySeparator => ' de ';

  @override
  String get permissionRequiredForFile => '❌ Debes conceder permiso para guardar el archivo.';

  @override
  String get permissionPermanentlyDenied => '⚠️ El permiso fue denegado permanentemente.';

  @override
  String get openSettings => 'Abrir ajustes';

  @override
  String fileSavedSuccess(String path) {
    return '✅ Archivo guardado en: $path';
  }

  @override
  String get exportFileError => '❌ Error al exportar el archivo';

  @override
  String get loading => 'Cargando...';
}
