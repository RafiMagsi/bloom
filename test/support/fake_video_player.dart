import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

/// In-memory video platform for widget tests: every video "initializes"
/// instantly as a 720×1280, 13.5s clip and renders as an empty box.
class FakeVideoPlayerPlatform extends VideoPlayerPlatform {
  final Map<int, StreamController<VideoEvent>> _events = {};
  final Map<int, Duration> _positions = {};
  int _nextId = 1;

  static void install() => VideoPlayerPlatform.instance = FakeVideoPlayerPlatform();

  @override
  Future<void> init() async {}

  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async {
    final id = _nextId++;
    final events = StreamController<VideoEvent>();
    _events[id] = events;
    _positions[id] = Duration.zero;
    events.add(VideoEvent(
      eventType: VideoEventType.initialized,
      size: const Size(720, 1280),
      duration: const Duration(milliseconds: 13500),
    ));
    return id;
  }

  @override
  Future<int?> create(DataSource dataSource) =>
      createWithOptions(VideoCreationOptions(
        dataSource: dataSource,
        viewType: VideoViewType.textureView,
      ));

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) => _events[playerId]!.stream;

  @override
  Future<void> dispose(int playerId) async {
    await _events.remove(playerId)?.close();
  }

  @override
  Future<void> setLooping(int playerId, bool looping) async {}

  @override
  Future<void> play(int playerId) async {}

  @override
  Future<void> pause(int playerId) async {}

  @override
  Future<void> setVolume(int playerId, double volume) async {}

  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}

  @override
  Future<void> seekTo(int playerId, Duration position) async {
    _positions[playerId] = position;
  }

  @override
  Future<Duration> getPosition(int playerId) async =>
      _positions[playerId] ?? Duration.zero;

  @override
  Future<void> setMixWithOthers(bool mixWithOthers) async {}

  @override
  Widget buildViewWithOptions(VideoViewOptions options) => const SizedBox();

  @override
  Widget buildView(int playerId) => const SizedBox();
}
