import 'package:supabase_flutter/supabase_flutter.dart';

class TermsService {
  static const String currentVersion = '1.0';

  static Future<bool> needsToAcceptNewTerms(String userId) async {
    try {
      final response = await Supabase.instance.client
          .from('user_terms')
          .select('terms_version')
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        return true;
      }

      final acceptedVersion = response['terms_version'] as String? ?? '0';
      return acceptedVersion != currentVersion;
    } catch (e) {
      return false;
    }
  }

  static Future<void> acceptTerms(String userId) async {
    try {
      final existing = await Supabase.instance.client
          .from('user_terms')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (existing != null) {
        await Supabase.instance.client
            .from('user_terms')
            .update({
              'terms_version': currentVersion,
              'accepted_at': DateTime.now().toIso8601String(),
            })
            .eq('user_id', userId);
      } else {
        await Supabase.instance.client.from('user_terms').insert({
          'user_id': userId,
          'terms_version': currentVersion,
          'accepted_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<String?> getAcceptedVersion(String userId) async {
    try {
      final response = await Supabase.instance.client
          .from('user_terms')
          .select('terms_version')
          .eq('user_id', userId)
          .maybeSingle();

      return response?['terms_version'] as String?;
    } catch (e) {
      return null;
    }
  }
}
