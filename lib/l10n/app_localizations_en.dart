// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'My Portfolio';

  @override
  String get dailyPL => 'Daily P/L | 0.00 € 0.00%';

  @override
  String get openPL => 'Open P/L | 4,328.47 € 1.17%';

  @override
  String get graphPlaceholder => 'Graph placeholder';

  @override
  String get quantity => 'Quantity';

  @override
  String get noInvestments => 'No investments';

  @override
  String get emptyPortfolioMessage => 'No investments yet.\nStart by adding your first one!';

  @override
  String get newOperation => 'New Operation';

  @override
  String get assetType => 'Asset Type';

  @override
  String get selectAssetType => 'Select a type';

  @override
  String get symbol => 'Symbol';

  @override
  String get selectSymbol => 'Select a symbol';

  @override
  String get buy => 'Buy';

  @override
  String get sell => 'Sell';

  @override
  String get fieldRequired => 'Field required';

  @override
  String get invalidQuantity => 'Invalid quantity';

  @override
  String get unitPrice => 'Price per unit';

  @override
  String get invalidPrice => 'Invalid price';

  @override
  String get date => 'Date';

  @override
  String get selectDate => 'Select date';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get sellAll => 'Sell All';

  @override
  String get exceedQuantity => 'Quantity exceeds available';

  @override
  String get searchAsset => 'Search asset';

  @override
  String get notEnoughChartData => 'Not enough data to display the chart';

  @override
  String get archivedAssetsTitle => 'Archived assets';

  @override
  String get noArchivedAssets => 'No hidden assets found.';

  @override
  String get settings => 'Settings';

  @override
  String get theme => 'Theme';

  @override
  String get themeOptions => 'Theme Options';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeLightMono => 'Light Mono';

  @override
  String get themeDarkMono => 'Dark Mono';

  @override
  String get language => 'Language';

  @override
  String get loadSymbolsError => 'Failed to load symbols';

  @override
  String get noSymbolsFound => 'No symbols found';

  @override
  String get deleteOperations => 'Delete operations';

  @override
  String get deleteOperationsMessage => 'Are you sure you want to delete the selected operations? This action cannot be undone.';

  @override
  String get delete => 'Delete';

  @override
  String get noOperations => 'No operations recorded.';

  @override
  String get editOperation => 'Edit operation';

  @override
  String get selectOperationType => 'Select operation type';

  @override
  String get dateLabel => 'Date:';

  @override
  String get spanish => 'Spanish';

  @override
  String get english => 'English';

  @override
  String get confirmResetTitle => 'Are you sure?';

  @override
  String get confirmResetMessage => 'This action will delete all your investments.';

  @override
  String get baseCurrency => 'Base currency';

  @override
  String get selectCurrency => 'Select a currency';

  @override
  String get selectLanguage => 'Select a language';

  @override
  String get exportOperationsToCsv => 'Export operations to CSV';

  @override
  String get deleteAllPortfolioData => 'Delete all portfolio data';

  @override
  String get portfolioDeletedSuccess => '✅ Portfolio deleted';

  @override
  String get searchAssetPlaceholder => 'E.g. BTC, Ethereum…';

  @override
  String get operationQuantitySeparator => ' of ';

  @override
  String get permissionRequiredForFile => '❌ You must grant permission to save the file.';

  @override
  String get permissionPermanentlyDenied => '⚠️ Permission was permanently denied.';

  @override
  String get openSettings => 'Open settings';

  @override
  String fileSavedSuccess(String path) {
    return '✅ File saved at: $path';
  }

  @override
  String get exportFileError => '❌ Error while exporting file';

  @override
  String get loading => 'Loading...';

  @override
  String get donationsTitle => '☕ Donations';

  @override
  String get donationsMessage => 'Thank you for using Lumina!';

  @override
  String get ok => 'OK';

  @override
  String currencyFormat(String currency, String name) {
    return '$currency – $name';
  }

  @override
  String get assetIconVisibilityTitle => 'Show asset icons';

  @override
  String get assetIconVisibilityShow => 'Show icons';

  @override
  String get assetIconVisibilityHide => 'Hide icons';
}
