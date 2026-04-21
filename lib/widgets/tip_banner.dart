import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A one-time dismissible tip card shown at the top of a screen.
///
/// Calls [hasSeenFn] on first build — if already seen, renders nothing.
/// When the user taps ×, calls [markSeenFn] and collapses with animation.
class TipBanner extends StatefulWidget {
  final String title;
  final String body;
  final Future<bool> Function() hasSeenFn;
  final Future<void> Function() markSeenFn;

  const TipBanner({
    super.key,
    required this.title,
    required this.body,
    required this.hasSeenFn,
    required this.markSeenFn,
  });

  @override
  State<TipBanner> createState() => _TipBannerState();
}

class _TipBannerState extends State<TipBanner>
    with SingleTickerProviderStateMixin {
  bool _visible = false;
  bool _loaded  = false;

  late AnimationController _ctrl;
  late Animation<double>   _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);

    widget.hasSeenFn().then((seen) {
      if (!mounted) return;
      setState(() {
        _visible = !seen;
        _loaded  = true;
      });
      if (!seen) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    await _ctrl.reverse();
    await widget.markSeenFn();
    if (mounted) setState(() => _visible = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || !_visible) return const SizedBox.shrink();

    final c  = AppColors.of(context);
    final sw = MediaQuery.of(context).size.width;
    final body  = (sw * 0.034).clamp(12.5, 15.0);
    final label = (sw * 0.028).clamp(10.5, 12.5);

    return FadeTransition(
      opacity: _fade,
      child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: c.sheetBg,
              border: Border.all(color: c.cardBorder),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7BC344).withValues(alpha: 0.10),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            // IntrinsicHeight lets CrossAxisAlignment.stretch work without
            // propagating infinite height constraints to the stripe child
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Green left stripe — fills card height via stretch
                  Container(width: 4, color: const Color(0xFF7BC344)),
                  const SizedBox(width: 10),

                  // Icon
                  Padding(
                    padding: EdgeInsets.only(top: (sw * 0.03).clamp(10.0, 14.0)),
                    child: Container(
                      width: (sw * 0.08).clamp(28.0, 36.0),
                      height: (sw * 0.08).clamp(28.0, 36.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7BC344).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lightbulb_rounded,
                        color: const Color(0xFF5A9E1F),
                        size: (sw * 0.045).clamp(16.0, 20.0),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Text content
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: (sw * 0.03).clamp(10.0, 14.0),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.title,
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              color: c.primaryText,
                              fontSize: body,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.body,
                            style: TextStyle(
                              color: c.secondaryText,
                              fontSize: label,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),

                  // Dismiss button
                  GestureDetector(
                    onTap: _dismiss,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(4, 12, 10, 12),
                      child: Icon(
                        Icons.close_rounded,
                        color: c.tertiaryText,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ),
    );
  }
}
