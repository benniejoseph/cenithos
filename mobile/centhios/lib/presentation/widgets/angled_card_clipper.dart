import 'package:flutter/material.dart';

class AngledCardClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    const angleHeight = 15.0;

    path.moveTo(0, angleHeight);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height - angleHeight);
    path.lineTo(0, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
