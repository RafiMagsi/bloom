import 'package:flutter/material.dart';

/// Soft fade + slight rise transition used between top-level screens.
Route<T> fadeRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 430),
    pageBuilder: (_, _, _) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.035),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// Scene change for screens built from [Reveal] objects: only the
/// *background* dissolves here — the incoming screen's objects animate in on
/// their own (and the outgoing screen's objects animate out on theirs).
Route<T> sceneRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 900),
    reverseTransitionDuration: const Duration(milliseconds: 500),
    pageBuilder: (_, _, _) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: const Interval(0.2, 1, curve: Curves.easeInOutCubic),
        ),
        child: child,
      );
    },
  );
}
