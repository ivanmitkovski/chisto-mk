import 'package:flutter/material.dart';

/// Exposes bottom scroll padding for nested lists inside [AppSheetScaffold].
class AppSheetScrollInsets extends InheritedWidget {
  const AppSheetScrollInsets({
    super.key,
    required this.scrollBottom,
    required super.child,
  });

  final double scrollBottom;

  static double of(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<AppSheetScrollInsets>()
            ?.scrollBottom ??
        0;
  }

  @override
  bool updateShouldNotify(AppSheetScrollInsets oldWidget) {
    return scrollBottom != oldWidget.scrollBottom;
  }
}

/// Merges home-indicator clearance into direct scroll views used as sheet bodies.
abstract final class AppSheetScrollInset {
  static EdgeInsets _mergeBottom(EdgeInsetsGeometry? existing, double bottom) {
    if (bottom <= 0) {
      return existing is EdgeInsets
          ? existing
          : existing?.resolve(TextDirection.ltr) ?? EdgeInsets.zero;
    }
    final EdgeInsets base = existing is EdgeInsets
        ? existing
        : existing?.resolve(TextDirection.ltr) ?? EdgeInsets.zero;
    return base.copyWith(bottom: base.bottom + bottom);
  }

  static Widget wrap({
    required Widget child,
    required double bottom,
  }) {
    if (bottom <= 0) {
      return AppSheetScrollInsets(scrollBottom: 0, child: child);
    }
    return AppSheetScrollInsets(
      scrollBottom: bottom,
      child: _mergeScrollPadding(child, bottom),
    );
  }

  static Widget _mergeScrollPadding(Widget child, double bottom) {
    if (child is SingleChildScrollView) {
      return SingleChildScrollView(
        key: child.key,
        scrollDirection: child.scrollDirection,
        reverse: child.reverse,
        padding: _mergeBottom(child.padding, bottom),
        primary: child.primary,
        physics: child.physics,
        controller: child.controller,
        clipBehavior: child.clipBehavior,
        restorationId: child.restorationId,
        keyboardDismissBehavior: child.keyboardDismissBehavior,
        child: child.child,
      );
    }

    if (child is ListView) {
      final ScrollViewKeyboardDismissBehavior? keyboardDismissBehavior =
          child.keyboardDismissBehavior;
      final ScrollPhysics? physics = child.physics;
      final ScrollController? controller = child.controller;
      final bool? primary = child.primary;
      final bool shrinkWrap = child.shrinkWrap;
      final Axis scrollDirection = child.scrollDirection;
      final bool reverse = child.reverse;
      final EdgeInsetsGeometry? mergedPadding = _mergeBottom(
        child.padding,
        bottom,
      );

      final SliverChildDelegate delegate = child.childrenDelegate;
      if (delegate is SliverChildBuilderDelegate) {
        return ListView.builder(
          key: child.key,
          scrollDirection: scrollDirection,
          reverse: reverse,
          controller: controller,
          primary: primary,
          physics: physics,
          shrinkWrap: shrinkWrap,
          padding: mergedPadding,
          itemExtent: child.itemExtent,
          prototypeItem: child.prototypeItem,
          keyboardDismissBehavior: keyboardDismissBehavior,
          itemBuilder: delegate.builder,
          itemCount: delegate.childCount,
          findChildIndexCallback: delegate.findChildIndexCallback,
          addAutomaticKeepAlives: delegate.addAutomaticKeepAlives,
          addRepaintBoundaries: delegate.addRepaintBoundaries,
          addSemanticIndexes: delegate.addSemanticIndexes,
        );
      }
      if (delegate is SliverChildListDelegate) {
        return ListView(
          key: child.key,
          scrollDirection: scrollDirection,
          reverse: reverse,
          controller: controller,
          primary: primary,
          physics: physics,
          shrinkWrap: shrinkWrap,
          padding: mergedPadding,
          itemExtent: child.itemExtent,
          prototypeItem: child.prototypeItem,
          keyboardDismissBehavior: keyboardDismissBehavior,
          children: delegate.children,
          addAutomaticKeepAlives: delegate.addAutomaticKeepAlives,
          addRepaintBoundaries: delegate.addRepaintBoundaries,
          addSemanticIndexes: delegate.addSemanticIndexes,
        );
      }
    }

    return child;
  }
}
