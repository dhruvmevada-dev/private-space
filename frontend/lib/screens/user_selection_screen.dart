import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/user_tile.dart';
import 'create_space_screen.dart';
import 'pin_login_screen.dart';

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
    Widget list;
    if (_error != null) {
      list = ErrorView(message: _error!, onRetry: _load);
    } else if (_users == null) {
      list = const SingleChildScrollView(child: SkeletonList(count: 3));
    } else if (_users!.isEmpty) {
      list = const Center(
        child: Text(
          'No spaces yet.\nTap "Create a space" to add one.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.muted, height: 1.5),
        ),
      );
    } else {
      list = ListView(
        padding: const EdgeInsets.only(bottom: 96),
        children: [
          for (var i = 0; i < _users!.length; i++)
            FadeSlideIn(
              index: i,
              child: UserTile(
                user: _users![i],
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => PinLoginScreen(user: _users![i])),
                ),
              ),
            ),
        ],
      );
    }

    return AppScaffold(
      floatingActionButton: _error == null
          ? FloatingActionButton.extended(
              onPressed: _create,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create a space'),
            )
          : null,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FadeSlideIn(child: LogoMark(size: 56)),
              const SizedBox(height: 22),
              const FadeSlideIn(
                index: 1,
                child: Text('Private Space',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
              ),
              const SizedBox(height: 6),
              const FadeSlideIn(
                index: 2,
                child: Text('Write freely. They can only read.',
                    style: TextStyle(fontSize: 15, color: AppColors.muted)),
              ),
              const SizedBox(height: 32),
              const Text('CHOOSE YOUR SPACE',
                  style: TextStyle(
                      fontSize: 12,
                      letterSpacing: 2,
                      color: AppColors.muted,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 14),
              Expanded(child: list),
            ],
          ),
        ),
      ),
    );
  }
}
