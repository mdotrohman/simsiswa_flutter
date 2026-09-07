import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'api.dart';
import 'app_nav.dart';
import 'session.dart';

final FlutterLocalNotificationsPlugin localNotifications =
    FlutterLocalNotificationsPlugin();

/// Handler push saat aplikasi di latar belakang / tertutup.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await _tryShow(message);
}

Future<void> initFcm() async {
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('FCM initializeApp gagal (google-services.json belum asli?): $e');
    return;
  }
  try {
    final fm = FirebaseMessaging.instance;
    final token = await fm.getToken();
    if (token != null && token.isNotEmpty) {
      await Session.saveDeviceToken(token);
      await _register(token);
    }
    fm.onTokenRefresh.listen((t) async {
      await Session.saveDeviceToken(t);
      await _register(t);
    });
    await fm.requestPermission();
    await _initLocal();
    await _subscribeListeners();
  } catch (e) {
    debugPrint('initFcm error: $e');
  }
}

Future<void> _initLocal() async {
  try {
    const androidInit = AndroidInitializationSettings('ic_notification');
    const iosInit = DarwinInitializationSettings();
    await localNotifications.initialize(
      settings:
          const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (response) {
        final id = int.tryParse(response.payload ?? '');
        if (id != null && id > 0) AppNav.openPengumumanId(id);
      },
    );
  } catch (e) {
    debugPrint('FCM local notifications init error: $e');
  }
}

Future<void> _subscribeListeners() async {
  try {
    FirebaseMessaging.onMessage.listen(_tryShow);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleOpen);
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) _handleOpen(initial);
  } catch (e) {
    debugPrint('FCM listeners error: $e');
  }
}

Future<void> _register(String token) async {
  try {
    if (Session.isLoggedIn() && Session.userId > 0) {
      await Api.registerFcmToken(token);
    }
  } catch (e) {
    debugPrint('FCM register token error: $e');
  }
}

Future<void> _tryShow(RemoteMessage message) async {
  final n = message.notification;
  if (n == null) return;
  final id =
      int.tryParse(message.data['pengumuman_id']?.toString() ?? '') ?? 0;
  try {
    const android = AndroidNotificationDetails(
      'pengumuman',
      'Pengumuman',
      channelDescription: 'Notifikasi pengumuman madrasah',
      importance: Importance.high,
      priority: Priority.high,
    );
    final nid = id > 0 ? id : (message.messageId?.hashCode ?? 0) & 0x7fffffff;
    await localNotifications.show(
      id: nid,
      title: n.title ?? 'Pengumuman',
      body: n.body ?? '',
      notificationDetails: const NotificationDetails(android: android),
      payload: id > 0 ? id.toString() : null,
    );
  } catch (e) {
    debugPrint('FCM show notification error: $e');
  }
}

void _handleOpen(RemoteMessage message) {
  final id = int.tryParse(message.data['pengumuman_id']?.toString() ?? '');
  if (id != null && id > 0) {
    AppNav.openPengumumanId(id);
  } else {
    AppNav.openTab(4);
  }
}

/// Registrasi ulang token ke server (dipanggil saat sudah login / MainShell).
Future<void> registerSavedToken() async {
  final token = Session.deviceToken;
  if (token.isEmpty) return;
  await _register(token);
}