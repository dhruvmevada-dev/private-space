import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../config.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/message_bubble.dart';

/// One person's space, with two one-way views:
///  - "Written by me": what I wrote to them (composer shown)
///  - "Written to me": what they wrote to me (read-only, no composer)
class ChatScreen extends StatefulWidget {
  final Chat chat;
  const ChatScreen({super.key, required this.chat});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _api = ApiService.instance;
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _freshIds = <int>{};

  String _direction = 'sent';
  MessageThread? _thread;
  bool _loading = true;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Open on "Written to me" if there is something new to read.
    if (widget.chat.unreadCount > 0) _direction = 'received';
    _input.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final dir = _direction;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final t = await _api.getThread(widget.chat.userId, dir);
      if (!mounted || dir != _direction) return;
      setState(() {
        _thread = t;
        _loading = false;
      });
      _scrollToBottom(animate: false);
    } on ApiException catch (e) {
      if (!mounted || dir != _direction || e.statusCode == 401) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  void _scrollToBottom({required bool animate}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final max = _scroll.position.maxScrollExtent;
      if (animate) {
        _scroll.animateTo(max,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);
      } else {
        _scroll.jumpTo(max);
      }
    });
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty) return _snack('Empty message\nWrite something first.');
    if (text.length > maxMessageLength) {
      return _snack('Message too long\nMaximum is $maxMessageLength characters.');
    }
    setState(() => _sending = true);
    try {
      final m = await _api.sendMessage(widget.chat.userId, text);
      if (!mounted) return;
      _input.clear();
      _freshIds.add(m.id);
      setState(() => _thread = _thread?.withMessage(m));
      _scrollToBottom(animate: true);
    } on ApiException catch (e) {
      if (mounted && e.statusCode != 401) _snack(e.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _switchTo(String dir) {
    if (dir == _direction) return;
    setState(() {
      _direction = dir;
      _thread = null;
    });
    _load();
  }

  String _dayLabel(DateTime day) {
    final now = DateTime.now();
    final diff = DateTime(now.year, now.month, now.day).difference(day).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return DateFormat.yMMMd().format(day);
  }

  List<Widget> _items(List<Message> msgs, bool mine) {
    final out = <Widget>[];
    DateTime? lastDay;
    for (final m in msgs) {
      final l = m.createdAt.toLocal();
      final day = DateTime(l.year, l.month, l.day);
      if (lastDay != day) {
        lastDay = day;
        out.add(Center(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(_dayLabel(day),
                style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          ),
        ));
      }
      out.add(MessageBubble(message: m, isMine: mine, animate: _freshIds.contains(m.id)));
    }
    return out;
  }

  Widget _messages() {
    if (_error != null) return ErrorView(message: _error!, onRetry: _load);
    final t = _thread;
    if (t == null) return const SizedBox.shrink();
    if (t.messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: FadeSlideIn(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  t.canWrite ? Icons.edit_note_rounded : Icons.inbox_outlined,
                  size: 52,
                  color: AppColors.muted,
                ),
                const SizedBox(height: 14),
                Text(
                  t.canWrite
                      ? 'Nothing here yet.\nWrite something to ${widget.chat.displayName}.'
                      : '${widget.chat.displayName} has not written\nanything to you yet.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted, height: 1.5),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final items = _items(t.messages, t.canWrite);
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      itemCount: items.length,
      itemBuilder: (_, i) => items[i],
    );
  }

  Widget _bottomBar() {
    final t = _thread;
    if (t == null) return const SizedBox.shrink();
    if (!t.canWrite) {
      return SafeArea(
        top: false,
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(14, 6, 14, 12),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.outline),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline_rounded, size: 17, color: AppColors.muted),
              SizedBox(width: 8),
              Text('You can only read this space.',
                  style: TextStyle(color: AppColors.muted)),
            ],
          ),
        ),
      );
    }

    final canSend = _input.text.trim().isNotEmpty && !_sending;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 6, 12, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.outline),
                ),
                child: TextField(
                  controller: _input,
                  minLines: 1,
                  maxLines: 5,
                  maxLength: maxMessageLength,
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(fontSize: 15.5),
                  decoration: const InputDecoration(
                    hintText: 'Write something...',
                    counterText: '',
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: canSend ? _send : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: canSend || _sending ? AppColors.gradient : null,
                  color: canSend || _sending ? null : AppColors.surfaceHigh,
                  boxShadow: canSend
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.4),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : const [],
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: _sending
                      ? const Padding(
                          key: ValueKey('spin'),
                          padding: EdgeInsets.all(14),
                          child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                        )
                      : Icon(
                          Icons.arrow_upward_rounded,
                          key: const ValueKey('send'),
                          color: canSend ? Colors.white : AppColors.muted,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            Avatar(
              name: widget.chat.displayName,
              size: 38,
              heroTag: 'avatar-${widget.chat.userId}',
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.chat.displayName,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                const Text('Private space',
                    style: TextStyle(fontSize: 12, color: AppColors.muted)),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
            child: _DirectionToggle(value: _direction, onChanged: _switchTo),
          ),
          Expanded(
            child: Stack(
              children: [
                AnimatedOpacity(
                  opacity: _loading ? 0 : 1,
                  duration: const Duration(milliseconds: 250),
                  child: _messages(),
                ),
                if (_loading)
                  const Center(
                    child: SizedBox(
                      height: 28,
                      width: 28,
                      child: CircularProgressIndicator(strokeWidth: 2.4),
                    ),
                  ),
              ],
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            child: _bottomBar(),
          ),
        ],
      ),
    );
  }
}

class _DirectionToggle extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _DirectionToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
      ),
      child: LayoutBuilder(
        builder: (context, cons) {
          final w = cons.maxWidth / 2;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                left: value == 'sent' ? 0 : w,
                top: 0,
                bottom: 0,
                width: w,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppColors.gradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(child: _segment('Written by me', 'sent')),
                  Expanded(child: _segment('Written to me', 'received')),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _segment(String label, String v) {
    final selected = value == v;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(v),
      child: Center(
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.muted,
          ),
          child: Text(label),
        ),
      ),
    );
  }
}
