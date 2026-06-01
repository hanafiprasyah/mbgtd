import 'package:flutter/material.dart';
import 'package:mbg_test/core/helper/design_system.dart';

class MenuCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? accentColor;
  final int index; // for stagger animation

  const MenuCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.accentColor,
    this.index = 0,
  });

  @override
  State<MenuCard> createState() => _MenuCardState();
}

class _MenuCardState extends State<MenuCard> {
  double scale = 1.0;
  bool isVisible = false;

  @override
  void initState() {
    super.initState();

    // stagger delay based on index
    Future.delayed(Duration(milliseconds: 80 * widget.index), () {
      if (mounted) {
        setState(() => isVisible = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color baseColor =
        widget.accentColor ?? Theme.of(context).primaryColor;

    return MouseRegion(
      onEnter: (_) => setState(() => scale = 1.03),
      onExit: (_) => setState(() => scale = 1.0),
      child: AnimatedOpacity(
        opacity: isVisible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        child: AnimatedSlide(
          offset: isVisible ? Offset.zero : const Offset(0, 0.1),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          child: AnimatedScale(
            scale: scale,
            duration: const Duration(milliseconds: 120),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.md),
                splashColor: baseColor.withValues(alpha: 0.15),
                highlightColor: Colors.transparent,
                onTap: () async {
                  setState(() => scale = 0.97);
                  await Future.delayed(const Duration(milliseconds: 80));
                  if (mounted) setState(() => scale = 1.0);
                  widget.onTap();
                },
                child: Ink(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    gradient: LinearGradient(
                      colors: isDark
                          ? [Colors.grey.shade900, Colors.grey.shade800]
                          : [Colors.white, baseColor.withValues(alpha: 0.08)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.05),
                    ),
                    boxShadow: isDark
                        ? []
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon container
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: baseColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(widget.icon, size: 22, color: baseColor),
                        ),

                        const Spacer(),

                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14,
                              color: isDark
                                  ? Colors.grey.shade500
                                  : Colors.grey.shade500,
                            ),
                          ],
                        ),

                        const SizedBox(height: 4),

                        Text(
                          widget.subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
