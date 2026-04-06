import 'package:flutter/services.dart';

import '../models/school_site_models.dart';
import 'school_site_store.dart';

class SchoolSiteService {
  const SchoolSiteService({SchoolSiteStore? store}) : _store = store ?? const SchoolSiteStore();

  static const schoolSitesAssetPath = 'assets/school_sites.json';

  final SchoolSiteStore _store;

  Future<List<SchoolSite>> loadSites() async {
    final stored = await _store.load();
    if (stored != null && stored.trim().isNotEmpty) {
      return decodeSchoolSites(stored);
    }
    final source = await rootBundle.loadString(schoolSitesAssetPath);
    return decodeSchoolSites(source);
  }

  Future<void> saveSites(List<SchoolSite> sites) async {
    await _store.save(encodeSchoolSites(sites));
  }

  Future<String> exportSites(List<SchoolSite> sites) async {
    return encodeSchoolSites(sites);
  }

  Future<List<SchoolSite>> importSites(String source) async {
    final sites = decodeSchoolSites(source);
    await saveSites(sites);
    return sites;
  }

  Future<String?> storagePath() => _store.filePath();
}
