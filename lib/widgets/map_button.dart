import 'package:flutter/material.dart';

class MapButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onPressed;

  const MapButton({
    super.key,
    this.title = 'فتح Google Maps',
    this.icon = Icons.navigation_outlined,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(title),
    );
  }
}
