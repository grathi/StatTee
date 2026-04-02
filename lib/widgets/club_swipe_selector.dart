import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:superellipse_shape/superellipse_shape.dart';
import '../theme/app_theme.dart';

// ---------------------------------------------------------------------------
// ClubSwipeSelector — ordered multi-select club picker
//
// • Shows a big card at the top listing selected clubs in order
// • All clubs shown as small chips below — tap to select, tap again to remove
// • Max selections = maxSelections (= player's score for the hole)
// • Each selected chip shows a numbered badge (①②③…) indicating selection order
// • Recommended clubs are visually highlighted
// ---------------------------------------------------------------------------

class ClubSwipeSelector extends StatelessWidget {
  final List<String> clubs;

  /// Clubs highlighted as AI-recommended.
  final List<String> recommendedClubs;

  /// Ordered list of selected clubs — index 0 = first hit.
  final List<String> selectedClubs;

  /// Maximum number of selections allowed (= player's score).
  final int maxSelections;

  /// Called whenever the ordered selection changes.
  final void Function(List<String> clubs) onClubsChanged;

  const ClubSwipeSelector({
    super.key,
    required this.clubs,
    required this.recommendedClubs,
    required this.selectedClubs,
    required this.maxSelections,
    required this.onClubsChanged,
  });

  void _toggle(String club) {
    final idx = selectedClubs.indexOf(club);
    if (idx >= 0) {
      // Deselect — remove and keep order of remaining
      final updated = List<String>.from(selectedClubs)..removeAt(idx);
      onClubsChanged(updated);
    } else if (selectedClubs.length < maxSelections) {
      // Select — append to end
      onClubsChanged([...selectedClubs, club]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Selected clubs summary card ─────────────────────────────────
        _SummaryCard(
          selectedClubs: selectedClubs,
          maxSelections: maxSelections,
          recommendedClubs: recommendedClubs,
          c: c,
        ),
        const SizedBox(height: 12),
        // ── Club chip grid ──────────────────────────────────────────────
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: clubs.map((club) {
            final selIdx    = selectedClubs.indexOf(club);
            final isSelected  = selIdx >= 0;
            final isRecommended = recommendedClubs.contains(club);
            final atMax       = selectedClubs.length >= maxSelections;
            final isDisabled  = !isSelected && atMax;

            return _ClubChip(
              club: club,
              selectionOrder: isSelected ? selIdx + 1 : null,
              isRecommended: isRecommended,
              isDisabled: isDisabled,
              c: c,
              onTap: isDisabled
                  ? null
                  : () {
                      HapticFeedback.selectionClick();
                      _toggle(club);
                    },
            );
          }).toList(),
        ),
        const SizedBox(height: 4),
        // ── Counter hint ────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            '${selectedClubs.length} of $maxSelections clubs selected',
            style: TextStyle(
              color: c.tertiaryText,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Summary card (top) ────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final List<String> selectedClubs;
  final List<String> recommendedClubs;
  final int maxSelections;
  final AppColors c;

  const _SummaryCard({
    required this.selectedClubs,
    required this.recommendedClubs,
    required this.maxSelections,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    final hasSelection = selectedClubs.isNotEmpty;

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: hasSelection ? 14 : 13,
        ),
        decoration: ShapeDecoration(
          color: hasSelection ? c.accentBg : c.fieldBg,
          shape: SuperellipseShape(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: hasSelection ? c.accentBorder : c.fieldBorder,
              width: hasSelection ? 1.5 : 1.0,
            ),
          ),
          shadows: hasSelection
              ? [BoxShadow(
                  color: c.accent.withValues(alpha: 0.10),
                  blurRadius: 12, offset: const Offset(0, 3),
                )]
              : null,
        ),
        child: hasSelection ? _selectedContent() : _emptyContent(),
      ),
    );
  }

  Widget _emptyContent() {
    return Row(
      children: [
        Icon(Icons.sports_golf_rounded, color: c.tertiaryText, size: 20),
        const SizedBox(width: 10),
        Text(
          'Tap clubs below to track each shot',
          style: TextStyle(
            color: c.tertiaryText,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _selectedContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Row of ordered club pills
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: List.generate(selectedClubs.length, (i) {
            final club = selectedClubs[i];
            final isRec = recommendedClubs.contains(club);
            return _OrderedPill(
              club: club,
              order: i + 1,
              isRecommended: isRec,
              c: c,
            );
          }),
        ),
      ],
    );
  }
}

// ── Ordered pill inside summary card ─────────────────────────────────────────

class _OrderedPill extends StatelessWidget {
  final String club;
  final int order;
  final bool isRecommended;
  final AppColors c;

  const _OrderedPill({
    required this.club,
    required this.order,
    required this.isRecommended,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: ShapeDecoration(
        color: c.fieldBg,
        shape: SuperellipseShape(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: c.accentBorder),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Order badge circle
          Container(
            width: 16, height: 16,
            decoration: BoxDecoration(
              color: c.accent,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$order',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            club,
            style: TextStyle(
              fontFamily: 'Nunito',
              color: c.accent,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (isRecommended) ...[
            const SizedBox(width: 4),
            Container(
              width: 5, height: 5,
              decoration: BoxDecoration(
                color: c.accent.withValues(alpha: 0.60),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Individual club chip ──────────────────────────────────────────────────────

class _ClubChip extends StatelessWidget {
  final String club;

  /// 1-based order index, or null if not selected.
  final int? selectionOrder;

  final bool isRecommended;
  final bool isDisabled;
  final AppColors c;
  final VoidCallback? onTap;

  const _ClubChip({
    required this.club,
    required this.selectionOrder,
    required this.isRecommended,
    required this.isDisabled,
    required this.c,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selectionOrder != null;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: ShapeDecoration(
          color: isSelected
              ? c.accentBg
              : isRecommended
                  ? c.accentBg.withValues(alpha: 0.55)
                  : c.fieldBg,
          shape: SuperellipseShape(
            borderRadius: BorderRadius.circular(11),
            side: BorderSide(
              color: isDisabled
                  ? c.fieldBorder.withValues(alpha: 0.4)
                  : isSelected
                      ? c.accentBorder.withValues(alpha: 0.7)
                      : isRecommended
                          ? c.accentBorder
                          : c.fieldBorder,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          shadows: isSelected
              ? [BoxShadow(
                  color: c.accent.withValues(alpha: 0.12),
                  blurRadius: 6, offset: const Offset(0, 2),
                )]
              : null,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Club label
            Padding(
              // Extra right padding when there is a badge to avoid overlap
              padding: EdgeInsets.only(right: isSelected ? 4.0 : 0),
              child: Text(
                club,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  color: isDisabled
                      ? c.tertiaryText.withValues(alpha: 0.5)
                      : isSelected
                          ? c.accent
                          : isRecommended
                              ? c.accent.withValues(alpha: 0.80)
                              : c.secondaryText,
                  fontSize: 13,
                  fontWeight: (isSelected || isRecommended)
                      ? FontWeight.w700
                      : FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
            ),

            // Recommended dot (unselected only)
            if (isRecommended && !isSelected)
              Positioned(
                top: -3, right: -4,
                child: Container(
                  width: 5, height: 5,
                  decoration: BoxDecoration(
                    color: c.accent.withValues(alpha: 0.70),
                    shape: BoxShape.circle,
                  ),
                ),
              ),

            // Order number badge
            if (isSelected)
              Positioned(
                top: -6, right: -6,
                child: Container(
                  width: 16, height: 16,
                  decoration: BoxDecoration(
                    color: c.accent,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      '${selectionOrder!}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
