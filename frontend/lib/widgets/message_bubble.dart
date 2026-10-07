import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/message.dart';
import '../theme.dart';

class MessageBubble extends StatelessWidget {
  final Message message;

  /// true: written by me (right, gradient). false: written to me (left, read-only).
  final bool isMine;

  /// Plays a pop-in animation (used for a message that was just sent).
  final bool animate;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    this.animate = false,
  });

  @override
  Widget build(BuildContext context) {
    final bubble = Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 7),
      decoration: BoxDecoration(
        gradient: isMine ? AppColors.gradient : null,
        color: isMine ? null : AppColors.surfaceHigh,
        border: isMine ? null : Border.all(color: AppColors.outline),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isMine ? 18 : 4),
          bottomRight: Radius.circular(isMine ? 4 : 18),
        ),
        boxShadow: isMine
            ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.22),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: SelectableText(
              message.content,
              style: TextStyle(
                color: isMine ? Colors.white : AppColors.text,
                fontSize: 15.5,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            DateFormat.jm().format(message.createdAt.toLocal()),
            style: TextStyle(
              fontSize: 11,
              color: isMine ? Colors.white70 : AppColors.muted,
            ),
          ),
        ],
      ),
    );

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: animate
          ? TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 380),
              curve: Curves.easeOutBack,
              builder: (context, v, child) => Opacity(
                opacity: v.clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: 0.85 + 0.15 * v,
                  alignment: isMine ? Alignment.bottomRight : Alignment.bottomLeft,
                  child: child,
                ),
              ),
              child: bubble,
            )
          : bubble,
    );
  }
}
