/// Heuristik murni untuk mendeteksi tautan berbahaya.
/// Dipisah dari [LinkRepository] agar mudah diuji tanpa HTTP/env.
class LinkHeuristics {
  LinkHeuristics._();

  // Kata kunci kuat: cukup satu kemunculan untuk menandai judol.
  static const List<String> _judolStrong = [
    'judi', 'judol', 'judislot', 'judionline', 'situsjudi', 'judibola',
    'slotgacor', 'slotonline', 'togel', 'togelslot', 'toto4d',
    'gacor', 'maxwin', 'rtpgacor', 'sbobet', 'bet365', '1xbet', 'm88',
    'w88', '188bet', 'cmd368', 'betway', 'fun88', 'bk8', 'dafabet', 'bwin',
    'pragmaticplay', 'pkv', 'bandar', 'casino', 'poker', 'parlay',
    'taruhan', 'linkalternatif', 'agen',
  ];

  // Kata lemah: hanya menandai jika dikombinasikan TLD mencurigakan
  // atau domain penuh angka (pola umum judol).
  static const List<String> _judolWeak = [
    'slot', 'toto', 'qq', 'pulsa', '4d', 'hoki', 'jp', 'livechat',
  ];

  static const List<String> _riskyTlds = [
    '.top', '.bet', '.vip', '.xyz', '.club', '.site', '.cc',
    '.icu', '.cyou', '.live', '.win', '.cam', '.online',
  ];

  static const List<String> _pornKeywords = [
    'pornhub', 'xnxx', 'xvideos', 'redtube', 'youporn', 'brazzers',
    'bokep', 'xhamster', 'tube8', 'hentai', 'spankbang', 'nhentai',
    'faketaxi', 'colmek', 'sange', 'lendir',
  ];

  static const List<String> _malwareKeywords = [
    'keygen', 'nulled', 'crackdownload', 'cracksoftware', 'crack-software',
    'modapk', 'hacktool', 'cheatengine', 'aimbot', 'wallhack', 'spoofer',
    'free-robux', 'free-vbucks', 'free-gems',
    'coinhive', 'cryptoloot', 'minergate', 'xmrpool',
    'stealer', 'grabber', 'botnet', 'ransomware', 'trojan',
    'spyware', 'keylogger', 'phish', 'ngrok.io', 'loca.lt',
  ];

  static const List<String> _safeDomains = [
    'google.com', 'youtube.com', 'facebook.com', 'github.com', 'instagram.com',
    'bri.co.id', 'bca.co.id', 'bankmandiri.co.id', 'bni.co.id', 'bankbsi.co.id',
    'dana.id', 'ovo.id', 'gopay.co.id', 'tokopedia.com', 'bukalapak.com',
    'shopee.co.id',
  ];

  /// Mengambil host dari URL, dengan fallback manual bila tanpa skema.
  static String domainOf(String url) {
    final uri = Uri.tryParse(url);
    final host = uri?.host.toLowerCase() ?? '';
    if (host.isNotEmpty) return host;
    final stripped = url
        .toLowerCase()
        .replaceFirst(RegExp(r'^https?://'), '')
        .split('/')
        .first
        .split('?')
        .first;
    return stripped;
  }

  static String _pathOf(String url) {
    final uri = Uri.tryParse(url);
    return uri?.path.toLowerCase() ?? '';
  }

  static String _normalize(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[-_.]'), '');

  static bool _containsAny(String raw, String norm, List<String> keywords) =>
      keywords.any((k) => raw.contains(k) || norm.contains(k));

  static bool isJudolLink(String url) {
    final domain = domainOf(url);
    final raw = '$domain${_pathOf(url)}';
    final norm = _normalize(raw);

    if (_containsAny(raw, norm, _judolStrong)) return true;

    final hasWeak = _judolWeak.any((k) => norm.contains(k));
    if (!hasWeak) return false;

    final tld = domain.contains('.') ? '.${domain.split('.').last}' : '';
    final riskyTld = _riskyTlds.contains(tld);
    final numericHeavy = RegExp(r'\d').allMatches(domain).length >= 2;
    return riskyTld || numericHeavy;
  }

  static bool isPornLink(String url) {
    final raw = '${domainOf(url)}${_pathOf(url)}';
    return _containsAny(raw, _normalize(raw), _pornKeywords);
  }

  static bool isMalwareOrScamLink(String url) {
    final domain = domainOf(url);
    final raw = '$domain${_pathOf(url)}';
    if (_containsAny(raw, _normalize(raw), _malwareKeywords)) return true;

    // DGA sederhana: label domain panjang berisi konsonan+angka acak.
    final label = domain.split('.').first;
    if (label.length >= 15 &&
        RegExp(r'^[bcdfghjklmnpqrstvwxyz0-9]+$').hasMatch(label)) {
      return true;
    }
    return false;
  }

  /// Domain yang dianggap aman (whitelist), dengan batas label yang benar
  /// sehingga `evil-bri.co.id` atau `bri.co.id.evil.com` tidak lolos.
  static bool isSafeDomain(String url) {
    final domain = domainOf(url);
    return _safeDomains.any((d) => domain == d || domain.endsWith('.$d'));
  }
}
