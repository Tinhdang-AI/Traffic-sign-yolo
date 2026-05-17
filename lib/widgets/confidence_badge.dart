import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ConfidenceBadge extends StatelessWidget {
  final double confidence;
  final double fontSize;
  final double iconSize;
  final EdgeInsets padding;
  final bool showIcon;
  final bool outline;
  final BorderRadius? borderRadius;

  const ConfidenceBadge({
    super.key,
    required this.confidence,
    this.fontSize = 11,
    this.iconSize = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    this.showIcon = true,
    this.outline = true,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final confPercent = (confidence * 100).toInt().clamp(0, 100);
    
    // Determine colors and icon based on confidence threshold
    final Color badgeColor;
    final Color backgroundColor;
    final IconData iconData;

    if (confidence >= 0.80) {
      // High confidence (>= 80%): Safety Green
      badgeColor = const Color(0xFF34D399); // Mint green
      backgroundColor = const Color(0xFF34D399).withOpacity(0.12);
      iconData = Icons.verified_user_rounded;
    } else if (confidence >= 0.60) {
      // Medium confidence (60% - 79%): Warning Amber/Orange
      badgeColor = const Color(0xFFFBBF24); // Warm yellow/amber
      backgroundColor = const Color(0xFFFBBF24).withOpacity(0.12);
      iconData = Icons.info_outline_rounded;
    } else {
      // Low confidence (< 60%): Danger/Error Red
      badgeColor = const Color(0xFFF87171); // Soft vibrant red
      backgroundColor = const Color(0xFFF87171).withOpacity(0.12);
      iconData = Icons.gpp_maybe_rounded;
    }

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius ?? BorderRadius.circular(999), // Capsule style
        border: outline 
            ? Border.all(color: badgeColor.withOpacity(0.35), width: 1.0) 
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              iconData,
              size: iconSize,
              color: badgeColor,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            '$confPercent%',
            style: GoogleFonts.inter(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: badgeColor,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
