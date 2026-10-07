import 'package:flutter/material.dart';

import '../models/chat.dart';
import '../theme.dart';
import 'common.dart';

class ChatTile extends StatelessWidget {
  final Chat chat;
  final VoidCallback onTap;

  const ChatTile({super.key, required this.chat, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasUnread = chat.unreadCount > 0;
    final preview = hasUnread
        ? chat.lastReceivedPreview
        : (chat.lastSentPreview ?? chat.lastReceivedPreview);
    final empty = chat.sentCount == 0 && chat.receivedCount == 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: hasUnread ? AppColors.primary.withOpacity(0.55) : AppColors.outline,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Avatar(name: chat.displayName, size: 52, heroTag: 'avatar-${chat.userId}'),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(chat.displayName,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      if (empty)
                        const Text('Nothing here yet',
                            style: TextStyle(color: AppColors.muted, fontSize: 13))
                      else
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            if (chat.sentCount > 0)
                              _Chip(
                                icon: Icons.edit_outlined,
                                label: '${chat.sentCount} written',
                              ),
                            if (chat.receivedCount > 0)
                              _Chip(
                                icon: hasUnread
                                    ? Icons.mark_email_unread_outlined
                                    : Icons.inbox_outlined,
                                label: hasUnread
                                    ? '${chat.unreadCount} new for you'
                                    : '${chat.receivedCount} for you',
                                highlight: hasUnread,
                              ),
                          ],
                        ),
                      if (preview != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          preview,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.muted, fontSize: 13.5),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (hasUnread)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: AppColors.gradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('${chat.unreadCount}',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                  )
                else
                  const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool highlight;

  const _Chip({required this.icon, required this.label, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    final color = highlight ? AppColors.primary : AppColors.muted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: highlight ? AppColors.primary.withOpacity(0.14) : AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
