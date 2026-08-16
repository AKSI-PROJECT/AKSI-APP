import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../data/services/supabase_service.dart';
import '../models/email_reputation.dart';
import '../models/email_tag.dart';
import 'package:flutter/foundation.dart';

class ApiEmailReputation {
  final String email;
  final String reputation;
  final bool suspicious;
  final int references;
  final Map<String, dynamic> details;
  final bool isOffline;

  ApiEmailReputation({
    required this.email,
    required this.reputation,
    required this.suspicious,
    required this.references,
    required this.details,
    this.isOffline = false,
  });

  factory ApiEmailReputation.fromJson(Map<String, dynamic> json) {
    return ApiEmailReputation(
      email: json['email'] ?? '',
      reputation: json['reputation'] ?? 'none',
      suspicious: json['suspicious'] ?? false,
      references: json['references'] ?? 0,
      details: json['details'] ?? {},
      isOffline: false,
    );
  }
}

class EmailRepository {
  // Lazy agar repositori bisa dikonstruksi & diuji tanpa Supabase terinisialisasi.
  SupabaseClient get _client => SupabaseService().client;

  Future<bool> _hasInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<ApiEmailReputation?> checkEmailReputationAPI(
    String emailAddress,
  ) async {
    final emailClean = emailAddress.toLowerCase().trim();

    // 1. Cek Laporan Komunitas Dulu
    final localReputation = await getEmailReputation(emailClean);
    if (localReputation != null) {
      final tags = await getEmailTags(localReputation.id);
      if (tags.isNotEmpty) {
        final reason = tags.first.tagName;
        return ApiEmailReputation(
          email: emailClean,
          reputation: 'low',
          suspicious: true,
          references: localReputation.trustScore,
          details: {
            'malicious_activity': true,
            'reason': 'Pernah dilaporkan komunitas sebagai "$reason". Harap berhati-hati karena laporan belum diverifikasi admin.'
          },
          isOffline: false,
        );
      }
    }
    
    bool hasInternet = await _hasInternet();
    
    if (!hasInternet) {
      return await _fallbackCheck(emailClean, isOffline: true);
    }

    try {
      final url = Uri.parse('https://emailrep.io/$emailClean');
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'aksi-app-flutter/1.0',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ApiEmailReputation.fromJson(data);
      } else {
        debugPrint('EmailRep API Error: ${response.statusCode}');
        return await _fallbackCheck(emailClean, isOffline: false);
      }
    } catch (e) {
      debugPrint('Error checking email reputation via API: $e');
      return await _fallbackCheck(emailClean, isOffline: false);
    }
  }

  Future<ApiEmailReputation> _fallbackCheck(String email, {bool isOffline = false}) async {
    final localReputation = await getEmailReputation(email);
    if (localReputation != null) {
      bool suspicious = localReputation.trustScore < 50;
      return ApiEmailReputation(
        email: email,
        reputation: suspicious ? 'low' : 'high',
        suspicious: suspicious,
        references: 1,
        details: {'malicious_activity': suspicious},
        isOffline: isOffline,
      );
    }

    final parts = email.split('@');
    if (parts.length != 2) {
      return ApiEmailReputation(
        email: email,
        reputation: 'none',
        suspicious: true,
        references: 0,
        details: {},
        isOffline: isOffline,
      );
    }
    final prefix = parts[0];
    final domain = parts[1];

    final freeDomains = [
      'gmail.com',
      'yahoo.com',
      'outlook.com',
      'hotmail.com',
    ];
    final officialKeywords = [
      'hrd', 'rekrutmen', 'admin', 'cs', 'support', 'official', 'customer', 'info',
      'bca', 'bri', 'bni', 'mandiri', 'bsi', 'dana', 'ovo', 'gopay', 'shopee'
    ];

    bool isSuspicious = false;
    Map<String, dynamic> details = {};

    if (freeDomains.contains(domain)) {
      bool pretendsOfficial = officialKeywords.any((kw) => prefix.contains(kw));
      if (pretendsOfficial) {
        isSuspicious = true;
        details['malicious_activity'] = true;
        details['reason'] = 'Email mencurigakan (menyamar sebagai pihak resmi).\n\n'
            'Peringatan: Mengklik tautan atau mengunduh aplikasi dari sembarang email berisiko mencuri data pribadi, menginfeksi perangkat dengan virus, membobol akun bank, hingga mengambil alih kendali ponsel atau komputer.';
      }
    }

    final judolKeywords = [
      'slot', 'judi', 'togel', 'maxwin', 'gacor', 'sbobet', '1xbet', 'm88', 'bet365', 'poker', 'casino'
    ];
    
    bool containsJudol = judolKeywords.any((kw) => email.contains(kw));
    if (containsJudol) {
      isSuspicious = true;
      details['judol_activity'] = true;
      details['reason'] = 'Email mengandung kata kunci judi online.\n\n'
          'Peringatan: Mengklik tautan atau berinteraksi dengan email sembarangan berisiko membahayakan data pribadi dan finansial Anda.';
    }

    return ApiEmailReputation(
      email: email,
      reputation: isSuspicious ? 'low' : 'high',
      suspicious: isSuspicious,
      references: 0,
      details: details,
      isOffline: isOffline,
    );
  }

  Future<EmailReputation?> getEmailReputation(String emailAddress) async {
    try {
      final response = await _client
          .from('email_reputations')
          .select()
          .eq('email_address', emailAddress.toLowerCase().trim())
          .maybeSingle();

      if (response == null) return null;
      return EmailReputation.fromJson(response);
    } catch (e) {
      debugPrint('Error getting email reputation: $e');
      return null;
    }
  }

  Future<List<EmailTag>> getEmailTags(String emailId) async {
    try {
      final response = await _client
          .from('email_tags')
          .select()
          .eq('email_id', emailId)
          .order('upvotes', ascending: false);

      return (response as List).map((t) => EmailTag.fromJson(t)).toList();
    } catch (e) {
      debugPrint('Error getting email tags: $e');
      return [];
    }
  }

  Future<void> upvoteTag(String tagId) async {
    try {
      await _client.rpc('increment_tag_upvote', params: {'tag_id': tagId});
    } catch (e) {
      debugPrint('Error upvoting tag: $e');
    }
  }

  Future<String?> submitScamReport({
    required String emailAddress,
    required String categoryTag,
    required File evidenceImage,
    String? description,
  }) async {
    try {
      final emailClean = emailAddress.toLowerCase().trim();
      final domain = emailClean.split('@').last;

      var emailRecord = await _client
          .from('email_reputations')
          .select()
          .eq('email_address', emailClean)
          .maybeSingle();

      if (emailRecord == null) {
        final insertResponse = await _client
            .from('email_reputations')
            .insert({
              'email_address': emailClean,
              'domain': domain,
              'trust_score': 30,
            })
            .select()
            .single();
        emailRecord = insertResponse;
      }

      final emailId = emailRecord['id'];
      final userId = _client.auth.currentUser?.id;

      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storagePath = userId != null ? '$userId/$fileName' : 'public/$fileName';

      await _client.storage
          .from('evidence_bucket')
          .upload(storagePath, evidenceImage);

      final evidenceUrl = _client.storage
          .from('evidence_bucket')
          .getPublicUrl(storagePath);

      final reportData = {
        if (userId != null) 'reporter_id': userId,
        'email_id': emailId,
        'category_tag': categoryTag,
        'evidence_url': evidenceUrl,
        'description': description,
      };

      await _client.from('community_reports').insert(reportData);

      try {
        await _client.from('email_tags').insert({
          'email_id': emailId,
          'tag_name': categoryTag,
          'upvotes': 1,
        });
      } catch (e) {
        debugPrint('Tag might already exist: $e');
      }

      return null;
    } on PostgrestException catch (e) {
      debugPrint('PostgrestException: ${e.message}');
      return e.message;
    } on StorageException catch (e) {
      debugPrint('StorageException: ${e.message}');
      return e.message;
    } catch (e) {
      debugPrint('Error submitting scam report: $e');
      return e.toString();
    }
  }
}
