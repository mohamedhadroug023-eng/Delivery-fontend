import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({
    super.key,
    required this.status,
  });

  String get label {
    switch (status) {
      case 'pending':
        return 'في انتظار السائق';

      case 'offered':
        return 'تم إرسال الطلب';

      case 'accepted':
        return 'تم قبول الطلب';

      case 'arrived_restaurant':
        return 'السائق وصل للمطعم';

      case 'picked_up':
        return 'تم استلام الطلب';

      case 'on_the_way':
        return 'في الطريق للزبون';

      case 'delivered':
        return 'تم التوصيل';

      case 'cancelled':
        return 'ملغى';

      default:
        return status;
    }
  }

  Color get color {
    switch (status) {
      case 'pending':
      case 'offered':
        return Colors.orange;

      case 'accepted':
      case 'arrived_restaurant':
        return Colors.blue;

      case 'picked_up':
      case 'on_the_way':
        return Colors.indigo;

      case 'delivered':
        return Colors.green;

      case 'cancelled':
        return Colors.red;

      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
