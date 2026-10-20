import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Full-bleed, muted, looping background video with a poster frame.
///
/// - Starts at [loopStart] and loops back there (skips the clip's intro).
/// - Shows [poster] until the first video frame is ready, then cross-fades.
/// - Pauses while the app is backgrounded or the screen is covered, and
///   stays on the poster when the OS asks for reduced motion or the video
///   can't play on this platform.
class GlowVideoHero extends StatefulWidget {
  const GlowVideoHero({
    super.key,
    required this.asset,
    required this.poster,
    this.loopStart = Duration.zero,
    this.alignment = Alignment.center,
  });

  final String asset;
  final String poster;
  final Duration loopStart;
  final Alignment alignment;

  @override
  State<GlowVideoHero> createState() => _GlowVideoHeroState();
}

class _GlowVideoHeroState extends State<GlowVideoHero>
    with WidgetsBindingObserver {
  VideoPlayerController? _video;
  bool _ready = false;
  bool _seeking = false;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(AssetImage(widget.poster), context);
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    // TickerMode turns off while another route covers this one.
    _visible = TickerMode.valuesOf(context).enabled;
    if (_video == null && !_reduceMotion) {
      _start();
    } else {
      _syncPlayback();
    }
  }

  bool _visible = true;
  bool _foreground = true;

  bool get _shouldPlay => _ready && _visible && _foreground && !_reduceMotion;

  void _syncPlayback() {
    final video = _video;
    if (video == null || !_ready) return;
    if (_shouldPlay && !video.value.isPlaying) video.play();
    if (!_shouldPlay && video.value.isPlaying) video.pause();
  }

  Future<void> _start() async {
    final video = VideoPlayerController.asset(
      widget.asset,
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    _video = video;
    try {
      await video.initialize();
      if (!mounted || _video != video) return;
      await video.setVolume(0);
      await video.setLooping(false); // looped manually from [loopStart]
      await video.seekTo(widget.loopStart);
      video.addListener(_onTick);
      if (!mounted) return;
      setState(() => _ready = true);
      _syncPlayback();
    } catch (_) {
      // No video on this platform/device — the poster stays up.
    }
  }

  void _onTick() {
    final video = _video;
    if (video == null || _seeking) return;
    final v = video.value;
    if (!v.isInitialized || v.duration <= Duration.zero) return;
    final ending = v.position >= v.duration - const Duration(milliseconds: 160);
    if (ending || v.isCompleted) {
      _seeking = true;
      video.seekTo(widget.loopStart).then((_) {
        _seeking = false;
        if (mounted) _syncPlayback();
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _syncPlayback();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _video?.removeListener(_onTick);
    _video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final video = _video;
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          widget.poster,
          fit: BoxFit.cover,
          alignment: widget.alignment,
          gaplessPlayback: true,
        ),
        // The first video frame melts in over the poster.
        if (video != null)
          AnimatedOpacity(
            opacity: _ready ? 1 : 0,
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOut,
            child: _ready
                ? ClipRect(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      alignment: widget.alignment,
                      child: SizedBox(
                        width: video.value.size.width,
                        height: video.value.size.height,
                        child: VideoPlayer(video),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
      ],
    );
  }
}
