import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MapButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final double? latitude;
  final double? longitude;

  const MapButton({
    super.key,
    this.title = 'فتح Google Maps',
    this.icon = Icons.navigation_outlined,
    this.latitude,
    this.longitude,
  });

  Future<void> _openMaps(BuildContext context) async {
    if (latitude == null || longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'إحداثيات الموقع غير متوفرة',
          ),
        ),
      );
      return;
    }

    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=$latitude,$longitude'
      '&travelmode=driving',
    );

    try {
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!opened && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تعذر فتح Google Maps',
            ),
          ),
        );
      }
    } catch (error) {
      debugPrint(
        'Google Maps error: $error',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'حدث خطأ أثناء فتح الخريطة',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => _openMaps(context),
      icon: Icon(icon),
      label: Text(title),
    );
  }
}
