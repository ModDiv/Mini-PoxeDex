import 'dart:math' as math;

import 'package:flutter/material.dart';

class RotatingPokeball extends StatefulWidget {
  final double size;

  const RotatingPokeball({super.key, required this.size});

  @override
  State<RotatingPokeball> createState() => _RotatingPokeballState();
}

class _RotatingPokeballState extends State<RotatingPokeball>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 10),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: CustomPaint(
        size: Size.square(widget.size),
        painter: _PokeballPainter(),
      ),
    );
  }
}

class _PokeballPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final center = Offset(r, r);
    final rect = Rect.fromCircle(center: center, radius: r);

    canvas.clipPath(Path()..addOval(rect));

    // Setengah atas lebih gelap, setengah bawah lebih terang
    canvas.drawArc(
      rect,
      math.pi,
      math.pi,
      true,
      Paint()..color = Colors.black.withAlpha(40),
    );
    canvas.drawArc(
      rect,
      0,
      math.pi,
      true,
      Paint()..color = Colors.black.withAlpha(20),
    );

    // Pita tengah
    final white = Paint()..color = Colors.white.withAlpha(80);
    canvas.drawRect(
      Rect.fromCenter(center: center, width: size.width, height: r * 0.14),
      white,
    );

    // Tombol tengah
    canvas.drawCircle(center, r * 0.27, white);
    canvas.drawCircle(
      center,
      r * 0.17,
      Paint()..color = Colors.black.withAlpha(50),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}