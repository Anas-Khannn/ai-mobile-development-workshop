import 'dart:math';

import 'package:flutter/material.dart';

const EdgeInsets pagePadding = EdgeInsets.fromLTRB(20, 8, 20, 24);

const String appLogoHeroTag = 'app-logo';

// ---------------------------------------------------------------------------
// Page transitions
// ---------------------------------------------------------------------------

/// Fades and gently zooms the new page in.
Route<T> fadeScaleRoute<T>(Widget page, {int milliseconds = 550}) {
  return PageRouteBuilder<T>(
    transitionDuration: Duration(milliseconds: milliseconds),
    reverseTransitionDuration: const Duration(milliseconds: 350),
    pageBuilder: (_, _, _) => page,
    transitionsBuilder: (_, Animation<double> animation, _, Widget child) {
      final Animation<double> curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// Slides the new page in from the side ([fromRight] = forward navigation).
Route<T> slideRoute<T>(Widget page, {bool fromRight = true}) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 480),
    reverseTransitionDuration: const Duration(milliseconds: 380),
    pageBuilder: (_, _, _) => page,
    transitionsBuilder: (_, Animation<double> animation, _, Widget child) {
      final Animation<double> curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return SlideTransition(
        position: Tween<Offset>(
          begin: Offset(fromRight ? 0.25 : -0.25, 0),
          end: Offset.zero,
        ).animate(curved),
        child: FadeTransition(opacity: curved, child: child),
      );
    },
  );
}

// ---------------------------------------------------------------------------
// Entrance animation
// ---------------------------------------------------------------------------

/// Fades and slides [child] up when it first appears; [index] staggers it
/// after its siblings.
class FadeSlideIn extends StatelessWidget {
  const FadeSlideIn({
    super.key,
    required this.index,
    required this.child,
    this.step = 70,
  });

  final int index;
  final int step;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final int delay = index * step;
    final int total = delay + 450;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: total),
      builder: (BuildContext context, double t, Widget? child) {
        // The first [delay] ms are a hold, the rest is the actual animation.
        final double local = ((t * total - delay) / 450).clamp(0.0, 1.0);
        final double eased = Curves.easeOutCubic.transform(local);
        return Opacity(
          opacity: eased,
          child: Transform.translate(
            offset: Offset(0, 24 * (1 - eased)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

// ---------------------------------------------------------------------------
// Logo
// ---------------------------------------------------------------------------

/// The launcher-icon artwork in a white disc.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 96});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: size * 0.3,
            offset: Offset(0, size * 0.06),
          ),
        ],
      ),
      child: ClipOval(
        child: Transform.scale(
          // The foreground artwork sits in the middle 66% of its canvas.
          scale: 1.45,
          child: Image.asset(
            'assets/icon/app_icon_foreground.png',
            fit: BoxFit.contain,
            semanticLabel: 'Studyy Buddy logo',
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Small building blocks shared by the home and quiz screens
// ---------------------------------------------------------------------------

class HeaderCard extends StatelessWidget {
  const HeaderCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: dark
              ? const <Color>[Color(0xFF8A3A00), Color(0xFF4A1C00)]
              : const <Color>[Color(0xFFF57C00), Color(0xFFD84315)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: Colors.white),
        child: IconTheme.merge(
          data: IconThemeData(color: Colors.white),
          child: child,
        ),
      ),
    );
  }
}

class Pill extends StatelessWidget {
  const Pill({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
    this.icon,
  });

  final String label;
  final Color background;
  final Color foreground;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: foreground,
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

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Icon, title and message for screens or sections with nothing to show.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        children: <Widget>[
          Icon(icon, size: 48, color: scheme.primary),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Scrolls when the content is taller than the viewport and centres it when it
/// is shorter, so short screens can never overflow.
class ScrollableCenteredPage extends StatelessWidget {
  const ScrollableCenteredPage({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return SingleChildScrollView(
          padding: pagePadding,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: max(0, constraints.maxHeight - pagePadding.vertical),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[child],
            ),
          ),
        );
      },
    );
  }
}

String percentLabel(double fraction) => '${(fraction * 100).round()}%';

String shortDate(DateTime date) {
  const List<String> months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

/// "1 question", "3 questions".
String plural(int count, String noun) => '$count $noun${count == 1 ? '' : 's'}';
