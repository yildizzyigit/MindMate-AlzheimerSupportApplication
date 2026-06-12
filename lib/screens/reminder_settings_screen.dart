import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../services/notification_service.dart';

class ReminderSettingsScreen extends StatelessWidget {
  const ReminderSettingsScreen({super.key});

  Future<void> _sendTestNotification(BuildContext context) async {
    final isTR = context.read<AppProvider>().language == 'TR';

    await NotificationService.showNow(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: isTR ? 'MindMate Bildirimi' : 'MindMate Notification',
      body: isTR
          ? 'Bildirimler bu cihazda çalışıyor.'
          : 'Notifications are working on this device.',
    );

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isTR ? 'Test bildirimi gönderildi' : 'Test notification sent',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTR = context.watch<AppProvider>().language == 'TR';

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFBA7517),
        foregroundColor: Colors.white,
        title: Text(isTR ? 'Bildirim Testi' : 'Notification Test'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFAEEDA),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              isTR
                  ? 'Bu ekran cihazda bildirimlerin çalışıp çalışmadığını test etmek içindir. İlaç ve aktivite bildirimleri bu sürümde otomatik planlanmaz.'
                  : 'This screen is for testing whether notifications work on this device. Medicine and activity notifications are not automatically scheduled in this version.',
              style: const TextStyle(
                color: Color(0xFF633806),
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _sendTestNotification(context),
              icon: const Icon(Icons.notifications_active_outlined),
              label: Text(
                isTR ? 'Test Bildirimi Gönder' : 'Send Test Notification',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFBA7517),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}