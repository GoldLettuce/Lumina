import 'asset_type.dart';

extension AssetTypeExt on AssetType {
  String toFinnhubString() {
    switch (this) {
      case AssetType.stock:
        return 'Common Stock';
      case AssetType.etf:
        return 'ETF';
      case AssetType.commodity:
        return 'Commodity';
      default:
        return '';
    }
  }
}
