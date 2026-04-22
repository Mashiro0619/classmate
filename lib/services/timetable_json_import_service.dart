import '../models/school_import_models.dart';
import '../models/timetable_models.dart';
import '../providers/timetable_provider.dart';

class TimetableJsonImportPreview {
  const TimetableJsonImportPreview({
    required this.candidates,
    required this.hasBundledPeriodTimeSets,
  });

  final List<TimetableData> candidates;
  final bool hasBundledPeriodTimeSets;
}

class TimetableJsonImportRequest {
  const TimetableJsonImportRequest({
    required this.source,
    required this.timetableIds,
    required this.mode,
    required this.importBundledPeriodTimeSets,
    this.targetPeriodTimeSetId,
  });

  final String source;
  final List<String> timetableIds;
  final TimetableImportMode mode;
  final bool importBundledPeriodTimeSets;
  final String? targetPeriodTimeSetId;
}

class TimetableJsonImportService {
  const TimetableJsonImportService();

  TimetableJsonImportPreview preview(
    TimetableProvider provider,
    String source,
  ) {
    final envelope = ImportExportEnvelope.decode(source);
    final candidates = provider.previewImportTimetables(source);
    final hasBundledPeriodTimeSets = switch (envelope.schema) {
      timetableDataSchema =>
        (envelope.data['periodTimeSets'] as List<dynamic>? ?? const <dynamic>[])
            .isNotEmpty ||
        (envelope.data.containsKey('config') &&
            envelope.data.containsKey('courses')),
      appDataSchema =>
        (envelope.data['periodTimeSets'] as List<dynamic>? ?? const <dynamic>[])
            .isNotEmpty,
      _ => false,
    };
    return TimetableJsonImportPreview(
      candidates: candidates,
      hasBundledPeriodTimeSets: hasBundledPeriodTimeSets,
    );
  }

  Future<int> apply(
    TimetableProvider provider,
    TimetableJsonImportRequest request,
  ) {
    return provider.importSelectedTimetablesJson(
      request.source,
      timetableIds: request.timetableIds,
      mode: request.mode,
      importBundledPeriodTimeSets: request.importBundledPeriodTimeSets,
      targetPeriodTimeSetId: request.targetPeriodTimeSetId,
    );
  }
}
