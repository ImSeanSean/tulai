import 'package:flutter/material.dart';

class Button extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final VoidCallback onPressed;
  final double borderRadius;

  const Button({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.onPressed,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
      onPressed: onPressed,
      child: Text(
        label,
        style: const TextStyle(color: Colors.white),
      ),
    );
  }
}
