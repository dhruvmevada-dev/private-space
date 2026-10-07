import 'package:flutter/material.dart';

import '../models/chat.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/chat_tile.dart';
import 'chat_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Chat>? _chats;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final chats = await ApiService.instance.getChats();
      if (mounted) setState(() => _chats = chats);
    } on ApiException catch (e) {
      if (mounted && e.statusCode != 401) setState(() => _error = e.message);
    }
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Future<void> _open(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    if (mounted) _load(); // refresh counts after returning
  }

  @override
  Widget build(BuildContext context) {
    final name = AuthService.instance.currentUser?.displayName ?? '';
    final theme = Theme.of(context);

    Widget body;
    if (_error != null && _chats == null) {
      body = Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(onPressed: _load, child: const Text('Retry')),
        ]),
      );
    } else if (_chats == null) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_chats!.isEmpty) {
      body = const Center(child: Text('There is no one else here yet.'));
    } else {
      body = RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            for (final c in _chats!)
              ChatTile(chat: c, onTap: () => _open(ChatScreen(chat: c))),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("$name's Space"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => _open(const SettingsScreen()),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Text('${_greeting()}, $name', style: theme.textTheme.titleLarge),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text('Your spaces', style: theme.textTheme.bodyMedium),
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}
