import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/timetable_provider.dart';

const _themeSeedOptions = <int>[
  0xFF6750A4,
  0xFF5E35B1,
  0xFF3949AB,
  0xFF1E88E5,
  0xFF00897B,
  0xFF2E7D32,
  0xFF7CB342,
  0xFFF9A825,
  0xFFEF6C00,
  0xFFF4511E,
  0xFFD81B60,
  0xFFC2185B,
  0xFF6D4C41,
  0xFF455A64,
  0xFF546E7A,
];

bool _isPresetThemeColor(int colorValue) => _themeSeedOptions.contains(colorValue);

String _formatThemeColorHex(int colorValue) {
  final rgb = colorValue & 0x00FFFFFF;
  return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

class ThemeSettingsPage extends StatelessWidget {
  const ThemeSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TimetableProvider>(
      builder: (context, provider, child) {
        final l10n = AppLocalizations.of(context)!;
        final hasCustomColor = !_isPresetThemeColor(
          provider.themeSeedColorValue,
        );
        return Scaffold(
          appBar: AppBar(title: Text(l10n.theme)),
          body: ListView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                title: Text(l10n.themeFollowSystem),
                trailing: provider.themeMode == 'system'
                    ? const Icon(Icons.check)
                    : null,
                onTap: () => provider.updateThemeMode('system'),
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                title: Text(l10n.themeLight),
                trailing: provider.themeMode == 'light'
                    ? const Icon(Icons.check)
                    : null,
                onTap: () => provider.updateThemeMode('light'),
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                title: Text(l10n.themeDark),
                trailing: provider.themeMode == 'dark'
                    ? const Icon(Icons.check)
                    : null,
                onTap: () => provider.updateThemeMode('dark'),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  l10n.themeColor,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _themeSeedOptions.length,
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 104,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    mainAxisExtent: 52,
                  ),
                  itemBuilder: (context, index) {
                    final colorValue = _themeSeedOptions[index];
                    return _ThemeColorOption(
                      colorValue: colorValue,
                      selected: provider.themeSeedColorValue == colorValue,
                      onTap: () => provider.updateThemeSeedColorValue(colorValue),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                leading: _ThemeColorPreview(
                  colorValue: provider.themeSeedColorValue,
                  selected: hasCustomColor,
                ),
                title: Text(l10n.themeCustomColor),
                subtitle: hasCustomColor
                    ? Text(_formatThemeColorHex(provider.themeSeedColorValue))
                    : null,
                trailing: hasCustomColor
                    ? const Icon(Icons.check)
                    : const Icon(Icons.chevron_right),
                onTap: () => _openCustomColorDialog(context, provider),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openCustomColorDialog(
    BuildContext context,
    TimetableProvider provider,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    var selectedColor = Color(provider.themeSeedColorValue);
    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(l10n.themeCustomColor),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          l10n.themeColor,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(width: 12),
                        _ThemeColorPreview(
                          colorValue: selectedColor.toARGB32(),
                          selected: true,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _formatThemeColorHex(selectedColor.toARGB32()),
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ColorPicker(
                      pickerColor: selectedColor,
                      onColorChanged: (color) => setState(() {
                        selectedColor = color;
                      }),
                      enableAlpha: false,
                      displayThumbColor: true,
                      portraitOnly: true,
                      labelTypes: const [],
                      paletteType: PaletteType.hsvWithHue,
                      hexInputBar: true,
                      pickerAreaHeightPercent: 0.7,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  onPressed: () async {
                    await provider.updateThemeSeedColorValue(
                      selectedColor.toARGB32(),
                    );
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: Text(l10n.themeApplyCustomColor),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _ThemeColorOption extends StatelessWidget {
  const _ThemeColorOption({
    required this.colorValue,
    required this.selected,
    required this.onTap,
  });

  final int colorValue;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: _ThemeColorPreview(
        colorValue: colorValue,
        selected: selected,
        onTap: onTap,
      ),
    );
  }
}

class _ThemeColorPreview extends StatelessWidget {
  const _ThemeColorPreview({
    required this.colorValue,
    required this.selected,
    this.onTap,
  });

  final int colorValue;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = Color(colorValue);
    final child = Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected
              ? Theme.of(context).colorScheme.onSurface
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: selected
          ? Icon(
              Icons.check,
              color: ThemeData.estimateBrightnessForColor(color) ==
                      Brightness.dark
                  ? Colors.white
                  : Colors.black,
            )
          : null,
    );
    if (onTap == null) {
      return child;
    }
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: child,
    );
  }
}
