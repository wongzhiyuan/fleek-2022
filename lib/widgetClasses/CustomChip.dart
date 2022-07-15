import 'package:flutter/material.dart';

class CustomChip extends StatelessWidget {
  final Color backgroundColor;
  final Widget label;
  final Function onPressed;
  final double borderRadius;
  final double paddingH;
  final double paddingV;

  CustomChip({
    this.backgroundColor,
    this.label,
    this.onPressed,
    this.borderRadius,
    this.paddingH,
    this.paddingV,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          color: backgroundColor,
          padding: EdgeInsets.symmetric(horizontal: paddingH, vertical: paddingV),
          child: label,
        ),
      ),
    );
  }

}