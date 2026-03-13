import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_motion.dart';

class EventDetailPageRoute<T> extends PageRouteBuilder<T> {
  EventDetailPageRoute({
    required WidgetBuilder builder,
    super.settings,
  }) : super(
          transitionDuration: AppMotion.standard,
          reverseTransitionDuration: AppMotion.fast,
          pageBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) =>
              builder(context),
          transitionsBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) {
            final Animation<double> curved = CurvedAnimation(
              parent: animation,
              curve: AppMotion.emphasized,
              reverseCurve: AppMotion.standardCurve,
            );

            return AnimatedBuilder(
              animation: curved,
              child: child,
              builder: (BuildContext context, Widget? child) {
                final double t = curved.value;
                return Opacity(
                  opacity: t.clamp(0.0, 1.0),
                  child: Transform.translate(
                    offset: Offset(0, (1 - t) * 16),
                    child: child,
                  ),
                );
              },
            );
          },
        );
}

class EventSheetPageRoute<T> extends PageRouteBuilder<T> {
  EventSheetPageRoute({
    required WidgetBuilder builder,
    super.settings,
  }) : super(
          fullscreenDialog: true,
          transitionDuration: AppMotion.emphasizedDuration,
          reverseTransitionDuration: AppMotion.standard,
          pageBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) =>
              builder(context),
          transitionsBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) {
            final Animation<double> curved = CurvedAnimation(
              parent: animation,
              curve: AppMotion.emphasized,
              reverseCurve: AppMotion.standardCurve,
            );

            return AnimatedBuilder(
              animation: curved,
              child: child,
              builder: (BuildContext context, Widget? child) {
                final double screenHeight = MediaQuery.sizeOf(context).height;
                return Transform.translate(
                  offset: Offset(0, (1 - curved.value) * screenHeight),
                  child: child,
                );
              },
            );
          },
        );
}

class EventCheckInPageRoute<T> extends PageRouteBuilder<T> {
  EventCheckInPageRoute({
    required WidgetBuilder builder,
    super.settings,
  }) : super(
          transitionDuration: AppMotion.standard,
          reverseTransitionDuration: AppMotion.fast,
          pageBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) =>
              builder(context),
          transitionsBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) {
            final Animation<double> curved = CurvedAnimation(
              parent: animation,
              curve: AppMotion.emphasized,
              reverseCurve: AppMotion.standardCurve,
            );

            return AnimatedBuilder(
              animation: curved,
              child: child,
              builder: (BuildContext context, Widget? child) {
                final double t = curved.value;
                return Opacity(
                  opacity: t.clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: 0.94 + 0.06 * t,
                    child: child,
                  ),
                );
              },
            );
          },
        );
}
