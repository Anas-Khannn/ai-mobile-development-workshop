import 'dart:math';

import 'package:flutter/material.dart';

import '../data/models.dart';
import '../ui/common.dart';
import 'navigation.dart';

/// Avatar in the app bar that opens the account menu with "Log out".
class AccountButton extends StatelessWidget {
  const AccountButton({super.key, required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    return PopupMenuButton<String>(
      key: const ValueKey<String>('account_menu'),
      tooltip: 'Account',
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (String value) {
        if (value == 'logout') logOut(context);
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                user.name,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(user.email, style: theme.textTheme.bodySmall),
              const SizedBox(height: 6),
              Pill(
                label: user.role.label,
                icon: user.role.icon,
                background: scheme.secondaryContainer,
                foreground: scheme.onSecondaryContainer,
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          key: ValueKey<String>('logout'),
          value: 'logout',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.logout_rounded),
            title: Text('Log out'),
          ),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.only(right: 12),
        child: CircleAvatar(
          radius: 18,
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          child: Text(
            user.name.isEmpty ? '?' : user.name[0].toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

/// Gradient greeting card at the top of both home screens.
class GreetingCard extends StatelessWidget {
  const GreetingCard({
    super.key,
    required this.user,
    required this.message,
    required this.stats,
  });

  final AppUser user;
  final String message;
  final List<HeaderStat> stats;

  @override
  Widget build(BuildContext context) {
    return HeaderCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Hi, ${user.firstName}!',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _WavingHand(),
            ],
          ),
          const SizedBox(height: 4),
          Text(message, style: const TextStyle(fontSize: 14)),
          if (stats.isNotEmpty) ...<Widget>[
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                for (final HeaderStat stat in stats)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(
                            begin: 0,
                            end: stat.value.toDouble(),
                          ),
                          duration: const Duration(milliseconds: 900),
                          curve: Curves.easeOutCubic,
                          builder: (BuildContext context, double v, _) => Text(
                            '${v.round()}${stat.suffix}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Text(
                          stat.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _WavingHand extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1400),
      builder: (BuildContext context, double t, Widget? child) =>
          Transform.rotate(
            angle: 0.4 * sin(t * 6 * pi) * (1 - t),
            alignment: Alignment.bottomRight,
            child: child,
          ),
      child: const Text('👋', style: TextStyle(fontSize: 26)),
    );
  }
}

/// A number in the greeting card that counts up from zero.
class HeaderStat {
  const HeaderStat(this.value, this.label, {this.suffix = ''});

  final int value;
  final String label;
  final String suffix;
}
