import 'package:flutter/material.dart';

class BackgroundShape {
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;
  final double width;
  final double height;
  final Color color;

  const BackgroundShape({
    this.top,
    this.bottom,
    this.left,
    this.right,
    required this.width,
    required this.height,
    required this.color,
  });
}