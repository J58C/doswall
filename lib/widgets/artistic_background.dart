import 'package:flutter/material.dart';
import '../models/background_shape.dart';

class ArtisticBackground extends StatelessWidget {
  final List<BackgroundShape> shapes;

  const ArtisticBackground({super.key, required this.shapes});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: shapes.map((shape) {
        return Positioned(
          top: shape.top,
          bottom: shape.bottom,
          left: shape.left,
          right: shape.right,
          child: Container(
            width: shape.width,
            height: shape.height,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: shape.color,
            ),
          ),
        );
      }).toList(),
    );
  }
}