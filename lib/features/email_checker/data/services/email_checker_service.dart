import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../data/services/supabase_service.dart';
import '../models/email_reputation_model.dart';

class EmailCheckerService {
  final SupabaseClient _client = SupabaseService().client;

  Future<EmailReputationModel?> getEmailReputation(String emailAddress) async {
    try {
      final response = await _client
          .from('email_reputations')
          .select()
          .eq('email_address', emailAddress)
          .maybeSingle();

      if (response != null) {
        return EmailReputationModel.fromJson(response);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch email reputation: $e');
    }
  }

  Future<List<EmailTagModel>> getEmailTags(String emailId) async {
    try {
      final response = await _client
          .from('email_tags')
          .select()
          .eq('email_id', emailId)
          .order('upvotes', ascending: false);

      return (response as List<dynamic>)
          .map((json) => EmailTagModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch email tags: $e');
    }
  }

  Future<void> upvoteTag(String tagId) async {
    try {
      await _client.rpc('increment_tag_upvote', params: {'tag_id': tagId});
    } catch (e) {
      throw Exception('Failed to upvote tag: $e');
    }
  }

  Future<void> submitScamReport({
    required String emailId,
    required String categoryTag,
    required File imageEvidence,
    String? description,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User is not authenticated.');
      }

      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storagePath = '$userId/$fileName';

      await _client.storage
          .from('evidence_bucket')
          .upload(
            storagePath,
            imageEvidence,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      final evidenceUrl = _client.storage
          .from('evidence_bucket')
          .getPublicUrl(storagePath);

      await _client.from('community_reports').insert({
        'reporter_id': userId,
        'email_id': emailId,
        'category_tag': categoryTag,
        'evidence_url': evidenceUrl,
        'description': description,
      });
    } catch (e) {
      throw Exception('Failed to submit report: $e');
    }
  }
}
