import 'dart:ui';

import 'app_colors.dart';

/// Parse hex string (RRGGBB, #RRGGBB, or AARRGGBB) to Color.
Color colorFromHex(String? hex) {
  if (hex == null || hex.isEmpty) return AppColors.light.ink;
  var s = hex.trim().toUpperCase().replaceAll('#', '');
  if (s.startsWith('0X')) s = s.substring(2);
  if (s.length == 6) s = 'FF$s';
  final n = int.tryParse(s, radix: 16);
  if (n == null) return AppColors.light.ink;
  return Color(n);
}

extension ColorAlpha on Color {
  /// Accepts both percentage and alpha styles:
  /// - `12` -> 12%
  /// - `0.12` -> 12%
  Color withOpacityPercent(num opacity) {
    final raw = opacity.toDouble();
    final normalized = raw > 1 ? raw / 100.0 : raw;
    final clamped = normalized.clamp(0.0, 1.0);
    return withValues(alpha: clamped);
  }

  String toHex() {
    int to8(double c) => (c.clamp(0.0, 1.0) * 255).round();
    String two(int v) => v.toRadixString(16).padLeft(2, '0').toUpperCase();
    final r = to8(this.r);
    final g = to8(this.g);
    final b = to8(this.b);
    return '${two(r)}${two(g)}${two(b)}';
  }
}
