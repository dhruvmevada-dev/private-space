import 'package:flutter/material.dart';

import '../theme.dart';

/// Scaffold with a soft violet/teal glow behind the content.
class AppScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;

  const AppScaffold({super.key, this.appBar, required this.body, this.floatingActionButton});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.bg,
      child: Stack(
        children: [
          const Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(-0.95, -1.1),
                    radius: 1.3,
                    colors: [Color(0x337C6CFF), Color(0x007C6CFF)],
                  ),
                ),
              ),
            ),
          ),
          const Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(1.0, 1.1),
                    radius: 1.1,
                    colors: [Color(0x1F4FD1C5), Color(0x004FD1C5)],
                  ),
                ),
              ),
            ),
          ),
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: appBar,
            body: body,
            floatingActionButton: floatingActionButton,
          ),
        ],
      ),
    );
  }
}

class LogoMark extends StatelessWidget {
  final double size;
  const LogoMark({super.key, this.size = 64});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppColors.gradient,
        borderRadius: BorderRadius.circular(size * 0.32),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.45),
            blurRadius: size * 0.5,
            offset: Offset(0, size * 0.15),
          ),
        ],
      ),
      child: Icon(Icons.lock_outline_rounded, color: Colors.white, size: size * 0.5),
    );
  }
}

class Avatar extends StatelessWidget {
  final String name;
  final double size;
  final String? heroTag;

  const Avatar({super.key, required this.name, this.size = 48, this.heroTag});

  static const _palettes = <List<Color>>[
    [Color(0xFF7C6CFF), Color(0xFF4F8CFF)],
    [Color(0xFFFF7EB3), Color(0xFFFF758C)],
    [Color(0xFF4FD1C5), Color(0xFF3B9EE8)],
    [Color(0xFFFFB86B), Color(0xFFFF7A59)],
    [Color(0xFF8BE28B), Color(0xFF2FBF9F)],
  ];

  @override
  Widget build(BuildContext context) {
    final idx = name.codeUnits.fold<int>(0, (a, b) => a + b) % _palettes.length;
    final circle = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _palettes[idx],
        ),
      ),
      child: Text(
        name.isEmpty ? '?' : name[0].toUpperCase(),
        style: TextStyle(color: Colors.white, fontSize: size * 0.42, fontWeight: FontWeight.w700),
      ),
    );
    if (heroTag == null) return circle;
    return Hero(
      tag: heroTag!,
      child: Material(type: MaterialType.transparency, child: circle),
    );
  }
}

/// Staggered entrance: fades in and slides up. Use `index` for the stagger.
class FadeSlideIn extends StatelessWidget {
  final Widget child;
  final int index;

  const FadeSlideIn({super.key, required this.child, this.index = 0});

  @override
  Widget build(BuildContext context) {
    final delay = (index.clamp(0, 8)) * 60;
    final total = 420 + delay;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: total),
      curve: Interval(delay / total, 1.0, curve: Curves.easeOutCubic),
      builder: (context, v, ch) => Opacity(
        opacity: v.clamp(0.0, 1.0),
        child: Transform.translate(offset: Offset(0, (1 - v) * 18), child: ch),
      ),
      child: child,
    );
  }
}

class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final dimmed = onPressed == null && !loading;
    return AnimatedOpacity(
      opacity: dimmed ? 0.5 : 1,
      duration: const Duration(milliseconds: 200),
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            gradient: AppColors.gradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.35),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: loading ? null : onPressed,
            child: Container(
              height: 54,
              alignment: Alignment.center,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: loading
                    ? const SizedBox(
                        key: ValueKey('loading'),
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                      )
                    : Row(
                        key: const ValueKey('label'),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (icon != null) ...[
                            Icon(icon, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SkeletonList extends StatefulWidget {
  final int count;
  const SkeletonList({super.key, this.count = 4});

  @override
  State<SkeletonList> createState() => _SkeletonListState();
}

class _SkeletonListState extends State<SkeletonList> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))
        ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.4, end: 1).animate(
        CurvedAnimation(parent: _c, curve: Curves.easeInOut),
      ),
      child: Column(
        children: [
          for (var i = 0; i < widget.count; i++)
            Container(
              height: 86,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.outline),
              ),
            ),
        ],
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ErrorView({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: FadeSlideIn(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.muted),
              const SizedBox(height: 16),
              Text(message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted, height: 1.4)),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.text,
                  side: const BorderSide(color: AppColors.outline),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
