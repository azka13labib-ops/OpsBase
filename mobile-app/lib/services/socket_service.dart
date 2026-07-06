import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  io.Socket? _socket;
  final List<Function> _statsListeners = [];

  void init(String guildId) {
    if (_socket != null) return;

    final session = Supabase.instance.client.auth.currentSession;
    final token = session?.accessToken;

    _socket = io.io(AppConfig.backendApiUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'auth': {
        'token': token,
      }
    });

    _socket!.connect();

    _socket!.onConnect((_) {
      debugPrint('Terhubung ke WebSockets Server');
      _socket!.emit('join_guild', guildId);
    });

    _socket!.on('stats_updated', (_) {
      for (var listener in _statsListeners) {
        listener();
      }
    });

    _socket!.onDisconnect((_) => debugPrint('Terputus dari WebSockets Server'));
  }

  void addStatsListener(Function callback) {
    _statsListeners.add(callback);
  }

  void removeStatsListener(Function callback) {
    _statsListeners.remove(callback);
  }

  void dispose() {
    _socket?.disconnect();
    _socket = null;
    _statsListeners.clear();
  }
}
