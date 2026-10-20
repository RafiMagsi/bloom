import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../state/bloom_scope.dart';
import '../theme/bloom_theme.dart';

/// Beautiful, shareable progress card + share button (Bloom.pdf §1, §5).
class ShareProgressCard extends StatefulWidget {
  const ShareProgressCard({super.key});

  @override
  State<ShareProgressCard> createState() => _ShareProgressCardState();
}

class _ShareProgressCardState extends State<ShareProgressCard> {
  final GlobalKey _cardKey = GlobalKey();

  Future<void> _share() async {
    HapticFeedback.mediumImpact();
    const caption =
        'My Bloom progress 🌸 Small habits. Softer days. A better you.';
    final messenger = ScaffoldMessenger.of(context);
    try {
      final boundary = _cardKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) {
        throw StateError('card not rendered');
      }
      final image = await boundary.toImage(pixelRatio: 2.5);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) {
        throw StateError('no png data');
      }
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              data.buffer.asUint8List(),
              mimeType: 'image/png',
              name: 'my-bloom-progress.png',
            ),
          ],
          text: caption,
        ),
      );
    } catch (_) {
      // Graceful fallback: share the stats as text instead of a screenshot.
      try {
        await SharePlus.instance.share(ShareParams(text: caption));
      } catch (e) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Sharing is not available here ($e)'),
            backgroundColor: BloomPalette.ink,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = BloomScope.of(context);
    final challenge = controller.challengeActive
        ? '${controller.challengeDone.length}/30'
        : '—';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RepaintBoundary(
          key: _cardKey,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF6B4C7),
                  BloomPalette.blushDeep,
                  Color(0xFFC96E93),
                ],
              ),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: BloomPalette.blushDeep.withValues(alpha: 0.45),
                  blurRadius: 26,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('🌸', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Text(
                      'BLOOM · MY RESET',
                      style: BloomText.overline(color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _Stat(
                      value: '${controller.currentStreak}',
                      label: 'day streak',
                      emoji: '🔥',
                    ),
                    _Stat(
                      value: '${controller.totalCompletions}',
                      label: 'check-ins',
                      emoji: '✅',
                    ),
                    _Stat(
                      value: challenge,
                      label: 'reset days',
                      emoji: '🌿',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Small habits. Softer days. A better you.',
                  style: BloomText.display(22,
                      wght: 700,
                      fontStyle: FontStyle.italic,
                      color: Colors.white),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 54,
          child: OutlinedButton.icon(
            onPressed: _share,
            icon: const Icon(Icons.ios_share_rounded, size: 19),
            label: Text('Share my progress', style: BloomText.button(color: BloomPalette.blushDeep)),
            style: OutlinedButton.styleFrom(
              foregroundColor: BloomPalette.blushDeep,
              side: const BorderSide(color: BloomPalette.blush, width: 1.6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(26),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, required this.emoji});

  final String value;
  final String label;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 4),
          Text(
            value,
            style: BloomText.display(30, wght: 700, color: Colors.white),
          ),
          Text(
            label,
            style: BloomText.body(11.5,
                wght: 700, color: Colors.white.withValues(alpha: 0.9)),
          ),
        ],
      ),
    );
  }
}
