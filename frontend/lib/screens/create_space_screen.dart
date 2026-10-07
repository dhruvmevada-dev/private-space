import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/pin_field.dart';

class CreateSpaceScreen extends StatefulWidget {
  const CreateSpaceScreen({super.key});

  @override
  State<CreateSpaceScreen> createState() => _CreateSpaceScreenState();
}

class _CreateSpaceScreenState extends State<CreateSpaceScreen> {
  final _name = TextEditingController();
  final _pin = TextEditingController();
  final _confirm = TextEditingController();
  final _f1 = FocusNode();
  final _f2 = FocusNode();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _pin, _confirm]) {
      c.dispose();
    }
    _f1.dispose();
    _f2.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    if (name.isEmpty) return setState(() => _error = 'Please enter a name.');
    if (!RegExp(r'^\d{4}$').hasMatch(_pin.text)) {
      return setState(() => _error = 'Invalid PIN format\nPIN must be exactly 4 digits.');
    }
    if (_pin.text != _confirm.text) {
      return setState(() => _error = 'PINs do not match.');
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ApiService.instance.createUser(name, _pin.text);
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) {
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
      appBar: AppBar(title: const Text('Create a space')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            children: [
              FadeSlideIn(
                child: TextField(
                  controller: _name,
                  maxLength: 50,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => _f1.requestFocus(),
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    counterText: '',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              FadeSlideIn(
                index: 1,
                child: PinField(
                  controller: _pin,
                  label: 'Choose a 4-digit PIN',
                  focusNode: _f1,
                  onCompleted: (_) => _f2.requestFocus(),
                ),
              ),
              const SizedBox(height: 28),
              FadeSlideIn(
                index: 2,
                child: PinField(
                  controller: _confirm,
                  label: 'Confirm PIN',
                  focusNode: _f2,
                  hasError: _error != null && _error!.contains('match'),
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
                  label: 'Create',
                  icon: Icons.check_rounded,
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
