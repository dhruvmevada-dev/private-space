import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'config.dart';
import 'screens/home_screen.dart';
import 'screens/user_selection_screen.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'theme.dart';
import 'widgets/common.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.bg,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(const PrivateSpaceApp());
}

class PrivateSpaceApp extends StatelessWidget {
  const PrivateSpaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Private Space',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      themeMode: ThemeMode.dark,
      home: const _Splash(),
    );
  }
}

/// Validates the stored token: valid -> Home, otherwise -> user selection.
class _Splash extends StatefulWidget {
  const _Splash();

  @override
  State<_Splash> createState() => _SplashState();
}

class _SplashState extends State<_Splash> {
  String? _error;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    setState(() => _error = null);
    try {
      final valid = await AuthService.instance.restoreSession();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => valid ? const HomeScreen() : const UserSelectionScreen(),
      ));
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: _error != null
          ? ErrorView(message: _error!, onRetry: _check)
          : Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutBack,
                builder: (context, v, child) => Opacity(
                  opacity: v.clamp(0.0, 1.0),
                  child: Transform.scale(scale: 0.7 + 0.3 * v, child: child),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    LogoMark(size: 84),
                    SizedBox(height: 22),
                    Text(
                      'PRIVATE SPACE',
                      style: TextStyle(
                        fontSize: 18,
                        letterSpacing: 5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
