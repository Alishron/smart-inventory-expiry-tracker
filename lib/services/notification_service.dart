import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  // 🔔 Init once in main()
  static Future<void> init() async {
    debugPrint("🔔 NotificationService.init()");

    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings =
    InitializationSettings(android: androidSettings);

    await _plugin.initialize(settings);

    debugPrint("✅ NotificationService initialized");
  }

  // 🧠 PUBLIC METHOD — call this when item is added
  static void scheduleExpiryReminders({
    required String itemName,
    required DateTime expiryDate,
  }) {
    final now = DateTime.now();

    final daysLeft = expiryDate.difference(now).inDays;

    debugPrint("📦 $itemName expires in $daysLeft days");

    // 🔔 2 DAYS BEFORE
    if (daysLeft >= 2) {
      _scheduleAfterDelay(
        delay: const Duration(seconds: 5), // demo
        title: "Expiry Reminder",
        body: "$itemName expires in 2 days",
      );
    }

    // 🔔 1 DAY BEFORE
    if (daysLeft >= 1) {
      _scheduleAfterDelay(
        delay: const Duration(seconds: 10), // demo
        title: "Expiry Reminder",
        body: "$itemName expires tomorrow",
      );
    }
  }

  // 🔧 INTERNAL helper (SAFE scheduling)
  static Future<void> _scheduleAfterDelay({
    required Duration delay,
    required String title,
    required String body,
  }) async {
    debugPrint("⏳ Scheduling notification in ${delay.inSeconds}s");

    await Future.delayed(delay);

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'expiry_channel',
          'Expiry Notifications',
          channelDescription: 'Item expiry reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );

    debugPrint("✅ Notification fired: $body");
  }
}
