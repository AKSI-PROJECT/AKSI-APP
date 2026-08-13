import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'link_heuristics.dart';
import 'url_repository.dart';

enum LinkStatus { safe, dangerous, unknown }

class LinkReputation {
  final LinkStatus status;
  final String message;
  final bool isOffline;

  LinkReputation({
    required this.status,
    required this.message,
    this.isOffline = false,
  });
}

class LinkRepository {
  static const String _gsbCachePrefix = 'gsb_verdict_';
  static const Duration _gsbCacheTtl = Duration(hours: 24);

  final UrlRepository _urlRepository = UrlRepository();

  /// Berlapis: laporan komunitas -> heuristik lokal -> Google Safe Browsing.
  /// Gagal verifikasi -> [LinkStatus.unknown] (fail-closed, bukan "aman").
  Future<LinkReputation> checkLink(String url) async {
    final apiKey =
        dotenv.isInitialized ? dotenv.env['SAFE_BROWSING_API_KEY'] : null;

    String targetUrl = url.trim();
    if (!targetUrl.startsWith('http://') && !targetUrl.startsWith('https://')) {
      targetUrl = 'https://$targetUrl';
    }

    // 1. Laporan komunitas (Supabase).
    final reportedCategory = await _urlRepository.getReportedCategory(targetUrl);
    if (reportedCategory != null) {
      return LinkReputation(
        status: LinkStatus.dangerous,
        message: 'Tautan pernah dilaporkan komunitas sebagai '
            '$reportedCategory. Harap jangan mengaksesnya.',
      );
    }

    // 2. Heuristik lokal.
    if (LinkHeuristics.isJudolLink(targetUrl)) {
      return LinkReputation(
        status: LinkStatus.dangerous,
        message: 'Tautan terindikasi sebagai situs judi online (Judol).',
      );
    }

    if (LinkHeuristics.isPornLink(targetUrl)) {
      return LinkReputation(
        status: LinkStatus.dangerous,
        message: 'Tautan terindikasi sebagai situs bermuatan pornografi.',
      );
    }

    if (LinkHeuristics.isMalwareOrScamLink(targetUrl)) {
      return LinkReputation(
        status: LinkStatus.dangerous,
        message: 'Tautan terindikasi sebagai situs penyebar malware, scam, crack, atau cryptojacking.\n\n'
            'Peringatan: Mengklik tautan sembarangan berisiko mencuri data pribadi, menginfeksi perangkat dengan virus, membobol akun bank, hingga mengambil alih kendali ponsel atau komputer.',
      );
    }

    if (LinkHeuristics.isSafeDomain(targetUrl)) {
      return LinkReputation(
        status: LinkStatus.safe,
        message: 'Tidak ada phishing yang terdeteksi.',
      );
    }

    // 3. Cache hasil Google Safe Browsing (hemat kuota 10k/24 jam).
    final cached = await _cachedVerdict(targetUrl);
    if (cached != null) return cached;

    // 4. Google Safe Browsing API.
    if (apiKey == null || apiKey.isEmpty) {
      debugPrint(
        "Warning: SAFE_BROWSING_API_KEY is not set in .env. "
        "Heuristic found no threat; returning unknown.",
      );
    } else {
      try {
        final verdict = await _callSafeBrowsing(targetUrl, apiKey);
        if (verdict != null) {
          await _cacheVerdict(targetUrl, verdict);
          return verdict;
        }
      } catch (e) {
        debugPrint('Error calling Safe Browsing API: $e');
      }
    }

    // 5. Fail-closed: tanpa sinyal & tanpa verifikasi -> unknown.
    return LinkReputation(
      status: LinkStatus.unknown,
      message: 'Tidak dapat diverifikasi keamanan tautan ini (mode offline). '
          'Hindari membuka tautan jika tidak yakin dengan pengirimnya.',
      isOffline: true,
    );
  }

  Future<LinkReputation?> _callSafeBrowsing(String url, String apiKey) async {
    final apiUrl = Uri.parse(
      'https://safebrowsing.googleapis.com/v4/threatMatches:find',
    );

    final body = jsonEncode({
      "client": {"clientId": "aksi_app", "clientVersion": "1.0.0"},
      "threatInfo": {
        "threatTypes": [
          "MALWARE",
          "SOCIAL_ENGINEERING",
          "UNWANTED_SOFTWARE",
          "POTENTIALLY_HARMFUL_APPLICATION",
        ],
        "platformTypes": ["ANY_PLATFORM"],
        "threatEntryTypes": ["URL"],
        "threatEntries": [
          {"url": url},
        ],
      },
    });

    final response = await http.post(
      apiUrl,
      headers: {
        "Content-Type": "application/json",
        // Key lewat header, bukan query string, agar tidak bocor ke log.
        "X-goog-api-key": apiKey,
      },
      body: body,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data != null &&
          data.containsKey('matches') &&
          (data['matches'] as List).isNotEmpty) {
        return LinkReputation(
          status: LinkStatus.dangerous,
          message: 'Tautan terindikasi berbahaya (Malware/Phishing).\n\n'
              'Peringatan: Mengklik tautan sembarangan berisiko mencuri data pribadi, menginfeksi perangkat dengan virus, membobol akun bank, hingga mengambil alih kendali ponsel atau komputer.',
        );
      }
      return LinkReputation(
        status: LinkStatus.safe,
        message: 'Tidak ada phishing yang terdeteksi.',
      );
    }

    debugPrint("Google Safe Browsing API Error: ${response.statusCode}");
    return null;
  }

  Future<LinkReputation?> _cachedVerdict(String url) async {
    try {
      final domain = LinkHeuristics.domainOf(url);
      if (domain.isEmpty) return null;
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_gsbCachePrefix$domain');
      if (raw == null) return null;

      final data = jsonDecode(raw) as Map<String, dynamic>;
      final cachedAt =
          DateTime.fromMillisecondsSinceEpoch(data['t'] as int);
      if (DateTime.now().difference(cachedAt) > _gsbCacheTtl) {
        await prefs.remove('$_gsbCachePrefix$domain');
        return null;
      }

      final status = LinkStatus.values[data['s'] as int];
      if (status == LinkStatus.safe || status == LinkStatus.dangerous) {
        return LinkReputation(
          status: status,
          message: data['m'] as String,
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _cacheVerdict(String url, LinkReputation verdict) async {
    try {
      final domain = LinkHeuristics.domainOf(url);
      if (domain.isEmpty) return;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        '$_gsbCachePrefix$domain',
        jsonEncode({
          's': verdict.status.index,
          'm': verdict.message,
          't': DateTime.now().millisecondsSinceEpoch,
        }),
      );
    } catch (e) {
      // Cache bersifat best-effort.
    }
  }
}
