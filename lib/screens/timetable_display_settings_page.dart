import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/timetable_provider.dart';

class TimetableDisplaySettingsPage extends StatelessWidget {
  const TimetableDisplaySettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TimetableProvider>(
      builder: (context, provider, child) {
        final l10n = AppLocalizations.of(context);
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
            ],
          ),
        );
      },
    );
  }
}
