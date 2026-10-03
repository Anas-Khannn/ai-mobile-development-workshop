import 'dart:math';

import 'package:flutter/material.dart';

import '../data/app_scope.dart';
import '../data/auth_service.dart';
import '../data/models.dart';
import '../ui/common.dart';
import 'auth/login_screen.dart';
import 'auth/signup_screen.dart';
import 'navigation.dart';

/// Animated intro: the logo springs in over ripples, the name types itself
/// out letter by letter, then the app moves on to sign-up, login or home.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.onFinished});

  /// Called once the intro has played. When null the splash picks the next
  /// screen itself, which needs an [AppScope] above it.
  final VoidCallback? onFinished;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  static const String _name = 'Studyy Buddy';

  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  late final Animation<double> _logoScale = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0, 0.45, curve: Curves.elasticOut),
  );
  late final Animation<double> _logoTurn = Tween<double>(begin: -0.6, end: 0)
      .animate(
        CurvedAnimation(
          parent: _intro,
          curve: const Interval(0, 0.4, curve: Curves.easeOutBack),
        ),
      );
  late final Animation<double> _tagline = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0.62, 0.85, curve: Curves.easeOut),
  );
  late final Animation<double> _loader = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0.75, 0.95, curve: Curves.easeOut),
  );

  @override
  void initState() {
    super.initState();
    _intro.forward().whenComplete(_continue);
  }

  Future<void> _continue() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    final VoidCallback? onFinished = widget.onFinished;
    if (onFinished != null) {
      onFinished();
      return;
    }
    final AuthService auth = AppScope.of(context).auth;
    final AppUser? user = auth.currentUser;
    final Widget next = user != null
        ? homeFor(user)
        : auth.hasAccounts
        ? const LoginScreen()
        : const SignUpScreen();
    Navigator.of(context)
        .pushReplacement(fadeScaleRoute<void>(next, milliseconds: 800));
  }

  @override
  void dispose() {
    _intro.dispose();
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            // Starts on the native launch colour (#FF6D00) for a seamless
            // hand-off from the platform splash.
            colors: <Color>[
              Color(0xFFFF8A00),
              Color(0xFFFF6D00),
              Color(0xFFE64A19),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: <Widget>[
              const Spacer(flex: 3),
              SizedBox(
                width: 220,
                height: 220,
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _RipplePainter(_loop, _logoScale),
                      ),
                    ),
                    AnimatedBuilder(
                      animation: _intro,
                      builder: (BuildContext context, Widget? child) =>
                          Transform.rotate(
                            angle: _logoTurn.value,
                            child: Transform.scale(
                              scale: _logoScale.value,
                              child: child,
                            ),
                          ),
                      child: const Hero(
                        tag: appLogoHeroTag,
                        child: AppLogo(size: 120),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Semantics(
                    label: _name,
                    child: ExcludeSemantics(
                      child: AnimatedBuilder(
                        animation: _intro,
                        builder: (BuildContext context, _) => Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            for (int i = 0; i < _name.length; i++)
                              _letter(i, text.displaySmall),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              FadeTransition(
                opacity: _tagline,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.6),
                    end: Offset.zero,
                  ).animate(_tagline),
                  child: Text(
                    'Learn together. Quiz smarter.',
                    style: text.titleMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.92),
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),
              const Spacer(flex: 2),
              FadeTransition(
                opacity: _loader,
                child: _BouncingDots(animation: _loop),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _letter(int i, TextStyle? style) {
    final double start = 0.3 + i * 0.025;
    final double t = ((_intro.value - start) / 0.18).clamp(0.0, 1.0);
    final double eased = Curves.easeOutBack.transform(t);
    return Opacity(
      opacity: t,
      child: Transform.translate(
        offset: Offset(0, 28 * (1 - eased)),
        child: Text(
          _name[i],
          style: style?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
            shadows: const <Shadow>[
              Shadow(
                color: Colors.black26,
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Two rings expanding out from behind the logo once it has landed.
class _RipplePainter extends CustomPainter {
  _RipplePainter(this.loop, this.reveal)
    : super(repaint: Listenable.merge(<Listenable>[loop, reveal]));

  final Animation<double> loop;
  final Animation<double> reveal;

  @override
  void paint(Canvas canvas, Size size) {
    final double strength = reveal.value.clamp(0.0, 1.0);
    if (strength == 0) return;
    final Offset center = size.center(Offset.zero);
    final double maxRadius = size.width / 2;
    for (int i = 0; i < 2; i++) {
      final double t = (loop.value + i / 2) % 1;
      final Paint paint = Paint()
        ..color = Colors.white.withValues(alpha: (1 - t) * 0.35 * strength)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawCircle(center, maxRadius * (0.55 + 0.45 * t), paint);
    }
    canvas.drawCircle(
      center,
      maxRadius * 0.62,
      Paint()..color = Colors.white.withValues(alpha: 0.12 * strength),
    );
  }

  @override
  bool shouldRepaint(_RipplePainter oldDelegate) => false;
}

class _BouncingDots extends StatelessWidget {
  const _BouncingDots({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (int i = 0; i < 3; i++)
            Transform.translate(
              offset: Offset(
                0,
                -10 * max(0, sin((animation.value - i * 0.15) * 2 * pi)),
              ),
              child: Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.symmetric(horizontal: 5),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
