import 'package:flutter/widgets.dart';

import 'bloom_controller.dart';

/// Exposes the [BloomController] to every screen, sheet and overlay.
/// Placed above [MaterialApp] so bottom sheets can reach it too.
class BloomScope extends InheritedNotifier<BloomController> {
  const BloomScope({
    super.key,
    required BloomController controller,
    required super.child,
  }) : super(notifier: controller);

  static BloomController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<BloomScope>();
    assert(scope != null, 'BloomScope is missing above this context');
    return scope!.notifier!;
  }
}
