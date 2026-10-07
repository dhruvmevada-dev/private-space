import 'package:flutter/material.dart';

import '../models/chat.dart';

class ChatTile extends StatelessWidget {
  final Chat chat;
  final VoidCallback onTap;

  const ChatTile({super.key, required this.chat, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = <String>[
      if (chat.sentCount > 0) 'You wrote ${chat.sentCount}',
      if (chat.receivedCount > 0)
        '${chat.receivedCount} for you'
            '${chat.unreadCount > 0 ? ' (${chat.unreadCount} new)' : ''}',
    ].join('  ·  ');

    // Surface what is new for me first; otherwise the last thing I wrote.
    final preview = chat.unreadCount > 0
        ? chat.lastReceivedPreview
        : (chat.lastSentPreview ?? chat.lastReceivedPreview);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: CircleAvatar(child: Text(chat.displayName[0].toUpperCase())),
        title: Text(chat.displayName, style: theme.textTheme.titleMedium),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(summary.isEmpty ? 'No messages yet' : summary,
                style: theme.textTheme.bodySmall),
            if (preview != null)
              Text('"$preview"', maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
        trailing: chat.unreadCount > 0
            ? Badge.count(count: chat.unreadCount)
            : const Icon(Icons.chevron_right),
        isThreeLine: preview != null,
        onTap: onTap,
      ),
    );
  }
}
