class Message {
  final int id;
  final int senderId;
  final int recipientId;
  final String content;
  final DateTime createdAt;
  final bool isRead;

  const Message({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.content,
    required this.createdAt,
    required this.isRead,
  });

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        id: json['id'] as int,
        senderId: json['sender_id'] as int,
        recipientId: json['recipient_id'] as int,
        content: json['content'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        isRead: json['is_read'] as bool,
      );
}

/// One direction of a relationship: either what I wrote ("sent")
/// or what the other person wrote to me ("received").
class MessageThread {
  final String direction;
  final bool canWrite;
  final List<Message> messages;

  const MessageThread({
    required this.direction,
    required this.canWrite,
    required this.messages,
  });

  factory MessageThread.fromJson(Map<String, dynamic> json) => MessageThread(
        direction: json['direction'] as String,
        canWrite: json['can_write'] as bool,
        messages: (json['messages'] as List)
            .map((m) => Message.fromJson(m as Map<String, dynamic>))
            .toList(),
      );

  MessageThread withMessage(Message m) => MessageThread(
        direction: direction,
        canWrite: canWrite,
        messages: [...messages, m],
      );
}
