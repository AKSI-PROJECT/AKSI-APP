import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

enum LinkStatus { safe, dangerous, unknown }

class LinkReputation {
  final LinkStatus status;
  final String message;
  final bool isOffline;

  LinkReputation({required this.status, required this.message, this.isOffline = false});
}

class LinkRepository {
  bool _isJudolLink(String url) {
    final urlString = url.toLowerCase();
    
    // Exact keywords that strongly indicate a judol site
    final judolKeywords = [
      'slotgacor', 'judionline', 'togel', 'situsjudi', 'maxwin', 'pragmaticplay',
      'gacor', 'rtpgacor', 'linkalternatif', 'sbobet', 'judol', 'judislot',
      'poker', 'casino', 'parlay', 'zeus', '1xbet', 'm88', 'bet365', 'w88',
      'dafabet', 'bwin', '188bet', 'sbo', 'cmd368', 'betway', 'fun88', 'bk8'
    ];

    // Regex patterns for combinations of keywords and numbers 
    // to avoid false positives with normal words (e.g., "better", "alphabet")
    final judolPatterns = [
      RegExp(r'(qq|bet|slot|toto|jp|cuan|hoki)\d+'), // e.g. qq888, bet365, slot88
      RegExp(r'\d+(qq|bet|slot|toto|jp|cuan|hoki)'), // e.g. 188bet, 77slot
      RegExp(r'(qq|slot|toto).*bet|bet.*(qq|slot|toto)'), // e.g. qq888bet
    ];
    
    final uri = Uri.tryParse(urlString);
    final domain = uri?.host ?? '';
    final path = uri?.path ?? '';
    
    // Fallback if URI parsing fails
    final stringToCheck = uri != null ? '$domain$path' : urlString;

    // 1. Check exact keywords
    for (var keyword in judolKeywords) {
      if (stringToCheck.contains(keyword)) {
        return true;
      }
    }

    // 2. Check regex patterns (primarily on domain to reduce false positives)
    final domainToCheck = domain.isNotEmpty ? domain : urlString;
    for (var pattern in judolPatterns) {
      if (pattern.hasMatch(domainToCheck)) {
        return true;
      }
    }

    return false;
  }

  bool _isPornLink(String url) {
    final urlString = url.toLowerCase();
    
    // Keywords that strongly indicate pornographic content
    final pornKeywords = [
      'pornhub', 'xnxx', 'xvideos', 'redtube', 'youporn', 'brazzers', 
      'bokep', 'xhamster', 'tube8', 'hentai', 'spankbang', 'nhentai', 
      'faketaxi', 'colmek', 'sange', 'lendir'
    ];

    final uri = Uri.tryParse(urlString);
    final domain = uri?.host ?? '';
    final path = uri?.path ?? '';
    
    final stringToCheck = uri != null ? '$domain$path' : urlString;

    for (var keyword in pornKeywords) {
      if (stringToCheck.contains(keyword)) {
        // avoid false positives for 'jav' since it's common for java/javascript, 
        // so we didn't include it in the array
        return true;
      }
    }
    
    return false;
  }

  bool _isMalwareOrScamLink(String url) {
    final urlString = url.toLowerCase();
    
    // Kata kunci untuk crack, keygen, cryptojacking, dan scam/malware
    final malwareKeywords = [
      'keygen', 'nulled', 'crackdownload', 'crack-software', 'modapk',
      'hacktool', 'cheatengine', 'aimbot', 'wallhack', 'spoofer',
      'free-robux', 'free-vbucks', 'free-gems', // Scam game currency
      'coinhive', 'cryptoloot', 'minergate', 'xmrpool', // Cryptojacking
      'stealer', 'grabber', 'botnet', 'ransomware', 'trojan', // C2/Malware
      'spyware', 'keylogger', 'rat', 'phish', 'ngrok.io', 'loca.lt' // RAT & Tunnels
    ];

    final uri = Uri.tryParse(urlString);
    final domain = uri?.host ?? '';
    final path = uri?.path ?? '';
    
    final stringToCheck = uri != null ? '$domain$path' : urlString;

    for (var keyword in malwareKeywords) {
      if (stringToCheck.contains(keyword)) {
        return true;
      }
    }
    
    // Deteksi DGA (Domain Generation Algorithm) sederhana 
    // Jika domain panjang dan isinya kebanyakan konsonan acak
    final dgaPattern = RegExp(r'^[bcdfghjklmnpqrstvwxyz0-9]{15,}\.');
    if (domain.isNotEmpty && dgaPattern.hasMatch(domain)) {
       return true;
    }

    return false;
  }

  Future<LinkReputation> checkLink(String url) async {
    final apiKey = dotenv.env['SAFE_BROWSING_API_KEY'];

    String targetUrl = url.trim();
    if (!targetUrl.startsWith('http://') && !targetUrl.startsWith('https://')) {
      targetUrl = 'https://$targetUrl';
    }

    if (_isJudolLink(targetUrl)) {
      return LinkReputation(
        status: LinkStatus.dangerous,
        message: 'Tautan terindikasi sebagai situs judi online (Judol).',
      );
    }

    if (_isPornLink(targetUrl)) {
      return LinkReputation(
        status: LinkStatus.dangerous,
        message: 'Tautan terindikasi sebagai situs bermuatan pornografi.',
      );
    }

    if (_isMalwareOrScamLink(targetUrl)) {
      return LinkReputation(
        status: LinkStatus.dangerous,
        message: 'Tautan terindikasi sebagai situs penyebar malware, scam, crack, atau cryptojacking.\n\n'
            'Peringatan: Mengklik tautan sembarangan berisiko mencuri data pribadi, menginfeksi perangkat dengan virus, membobol akun bank, hingga mengambil alih kendali ponsel atau komputer.',
      );
    }

    if (apiKey == null || apiKey.isEmpty) {
      debugPrint(
        "Warning: SAFE_BROWSING_API_KEY is not set in .env. Using basic heuristic.",
      );
      return _basicHeuristicCheck(targetUrl, isOffline: true);
    }

    try {
      final apiUrl = Uri.parse(
        'https://safebrowsing.googleapis.com/v4/threatMatches:find?key=$apiKey',
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
            {"url": targetUrl},
          ],
        },
      });

      final response = await http.post(
        apiUrl,
        headers: {"Content-Type": "application/json"},
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
        } else {
          return LinkReputation(
            status: LinkStatus.safe,
            message: 'Tidak ada phishing yang terdeteksi.',
          );
        }
      } else {
        debugPrint("Google Safe Browsing API Error: ${response.statusCode}");
        return _basicHeuristicCheck(targetUrl, isOffline: true);
      }
    } catch (e) {
      debugPrint("Error calling Safe Browsing API: $e");
      return _basicHeuristicCheck(targetUrl, isOffline: true);
    }
  }

  LinkReputation _basicHeuristicCheck(String url, {bool isOffline = false}) {
    final suspiciousKeywords = [
      'login', 'update', 'secure', 'verify', 'account', 'banking', 'free', 'bonus',
      'bri', 'bca', 'mandiri', 'bni', 'bsi', 'brimo', 'livin', 'dana', 'ovo', 'gopay', 'promosi', 'hadiah', 'undian'
    ];
    final domain = Uri.tryParse(url)?.host.toLowerCase() ?? '';

    final safeDomains = [
      'google.com', 'youtube.com', 'facebook.com', 'github.com', 'instagram.com',
      'bri.co.id', 'bca.co.id', 'bankmandiri.co.id', 'bni.co.id', 'bankbsi.co.id', 'dana.id', 'ovo.id'
    ];
    if (safeDomains.any((d) => domain.endsWith(d))) {
      return LinkReputation(
        status: LinkStatus.safe,
        message: 'Tidak ada phishing yang terdeteksi.',
        isOffline: isOffline,
      );
    }

    int suspicionScore = 0;
    for (var word in suspiciousKeywords) {
      if (domain.contains(word)) suspicionScore++;
    }

    final isIp = RegExp(
      r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$',
    ).hasMatch(domain);
    if (isIp) suspicionScore += 2;

    if (suspicionScore > 1) {
      return LinkReputation(
        status: LinkStatus.dangerous,
        message: 'Tautan mencurigakan (memiliki pola domain phishing).\n\n'
            'Peringatan: Mengklik tautan sembarangan berisiko mencuri data pribadi, menginfeksi perangkat dengan virus, membobol akun bank, hingga mengambil alih kendali ponsel atau komputer.',
        isOffline: isOffline,
      );
    }

    return LinkReputation(
      status: LinkStatus.safe,
      message: 'Tidak ada phishing yang terdeteksi.',
      isOffline: isOffline,
    );
  }
}
