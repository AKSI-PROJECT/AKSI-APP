import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../../../../data/services/supabase_service.dart';

/// Repositori URL berbasis laporan komunitas (Supabase).
class UrlRepository {
  static final UrlRepository _instance = UrlRepository._();
  factory UrlRepository() => _instance;
  UrlRepository._();

  late final SupabaseClient _client = SupabaseService().client;

  /// Mengembalikan kategori laporan bila URL pernah dilaporkan, else null.
  Future<String?> getReportedCategory(String url) async {
    try {
      final r = await _client
          .from('url_reputations')
          .select('category_tag')
          .eq('url', url.toLowerCase())
          .maybeSingle();
      return r?['category_tag'] as String?;
    } catch (e) {
      debugPrint('UrlRepository.getReportedCategory: $e');
      return null;
    }
  }

  Future<bool> submitReport(String url, String category) async {
    try {
      await _client.rpc('increment_url_report', params: {
        'target_url': url.toLowerCase(),
        'category': category,
      });
      return true;
    } catch (e) {
      debugPrint('UrlRepository.submitReport: $e');
      return false;
    }
  }
}
