import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:superellipse_shape/superellipse_shape.dart';
import '../theme/app_theme.dart';

// ---------------------------------------------------------------------------
// Core helpers
// ---------------------------------------------------------------------------

/// Wraps children in a Shimmer sweep using the app's card colours.
class AppShimmer extends StatelessWidget {
  final Widget child;
  const AppShimmer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Shimmer.fromColors(
      baseColor: c.cardBorder.withValues(alpha: 0.6),
      highlightColor: c.cardBg,
      period: const Duration(milliseconds: 1200),
      child: child,
    );
  }
}

/// Plain rounded rectangle placeholder block.
class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;
  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.radius = 10,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      width: width,
      height: height,
      decoration: ShapeDecoration(
        color: c.cardBg,
        shape: SuperellipseShape(
          borderRadius: BorderRadius.circular(radius * 2),
        ),
      ),
    );
  }
}

/// Circle placeholder.
class ShimmerCircle extends StatelessWidget {
  final double size;
  const ShimmerCircle({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: c.cardBg, shape: BoxShape.circle),
    );
  }
}

// ---------------------------------------------------------------------------
// Card-shaped shimmer containers
// ---------------------------------------------------------------------------

Widget _shimmerCard({
  required BuildContext context,
  required Widget child,
  double radius = 48,
}) {
  final c = AppColors.of(context);
  return Container(
    decoration: ShapeDecoration(
      color: c.cardBg,
      shape: SuperellipseShape(
        borderRadius: BorderRadius.circular(radius),
        side: BorderSide(color: c.cardBorder),
      ),
      shadows: c.cardShadow,
    ),
    child: child,
  );
}

// ---------------------------------------------------------------------------
// Home screen skeletons
// ---------------------------------------------------------------------------

/// Skeleton for the start-round / resume-round carousel card.
class ShimmerCarouselCard extends StatelessWidget {
  final double height;
  const ShimmerCarouselCard({super.key, required this.height});

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final hPad = (sw * 0.055).clamp(18.0, 28.0);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad),
      child: AppShimmer(
        child: _shimmerCard(
          context: context,
          radius: 40,
          child: SizedBox(
            height: height,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    ShimmerCircle(size: 34),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerBox(width: sw * 0.18, height: 10),
                        const SizedBox(height: 6),
                        ShimmerBox(width: sw * 0.38, height: 14),
                      ],
                    ),
                  ]),
                  const Spacer(),
                  ShimmerBox(width: double.infinity, height: 5, radius: 4),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: ShimmerBox(width: double.infinity, height: 40, radius: 12)),
                    const SizedBox(width: 10),
                    Expanded(flex: 2, child: ShimmerBox(width: double.infinity, height: 40, radius: 12)),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Skeleton for a horizontal recent-round card.
class ShimmerRoundCard extends StatelessWidget {
  final double width;
  final double height;
  const ShimmerRoundCard({super.key, required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: _shimmerCard(
        context: context,
        radius: 40,
        child: SizedBox(
          width: width,
          height: height,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  ShimmerCircle(size: 40),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(width: width * 0.45, height: 12),
                      const SizedBox(height: 6),
                      ShimmerBox(width: width * 0.3, height: 10),
                    ],
                  ),
                ]),
                const Spacer(),
                ShimmerBox(width: double.infinity, height: 8, radius: 4),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(4, (_) =>
                      ShimmerBox(width: width * 0.15, height: 10)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Skeleton for the performance summary card (full-width).
class ShimmerPerformanceCard extends StatelessWidget {
  const ShimmerPerformanceCard({super.key});

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final hPad = (sw * 0.055).clamp(18.0, 28.0);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad),
      child: AppShimmer(
        child: _shimmerCard(
          context: context,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(width: sw * 0.25, height: 11),
                      const SizedBox(height: 8),
                      ShimmerBox(width: sw * 0.18, height: 40),
                      const SizedBox(height: 10),
                      ShimmerBox(width: sw * 0.30, height: 10),
                      const SizedBox(height: 6),
                      ShimmerBox(width: sw * 0.22, height: 10),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                ShimmerCircle(size: (sw * 0.28).clamp(90.0, 120.0)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Skeleton for a quick-stat tile (2-column grid item).
class ShimmerStatTile extends StatelessWidget {
  final double height;
  const ShimmerStatTile({super.key, required this.height});

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    return AppShimmer(
      child: _shimmerCard(
        context: context,
        child: SizedBox(
          height: height,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ShimmerBox(width: 36, height: 36, radius: 10),
                    ShimmerCircle(size: 44),
                  ],
                ),
                const Spacer(),
                ShimmerBox(width: sw * 0.14, height: 28),
                const SizedBox(height: 6),
                ShimmerBox(width: sw * 0.20, height: 10),
                const SizedBox(height: 4),
                ShimmerBox(width: sw * 0.28, height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Skeleton for a nearby course card.
class ShimmerCourseCard extends StatelessWidget {
  final double width;
  final double height;
  const ShimmerCourseCard({super.key, required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: _shimmerCard(
        context: context,
        radius: 40,
        child: SizedBox(
          width: width,
          height: height,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ShimmerBox(width: 36, height: 36, radius: 10),
                    ShimmerBox(width: 60, height: 28, radius: 10),
                  ],
                ),
                const Spacer(),
                ShimmerBox(width: width * 0.65, height: 13),
                const SizedBox(height: 6),
                ShimmerBox(width: width * 0.45, height: 10),
                const SizedBox(height: 6),
                ShimmerBox(width: width * 0.35, height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Rounds screen skeletons
// ---------------------------------------------------------------------------

/// Skeleton for a completed-round list card.
class ShimmerRoundListCard extends StatelessWidget {
  const ShimmerRoundListCard({super.key});

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    return AppShimmer(
      child: _shimmerCard(
        context: context,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Column(
            children: [
              Row(
                children: [
                  ShimmerCircle(size: 52),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerBox(width: sw * 0.40, height: 14),
                        const SizedBox(height: 6),
                        ShimmerBox(width: sw * 0.28, height: 10),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      ShimmerBox(width: 56, height: 11),
                      const SizedBox(height: 6),
                      ShimmerBox(width: 40, height: 10),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ShimmerBox(width: double.infinity, height: 1, radius: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(5, (_) =>
                    ShimmerBox(width: sw * 0.10, height: 10)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stats screen skeletons
// ---------------------------------------------------------------------------

/// Skeleton for the large handicap card.
class ShimmerHandicapCard extends StatelessWidget {
  const ShimmerHandicapCard({super.key});

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    return AppShimmer(
      child: _shimmerCard(
        context: context,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(width: sw * 0.30, height: 11),
                    const SizedBox(height: 10),
                    ShimmerBox(width: sw * 0.22, height: 52),
                    const SizedBox(height: 10),
                    ShimmerBox(width: sw * 0.38, height: 10),
                  ],
                ),
              ),
              ShimmerCircle(size: (sw * 0.28).clamp(90.0, 110.0)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton for a 2-column overview stat tile (stats screen).
class ShimmerOverviewTile extends StatelessWidget {
  final double height;
  const ShimmerOverviewTile({super.key, required this.height});

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    return AppShimmer(
      child: _shimmerCard(
        context: context,
        child: SizedBox(
          height: height,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                ShimmerBox(width: 38, height: 38, radius: 10),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ShimmerBox(width: sw * 0.16, height: 22),
                    const SizedBox(height: 6),
                    ShimmerBox(width: sw * 0.20, height: 10),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Skeleton for a full-width chart / content card.
class ShimmerChartCard extends StatelessWidget {
  final double height;
  const ShimmerChartCard({super.key, required this.height});

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    return AppShimmer(
      child: _shimmerCard(
        context: context,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ShimmerBox(width: sw * 0.35, height: 14),
                  ShimmerBox(width: 52, height: 22, radius: 10),
                ],
              ),
              const SizedBox(height: 16),
              ShimmerBox(width: double.infinity, height: height - 80),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Profile screen skeletons
// ---------------------------------------------------------------------------

/// Skeleton for the profile header card (avatar + name).
class ShimmerProfileCard extends StatelessWidget {
  const ShimmerProfileCard({super.key});

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    return AppShimmer(
      child: _shimmerCard(
        context: context,
        child: Padding(
          padding: EdgeInsets.all((sw * 0.055).clamp(18.0, 24.0)),
          child: Row(
            children: [
              ShimmerCircle(size: (sw * 0.18).clamp(62.0, 76.0)),
              SizedBox(width: (sw * 0.04).clamp(12.0, 18.0)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(width: sw * 0.30, height: 16),
                  const SizedBox(height: 6),
                  ShimmerBox(width: sw * 0.40, height: 11),
                  const SizedBox(height: 8),
                  ShimmerBox(width: sw * 0.16, height: 20, radius: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton for the 3-column stats row (rounds / handicap / birdies).
class ShimmerStatsRow extends StatelessWidget {
  const ShimmerStatsRow({super.key});

  @override
  Widget build(BuildContext context) {
    final sh = MediaQuery.of(context).size.height;
    final sw = MediaQuery.of(context).size.width;
    final tileH = (sh * 0.022 * 2 + 80).clamp(90.0, 130.0);
    return AppShimmer(
      child: Row(
        children: List.generate(3, (i) => [
          Expanded(
            child: _shimmerCard(
              context: context,
              child: SizedBox(
                height: tileH,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ShimmerCircle(size: (sw * 0.088).clamp(30.0, 38.0)),
                      const SizedBox(height: 8),
                      ShimmerBox(width: sw * 0.10, height: 22),
                      const SizedBox(height: 4),
                      ShimmerBox(width: sw * 0.12, height: 10),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (i < 2) const SizedBox(width: 10),
        ]).expand((e) => e).toList(),
      ),
    );
  }
}

/// Skeleton for the achievements 3-column grid.
class ShimmerAchievementsGrid extends StatelessWidget {
  final int count;
  const ShimmerAchievementsGrid({super.key, this.count = 6});

  @override
  Widget build(BuildContext context) {
    final sh = MediaQuery.of(context).size.height;
    final tileH = (sh * 0.130).clamp(100.0, 120.0);
    return AppShimmer(
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          mainAxisExtent: tileH,
        ),
        itemCount: count,
        itemBuilder: (context, _) => _shimmerCard(
          context: context,
          radius: 40,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ShimmerCircle(size: 40),
              const SizedBox(height: 8),
              ShimmerBox(width: 60, height: 10),
              const SizedBox(height: 4),
              ShimmerBox(width: 44, height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton for a section menu (e.g. Account settings rows).
class ShimmerMenuSection extends StatelessWidget {
  final int itemCount;
  const ShimmerMenuSection({super.key, this.itemCount = 2});

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;
    return AppShimmer(
      child: _shimmerCard(
        context: context,
        child: Column(
          children: List.generate(itemCount, (i) => Container(
            padding: EdgeInsets.symmetric(
              horizontal: (sw * 0.045).clamp(14.0, 20.0),
              vertical: (sh * 0.016).clamp(12.0, 18.0),
            ),
            decoration: BoxDecoration(
              border: Border(
                top: i == 0
                    ? BorderSide.none
                    : BorderSide(color: AppColors.of(context).divider, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                ShimmerBox(width: (sw * 0.088).clamp(30.0, 38.0), height: (sw * 0.088).clamp(30.0, 38.0), radius: 10),
                const SizedBox(width: 12),
                ShimmerBox(width: sw * 0.35, height: 13),
              ],
            ),
          )),
        ),
      ),
    );
  }
}
