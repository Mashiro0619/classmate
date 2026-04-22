import '../models/school_import_models.dart';
import '../models/timetable_models.dart';
import 'school_import_api.dart';
import 'school_import_content_sanitizer.dart';

class SchoolImportParserService {
  const SchoolImportParserService({SchoolImportApi? api}) : _api = api;

  final SchoolImportApi? _api;

  Future<SchoolImportApiResult> parse({
    required SchoolImportParseRequest request,
    required SchoolImportParserSettings parserSettings,
  }) async {
    final sanitizedContent = SchoolImportContentSanitizer.sanitize(
      request.source.content.trim(),
    );
    if (sanitizedContent.isEmpty) {
      throw const FormatException('Import content is empty.');
    }
    final api = _api ?? const SchoolImportApi();
    return api.importCurrentPageWithRawResponse(
      SchoolImportPagePayload.fromParseRequest(
        SchoolImportParseRequest(
          source: SchoolImportSourcePayload(
            url: request.source.url,
            title: request.source.title,
            content: sanitizedContent,
          ),
          locale: request.locale,
          sourceHint: request.sourceHint,
        ),
      ),
      parserSettings: parserSettings,
    );
  }
}
