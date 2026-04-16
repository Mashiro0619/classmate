import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/timetable_models.dart';
import '../providers/timetable_provider.dart';

String _formatOutlineColorHex(int colorValue) {
  final rgb = colorValue & 0x00FFFFFF;
  return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

String _formatOutlineWidthValue(double width) {
  return width.toStringAsFixed(width % 1 == 0 ? 0 : 1);
}

int _derivedOutlineColorValue(int themeSeedColorValue) {
  return deriveLiveCourseOutlineColorFromSeed(
    Color(themeSeedColorValue),
  ).toARGB32();
}

class TimetableDisplaySettingsPage extends StatelessWidget {
  const TimetableDisplaySettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TimetableProvider>(
      builder: (context, provider, child) {
        final l10n = AppLocalizations.of(context)!;
        final effectiveOutlineColorValue = provider.liveCourseOutlineFollowTheme
            ? _derivedOutlineColorValue(provider.themeSeedColorValue)
            : provider.liveCourseOutlineColorValue;
        final outlineWidth = provider.liveCourseOutlineWidth;
        return Scaffold(
          appBar: AppBar(title: Text(l10n.timetableDisplaySettings)),
          body: ListView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: [
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                value: provider.closeCoursePopupOnOutsideTap,
                title: Text(l10n.coursePopupDismissSetting),
                subtitle: Text(l10n.coursePopupDismissSettingHint),
                onChanged: provider.updateCloseCoursePopupOnOutsideTap,
              ),
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                value: provider.preserveTimetableGaps,
                title: Text(l10n.preserveTimetableGaps),
                subtitle: Text(l10n.preserveTimetableGapsHint),
                onChanged: provider.updatePreserveTimetableGaps,
              ),
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                value: provider.showPastEndedCourses,
                title: Text(l10n.showPastEndedCourses),
                subtitle: Text(l10n.showPastEndedCoursesHint),
                onChanged: provider.updateShowPastEndedCourses,
              ),
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                value: provider.showFutureCourses,
                title: Text(l10n.showFutureCourses),
                subtitle: Text(l10n.showFutureCoursesHint),
                onChanged: provider.updateShowFutureCourses,
              ),
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                value: provider.showTimetableGridLines,
                title: Text(l10n.showTimetableGridLines),
                subtitle: Text(l10n.showTimetableGridLinesHint),
                onChanged: provider.updateShowTimetableGridLines,
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                leading: _OutlineColorPreview(
                  colorValue: effectiveOutlineColorValue,
                  borderWidth: outlineWidth,
                ),
                title: Text(l10n.liveCourseOutlineSettings),
                subtitle: Text(
                  '${l10n.liveCourseOutlineSettingsHint}\n${_formatOutlineColorHex(effectiveOutlineColorValue)} · ${_formatOutlineWidthValue(outlineWidth)}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _openOutlineSettingsDialog(context, provider),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openOutlineSettingsDialog(
    BuildContext context,
    TimetableProvider provider,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final derivedThemeColorValue = _derivedOutlineColorValue(
      provider.themeSeedColorValue,
    );
    var enabled = provider.liveCourseOutlineEnabled;
    var followTheme = provider.liveCourseOutlineFollowTheme;
    var customColorValue = provider.liveCourseOutlineColorValue;
    var customColorInitialized =
        provider.liveCourseOutlineCustomColorInitialized;
    var outlineWidth = provider.liveCourseOutlineWidth;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final effectiveColorValue = followTheme
                ? derivedThemeColorValue
                : customColorValue;
            return AlertDialog(
              title: Text(l10n.liveCourseOutlineSettings),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.liveCourseOutlineSettingsHint,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: enabled,
                      title: Text(l10n.liveCourseOutlineEnabled),
                      onChanged: (value) => setState(() {
                        enabled = value;
                      }),
                    ),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: followTheme,
                      title: Text(l10n.liveCourseOutlineFollowTheme),
                      onChanged: (value) => setState(() {
                        final initializingCustomColor =
                            followTheme &&
                            !value &&
                            !customColorInitialized;
                        followTheme = value;
                        if (initializingCustomColor) {
                          customColorValue = derivedThemeColorValue;
                          customColorInitialized = true;
                        }
                      }),
                    ),
                    const SizedBox(height: 8),
                    _OutlineColorSummaryRow(
                      label: l10n.liveCourseOutlineEffectiveColor,
                      colorValue: effectiveColorValue,
                      borderWidth: outlineWidth,
                    ),
                    const SizedBox(height: 16),
                    _OutlineWidthSummaryRow(
                      width: outlineWidth,
                    ),
                    Slider.adaptive(
                      value: outlineWidth,
                      min: minLiveCourseOutlineWidth,
                      max: maxLiveCourseOutlineWidth,
                      divisions: 6,
                      label: _formatOutlineWidthValue(outlineWidth),
                      onChanged: (value) => setState(() {
                        outlineWidth = value;
                      }),
                    ),
                    const SizedBox(height: 16),
                    Opacity(
                      opacity: followTheme ? 0.45 : 1,
                      child: IgnorePointer(
                        ignoring: followTheme,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _OutlineColorSummaryRow(
                              label: l10n.liveCourseOutlineCustomColor,
                              colorValue: customColorValue,
                              borderWidth: outlineWidth,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.themeCustomColor,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 12),
                            ColorPicker(
                              pickerColor: Color(customColorValue),
                              onColorChanged: (color) => setState(() {
                                customColorValue = color.toARGB32();
                                customColorInitialized = true;
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
                    await provider.updateLiveCourseOutlineSettings(
                      enabled: enabled,
                      followTheme: followTheme,
                      colorValue: customColorValue,
                      customColorInitialized: customColorInitialized,
                      width: outlineWidth,
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

class _OutlineColorSummaryRow extends StatelessWidget {
  const _OutlineColorSummaryRow({
    required this.label,
    required this.colorValue,
    required this.borderWidth,
  });

  final String label;
  final int colorValue;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        const SizedBox(width: 12),
        _OutlineColorPreview(
          colorValue: colorValue,
          borderWidth: borderWidth,
        ),
        const SizedBox(width: 12),
        Text(_formatOutlineColorHex(colorValue)),
      ],
    );
  }
}

class _OutlineWidthSummaryRow extends StatelessWidget {
  const _OutlineWidthSummaryRow({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            AppLocalizations.of(context)!.liveCourseOutlineWidth,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Text(_formatOutlineWidthValue(width)),
      ],
    );
  }
}

class _OutlineColorPreview extends StatelessWidget {
  const _OutlineColorPreview({
    required this.colorValue,
    required this.borderWidth,
  });

  final int colorValue;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    final color = Color(colorValue);
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        shape: BoxShape.circle,
        border: Border.all(color: color, width: borderWidth),
      ),
    );
  }
}
