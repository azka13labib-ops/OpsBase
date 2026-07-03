import 'package:firebase_messaging/firebase_messaging.dart';
import 'api_service.dart';

class PushService {
  static final _messaging = FirebaseMessaging.instance;

  /// Panggil ini setelah user berhasil login.
  static Future<void> initAndRegister() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus != AuthorizationStatus.authorized &&
        settings.authorizationStatus != AuthorizationStatus.provisional) {
      return; // User menolak izin notifikasi
    }

    final token = await _messaging.getToken();
    if (token != null) {
      await ApiService.registerDevice(token);
    }

    // Kalau token berubah (reinstall app, dll), daftarkan ulang otomatis
    _messaging.onTokenRefresh.listen((newToken) {
      ApiService.registerDevice(newToken);
    });
  }

  /// Panggil di main() sebelum runApp, untuk handle notifikasi saat app di-background.
  static void setupBackgroundHandler(Future<void> Function(RemoteMessage) handler) {
    FirebaseMessaging.onBackgroundMessage(handler);
  }

  /// Listener saat app sedang dibuka (foreground) dan notif masuk.
  static void listenForegroundMessages(void Function(RemoteMessage) onMessage) {
    FirebaseMessaging.onMessage.listen(onMessage);
  }
}
