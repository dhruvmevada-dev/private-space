import 'package:flutter/material.dart';

import '../models/chat.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme.dart';
import '../widgets/chat_tile.dart';
import '../widgets/common.dart';
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

  Widget _header(String name) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${_greeting()},',
              style: const TextStyle(fontSize: 16, color: AppColors.muted)),
          const SizedBox(height: 2),
          ShaderMask(
            shaderCallback: (rect) => AppColors.gradient.createShader(rect),
            child: Text(name,
                style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                    color: Colors.white)),
          ),
          const SizedBox(height: 22),
          const Text('YOUR SPACES',
              style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 2,
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = AuthService.instance.currentUser?.displayName ?? '';

    Widget content;
    if (_error != null && _chats == null) {
      content = ErrorView(message: _error!, onRetry: _load);
    } else if (_chats == null) {
      content = ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [_header(name), const SkeletonList()],
      );
    } else {
      content = RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.surfaceHigh,
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            _header(name),
            if (_chats!.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 60),
                child: Column(
                  children: [
                    Icon(Icons.people_outline_rounded, size: 48, color: AppColors.muted),
                    SizedBox(height: 12),
                    Text('There is no one else here yet.',
                        style: TextStyle(color: AppColors.muted)),
                  ],
                ),
              )
            else
              for (var i = 0; i < _chats!.length; i++)
                FadeSlideIn(
                  index: i,
                  child: ChatTile(
                    chat: _chats![i],
                    onTap: () => _open(ChatScreen(chat: _chats![i])),
                  ),
                ),
          ],
        ),
      );
    }

    return AppScaffold(
      appBar: AppBar(
        title: const Text('PRIVATE SPACE',
            style: TextStyle(fontSize: 13, letterSpacing: 3, color: AppColors.muted)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => _open(const SettingsScreen()),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: content,
    );
  }
}
