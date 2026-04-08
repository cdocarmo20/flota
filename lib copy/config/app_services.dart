import 'package:flutter/material.dart';

// --- SERVICIO DE NOTIFICACIONES ---
enum NotifType { success, error, info }

class AppNotif {
  final String msg;
  final NotifType type;
  AppNotif(this.msg, this.type);
}

final ValueNotifier<AppNotif?> notifNotifier = ValueNotifier(null);

class NotifService {
  static void show(String msg, {NotifType type = NotifType.info}) {
    notifNotifier.value = AppNotif(msg, type);
    Future.delayed(
      const Duration(seconds: 3),
      () => notifNotifier.value = null,
    );
  }
}

// --- SERVICIO DE CARGA ---
final ValueNotifier<bool> loadingNotifier = ValueNotifier(false);

class LoadingService {
  static void show() => loadingNotifier.value = true;
  static void hide() => loadingNotifier.value = false;

  static Future<void> run(Future<void> Function() task) async {
    show();
    try {
      await task();
    } finally {
      hide();
    }
  }
}
