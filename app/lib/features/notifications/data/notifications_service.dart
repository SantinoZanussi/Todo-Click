import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:todoclick/core/constants/app_constants.dart';
import 'package:todoclick/core/di/app_providers.dart';
import 'package:todoclick/core/router/app_router.dart';
import 'package:todoclick/core/router/app_routes.dart';
import 'package:todoclick/features/auth/presentation/controllers/auth_controller.dart';

/// Maneja Firebase Cloud Messaging en el cliente:
///  • pide permiso de notificaciones,
///  • registra/guarda el token FCM en `usuarios/{uid}.fcmTokens`,
///  • muestra notificaciones en foreground (flutter_local_notifications),
///  • se suscribe al tópico `promos`,
///  • navega al tocar una notificación.
///
/// Toda la inicialización es tolerante a fallos: si Firebase no está
/// configurado (Fase 2 pendiente) la app sigue funcionando sin push.
class NotificationsService {
  NotificationsService(this._ref);

  final Ref _ref;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  bool _started = false;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'todoclick_default',
    'Notificaciones TodoClick',
    description: 'Pagos, pedidos y promociones',
    importance: Importance.high,
  );

  Future<void> init() async {
    if (_started) return;
    _started = true;

    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      await _initLocal();

      try {
        await messaging.subscribeToTopic('promos');
      } catch (_) {
        // subscribeToTopic no está soportado en web.
      }

      FirebaseMessaging.onMessage.listen(_showForeground);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);

      // Registrar el token cuando hay sesión y al refrescarse.
      _ref.listen(authStateProvider, (_, next) {
        final user = next.valueOrNull;
        if (user != null) _registerToken(user.uid);
      }, fireImmediately: true);

      messaging.onTokenRefresh.listen((token) {
        final user = _ref.read(authStateProvider).valueOrNull;
        if (user != null) _saveToken(user.uid, token);
      });
    } catch (e) {
      debugPrint('⚠️ NotificationsService.init: $e');
    }
  }

  Future<void> _initLocal() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings();
    await _local.initialize(
      const InitializationSettings(android: android, iOS: darwin),
    );
    await _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);
  }

  Future<void> _registerToken(String uid) async {
    // El push en web requiere un service worker (`firebase-messaging-sw.js`) y
    // una clave VAPID; hasta configurarlos, evitamos `getToken` en web para no
    // registrar un service worker inexistente. Las notificaciones in-app
    // (Firestore) funcionan igual.
    if (kIsWeb) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _saveToken(uid, token);
    } catch (e) {
      debugPrint('⚠️ getToken: $e');
    }
  }

  Future<void> _saveToken(String uid, String token) async {
    await _ref
        .read(firestoreProvider)
        .collection(FirestoreCollections.users)
        .doc(uid)
        .set({
          'fcmTokens': FieldValue.arrayUnion([token]),
        }, SetOptions(merge: true));
  }

  void _showForeground(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;
    _local.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  void _handleTap(RemoteMessage message) {
    // Por ahora llevamos al centro de notificaciones; desde ahí se navega al
    // pedido correspondiente.
    _ref.read(routerProvider).go(AppRoutes.notifications);
  }
}

final notificationsServiceProvider = Provider<NotificationsService>(
  (ref) => NotificationsService(ref),
);

/// Provider que dispara la inicialización de FCM una sola vez (lo observa el
/// widget raíz de la app).
final notificationsBootstrapProvider = Provider<void>((ref) {
  ref.read(notificationsServiceProvider).init();
});
