import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'My Portfolio'**
  String get appTitle;

  /// No description provided for @dailyPL.
  ///
  /// In en, this message translates to:
  /// **'Daily P/L | 0.00 € 0.00%'**
  String get dailyPL;

  /// No description provided for @openPL.
  ///
  /// In en, this message translates to:
  /// **'Open P/L | 4,328.47 € 1.17%'**
  String get openPL;

  /// No description provided for @graphPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Graph placeholder'**
  String get graphPlaceholder;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @noInvestments.
  ///
  /// In en, this message translates to:
  /// **'No investments'**
  String get noInvestments;

  /// No description provided for @emptyPortfolioMessage.
  ///
  /// In en, this message translates to:
  /// **'No investments yet.\nStart by adding your first one!'**
  String get emptyPortfolioMessage;

  /// No description provided for @newOperation.
  ///
  /// In en, this message translates to:
  /// **'New Operation'**
  String get newOperation;

  /// No description provided for @assetType.
  ///
  /// In en, this message translates to:
  /// **'Asset Type'**
  String get assetType;

  /// No description provided for @selectAssetType.
  ///
  /// In en, this message translates to:
  /// **'Select a type'**
  String get selectAssetType;

  /// No description provided for @symbol.
  ///
  /// In en, this message translates to:
  /// **'Symbol'**
  String get symbol;

  /// No description provided for @selectSymbol.
  ///
  /// In en, this message translates to:
  /// **'Select a symbol'**
  String get selectSymbol;

  /// No description provided for @buy.
  ///
  /// In en, this message translates to:
  /// **'Buy'**
  String get buy;

  /// No description provided for @sell.
  ///
  /// In en, this message translates to:
  /// **'Sell'**
  String get sell;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'Field required'**
  String get fieldRequired;

  /// No description provided for @invalidQuantity.
  ///
  /// In en, this message translates to:
  /// **'Invalid quantity'**
  String get invalidQuantity;

  /// No description provided for @unitPrice.
  ///
  /// In en, this message translates to:
  /// **'Unit Price (€)'**
  String get unitPrice;

  /// No description provided for @invalidPrice.
  ///
  /// In en, this message translates to:
  /// **'Invalid price'**
  String get invalidPrice;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get selectDate;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @sellAll.
  ///
  /// In en, this message translates to:
  /// **'Sell All'**
  String get sellAll;

  /// No description provided for @exceedQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity exceeds available'**
  String get exceedQuantity;

  /// No description provided for @searchAsset.
  ///
  /// In en, this message translates to:
  /// **'Search asset'**
  String get searchAsset;

  /// No description provided for @notEnoughChartData.
  ///
  /// In en, this message translates to:
  /// **'Not enough data to display the chart'**
  String get notEnoughChartData;

  /// No description provided for @archivedAssetsTitle.
  ///
  /// In en, this message translates to:
  /// **'Archived assets'**
  String get archivedAssetsTitle;

  /// No description provided for @noArchivedAssets.
  ///
  /// In en, this message translates to:
  /// **'No hidden assets found.'**
  String get noArchivedAssets;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeOptions.
  ///
  /// In en, this message translates to:
  /// **'Theme Options'**
  String get themeOptions;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeLightMono.
  ///
  /// In en, this message translates to:
  /// **'Light Mono'**
  String get themeLightMono;

  /// No description provided for @themeDarkMono.
  ///
  /// In en, this message translates to:
  /// **'Dark Mono'**
  String get themeDarkMono;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @loadSymbolsError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load symbols'**
  String get loadSymbolsError;

  /// No description provided for @noSymbolsFound.
  ///
  /// In en, this message translates to:
  /// **'No symbols found'**
  String get noSymbolsFound;

  /// No description provided for @deleteOperations.
  ///
  /// In en, this message translates to:
  /// **'Delete operations'**
  String get deleteOperations;

  /// No description provided for @deleteOperationsMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the selected operations? This action cannot be undone.'**
  String get deleteOperationsMessage;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @noOperations.
  ///
  /// In en, this message translates to:
  /// **'No operations recorded.'**
  String get noOperations;

  /// No description provided for @editOperation.
  ///
  /// In en, this message translates to:
  /// **'Edit operation'**
  String get editOperation;

  /// No description provided for @selectOperationType.
  ///
  /// In en, this message translates to:
  /// **'Select operation type'**
  String get selectOperationType;

  /// No description provided for @dateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date:'**
  String get dateLabel;

  /// No description provided for @spanish.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get spanish;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @confirmResetTitle.
  ///
  /// In en, this message translates to:
  /// **'Are you sure?'**
  String get confirmResetTitle;

  /// No description provided for @confirmResetMessage.
  ///
  /// In en, this message translates to:
  /// **'This action will delete all your investments.'**
  String get confirmResetMessage;

  /// No description provided for @baseCurrency.
  ///
  /// In en, this message translates to:
  /// **'Base currency'**
  String get baseCurrency;

  /// No description provided for @selectCurrency.
  ///
  /// In en, this message translates to:
  /// **'Select a currency'**
  String get selectCurrency;

  /// No description provided for @exportOperationsToCsv.
  ///
  /// In en, this message translates to:
  /// **'Export operations to CSV'**
  String get exportOperationsToCsv;

  /// No description provided for @deleteAllPortfolioData.
  ///
  /// In en, this message translates to:
  /// **'Delete all portfolio data'**
  String get deleteAllPortfolioData;

  /// No description provided for @portfolioDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'✅ Portfolio deleted'**
  String get portfolioDeletedSuccess;

  /// No description provided for @searchAssetPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'E.g. BTC, Ethereum…'**
  String get searchAssetPlaceholder;

  /// No description provided for @operationQuantitySeparator.
  ///
  /// In en, this message translates to:
  /// **' of '**
  String get operationQuantitySeparator;

  /// No description provided for @permissionRequiredForFile.
  ///
  /// In en, this message translates to:
  /// **'❌ You must grant permission to save the file.'**
  String get permissionRequiredForFile;

  /// No description provided for @permissionPermanentlyDenied.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Permission was permanently denied.'**
  String get permissionPermanentlyDenied;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get openSettings;

  /// No description provided for @fileSavedSuccess.
  ///
  /// In en, this message translates to:
  /// **'✅ File saved at: {path}'**
  String fileSavedSuccess(String path);

  /// No description provided for @exportFileError.
  ///
  /// In en, this message translates to:
  /// **'❌ Error while exporting file'**
  String get exportFileError;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @donationsTitle.
  ///
  /// In en, this message translates to:
  /// **'☕ Donations'**
  String get donationsTitle;

  /// No description provided for @donationsMessage.
  ///
  /// In en, this message translates to:
  /// **'Thank you for using Lumina!'**
  String get donationsMessage;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @currencyFormat.
  ///
  /// In en, this message translates to:
  /// **'{currency} – {name}'**
  String currencyFormat(String currency, String name);
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'es': return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
