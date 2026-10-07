import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/pin_field.dart';
import 'user_selection_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Log out?'),
        content: const Text('You will need your PIN to come back.',
            style: TextStyle(color: AppColors.muted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log out', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok != true) return;
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
    return AppScaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          FadeSlideIn(
            child: Row(
              children: [
                Avatar(name: name, size: 64),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    const Text('Your private space',
                        style: TextStyle(color: AppColors.muted)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 10),
            child: Text('ACCOUNT',
                style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 2,
                    color: AppColors.muted,
                    fontWeight: FontWeight.w600)),
          ),
          FadeSlideIn(
            index: 1,
            child: Material(
              color: AppColors.surface,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: AppColors.outline),
              ),
              child: Column(
                children: [
                  _SettingsTile(
                    icon: Icons.pin_outlined,
                    label: 'Change PIN',
                    onTap: () => Navigator.of(context)
                        .push(MaterialPageRoute(builder: (_) => const ChangePinScreen())),
                  ),
                  const Divider(height: 1, indent: 64),
                  _SettingsTile(
                    icon: Icons.logout_rounded,
                    label: 'Logout',
                    color: AppColors.error,
                    onTap: () => _logout(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AppColors.text,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(label, style: TextStyle(fontSize: 16, color: color))),
            const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
          ],
        ),
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
  final _f1 = FocusNode();
  final _f2 = FocusNode();
  final _f3 = FocusNode();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_current, _new, _confirm]) {
      c.dispose();
    }
    for (final f in [_f1, _f2, _f3]) {
      f.dispose();
    }
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
    return AppScaffold(
      appBar: AppBar(title: const Text('Change PIN')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            children: [
              FadeSlideIn(
                child: PinField(
                  controller: _current,
                  label: 'Current PIN',
                  focusNode: _f1,
                  autofocus: true,
                  hasError: _error != null,
                  onCompleted: (_) => _f2.requestFocus(),
                ),
              ),
              const SizedBox(height: 28),
              FadeSlideIn(
                index: 1,
                child: PinField(
                  controller: _new,
                  label: 'New PIN',
                  focusNode: _f2,
                  onCompleted: (_) => _f3.requestFocus(),
                ),
              ),
              const SizedBox(height: 28),
              FadeSlideIn(
                index: 2,
                child: PinField(
                  controller: _confirm,
                  label: 'Confirm New PIN',
                  focusNode: _f3,
                  onCompleted: (_) => FocusScope.of(context).unfocus(),
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                child: _error == null
                    ? const SizedBox(width: double.infinity)
                    : Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: Text(_error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.error, height: 1.4)),
                      ),
              ),
              const SizedBox(height: 32),
              FadeSlideIn(
                index: 3,
                child: GradientButton(
                  label: 'Change PIN',
                  loading: _busy,
                  onPressed: _busy ? null : _submit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
