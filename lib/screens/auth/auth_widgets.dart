import 'dart:math';

import 'package:flutter/material.dart';

import '../../data/auth_service.dart';
import '../../data/models.dart';
import '../../ui/common.dart';

/// Brand gradient behind the splash and auth screens.
List<Color> brandGradient(Brightness brightness) =>
    brightness == Brightness.dark
    ? const <Color>[Color(0xFF7A3300), Color(0xFF2B1300)]
    : const <Color>[Color(0xFFFF8A00), Color(0xFFE64A19)];

/// The brand gradient with soft bubbles drifting around behind [child].
///
/// The drift stops when the platform asks for reduced motion.
class AnimatedAuthBackground extends StatefulWidget {
  const AnimatedAuthBackground({super.key, required this.child});

  final Widget child;

  @override
  State<AnimatedAuthBackground> createState() => _AnimatedAuthBackgroundState();
}

class _AnimatedAuthBackgroundState extends State<AnimatedAuthBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Color> colors = brandGradient(Theme.of(context).brightness);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(painter: _BubblePainter(_controller)),
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}

class _BubblePainter extends CustomPainter {
  _BubblePainter(this.animation) : super(repaint: animation);

  final Animation<double> animation;

  // (x, y, radius, speed, phase) as fractions of the screen size.
  static const List<List<double>> _bubbles = <List<double>>[
    <double>[0.12, 0.10, 0.22, 1, 0.0],
    <double>[0.92, 0.18, 0.30, 1, 1.7],
    <double>[0.80, 0.62, 0.18, 2, 3.1],
    <double>[0.06, 0.70, 0.26, 1, 4.4],
    <double>[0.55, 0.95, 0.20, 2, 2.2],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final double t = animation.value * 2 * pi;
    final double unit = size.shortestSide;
    final Paint paint = Paint()..color = Colors.white.withValues(alpha: 0.10);
    for (final List<double> b in _bubbles) {
      final double angle = t * b[3] + b[4];
      final Offset center = Offset(
        b[0] * size.width + cos(angle) * unit * 0.05,
        b[1] * size.height + sin(angle) * unit * 0.05,
      );
      canvas.drawCircle(center, b[2] * unit * (1 + 0.06 * sin(angle)), paint);
    }
  }

  @override
  bool shouldRepaint(_BubblePainter oldDelegate) =>
      oldDelegate.animation != animation;
}

/// Shared layout for the sign-up, login and forgot-password screens: the
/// animated background, the hero logo, a heading and a card for the form.
class AuthLayout extends StatelessWidget {
  const AuthLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.showBack = false,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      body: AnimatedAuthBackground(
        child: SafeArea(
          child: Stack(
            children: <Widget>[
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        const Center(
                          child: Hero(
                            tag: appLogoHeroTag,
                            child: AppLogo(size: 84),
                          ),
                        ),
                        const SizedBox(height: 18),
                        FadeSlideIn(
                          index: 0,
                          child: Text(
                            title,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        FadeSlideIn(
                          index: 1,
                          child: Text(
                            subtitle,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        FadeSlideIn(
                          index: 2,
                          child: Material(
                            color: theme.colorScheme.surface,
                            elevation: 0,
                            borderRadius: BorderRadius.circular(28),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                24,
                                20,
                                20,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: <Widget>[
                                  for (int i = 0; i < children.length; i++)
                                    FadeSlideIn(
                                      index: i + 3,
                                      step: 55,
                                      child: children[i],
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (showBack)
                Positioned(
                  left: 4,
                  top: 4,
                  child: IconButton(
                    tooltip: 'Back',
                    color: Colors.white,
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.validator,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
    this.autofillHints,
    this.onSubmitted,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onSubmitted;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        autofillHints: autofillHints,
        textCapitalization: textCapitalization,
        onFieldSubmitted: onSubmitted,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      ),
    );
  }
}

class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    this.label = 'Password',
    this.validator,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
    this.showStrength = false,
    this.autofillHints = const <String>[AutofillHints.password],
  });

  final TextEditingController controller;
  final String label;
  final FormFieldValidator<String>? validator;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;
  final bool showStrength;
  final Iterable<String> autofillHints;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          TextFormField(
            controller: widget.controller,
            validator: widget.validator,
            obscureText: _obscured,
            textInputAction: widget.textInputAction,
            autofillHints: widget.autofillHints,
            onFieldSubmitted: widget.onSubmitted,
            decoration: InputDecoration(
              labelText: widget.label,
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                tooltip: _obscured ? 'Show password' : 'Hide password',
                onPressed: () => setState(() => _obscured = !_obscured),
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (Widget child, Animation<double> a) =>
                      RotationTransition(
                        turns: Tween<double>(begin: 0.75, end: 1).animate(a),
                        child: FadeTransition(opacity: a, child: child),
                      ),
                  child: Icon(
                    _obscured
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    key: ValueKey<bool>(_obscured),
                  ),
                ),
              ),
            ),
          ),
          if (widget.showStrength)
            ListenableBuilder(
              listenable: widget.controller,
              builder: (BuildContext context, _) =>
                  _StrengthMeter(password: widget.controller.text),
            ),
        ],
      ),
    );
  }
}

class _StrengthMeter extends StatelessWidget {
  const _StrengthMeter({required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) {
      return const SizedBox.shrink();
    }
    int score = 0;
    if (password.length >= 6) score++;
    if (password.length >= 10) score++;
    if (RegExp(r'\d').hasMatch(password)) score++;
    if (RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[^A-Za-z0-9]').hasMatch(password)) {
      score++;
    }
    const List<String> labels = <String>[
      'Too weak',
      'Weak',
      'Okay',
      'Good',
      'Strong',
    ];
    const List<Color> colors = <Color>[
      Color(0xFFD32F2F),
      Color(0xFFF57C00),
      Color(0xFFFBC02D),
      Color(0xFF7CB342),
      Color(0xFF2E7D32),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
      child: Row(
        children: <Widget>[
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(end: (score + 1) / 5),
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                builder: (BuildContext context, double value, _) =>
                    LinearProgressIndicator(
                      value: value,
                      minHeight: 6,
                      color: colors[score],
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                    ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              labels[score],
              key: ValueKey<int>(score),
              style: TextStyle(
                color: colors[score],
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A full-width button that morphs into a spinner while [loading].
class AnimatedSubmitButton extends StatelessWidget {
  const AnimatedSubmitButton({
    super.key,
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  final String label;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOutCubic,
            width: loading ? 54 : constraints.maxWidth,
            height: 54,
            child: FilledButton(
              onPressed: loading ? null : onPressed,
              style: FilledButton.styleFrom(
                padding: EdgeInsets.zero,
                disabledBackgroundColor: scheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(loading ? 27 : 16),
                ),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: loading
                    ? SizedBox(
                        key: const ValueKey<String>('spinner'),
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.6,
                          color: scheme.onPrimary,
                        ),
                      )
                    : Text(
                        label,
                        key: const ValueKey<String>('label'),
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        softWrap: false,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: <Widget>[
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('or', style: TextStyle(color: scheme.onSurfaceVariant)),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }
}

class GoogleButton extends StatelessWidget {
  const GoogleButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      key: const ValueKey<String>('google_button'),
      onPressed: loading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: loading
                ? const SizedBox(
                    key: ValueKey<String>('spinner'),
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  )
                : const SizedBox(
                    key: ValueKey<String>('logo'),
                    width: 22,
                    height: 22,
                    child: CustomPaint(painter: _GoogleLogoPainter()),
                  ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// The four-colour Google "G", drawn so no image asset is needed.
class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double stroke = size.width * 0.22;
    final Rect rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );
    Paint arc(Color color) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    double rad(double degrees) => degrees * pi / 180;

    canvas
      ..drawArc(rect, rad(-140), rad(100), false, arc(const Color(0xFFEA4335)))
      ..drawArc(rect, rad(140), rad(80), false, arc(const Color(0xFFFBBC05)))
      ..drawArc(rect, rad(45), rad(95), false, arc(const Color(0xFF34A853)))
      ..drawArc(rect, rad(0), rad(45), false, arc(const Color(0xFF4285F4)))
      ..drawRect(
        Rect.fromLTWH(
          size.width / 2,
          size.height / 2 - stroke / 2,
          size.width / 2,
          stroke,
        ),
        Paint()..color = const Color(0xFF4285F4),
      );
  }

  @override
  bool shouldRepaint(_GoogleLogoPainter oldDelegate) => false;
}

/// Shakes [child] sideways every time [trigger] changes, e.g. on a failed
/// submit.
class ShakeOnChange extends StatefulWidget {
  const ShakeOnChange({super.key, required this.trigger, required this.child});

  final int trigger;
  final Widget child;

  @override
  State<ShakeOnChange> createState() => _ShakeOnChangeState();
}

class _ShakeOnChangeState extends State<ShakeOnChange>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );

  @override
  void didUpdateWidget(ShakeOnChange oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != oldWidget.trigger) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final double t = _controller.value;
        final double dx = sin(t * pi * 6) * 12 * (1 - t);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: widget.child,
    );
  }
}

/// Inline error banner that grows in when [message] is set.
class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({super.key, required this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      child: message == null
          ? const SizedBox(width: double.infinity)
          : Container(
              key: const ValueKey<String>('auth_error'),
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.errorContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: <Widget>[
                  Icon(Icons.error_outline_rounded, color: scheme.error),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      message!,
                      style: TextStyle(color: scheme.onErrorContainer),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

/// "Join as a teacher" / "Join as a student" selector.
class RolePicker extends StatelessWidget {
  const RolePicker({super.key, required this.value, required this.onChanged});

  final UserRole value;
  final ValueChanged<UserRole> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: <Widget>[
          for (final UserRole role in UserRole.values) ...<Widget>[
            if (role != UserRole.values.first) const SizedBox(width: 12),
            Expanded(
              child: _RoleCard(
                role: role,
                selected: role == value,
                onTap: () => onChanged(role),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.role,
    required this.selected,
    required this.onTap,
  });

  final UserRole role;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final String blurb = role == UserRole.teacher
        ? 'Create quizzes'
        : 'Solve quizzes';

    return Semantics(
      button: true,
      selected: selected,
      label: 'Join as a ${role.label.toLowerCase()}. $blurb',
      child: ExcludeSemantics(
        child: AnimatedScale(
          scale: selected ? 1 : 0.95,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutBack,
          child: AnimatedContainer(
            key: ValueKey<String>('role_${role.name}'),
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: selected
                  ? scheme.primaryContainer
                  : scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected ? scheme.primary : scheme.outlineVariant,
                width: selected ? 2 : 1,
              ),
            ),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: <Widget>[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          TweenAnimationBuilder<double>(
                            tween: Tween<double>(end: selected ? 1 : 0),
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.elasticOut,
                            builder: (BuildContext context, double v, _) =>
                                Transform.rotate(
                                  angle: sin(v * pi) * 0.15,
                                  child: Transform.scale(
                                    scale: 1 + v * 0.12,
                                    child: Icon(
                                      role.icon,
                                      size: 34,
                                      color: selected
                                          ? scheme.primary
                                          : scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Join as ${role.label}',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: selected
                                  ? scheme.onPrimaryContainer
                                  : scheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            blurb,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: selected
                                  ? scheme.onPrimaryContainer
                                  : scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      Positioned(
                        right: -4,
                        top: -6,
                        child: AnimatedScale(
                          scale: selected ? 1 : 0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutBack,
                          child: Icon(
                            Icons.check_circle_rounded,
                            color: scheme.primary,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Asks a first-time Google user which role they are joining as.
Future<UserRole?> pickRoleSheet(BuildContext context) {
  return showModalBottomSheet<UserRole>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (BuildContext context) {
      UserRole role = UserRole.student;
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setSheetState) {
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    'One last step',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'How will you use Studyy Buddy?',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  RolePicker(
                    value: role,
                    onChanged: (UserRole r) => setSheetState(() => role = r),
                  ),
                  FilledButton(
                    key: const ValueKey<String>('role_continue'),
                    onPressed: () => Navigator.of(context).pop(role),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Continue'),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

// ---------------------------------------------------------------------------
// Validators
// ---------------------------------------------------------------------------

final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

String? validateEmail(String? value) {
  final String email = value?.trim() ?? '';
  if (email.isEmpty) return 'Enter your email';
  if (!_emailPattern.hasMatch(email)) return 'Enter a valid email address';
  return null;
}

String? validateNewPassword(String? value) {
  final String password = value ?? '';
  if (password.isEmpty) return 'Enter a password';
  if (password.length < AuthService.minPasswordLength) {
    return 'Use at least ${AuthService.minPasswordLength} characters';
  }
  return null;
}

/// "Already have an account? Log in" style footer link.
class SwitchAuthLink extends StatelessWidget {
  const SwitchAuthLink({
    super.key,
    required this.prompt,
    required this.action,
    required this.onTap,
    required this.buttonKey,
  });

  final String prompt;
  final String action;
  final VoidCallback onTap;
  final Key buttonKey;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        Text(prompt),
        TextButton(key: buttonKey, onPressed: onTap, child: Text(action)),
      ],
    );
  }
}
