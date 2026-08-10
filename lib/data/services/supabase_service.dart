import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../../core/constants/env_constants.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();

  factory SupabaseService() {
    return _instance;
  }

  SupabaseService._internal();

  late final SupabaseClient client;

  static Future<void> init() async {
    await Supabase.initialize(
      url: EnvConstants.supabaseUrl,
      anonKey: EnvConstants.supabaseAnonKey,
    );
    
    _instance.client = Supabase.instance.client;
    await _instance._ensureAuthenticated();
  }

  Future<void> _ensureAuthenticated() async {
    try {
      final session = client.auth.currentSession;
      if (session == null) {
        await client.auth.signInAnonymously();
        debugPrint('Signed in anonymously successfully.');
      }
    } catch (e) {
      debugPrint('Error during anonymous sign in: $e');
    }
  }
}
