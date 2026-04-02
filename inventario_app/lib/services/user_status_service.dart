import 'package:supabase_flutter/supabase_flutter.dart';

class UserStatusService {
  static Future<bool> isUserActive(String userId) async {
    try {
      final response = await Supabase.instance.client
          .from('user_status')
          .select('is_active')
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        return true;
      }

      return response['is_active'] ?? true;
    } catch (e) {
      return true;
    }
  }

  static Future<void> deactivateAccount(String userId) async {
    await Supabase.instance.client.from('user_status').upsert({
      'user_id': userId,
      'is_active': false,
      'deactivated_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<void> reactivateAccount(String userId) async {
    await Supabase.instance.client.from('user_status').upsert({
      'user_id': userId,
      'is_active': true,
    });
  }

  static Future<Map<String, dynamic>?> getUserStatus(String userId) async {
    try {
      final response = await Supabase.instance.client
          .from('user_status')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      return response;
    } catch (e) {
      return null;
    }
  }
}
