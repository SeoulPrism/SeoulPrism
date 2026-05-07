import 'package:flutter/material.dart';

/// POI/장소 패널의 액션 버튼 (출발/도착/정보 등). 색상 톤만 다르고 형태 동일.
class PlaceActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const PlaceActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 0.8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 카카오 distance 문자열 (m 단위) → "320m" / "1.2km" 같은 표기로 정규화.
String formatPlaceDistance(String distance) {
  final m = int.tryParse(distance) ?? 0;
  if (m >= 1000) return '${(m / 1000).toStringAsFixed(1)}km';
  return '${m}m';
}
