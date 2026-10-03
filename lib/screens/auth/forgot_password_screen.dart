import 'dart:math';
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../data/auth_service.dart';
import '../../data/models.dart';
import 'auth_widgets.dart';

/// Three animated steps: find the account, choose a new password, done.
///
/// Accounts live on this device, so the reset happens here too; there is no
/// email server to send a link from. Pops with the account's email once the
/// password has been changed.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail = ''});

  final String initialEmail;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

enum _Step { email, password, done }

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final GlobalKey<FormState> _emailForm = GlobalKey<FormState>();
  final GlobalKey<FormState> _passwordForm = GlobalKey<FormState>();
  late final TextEditingController _email = TextEditingController(
    text: widget.initialEmail,
  );
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirm = TextEditingController();

  _Step _step = _Step.email;
  bool _loading = false;
  String? _error;
  int _shakes = 0;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _fail(String message) => setState(() {
    _loading = false;
    _error = message;
    _shakes++;
  });

  Future<void> _findAccount() async {
    FocusScope.of(context).unfocus();
    setState(() => _error = null);
    if (!_emailForm.currentState!.validate()) {
      setState(() => _shakes++);
      return;
    }
    final AuthService auth = AppScope.of(context).auth;
    setState(() => _loading = true);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    final AppUser? user = auth.findByEmail(_email.text);
    if (user == null) {
      _fail('No account found for this email.');
    } else if (user.provider == AuthProvider.google && !user.hasPassword) {
      _fail(
        'This account signs in with Google, so it has no password to reset.',
      );
    } else {
      setState(() {
        _loading = false;
        _step = _Step.password;
      });
    }
  }

  Future<void> _savePassword() async {
    FocusScope.of(context).unfocus();
    setState(() => _error = null);
    if (!_passwordForm.currentState!.validate()) {
      setState(() => _shakes++);
      return;
    }
    final AuthService auth = AppScope.of(context).auth;
    setState(() => _loading = true);
    try {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      await auth.resetPassword(email: _email.text, newPassword: _password.text);
      setState(() {
        _loading = false;
        _step = _Step.done;
      });
    } on AuthException catch (error) {
      _fail(error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      title: 'Reset password',
      subtitle: 'Get back into your account in a few seconds',
      showBack: true,
      children: <Widget>[
        _StepIndicator(current: _step.index, count: _Step.values.length),
        const SizedBox(height: 20),
        ShakeOnChange(
          trigger: _shakes,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 420),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (Widget child, Animation<double> animation) {
              final bool incoming = child.key == ValueKey<_Step>(_step);
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: Offset(incoming ? 0.3 : -0.3, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            layoutBuilder: (Widget? current, List<Widget> previous) => Stack(
              alignment: Alignment.topCenter,
              children: <Widget>[...previous, ?current],
            ),
            child: KeyedSubtree(
              key: ValueKey<_Step>(_step),
              child: switch (_step) {
                _Step.email => _buildEmailStep(),
                _Step.password => _buildPasswordStep(),
                _Step.done => _buildDoneStep(),
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmailStep() {
    return Form(
      key: _emailForm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const _StepHeading(
            icon: Icons.mark_email_read_outlined,
            title: 'Find your account',
            message: 'Enter the email you signed up with.',
          ),
          AuthErrorBanner(message: _error),
          AuthTextField(
            key: const ValueKey<String>('forgot_email'),
            controller: _email,
            label: 'Email',
            icon: Icons.alternate_email_rounded,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _findAccount(),
            validator: validateEmail,
          ),
          const SizedBox(height: 4),
          AnimatedSubmitButton(
            key: const ValueKey<String>('forgot_continue'),
            label: 'Continue',
            loading: _loading,
            onPressed: _findAccount,
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordStep() {
    return Form(
      key: _passwordForm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _StepHeading(
            icon: Icons.password_rounded,
            title: 'Choose a new password',
            message: 'For ${_email.text.trim()}',
          ),
          AuthErrorBanner(message: _error),
          PasswordField(
            key: const ValueKey<String>('forgot_password'),
            controller: _password,
            label: 'New password',
            showStrength: true,
            autofillHints: const <String>[AutofillHints.newPassword],
            validator: validateNewPassword,
          ),
          PasswordField(
            key: const ValueKey<String>('forgot_confirm'),
            controller: _confirm,
            label: 'Confirm new password',
            textInputAction: TextInputAction.done,
            autofillHints: const <String>[AutofillHints.newPassword],
            onSubmitted: (_) => _savePassword(),
            validator: (String? v) =>
                v != _password.text ? 'Passwords do not match' : null,
          ),
          const SizedBox(height: 4),
          AnimatedSubmitButton(
            key: const ValueKey<String>('forgot_save'),
            label: 'Update password',
            loading: _loading,
            onPressed: _savePassword,
          ),
          TextButton(
            onPressed: _loading
                ? null
                : () => setState(() {
                    _error = null;
                    _step = _Step.email;
                  }),
            child: const Text('Use a different email'),
          ),
        ],
      ),
    );
  }

  Widget _buildDoneStep() {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Center(child: _AnimatedCheck(size: 96)),
        const SizedBox(height: 18),
        Text(
          'Password updated!',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'You can now log in with your new password.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 22),
        FilledButton(
          key: const ValueKey<String>('forgot_back_to_login'),
          onPressed: () => Navigator.of(context).pop(_email.text.trim()),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Text('Back to login'),
        ),
      ],
    );
  }
}

class _StepHeading extends StatelessWidget {
  const _StepHeading({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: scheme.onPrimaryContainer),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.current, required this.count});

  final int current;
  final int count;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Step ${current + 1} of $count',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          for (int i = 0; i < count; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: i == current ? 32 : 10,
              height: 10,
              decoration: BoxDecoration(
                color: i <= current ? scheme.primary : scheme.outlineVariant,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
        ],
      ),
    );
  }
}

/// A circle that draws itself, then a check mark stroked inside it.
class _AnimatedCheck extends StatelessWidget {
  const _AnimatedCheck({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1100),
      builder: (BuildContext context, double t, _) {
        final double pop = Curves.elasticOut.transform(
          ((t - 0.1) / 0.9).clamp(0.0, 1.0),
        );
        return Transform.scale(
          scale: 0.6 + 0.4 * pop,
          child: CustomPaint(
            size: Size.square(size),
            painter: _CheckPainter(
              progress: t,
              color: scheme.primary,
              fill: scheme.primaryContainer,
            ),
          ),
        );
      },
    );
  }
}

class _CheckPainter extends CustomPainter {
  _CheckPainter({
    required this.progress,
    required this.color,
    required this.fill,
  });

  final double progress;
  final Color color;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    final double circleT = (progress / 0.5).clamp(0.0, 1.0);
    final double checkT = ((progress - 0.45) / 0.55).clamp(0.0, 1.0);
    final Offset center = size.center(Offset.zero);
    final double radius = size.width / 2 - 4;
    final Paint stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawCircle(
      center,
      radius,
      Paint()..color = fill.withValues(alpha: circleT),
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * Curves.easeOut.transform(circleT),
      false,
      stroke,
    );

    if (checkT == 0) return;
    final Path check = Path()
      ..moveTo(size.width * 0.28, size.height * 0.52)
      ..lineTo(size.width * 0.44, size.height * 0.67)
      ..lineTo(size.width * 0.73, size.height * 0.37);
    for (final PathMetric metric in check.computeMetrics()) {
      canvas.drawPath(
        metric.extractPath(0, metric.length * Curves.easeOut.transform(checkT)),
        stroke,
      );
    }
  }

  @override
  bool shouldRepaint(_CheckPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.fill != fill;
}
