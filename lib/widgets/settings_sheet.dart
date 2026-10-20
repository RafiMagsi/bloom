import 'package:flutter/material.dart';

import '../state/bloom_controller.dart';
import '../state/bloom_scope.dart';
import '../theme/bloom_theme.dart';

/// Settings sheet: profile name, daily reminders, replay welcome, reset data.
Future<void> showSettingsSheet(
  BuildContext context, {
  required BloomController controller,
  required VoidCallback onReplayWelcome,
  required VoidCallback onResetData,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _SettingsSheet(
      controller: controller,
      onReplayWelcome: onReplayWelcome,
      onResetData: onResetData,
    ),
  );
}

class _SettingsSheet extends StatefulWidget {
  const _SettingsSheet({
    required this.controller,
    required this.onReplayWelcome,
    required this.onResetData,
  });

  final BloomController controller;
  final VoidCallback onReplayWelcome;
  final VoidCallback onResetData;

  @override
  State<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<_SettingsSheet> {
  late final TextEditingController _name;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.controller.userName);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = BloomScope.of(context);
    final viewInsets = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 26),
        decoration: const BoxDecoration(
          color: BloomPalette.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: BloomPalette.creamDeep,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text('Settings', style: BloomText.h2()),
              const SizedBox(height: 18),
              Text('YOUR NAME', style: BloomText.overline()),
              const SizedBox(height: 8),
              TextField(
                controller: _name,
                maxLength: 24,
                textCapitalization: TextCapitalization.words,
                style: BloomText.cardTitle(),
                onChanged: controller.setUserName,
                decoration: InputDecoration(
                  counterText: '',
                  hintText: 'How should we greet you?',
                  hintStyle: BloomText.cardTitle(color: BloomPalette.inkSoft),
                  filled: true,
                  fillColor: BloomPalette.cream,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 15,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: BloomPalette.blush),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text('DAILY REMINDERS', style: BloomText.overline()),
              const SizedBox(height: 6),
              _ReminderTile(
                emoji: '☀️',
                title: 'Morning reminder',
                subtitle: 'A gentle nudge to start your glow-up',
                value: controller.morningReminder,
                onChanged: controller.setMorningReminder,
              ),
              _ReminderTile(
                emoji: '🌙',
                title: 'Evening reminder',
                subtitle: 'A soft reminder for your night reset',
                value: controller.eveningReminder,
                onChanged: controller.setEveningReminder,
              ),
              const SizedBox(height: 10),
              Text('MORE', style: BloomText.overline()),
              const SizedBox(height: 6),
              _NavTile(
                emoji: '🌸',
                title: 'Replay the welcome',
                onTap: () {
                  Navigator.of(context).pop();
                  widget.onReplayWelcome();
                },
              ),
              _NavTile(
                emoji: '🧹',
                title: 'Reset all data',
                destructive: true,
                onTap: () {
                  Navigator.of(context).pop();
                  widget.onResetData();
                },
              ),
              const SizedBox(height: 14),
              Center(
                child: Text(
                  'Bloom v1.0 · Made with 💗 by DropTicks AI',
                  style: BloomText.caption(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReminderTile extends StatelessWidget {
  const _ReminderTile({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
      decoration: BoxDecoration(
        color: BloomPalette.cream,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: BloomText.cardTitle()),
                Text(subtitle, style: BloomText.caption()),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: Colors.white,
            activeTrackColor: BloomPalette.sageDeep,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.emoji,
    required this.title,
    required this.onTap,
    this.destructive = false,
  });

  final String emoji;
  final String title;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: BloomPalette.cream,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: BloomText.cardTitle(
                  color: destructive ? BloomPalette.rose : BloomPalette.ink,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: BloomPalette.inkSoft.withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
    );
  }
}
