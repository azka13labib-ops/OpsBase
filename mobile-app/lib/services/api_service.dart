import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config.dart';

/// Semua pemanggilan ke backend Express kita lewat class ini.
/// Token diambil otomatis dari sesi Supabase yang sedang aktif.
class ApiService {
  static String get _baseUrl => AppConfig.backendApiUrl;

  static Map<String, String> get _headers {
    final session = Supabase.instance.client.auth.currentSession;
    return {
      'Content-Type': 'application/json',
      if (session != null) 'Authorization': 'Bearer ${session.accessToken}',
    };
  } 

  static Future<dynamic> _get(String path) async {
    final res = await http.get(Uri.parse('$_baseUrl$path'), headers: _headers);
    return _handleResponse(res);
  }

  static Future<dynamic> _post(String path, Map<String, dynamic> body) async {
    final res = await http.post(Uri.parse('$_baseUrl$path'), headers: _headers, body: jsonEncode(body));
    return _handleResponse(res);
  }

  static Future<dynamic> _delete(String path) async {
    final res = await http.delete(Uri.parse('$_baseUrl$path'), headers: _headers);
    return _handleResponse(res);
  }

  static dynamic _handleResponse(http.Response res) {
    final data = jsonDecode(res.body);
    if (res.statusCode >= 400) {
      throw ApiException(data['error'] ?? 'Terjadi kesalahan', res.statusCode);
    }
    return data;
  }

  // ---------- Auth ----------
  static Future<Map<String, dynamic>> getMe() async {
    final data = await _get('/api/auth/me');
    return data['user'] as Map<String, dynamic>;
  }

  // ---------- Dashboard ----------
  static Future<Map<String, dynamic>> getDashboardStats() async {
    final data = await _get('/api/dashboard/stats');
    return data as Map<String, dynamic>;
  }

  // ---------- Moderasi ----------
  static Future<List<dynamic>> getModHistory({int limit = 50, int offset = 0}) async {
    final data = await _get('/api/moderation/history?limit=$limit&offset=$offset');
    return data['history'] as List<dynamic>;
  }

  static Future<void> warnUser(String userId, String userTag, String reason) =>
      _post('/api/moderation/warn', {'userId': userId, 'userTag': userTag, 'reason': reason});

  static Future<void> kickUser(String userId, {String? reason}) =>
      _post('/api/moderation/kick', {'userId': userId, if (reason != null) 'reason': reason});

  static Future<void> banUser(String userId, {String? reason, int deleteMessageDays = 0}) =>
      _post('/api/moderation/ban', {'userId': userId, if (reason != null) 'reason': reason, 'deleteMessageDays': deleteMessageDays});

  static Future<void> muteUser(String userId, int durationMs, {String? reason}) =>
      _post('/api/moderation/mute', {'userId': userId, 'durationMs': durationMs, if (reason != null) 'reason': reason});

  // ---------- Events ----------
  static Future<List<dynamic>> getEvents({bool upcoming = true}) async {
    final data = await _get('/api/events?upcoming=$upcoming');
    return data['events'] as List<dynamic>;
  }

  static Future<Map<String, dynamic>> createEvent({
    required String title,
    String? description,
    String? channelId,
    String? location,
    String? coverUrl,
    required DateTime startTime,
    DateTime? endTime,
    bool isRecurring = false,
    String? recurrenceRule,
    bool syncToDiscord = false,
  }) async {
    final data = await _post('/api/events', {
      'title': title,
      if (description != null) 'description': description,
      if (channelId != null) 'channelId': channelId,
      if (location != null) 'location': location,
      if (coverUrl != null) 'coverUrl': coverUrl,
      'startTime': startTime.toIso8601String(),
      if (endTime != null) 'endTime': endTime.toIso8601String(),
      'isRecurring': isRecurring,
      if (recurrenceRule != null) 'recurrenceRule': recurrenceRule,
      'syncToDiscord': syncToDiscord,
    });
    return data['event'] as Map<String, dynamic>;
  }

  static Future<void> deleteEvent(String eventId) => _delete('/api/events/$eventId');

  static Future<Map<String, dynamic>> updateEvent(String eventId, {
    required String title,
    String? description,
    String? channelId,
    String? location,
    String? coverUrl,
    required DateTime startTime,
    DateTime? endTime,
    bool isRecurring = false,
    String? recurrenceRule,
  }) async {
    final data = await _post('/api/events/$eventId', {
      'title': title,
      if (description != null) 'description': description,
      if (channelId != null) 'channelId': channelId,
      if (location != null) 'location': location,
      if (coverUrl != null) 'coverUrl': coverUrl,
      'startTime': startTime.toIso8601String(),
      if (endTime != null) 'endTime': endTime.toIso8601String(),
      'isRecurring': isRecurring,
      if (recurrenceRule != null) 'recurrenceRule': recurrenceRule,
    });
    return data['event'] as Map<String, dynamic>;
  }

  static Future<void> rsvpEvent(String eventId, String status) =>
      _post('/api/events/$eventId/rsvp', {'status': status});

  // ---------- Devices (push notification) ----------
  static Future<void> registerDevice(String fcmToken, {String platform = 'android'}) =>
      _post('/api/devices/register', {'fcmToken': fcmToken, 'platform': platform});
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException(this.message, this.statusCode);
  @override
  String toString() => message;
}
