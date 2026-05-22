import 'package:flutter/material.dart';

class CustomActionButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onPressed;

  const CustomActionButton({
    super.key,
    required this.icon,
    required this.title,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 55,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF124559),
          foregroundColor: const Color(0xFFEFF6E0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        onPressed: onPressed,
        icon: Icon(icon, color: const Color(0xFFAEC3B0)),
        label: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}