import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_routes.dart';
import '../state/bloom_scope.dart';
import '../theme/bloom_theme.dart';
import '../widgets/bloom_painter.dart';
import '../widgets/glow_atmosphere.dart';
import '../widgets/glow_video_hero.dart';
import 'bloom_shell.dart';

/// 01 — Welcome: a full-bleed fashion film graded in rosé tones, a brand
/// medallion, story-style slides and "Get Started"
/// (layout after the GlowPrime reference).
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _Slide {
  const _Slide({
    required this.title,
    required this.subtitle,
    required this.tint,
    this.icon,
  });

  final String title;
  final String subtitle;

  /// Colour the video grade and sky wash towards on this slide.
  final Color tint;

  /// Null → brand medallion; otherwise a glossy icon bubble.
  final IconData? icon;
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entrance;
  late final AnimationController _ambient;
  late final AnimationController _story;
  late final AnimationController _exit;
  final PageController _pages = PageController();
  final GlobalKey _buttonKey = GlobalKey();
  final GlobalKey _continueKey = GlobalKey();
  final TextEditingController _name = TextEditingController();
  final FocusNode _nameFocus = FocusNode();
  late final AnimationController _nameIn;
  bool _askingName = false;
  bool _holding = false;
  bool _leaving = false;
  bool _reduceMotion = false;
  int _currentPage = 0;

  static const List<_Slide> _slides = [
    _Slide(
      title: 'Bloom',
      subtitle: 'Small habits. Softer days. A better you.',
      tint: Color(0xFFF6C3CF),
    ),
    _Slide(
      title: 'Rituals for your 9-to-5',
      subtitle: 'Gentle morning & evening routines that fit around work.',
      tint: Color(0xFFF8CEC6),
      icon: Icons.wb_twilight_rounded,
    ),
    _Slide(
      title: 'Feel every feeling',
      subtitle: 'Private mood check-ins that feel like a warm hug.',
      tint: Color(0xFFEACBEA),
      icon: Icons.favorite_rounded,
    ),
    _Slide(
      title: 'Your 30-day glow-up',
      subtitle: 'One small, kind goal a day — and a streak to be proud of.',
      tint: Color(0xFFF4C0D0),
      icon: Icons.local_florist_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    );
    _story = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
    )..addStatusListener(_onStoryStatus);
    _exit = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _nameIn = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _entrance.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_reduceMotion) {
        _story.forward(from: 0);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion) {
      _entrance.value = 1;
      _ambient.stop();
      _story.stop();
    } else if (!_entrance.isAnimating && !_entrance.isCompleted) {
      _entrance.forward();
      _ambient.repeat();
    }
  }

  @override
  void dispose() {
    _pages.dispose();
    _entrance.dispose();
    _ambient.dispose();
    _story.dispose();
    _exit.dispose();
    _nameIn.dispose();
    _name.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  // ---- Story autoplay --------------------------------------------------------

  void _onStoryStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed ||
        _leaving ||
        _askingName ||
        !_pages.hasClients) {
      return;
    }
    final next = (_currentPage + 1) % _slides.length;
    _pages.animateToPage(
      next,
      duration: Duration(milliseconds: next == 0 ? 1600 : 1200),
      curve: Curves.easeInOutCubic,
    );
  }

  void _onPageChanged(int page) {
    _currentPage = page;
    HapticFeedback.selectionClick();
    _story.value = 0;
    if (!_holding && !_reduceMotion && !_askingName && _entrance.isCompleted) {
      _story.forward();
    }
  }

  void _hold(bool holding) {
    _holding = holding;
    if (_reduceMotion || !_entrance.isCompleted || _leaving || _askingName) {
      return;
    }
    holding ? _story.stop() : _story.forward();
  }

  // ---- Helpers -----------------------------------------------------------------

  Animation<double> _interval(
    double begin,
    double end, [
    Curve curve = Curves.easeOutCubic,
  ]) {
    return CurvedAnimation(
      parent: _entrance,
      curve: Interval(begin, end, curve: curve),
    );
  }

  double get _page => _pages.hasClients && _pages.position.haveDimensions
      ? _pages.page ?? 0
      : 0;

  /// "Get Started": ask her name once, otherwise go straight in.
  void _getStarted() {
    if (_leaving || _askingName) return;
    if (BloomScope.of(context).userName.trim().isNotEmpty) {
      _enterApp(_buttonKey);
      return;
    }
    HapticFeedback.lightImpact();
    _story.stop();
    setState(() => _askingName = true);
    _nameIn.forward();
    Future.delayed(const Duration(milliseconds: 450), () {
      if (mounted && _askingName && !_leaving) _nameFocus.requestFocus();
    });
  }

  void _submitName({bool skip = false}) {
    final name = _name.text.trim();
    if (_leaving || (!skip && name.isEmpty)) return;
    if (!skip) unawaited(BloomScope.of(context).setUserName(name));
    _nameFocus.unfocus();
    _enterApp(_continueKey);
  }

  void _enterApp(GlobalKey from) {
    if (_leaving) return;
    _leaving = true;
    _story.stop();
    HapticFeedback.mediumImpact();
    final box = from.currentContext?.findRenderObject() as RenderBox?;
    final origin = box != null && box.hasSize
        ? box.localToGlobal(box.size.center(Offset.zero))
        : MediaQuery.sizeOf(context).center(Offset.zero);
    final controller = BloomScope.of(context);
    final navigator = Navigator.of(context);
    // The landing drifts forward and brightens while the app blooms open.
    // Persistence finishes in the background; the transition starts now.
    _exit.forward();
    unawaited(controller.completeOnboarding());
    navigator.pushReplacement(
      bloomRevealRoute(const BloomShell(), origin: origin),
    );
  }

  // ---- Build -------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: BloomPalette.petalMist,
        // The keyboard lifts the content instead of squashing the film.
        resizeToAvoidBottomInset: false,
        body: Listener(
          onPointerDown: (_) => _hold(true),
          onPointerUp: (_) => _hold(false),
          onPointerCancel: (_) => _hold(false),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final h = constraints.maxHeight;
              final w = constraints.maxWidth;
              final compact = h < 720;
              final heroHeight = h * (compact ? 0.64 : 0.7);
              final heroWidth = math.min(w, 620.0);

              return Stack(
                fit: StackFit.expand,
                children: [
                  _sky(),
                  Positioned(
                    top: 0,
                    height: heroHeight,
                    left: (w - heroWidth) / 2,
                    width: heroWidth,
                    child: _hero(heroWidth),
                  ),
                  _fadeIn(
                    _interval(0.15, 0.6),
                    GlowAtmosphere(ambient: _ambient, layer: GlowLayer.back),
                  ),
                  _mist(heroHeight),
                  _fadeIn(
                    _interval(0.35, 0.9),
                    GlowAtmosphere(ambient: _ambient, layer: GlowLayer.front),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: math.max(
                          0.0,
                          MediaQuery.viewInsetsOf(context).bottom -
                              MediaQuery.paddingOf(context).bottom,
                        ),
                      ),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 460),
                          child: _content(w, compact),
                        ),
                      ),
                    ),
                  ),
                  _exitVeil(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ---- Background & hero -------------------------------------------------------

  Color _tintAt(double page) {
    final p = page.clamp(0.0, _slides.length - 1.0);
    final i = p.floor();
    final j = math.min(i + 1, _slides.length - 1);
    return Color.lerp(_slides[i].tint, _slides[j].tint, p - i)!;
  }

  Widget _sky() {
    return AnimatedBuilder(
      animation: Listenable.merge([_pages, _entrance]),
      builder: (context, _) {
        final tint = _tintAt(_page);
        final fade = _interval(0, 0.35).value;
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.lerp(BloomPalette.petalMist, tint, fade)!,
                BloomPalette.petalMist,
              ],
              stops: const [0.0, 0.75],
            ),
          ),
        );
      },
    );
  }

  /// The landing film: a rosé colour grade unifies the cool city footage
  /// with the brand, with a focus pull on entrance, a gentle drift as the
  /// slides change and a push-in on exit.
  Widget _hero(double width) {
    final focus = _interval(0.0, 0.7, Curves.easeOutQuart);
    final video = GlowVideoHero(
      asset: 'assets/images/bloom1.mp4',
      poster: 'assets/images/bloom1_poster.jpg',
      loopStart: const Duration(milliseconds: 2600),
      alignment: const Alignment(0, -0.2),
    );
    return AnimatedBuilder(
      animation: Listenable.merge([_pages, _ambient, _entrance, _exit]),
      child: video,
      builder: (context, film) {
        final page = _page;
        final f = focus.value;
        final x = Curves.easeInCubic.transform(_exit.value);
        final breathe = 0.5 - 0.5 * math.cos(_ambient.value * 2 * math.pi);
        final scale =
            (1.04 + 0.03 * breathe) * // slow breathing zoom
            (1.14 - 0.14 * f) * // entrance zoom-out
            (1 + 0.1 * x); // exit push-in
        final tint = _tintAt(page);

        Widget hero = Stack(
          fit: StackFit.expand,
          children: [
            Transform.translate(
              offset: Offset(-page * 10, 0),
              child: Transform.scale(
                scale: scale,
                child: ColorFiltered(
                  colorFilter: ColorFilter.matrix(_roseFilm),
                  child: ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      tint.withValues(alpha: 0.45),
                      BlendMode.softLight,
                    ),
                    child: film,
                  ),
                ),
              ),
            ),
            // Petal wash from the top and a whisper of vignette.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    tint.withValues(alpha: 0.55),
                    tint.withValues(alpha: 0.0),
                  ],
                  stops: const [0.0, 0.32],
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.2),
                  radius: 1.1,
                  colors: [
                    Colors.white.withValues(alpha: 0),
                    tint.withValues(alpha: 0.4),
                  ],
                  stops: const [0.55, 1.0],
                ),
              ),
            ),
            // Exposure bloom: a soft white flash that settles on entrance.
            IgnorePointer(
              child: ColoredBox(
                color: Colors.white.withValues(
                  alpha: (math.pow(1 - f, 2) * 0.95 + x * 0.55).clamp(0.0, 1.0),
                ),
              ),
            ),
          ],
        );

        final blur = (1 - f) * 18;
        if (blur > 0.05) {
          hero = ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: hero,
          );
        }
        return ClipRect(child: hero);
      },
    );
  }

  /// "Rosé film" grade: softened saturation, lifted mauve blacks and
  /// blush-tinted highlights — cool concrete turns to petal, black to plum.
  static final List<double> _roseFilm = () {
    const s = 0.6; // saturation kept
    const lr = 0.2126, lg = 0.7152, lb = 0.0722;
    const k = 0.86; // contrast compression
    const lift = [46.0, 22.0, 34.0]; // black point (R, G, B)
    final rows = [
      [lr * (1 - s) + s, lg * (1 - s), lb * (1 - s)],
      [lr * (1 - s), lg * (1 - s) + s, lb * (1 - s)],
      [lr * (1 - s), lg * (1 - s), lb * (1 - s) + s],
    ];
    return <double>[
      for (var r = 0; r < 3; r++) ...[
        ...rows[r].map((v) => v * k),
        0.0,
        lift[r],
      ],
      0.0,
      0.0,
      0.0,
      1.0,
      0.0,
    ];
  }();

  /// Dreamy mist that dissolves the portrait into the content area.
  Widget _mist(double heroHeight) {
    const mist = BloomPalette.petalMist;
    return Positioned(
      top: heroHeight * 0.46,
      left: 0,
      right: 0,
      bottom: 0,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                mist.withValues(alpha: 0),
                mist.withValues(alpha: 0.5),
                mist.withValues(alpha: 0.9),
                mist,
              ],
              stops: const [0.0, 0.26, 0.46, 0.62],
            ),
          ),
        ),
      ),
    );
  }

  Widget _exitVeil() {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _exit,
        builder: (context, _) => _exit.value == 0
            ? const SizedBox.shrink()
            : ColoredBox(
                color: BloomPalette.petalMist.withValues(
                  alpha: Curves.easeIn.transform(_exit.value) * 0.5,
                ),
              ),
      ),
    );
  }

  Widget _fadeIn(Animation<double> a, Widget child) =>
      FadeTransition(opacity: a, child: child);

  // ---- Content -----------------------------------------------------------------

  Widget _content(double width, bool compact) {
    final rise = _interval(0.62, 0.95);
    final dots = _interval(0.75, 1.0);
    final exit = CurvedAnimation(parent: _exit, curve: Curves.easeInCubic);
    return AnimatedBuilder(
      animation: exit,
      builder: (context, child) => Opacity(
        opacity: 1 - exit.value,
        child: Transform.translate(
          offset: Offset(0, exit.value * 36),
          child: child,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(28, 0, 28, compact ? 10 : 18),
        child: AnimatedBuilder(
          animation: _nameIn,
          builder: (context, intro) {
            final t = Curves.easeInOutCubic.transform(_nameIn.value);
            return Stack(
              alignment: Alignment.bottomCenter,
              children: [
                // The slides stay mounted underneath so nothing jumps.
                IgnorePointer(
                  ignoring: _askingName,
                  child: Opacity(
                    opacity: 1 - t,
                    child: Transform.translate(
                      offset: Offset(0, t * 24),
                      child: intro,
                    ),
                  ),
                ),
                if (_askingName)
                  Opacity(
                    opacity: t,
                    child: Transform.translate(
                      offset: Offset(0, (1 - t) * 40),
                      child: Transform.scale(
                        scale: 0.96 + 0.04 * t,
                        child: _nameStep(compact),
                      ),
                    ),
                  ),
              ],
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: compact ? 178 : 206,
                child: PageView.builder(
                  controller: _pages,
                  itemCount: _slides.length,
                  onPageChanged: _onPageChanged,
                  itemBuilder: (context, i) => _slide(i, width, compact),
                ),
              ),
              SizedBox(height: compact ? 14 : 22),
              AnimatedBuilder(
                animation: rise,
                builder: (context, child) => Opacity(
                  opacity: rise.value,
                  child: Transform.translate(
                    offset: Offset(0, (1 - rise.value) * 28),
                    child: child,
                  ),
                ),
                child: _GetStartedButton(
                  key: _buttonKey,
                  ambient: _ambient,
                  inkKey: const Key('start-reset'),
                  label: 'Get Started',
                  onTap: _getStarted,
                ),
              ),
              SizedBox(height: compact ? 16 : 26),
              FadeTransition(opacity: dots, child: _storyDots()),
            ],
          ),
        ),
      ),
    );
  }

  /// Frosted card asking for her name — so every screen can greet her.
  Widget _nameStep(bool compact) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(34),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          padding: EdgeInsets.fromLTRB(22, compact ? 18 : 24, 22, 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(34),
            border: Border.all(color: Colors.white.withValues(alpha: 0.95)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BloomMark(size: compact ? 44 : 54),
              SizedBox(height: compact ? 6 : 10),
              Text(
                'What should we call you?',
                textAlign: TextAlign.center,
                style: BloomText.display(
                  compact ? 23 : 26,
                  wght: 600,
                  height: 1.15,
                  color: BloomPalette.mauveInk,
                ),
              ),
              const SizedBox(height: 6),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _name,
                builder: (context, value, _) {
                  final name = value.text.trim();
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    child: Text(
                      name.isEmpty
                          ? 'We\u2019ll greet you by name every day.'
                          : 'Lovely to meet you, $name \u{1F338}',
                      key: ValueKey(name.isEmpty),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: BloomText.body(
                        14.5,
                        wght: 600,
                        color: BloomPalette.mauveSoft,
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: compact ? 12 : 18),
              TextField(
                key: const Key('name-field'),
                controller: _name,
                focusNode: _nameFocus,
                textAlign: TextAlign.center,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                maxLength: 24,
                cursorColor: BloomPalette.dustyRoseDeep,
                onSubmitted: (_) => _submitName(),
                style: BloomText.display(
                  22,
                  wght: 600,
                  color: BloomPalette.mauveInk,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: 'Your first name',
                  hintStyle: BloomText.display(
                    21,
                    wght: 500,
                    fontStyle: FontStyle.italic,
                    color: BloomPalette.mauveSoft.withValues(alpha: 0.6),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide(
                      color: BloomPalette.dustyRose.withValues(alpha: 0.35),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: const BorderSide(
                      color: BloomPalette.dustyRoseDeep,
                      width: 1.6,
                    ),
                  ),
                ),
              ),
              SizedBox(height: compact ? 12 : 16),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _name,
                builder: (context, value, _) => _GetStartedButton(
                  key: _continueKey,
                  ambient: _ambient,
                  inkKey: const Key('name-continue'),
                  label: 'Continue',
                  enabled: value.text.trim().isNotEmpty,
                  onTap: _submitName,
                ),
              ),
              TextButton(
                key: const Key('name-skip'),
                onPressed: () => _submitName(skip: true),
                child: Text(
                  'Skip for now',
                  style: BloomText.body(
                    14.5,
                    wght: 700,
                    color: BloomPalette.mauveSoft,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _slide(int index, double width, bool compact) {
    final slide = _slides[index];
    final badge = _interval(0.32, 0.66, Curves.easeOutBack);
    final title = _interval(0.42, 0.8, Curves.easeInOutCubic);
    final sub = _interval(0.55, 0.88);
    final isBrand = slide.icon == null;
    final iconSize = compact ? 56.0 : 66.0;

    return AnimatedBuilder(
      animation: Listenable.merge([_pages, _entrance]),
      builder: (context, _) {
        final delta = index - _page;
        final away = delta.abs().clamp(0.0, 1.0);
        return Opacity(
          // Outgoing copy clears before the next arrives — no overlap.
          opacity: Curves.easeIn.transform((1 - away * 1.9).clamp(0.0, 1.0)),
          child: Transform.translate(
            // Content lags the page for a soft parallax.
            offset: Offset(-delta * width * 0.22, 0),
            child: Transform.scale(
              scale: 1 - away * 0.08,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Opacity(
                    opacity: badge.value.clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: 0.55 + 0.45 * badge.value,
                      child: _PulseHalo(
                        ambient: _ambient,
                        size: iconSize,
                        child: isBrand
                            ? BloomMedallion(size: iconSize)
                            : _IconMedallion(icon: slide.icon!, size: iconSize),
                      ),
                    ),
                  ),
                  SizedBox(height: compact ? 12 : 18),
                  _revealText(
                    title.value,
                    Text(
                      slide.title,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.visible,
                      style: BloomText.display(
                        isBrand ? (compact ? 46 : 54) : (compact ? 30 : 34),
                        wght: 600,
                        height: 1.05,
                        color: BloomPalette.mauveInk,
                        letterSpacing:
                            (isBrand ? 0.5 : -0.2) + (1 - title.value) * 7,
                      ),
                    ),
                  ),
                  SizedBox(height: compact ? 8 : 12),
                  Opacity(
                    opacity: sub.value,
                    child: Transform.translate(
                      offset: Offset(0, (1 - sub.value) * 10),
                      child: Text(
                        slide.subtitle,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        style: BloomText.body(
                          compact ? 14 : 15,
                          wght: 600,
                          height: 1.45,
                          color: BloomPalette.mauveSoft,
                          letterSpacing: 0.9 + (1 - sub.value) * 3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Ink-like left-to-right reveal with a soft feathered edge.
  Widget _revealText(double progress, Widget text) {
    if (progress >= 1) return text;
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (rect) {
        final edge = progress * 1.3 - 0.3;
        return LinearGradient(
          colors: const [Colors.white, Colors.white, Colors.transparent],
          stops: [0.0, edge.clamp(0.0, 1.0), (edge + 0.3).clamp(0.0, 1.0)],
        ).createShader(rect);
      },
      child: text,
    );
  }

  /// Story-style indicators: the active one stretches into a bar that fills
  /// while the slide plays; tap any to jump.
  Widget _storyDots() {
    return AnimatedBuilder(
      animation: Listenable.merge([_pages, _story]),
      builder: (context, _) {
        final p = _page;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(_slides.length, (i) {
            final t = (1 - (p - i).abs()).clamp(0.0, 1.0);
            final width = 8 + 22 * Curves.easeOut.transform(t);
            final fill = i == p.round() ? _story.value : 0.0;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _pages.animateToPage(
                i,
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeInOutCubic,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 10,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    width: width,
                    height: 8,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: ColoredBox(
                            color: Color.lerp(
                              const Color(0xFFEFDADD),
                              BloomPalette.dustyRose.withValues(alpha: 0.55),
                              t,
                            )!,
                          ),
                        ),
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          width: width * (_reduceMotion ? t : fill * t),
                          child: const ColoredBox(
                            color: BloomPalette.dustyRoseDeep,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

/// Soft ripple of light that blooms out from the badge every few seconds.
class _PulseHalo extends StatelessWidget {
  const _PulseHalo({
    required this.ambient,
    required this.size,
    required this.child,
  });

  final Animation<double> ambient;
  final double size;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PulsePainter(ambient),
      child: SizedBox.square(dimension: size, child: child),
    );
  }
}

class _PulsePainter extends CustomPainter {
  _PulsePainter(this.ambient) : super(repaint: ambient);

  final Animation<double> ambient;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    for (final offset in const [0.0, 0.5]) {
      final t = (ambient.value * 6 + offset) % 1.0;
      final eased = Curves.easeOutCubic.transform(t);
      canvas.drawCircle(
        c,
        r * (1 + eased * 0.75),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4 * (1 - t) + 0.2
          ..color = BloomPalette.dustyRose.withValues(alpha: 0.4 * (1 - t)),
      );
    }
  }

  @override
  bool shouldRepaint(_PulsePainter oldDelegate) => false;
}

/// Glossy rose bubble holding a white icon — matches [BloomMedallion].
class _IconMedallion extends StatelessWidget {
  const _IconMedallion({required this.icon, required this.size});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(-0.3, -0.35),
          radius: 1.0,
          colors: [Color(0xFFFFEDEC), Color(0xFFF2B7BE), Color(0xFFD9828F)],
          stops: [0.0, 0.5, 1.0],
        ),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: BloomPalette.dustyRoseDeep.withValues(alpha: 0.35),
            blurRadius: size * 0.3,
            offset: Offset(0, size * 0.1),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: size * 0.46),
    );
  }
}

/// Dusty-rose pill with a breathing glow, a periodic light sweep, a nudging
/// arrow and a tactile press.
class _GetStartedButton extends StatefulWidget {
  const _GetStartedButton({
    super.key,
    required this.ambient,
    required this.onTap,
    required this.label,
    required this.inkKey,
    this.enabled = true,
  });

  final Animation<double> ambient;
  final VoidCallback onTap;
  final String label;
  final Key inkKey;

  /// Disabled stays readable: rose label on a blush fill, no glow.
  final bool enabled;

  @override
  State<_GetStartedButton> createState() => _GetStartedButtonState();
}

class _GetStartedButtonState extends State<_GetStartedButton> {
  bool _pressed = false;

  void _press(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(32));
    return Listener(
      onPointerDown: (_) => _press(true),
      onPointerUp: (_) => _press(false),
      onPointerCancel: (_) => _press(false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        child: AnimatedBuilder(
          animation: widget.ambient,
          builder: (context, child) {
            final glow =
                0.5 + 0.5 * math.sin(widget.ambient.value * 2 * math.pi * 8);
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                borderRadius: radius,
                color: widget.enabled ? null : BloomPalette.blushSoft,
                gradient: widget.enabled
                    ? const LinearGradient(
                        colors: [Color(0xFFEDAAB3), BloomPalette.dustyRoseDeep],
                      )
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: BloomPalette.dustyRoseDeep.withValues(
                      alpha: widget.enabled ? 0.28 + 0.14 * glow : 0,
                    ),
                    blurRadius: 20 + 8 * glow,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: child,
            );
          },
          child: ClipRRect(
            borderRadius: radius,
            child: Stack(
              children: [
                if (widget.enabled)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _SheenPainter(widget.ambient),
                      ),
                    ),
                  ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    key: widget.inkKey,
                    onTap: widget.enabled ? widget.onTap : null,
                    splashColor: Colors.white.withValues(alpha: 0.25),
                    highlightColor: Colors.white.withValues(alpha: 0.08),
                    child: SizedBox(
                      height: 60,
                      width: double.infinity,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedBuilder(
                            animation: widget.ambient,
                            builder: (context, child) {
                              // A small "come in" nudge every few seconds.
                              final c = (widget.ambient.value * 6) % 1.0;
                              final nudge = c < 0.18
                                  ? math.sin(c / 0.18 * math.pi) * 4
                                  : 0.0;
                              return Transform.translate(
                                offset: Offset(nudge, 0),
                                child: child,
                              );
                            },
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              color: widget.enabled
                                  ? Colors.white
                                  : BloomPalette.dustyRoseDeep,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            widget.label,
                            style: BloomText.button(
                              color: widget.enabled
                                  ? Colors.white
                                  : BloomPalette.dustyRoseDeep,
                            ),
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
    );
  }
}

/// A diagonal band of light that glides across the button.
class _SheenPainter extends CustomPainter {
  _SheenPainter(this.ambient) : super(repaint: ambient);

  final Animation<double> ambient;

  @override
  void paint(Canvas canvas, Size size) {
    final cycle = (ambient.value * 6) % 1.0;
    if (cycle < 0.3 || cycle > 0.62) return;
    final t = Curves.easeInOutSine.transform((cycle - 0.3) / 0.32);
    final x = -size.width * 0.3 + t * size.width * 1.6;
    canvas.save();
    canvas.translate(x, 0);
    canvas.skew(-0.5, 0);
    final band = Rect.fromLTWH(0, 0, size.width * 0.22, size.height);
    canvas.drawRect(
      band,
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0),
            Colors.white.withValues(alpha: 0.38),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(band),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SheenPainter oldDelegate) => false;
}
