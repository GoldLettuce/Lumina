import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lumina/ui/providers/settings_provider.dart';
import '../../l10n/app_localizations.dart';

class AssetIconVisibilitySelector extends StatelessWidget {
  const AssetIconVisibilitySelector({super.key});

  static Future<void> show(BuildContext context) async {
    final t = AppLocalizations.of(context)!;
    final provider = context.read<SettingsProvider>();
    final current = provider.assetIconVisibility;

    final result = await showModalBottomSheet<AssetIconVisibility>(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              color: Theme.of(context).colorScheme.surface,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                Text(
                  t.assetIconVisibilityTitle,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: 2,
                    itemBuilder: (context, index) {
                      final options = <Map<String, dynamic>>[
                        {'value': AssetIconVisibility.show, 'name': t.assetIconVisibilityShow},
                        {'value': AssetIconVisibility.hide, 'name': t.assetIconVisibilityHide},
                      ];
                      final option = options[index];
                      final isSelected = option['value'] == current;
                      return InkWell(
                         onTap: () => Navigator.of(context).pop(option['value'] as AssetIconVisibility),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                 child: Text(
                                   option['name'] as String,
                                   style: TextStyle(
                                     fontSize: 16,
                                     color: Theme.of(context).colorScheme.onSurface,
                                   ),
                                 ),
                               ),
                              if (isSelected)
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (result != null) {
      provider.assetIconVisibility = result;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final current = context.watch<SettingsProvider>().assetIconVisibility;

    final subtitle = {
      AssetIconVisibility.show: t.assetIconVisibilityShow,
      AssetIconVisibility.hide: t.assetIconVisibilityHide,
    }[current]!;

    return ListTile(
      title: Text(t.assetIconVisibilityTitle),
      subtitle: Text(subtitle),
      onTap: () => show(context),
    );
  }
} 