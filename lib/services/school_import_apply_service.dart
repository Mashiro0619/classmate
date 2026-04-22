import '../models/school_import_models.dart';
import '../providers/timetable_provider.dart';

class SchoolImportApplyService {
  const SchoolImportApplyService();

  Future<void> apply(
    TimetableProvider provider,
    SchoolImportApplyRequest request,
  ) {
    return provider.applySchoolImportRequest(request);
  }
}
