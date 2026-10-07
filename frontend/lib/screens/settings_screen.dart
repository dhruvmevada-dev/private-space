import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/pin_field.dart';
import 'user_selection_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    await AuthService.instance.logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const UserSelectionScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = AuthService.instance.currentUser?.displayName ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text('Account', style: Theme.of(context).textTheme.titleSmall),
          ),
          ListTile(leading: const Icon(Icons.person_outline), title: Text(name)),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.pin_outlined),
            title: const Text('Change PIN'),
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const ChangePinScreen())),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }
}

class ChangePinScreen extends StatefulWidget {
  const ChangePinScreen({super.key});

  @override
  State<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends State<ChangePinScreen> {
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final re = RegExp(r'^\d{4}$');
    if (!re.hasMatch(_current.text) || !re.hasMatch(_new.text)) {
      return setState(() => _error = 'Invalid PIN format\nPINs must be exactly 4 digits.');
    }
    if (_new.text != _confirm.text) {
      return setState(() => _error = 'New PINs do not match.');
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ApiService.instance.changePin(_current.text, _new.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN changed.')));
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (mounted && e.statusCode != 401) {
        setState(() {
          _busy = false;
          _error = e.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change PIN')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          PinField(controller: _current, label: 'Current PIN'),
          const SizedBox(height: 16),
          PinField(controller: _new, label: 'New PIN'),
          const SizedBox(height: 16),
          PinField(controller: _confirm, label: 'Confirm New PIN'),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: _busy
                ? const SizedBox(
                    height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Change PIN'),
          ),
        ],
      ),
    );
  }
}
