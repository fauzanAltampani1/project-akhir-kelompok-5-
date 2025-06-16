import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/themes/app_colors.dart';
import '../../../config/themes/app_text_styles.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../thread/providers/thread_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _showUnreadOnly = false;

  @override
  Widget build(BuildContext context) {
    final threadProvider = Provider.of<ThreadProvider>(context);
    final notifications = threadProvider.threads
        .map((thread) => threadProvider.getThreadSummaryMessage(thread.id))
        .where((msg) => msg != null && msg.mentions.isNotEmpty)
        .toList();

    final filteredNotifications = _showUnreadOnly
        ? notifications.where((msg) => msg!.isUnread).toList()
        : notifications;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Notifications', showBackButton: true),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Show Unread Only',
                  style: AppTextStyles.bodyMedium.copyWith(fontFamily: 'Montserrat'),
                ),
                Switch(
                  value: _showUnreadOnly,
                  onChanged: (value) => setState(() => _showUnreadOnly = value),
                  activeColor: AppColors.primary,
                ),
              ],
            ),
          ),
          Expanded(
            child: filteredNotifications.isEmpty
                ? Center(
                    child: Text(
                      'No notifications',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: filteredNotifications.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final message = filteredNotifications[index]!;
                      final thread = threadProvider.threads
                          .firstWhere((t) => t.id == message.threadId);
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: Icon(
                            message.isUnread ? Icons.notifications_active : Icons.notifications,
                            color: message.isUnread ? AppColors.primary : AppColors.textSecondary,
                          ),
                          title: Text(
                            message.sender.name,
                            style: AppTextStyles.bodyMedium.copyWith(fontFamily: 'Montserrat'),
                          ),
                          subtitle: Text(
                            '${message.content} • In ${thread.name}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontFamily: 'Montserrat',
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () {
                            threadProvider.selectThread(message.threadId);
                            Navigator.pushNamed(context, '/thread',
                                arguments: message.threadId);
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}