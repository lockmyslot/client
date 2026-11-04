import 'package:flutter/widgets.dart';

/// Page snapping physics that react to shorter drags and lighter flicks than
/// [PageScrollPhysics] does out of the box.
///
/// By default a page only flips once it has been dragged more than half of the
/// viewport (or flung hard enough), which makes horizontal paging on the main
/// shell feel sluggish. This variant snaps forward as soon as the page has been
/// dragged past [dragThreshold] of the viewport, and treats much lighter flicks
/// as intentional page changes.
///
/// Use together with `PageView(pageSnapping: false, physics: ...)` so that this
/// physics is not wrapped by the default `PageScrollPhysics`.
class ResponsivePageScrollPhysics extends PageScrollPhysics {
  const ResponsivePageScrollPhysics({
    this.dragThreshold = 0.3,
    this.flingVelocity = 120.0,
    super.parent,
  });

  /// Fraction of the viewport that must be dragged before snapping to the next
  /// page, where `0.5` matches Flutter's default behaviour.
  final double dragThreshold;

  /// Minimum fling velocity (in logical pixels per second) that counts as an
  /// intentional page change, where lower values are more sensitive.
  final double flingVelocity;

  @override
  ResponsivePageScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return ResponsivePageScrollPhysics(
      dragThreshold: dragThreshold,
      flingVelocity: flingVelocity,
      parent: buildParent(ancestor),
    );
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    // If we're out of range and not headed back in range, defer to the parent
    // ballistics, which should put us back in range at a page boundary.
    if ((velocity <= 0.0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0.0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }

    final double viewport = position.viewportDimension;
    if (viewport <= 0.0) {
      return super.createBallisticSimulation(position, velocity);
    }

    final double page = position.pixels / viewport;
    final double pageFraction = page - page.roundToDouble();

    final double targetPage;
    if (velocity < -flingVelocity) {
      targetPage = page - 0.5;
    } else if (velocity > flingVelocity) {
      targetPage = page + 0.5;
    } else if (pageFraction >= dragThreshold) {
      targetPage = page + 0.5;
    } else if (pageFraction <= -dragThreshold) {
      targetPage = page - 0.5;
    } else {
      targetPage = page;
    }

    final Tolerance tolerance = toleranceFor(position);
    final double target = targetPage.roundToDouble() * viewport;
    if (target != position.pixels) {
      return ScrollSpringSimulation(
        spring,
        position.pixels,
        target,
        velocity,
        tolerance: tolerance,
      );
    }
    return null;
  }
}
