import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/api_service.dart';
import '../widgets/user_tile.dart';
import 'pin_login_screen.dart';
import 'create_space_screen.dart';

class UserSelectionScreen extends StatefulWidget {
  /// Optional message shown on arrival (e.g. session expired).
  final String? notice;
  const UserSelectionScreen({super.key, this.notice});

  @override
  State<UserSelectionScreen> createState() => _UserSelectionScreenState();
}

class _UserSelectionScreenState extends State<UserSelectionScreen> {
  List<User>? _users;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    if (widget.notice != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.notice!)));
        }
      });
    }
  }

  Future<void> _load() async {
    setState(() {
      _users = null;
      _error = null;
    });
    try {
      final users = await ApiService.instance.getUsers();
      if (mounted) setState(() => _users = users);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _create() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CreateSpaceScreen()),
    );
    if (created == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Space created. Select it to log in.')),
      );
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget body;
    if (_error != null) {
      body = Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(onPressed: _load, child: const Text('Retry')),
        ]),
      );
    } else if (_users == null) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_users!.isEmpty) {
      body = const Center(child: Text('No spaces yet.\nTap "Create a space" to add one.'));
    } else {
      body = ListView(
        children: [
          for (final u in _users!)
            UserTile(
              user: u,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => PinLoginScreen(user: u)),
              ),
            ),
        ],
      );
    }

    return Scaffold(
      floatingActionButton: _error == null
          ? FloatingActionButton.extended(
        onPressed: _create,
        icon: const Icon(Icons.add),
        label: const Text('Create a space'),
      )
          : null,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Text('PRIVATE SPACE',
                  style: theme.textTheme.headlineSmall?.copyWith(letterSpacing: 3)),
              const SizedBox(height: 8),
              Text('Choose your space', style: theme.textTheme.titleMedium),
              const SizedBox(height: 24),
              Expanded(child: body),
            ],
          ),
        ),
      ),
    );
  }
}
