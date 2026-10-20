import 'package:flutter/material.dart';

import '../data/bloom_content.dart';
import '../data/mood_insights.dart';
import '../state/bloom_controller.dart';
import '../theme/bloom_theme.dart';
import 'motion.dart';

/// "Your month in moods": a soft curve through the last 30 days of
/// check-ins that draws itself in, plus plain-language insights.
class MoodTrendCard extends StatelessWidget {
  const MoodTrendCard({super.key, required this.controller});

  final BloomController controller;

  static const _months = [
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

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final first = DateTime(today.year, today.month, today.day - 29);
    final points = <_MoodPoint>[];
    for (var i = 0; i < 30; i++) {
      final day = DateTime(first.year, first.month, first.day + i);
      final mood = controller.moodOn(day);
      if (mood == null) continue;
      final index = mood.moodIndex.clamp(0, kMoods.length - 1);
      points.add(_MoodPoint(i / 29, kMoodValence[index], kMoodColors[index]));
    }
    final insights = controller.moodInsights;
    final entrance = EntranceScope.maybeOf(context) ?? kAlwaysCompleteAnimation;
    final draw = CurvedAnimation(
      parent: entrance,
      curve: const Interval(0.3, 1, curve: Curves.easeInOutCubic),
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      decoration: BoxDecoration(
        color: BloomPalette.card,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: BloomPalette.blushDeep.withValues(alpha: 0.08),
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
              Expanded(
                child: Text('Your month in moods', style: BloomText.h3()),
              ),
              Text(
                '${points.length} check-ins',
                style: BloomText.small(color: BloomPalette.blushDeep),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('How your days have felt.', style: BloomText.caption()),
          const SizedBox(height: 14),
          if (points.length < 2)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Text(
                'Check in for a few days to see your mood curve bloom 🌷',
                style: BloomText.text(color: BloomPalette.inkSoft),
              ),
            )
          else ...[
            SizedBox(
              height: 150,
              child: AnimatedBuilder(
                animation: draw,
                builder: (context, _) => CustomPaint(
                  size: Size.infinite,
                  painter: _TrendPainter(points, draw.value),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: _TrendPainter.gutter),
              child: Row(
                children: [
                  Text(
                    '${first.day} ${_months[first.month - 1]}',
                    style: BloomText.caption(),
                  ),
                  const Spacer(),
                  Text(
                    'Today',
                    style: BloomText.caption(color: BloomPalette.blushDeep),
                  ),
                ],
              ),
            ),
          ],
          if (insights.isNotEmpty) ...[
            const SizedBox(height: 16),
            for (var i = 0; i < insights.length; i++)
              _InsightRow(
                insight: insights[i],
                appear: CurvedAnimation(
                  parent: entrance,
                  curve: Interval(
                    0.55 + i * 0.1,
                    (0.9 + i * 0.05).clamp(0.0, 1.0),
                    curve: BloomMotion.settle,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  const _InsightRow({required this.insight, required this.appear});

  final MoodInsight insight;
  final Animation<double> appear;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appear,
      builder: (context, child) => Opacity(
        opacity: appear.value,
        child: Transform.translate(
          offset: Offset(0, (1 - appear.value) * 12),
          child: child,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              BloomPalette.blushSoft,
              BloomPalette.orchidSoft.withValues(alpha: 0.9),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Text(insight.emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                insight.text,
                style: BloomText.body(14, wght: 700, height: 1.35),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoodPoint {
  const _MoodPoint(this.x, this.v, this.color);

  /// 0…1 across the month, and mood brightness 0…1.
  final double x, v;
  final Color color;
}

class _TrendPainter extends CustomPainter {
  _TrendPainter(this.points, this.progress);

  final List<_MoodPoint> points;
  final double progress;

  /// Left space for the emoji guides.
  static const double gutter = 30;

  @override
  void paint(Canvas canvas, Size size) {
    final chart = Rect.fromLTRB(gutter, 10, size.width - 6, size.height - 10);
    Offset at(_MoodPoint p) => Offset(
      chart.left + p.x * chart.width,
      chart.bottom - p.v * chart.height,
    );

    // Emoji guides + dashed lines.
    for (final (v, emoji) in const [(1.0, '😄'), (0.55, '😐'), (0.1, '😣')]) {
      final y = chart.bottom - v * chart.height;
      final tp = TextPainter(
        text: TextSpan(text: emoji, style: const TextStyle(fontSize: 14)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(0, y - tp.height / 2));
      final dash = Paint()
        ..color = BloomPalette.creamDeep
        ..strokeWidth = 1;
      for (var x = chart.left; x < chart.right; x += 8) {
        canvas.drawLine(Offset(x, y), Offset(x + 4, y), dash);
      }
    }

    // A 3-day rolling average keeps the curve calm and readable; each
    // day's own mood shows as a coloured dot along the baseline.
    final smooth = <Offset>[];
    for (var i = 0; i < points.length; i++) {
      final from = (i - 1).clamp(0, points.length - 1);
      final to = (i + 1).clamp(0, points.length - 1);
      var sum = 0.0;
      for (var j = from; j <= to; j++) {
        sum += points[j].v;
      }
      smooth.add(
        at(_MoodPoint(points[i].x, sum / (to - from + 1), points[i].color)),
      );
    }
    final pts = smooth;
    final line = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 0; i < pts.length - 1; i++) {
      final p0 = i == 0 ? pts[i] : pts[i - 1];
      final p1 = pts[i];
      final p2 = pts[i + 1];
      final p3 = i + 2 < pts.length ? pts[i + 2] : p2;
      final c1 = p1 + (p2 - p0) / 6;
      final c2 = p2 - (p3 - p1) / 6;
      line.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
    }

    // Reveal left → right.
    final revealX = chart.left - 4 + (chart.width + 12) * progress;
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(0, 0, revealX, size.height));

    final fill = Path.from(line)
      ..lineTo(pts.last.dx, chart.bottom)
      ..lineTo(pts.first.dx, chart.bottom)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            BloomPalette.blush.withValues(alpha: 0.4),
            BloomPalette.orchid.withValues(alpha: 0.0),
          ],
        ).createShader(chart),
    );
    canvas.drawPath(
      line,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..shader = const LinearGradient(
          colors: [
            BloomPalette.blush,
            BloomPalette.blushDeep,
            BloomPalette.orchidDeep,
          ],
        ).createShader(chart),
    );
    canvas.restore();

    // Each check-in's mood colour, popping in along the baseline.
    for (var i = 0; i < points.length; i++) {
      final x = chart.left + points[i].x * chart.width;
      final pop = ((revealX - x) / 18).clamp(0.0, 1.0);
      if (pop <= 0) continue;
      canvas.drawCircle(
        Offset(x, size.height - 3),
        3.2 * pop,
        Paint()..color = points[i].color,
      );
    }

    // Glowing "today" marker at the end of the curve.
    final endPop = ((revealX - pts.last.dx) / 18).clamp(0.0, 1.0);
    if (endPop > 0) {
      final p = pts.last;
      canvas.drawCircle(
        p,
        12 * endPop,
        Paint()..color = BloomPalette.orchidDeep.withValues(alpha: 0.18),
      );
      canvas.drawCircle(p, 5.5 * endPop, Paint()..color = Colors.white);
      canvas.drawCircle(
        p,
        5.5 * endPop,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..color = BloomPalette.orchidDeep,
      );
    }
  }

  @override
  bool shouldRepaint(_TrendPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.points != points;
}
