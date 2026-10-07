import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/user.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/pin_field.dart';
import 'home_screen.dart';

class PinLoginScreen extends StatefulWidget {
  final User user;
  const PinLoginScreen({super.key, required this.user});

  @override
  State<PinLoginScreen> createState() => _PinLoginScreenState();
}

class _PinLoginScreenState extends State<PinLoginScreen> with SingleTickerProviderStateMixin {
  final _pin = TextEditingController();
  late final AnimationController _shake =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _pin.dispose();
    _shake.dispose();
    super.dispose();
  }

  void _fail(String message) {
    HapticFeedback.heavyImpact();
    _shake.forward(from: 0);
    setState(() {
      _busy = false;
      _error = message;
      _pin.clear();
    });
  }

  Future<void> _login() async {
    if (_busy) return;
    if (_pin.text.length != 4) {
      return _fail('Invalid PIN format\nPlease enter exactly 4 digits.');
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AuthService.instance.login(widget.user.id, _pin.text);
      if (!mounted) return;
      HapticFeedback.lightImpact();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      _fail(e.statusCode == 401 ? 'Incorrect PIN\nPlease try again.' : e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Avatar(name: widget.user.displayName, size: 88, heroTag: 'avatar-${widget.user.id}'),
              const SizedBox(height: 20),
              FadeSlideIn(
                child: Text(widget.user.displayName,
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 6),
              const FadeSlideIn(
                index: 1,
                child: Text('Welcome back', style: TextStyle(color: AppColors.muted)),
              ),
              const SizedBox(height: 40),
              FadeSlideIn(
                index: 2,
                child: AnimatedBuilder(
                  animation: _shake,
                  builder: (context, child) => Transform.translate(
                    offset: Offset(math.sin(_shake.value * math.pi * 5) * 10 * (1 - _shake.value), 0),
                    child: child,
                  ),
                  child: PinField(
                    controller: _pin,
                    label: 'Enter your 4-digit PIN',
                    autofocus: true,
                    hasError: _error != null,
                    onCompleted: (_) => _login(),
                  ),
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                child: _error == null
                    ? const SizedBox(width: double.infinity)
                    : Padding(
                        padding: const EdgeInsets.only(top: 18),
                        child: Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.error, height: 1.4),
                        ),
                      ),
              ),
              const SizedBox(height: 32),
              FadeSlideIn(
                index: 3,
                child: GradientButton(
                  label: 'Login',
                  icon: Icons.arrow_forward_rounded,
                  loading: _busy,
                  onPressed: _busy ? null : _login,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
