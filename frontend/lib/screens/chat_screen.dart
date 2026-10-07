import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../config.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../services/api_service.dart';
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
      _jumpToBottom();
    } on ApiException catch (e) {
      if (!mounted || dir != _direction || e.statusCode == 401) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  void _jumpToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
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
      setState(() => _thread = _thread?.withMessage(m));
      _jumpToBottom();
    } on ApiException catch (e) {
      if (mounted && e.statusCode != 401) _snack(e.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String _dayLabel(DateTime day) {
    final today = DateTime.now();
    final d0 = DateTime(today.year, today.month, today.day);
    final diff = d0.difference(day).inDays;
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
        out.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Center(
            child: Text(_dayLabel(day), style: Theme.of(context).textTheme.labelMedium),
          ),
        ));
      }
      out.add(MessageBubble(message: m, isMine: mine));
    }
    return out;
  }

  Widget _messages() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(onPressed: _load, child: const Text('Retry')),
        ]),
      );
    }
    final t = _thread!;
    if (t.messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            t.canWrite
                ? 'Nothing here yet.\nWrite something to ${widget.chat.displayName}.'
                : '${widget.chat.displayName} has not written anything to you yet.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    final items = _items(t.messages, t.canWrite);
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: items.length,
      itemBuilder: (_, i) => items[i],
    );
  }

  Widget _bottomBar() {
    final t = _thread;
    if (t == null || _loading && t.messages.isEmpty && _error == null) {
      return const SizedBox.shrink();
    }
    if (!t.canWrite) {
      return SafeArea(
        top: false,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: const Text('You can only read this space.', textAlign: TextAlign.center),
        ),
      );
    }
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 8, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _input,
                minLines: 1,
                maxLines: 5,
                maxLength: maxMessageLength,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Write something...',
                  counterText: '',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 4),
            IconButton.filled(
              onPressed: _sending ? null : _send,
              icon: const Icon(Icons.send),
              tooltip: 'Send',
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          CircleAvatar(radius: 16, child: Text(widget.chat.displayName[0].toUpperCase())),
          const SizedBox(width: 12),
          Text(widget.chat.displayName),
        ]),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'sent', label: Text('Written by me')),
                  ButtonSegment(value: 'received', label: Text('Written to me')),
                ],
                selected: {_direction},
                onSelectionChanged: (s) {
                  if (s.first == _direction) return;
                  setState(() {
                    _direction = s.first;
                    _thread = null;
                  });
                  _load();
                },
              ),
            ),
          ),
          Expanded(child: _messages()),
          _bottomBar(),
        ],
      ),
    );
  }
}
