class Chat {
  final int userId;
  final String displayName;
  final int sentCount;
  final int receivedCount;
  final int unreadCount;
  final String? lastSentPreview;
  final String? lastReceivedPreview;

  const Chat({
    required this.userId,
    required this.displayName,
    required this.sentCount,
    required this.receivedCount,
    required this.unreadCount,
    this.lastSentPreview,
    this.lastReceivedPreview,
  });

  factory Chat.fromJson(Map<String, dynamic> json) => Chat(
        userId: json['user_id'] as int,
        displayName: json['display_name'] as String,
        sentCount: json['sent_count'] as int,
        receivedCount: json['received_count'] as int,
        unreadCount: json['unread_count'] as int,
        lastSentPreview: json['last_sent_preview'] as String?,
        lastReceivedPreview: json['last_received_preview'] as String?,
      );
}
