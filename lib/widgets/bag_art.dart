import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

class PackMark extends StatelessWidget {
  const PackMark({super.key, this.size = 28});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primaryOf(context),
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Icon(Icons.swap_horiz_rounded,
          color: AppColors.onPrimaryOf(context), size: size * 0.62),
    );
  }
}

class PackGlyph extends StatelessWidget {
  const PackGlyph({super.key, required this.icon, this.size = 22, this.color});

  final String icon;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final ink = color ?? AppColors.inkOf(context);
    if (icon == 'sun') return _SunGlyph(size: size, color: ink);
    return Icon(_icon(icon), size: size, color: ink);
  }
}

IconData _icon(String icon) => switch (icon) {
      'passport' => Icons.badge_outlined,
      'wallet' => Icons.account_balance_wallet_outlined,
      'phone' => Icons.smartphone_outlined,
      'charger' => Icons.power_outlined,
      'battery' => Icons.battery_5_bar_outlined,
      'shirt' => Icons.checkroom_outlined,
      'soap' => Icons.soap_outlined,
      'laptop' => Icons.laptop_mac_outlined,
      'badge' => Icons.badge_outlined,
      'note' => Icons.menu_book_outlined,
      _ => Icons.inventory_2_outlined,
    };

class _SunGlyph extends StatelessWidget {
  const _SunGlyph({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _SunPainter(color)),
    );
  }
}

class _SunPainter extends CustomPainter {
  const _SunPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round;
    final y = size.height * 0.55;
    final r = size.width * 0.16;
    canvas.drawCircle(Offset(size.width * 0.32, y), r, paint);
    canvas.drawCircle(Offset(size.width * 0.68, y), r, paint);
    canvas.drawLine(
        Offset(size.width * 0.48, y), Offset(size.width * 0.52, y), paint);
    canvas.drawLine(Offset(size.width * 0.18, y - r),
        Offset(size.width * 0.82, y - r * 1.35), paint);
  }

  @override
  bool shouldRepaint(covariant _SunPainter oldDelegate) =>
      oldDelegate.color != color;
}

class BagArt extends StatelessWidget {
  const BagArt({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 118,
      width: double.infinity,
      child: CustomPaint(painter: _BagPainter()),
    );
  }
}

class _BagPainter extends CustomPainter {
  const _BagPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final casePaint = Paint()..color = const Color(0xFFCDB892);
    final lidPaint = Paint()..color = const Color(0xFFE4D3B0);
    final inside = Paint()..color = const Color(0xFFF8F1E4);
    final line = Paint()
      ..color = const Color(0xFF8C6B45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final left = size.width * 0.08;
    final right = size.width * 0.92;
    final top = size.height * 0.28;
    final bottom = size.height * 0.92;
    final body = RRect.fromRectAndRadius(
        Rect.fromLTRB(left, top, right, bottom), const Radius.circular(16));
    canvas.drawRRect(body, casePaint);
    final cavity = RRect.fromRectAndRadius(
      Rect.fromLTRB(left + 10, top + 8, right - 10, bottom - 8),
      const Radius.circular(10),
    );
    canvas.drawRRect(cavity, inside);
    final lid = Path()
      ..moveTo(left + 8, top + 4)
      ..lineTo(left + 28, size.height * 0.02)
      ..lineTo(right - 36, size.height * 0.02)
      ..lineTo(right - 8, top + 2)
      ..close();
    canvas.drawPath(lid, lidPaint);
    canvas.drawPath(lid, line);
    final shirt = RRect.fromRectAndRadius(
      Rect.fromLTWH(left + 22, top + 22, size.width * 0.28, 46),
      const Radius.circular(6),
    );
    canvas.drawRRect(shirt, Paint()..color = const Color(0xFFF7F7F4));
    canvas.drawRRect(shirt, line);
    final pass = RRect.fromRectAndRadius(
      Rect.fromLTWH(left + size.width * 0.40, top + 28, 42, 54),
      const Radius.circular(4),
    );
    canvas.drawRRect(pass, Paint()..color = const Color(0xFF1B4A40));
    canvas.drawCircle(Offset(pass.center.dx, pass.top + 18), 7,
        Paint()..color = const Color(0xFFE7C56A));
    final bottle = RRect.fromRectAndRadius(
      Rect.fromLTWH(right - 58, top + 18, 22, 52),
      const Radius.circular(8),
    );
    canvas.drawRRect(bottle, Paint()..color = const Color(0xFFF0C84A));
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(right - 54, top + 12, 14, 10),
          const Radius.circular(3)),
      Paint()..color = const Color(0xFF8C6B45),
    );
    canvas.drawLine(Offset(size.width * 0.5, bottom - 6),
        Offset(size.width * 0.5, bottom + 2), line);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PackCheck extends StatelessWidget {
  const PackCheck({super.key, required this.on, required this.onTap});

  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fill = AppColors.primaryOf(context);
    return Material(
      color: on ? fill : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(
            color: on ? fill : AppColors.borderOf(context), width: 1.6),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          width: 26,
          height: 26,
          child: on
              ? Icon(Icons.check_rounded,
                  size: 18, color: AppColors.onPrimaryOf(context))
              : null,
        ),
      ),
    );
  }
}
