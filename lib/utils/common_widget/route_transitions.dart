import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

enum RouteTransitionType { fade, slide }

class RouteTransitions {
  static CustomTransitionPage buildPageWithTransition({
    required Widget child,
    required GoRouterState state,
    RouteTransitionType transitionType = RouteTransitionType.fade,
    Duration transitionDuration = const Duration(milliseconds: 300),
  }) {
    return CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionDuration: transitionDuration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        switch (transitionType) {
          case RouteTransitionType.fade:
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          case RouteTransitionType.slide:
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
        }
      },
    );
  }
}