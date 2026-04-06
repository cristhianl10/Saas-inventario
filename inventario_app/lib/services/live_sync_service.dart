import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LiveSyncService {
  static final LiveSyncService _instance = LiveSyncService._internal();
  factory LiveSyncService() => _instance;
  LiveSyncService._internal();

  final SupabaseClient _client = Supabase.instance.client;
  final List<RealtimeChannel> _channels = [];
  Timer? _debounce;

  void watchTables({
    required List<String> tables,
    required VoidCallback onChange,
    Duration debounce = const Duration(milliseconds: 350),
  }) {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    for (final table in tables) {
      final channel = _client
          .channel(
            'live:$table:$userId:${DateTime.now().microsecondsSinceEpoch}',
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: table,
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: userId,
            ),
            callback: (_) {
              _debounce?.cancel();
              _debounce = Timer(debounce, onChange);
            },
          )
          .subscribe();

      _channels.add(channel);
    }
  }

  void addTable(String table, VoidCallback onChange) {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    final channel = _client
        .channel('live:$table:$userId:${DateTime.now().microsecondsSinceEpoch}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: table,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (_) {
            _debounce?.cancel();
            _debounce = Timer(const Duration(milliseconds: 350), onChange);
          },
        )
        .subscribe();

    _channels.add(channel);
  }

  Future<void> dispose() async {
    _debounce?.cancel();
    for (final channel in _channels) {
      await _client.removeChannel(channel);
    }
    _channels.clear();
  }
}
