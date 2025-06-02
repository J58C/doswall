import 'package:flutter/material.dart';

@immutable
class CustomColors extends ThemeExtension<CustomColors> {
  const CustomColors({
    required this.success,
    // Anda bisa menambahkan warna kustom lainnya di sini jika perlu
  });

  final Color? success;

  @override
  CustomColors copyWith({Color? success}) {
    return CustomColors(
      success: success ?? this.success,
    );
  }

  @override
  CustomColors lerp(ThemeExtension<CustomColors>? other, double t) {
    if (other is! CustomColors) {
      return this;
    }
    return CustomColors(
      success: Color.lerp(success, other.success, t),
    );
  }

// Opsional: Helper untuk akses yang lebih mudah
// static CustomColors? of(BuildContext context) {
//   return Theme.of(context).extension<CustomColors>();
// }
}