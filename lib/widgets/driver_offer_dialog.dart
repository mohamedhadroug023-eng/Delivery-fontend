import 'dart:async';

import 'package:flutter/material.dart';

import '../models/order_model.dart';

class DriverOfferDialog extends StatefulWidget {
  final OrderModel order;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const DriverOfferDialog({
    super.key,
    required this.order,
    required this.onAccept,
    required this.onReject,
  });

  @override
  State<DriverOfferDialog> createState() =>
      _DriverOfferDialogState();
}

class _DriverOfferDialogState
    extends State<DriverOfferDialog> {
  int seconds = 20;
  Timer? timer;

  @override
  void initState() {
    super.initState();

    timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (seconds <= 1) {
          timer.cancel();

          if (mounted) {
            Navigator.pop(context);
            widget.onReject();
          }
        } else {
          setState(() {
            seconds--;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'طلب توصيل جديد',
        textAlign: TextAlign.center,
      ),

      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B00)
                  .withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$seconds',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF6B00),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          Text(
            widget.order.restaurantName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            widget.order.customerAddress,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 14),

          Text(
            'أجرة السائق: ${widget.order.driverFee.toStringAsFixed(3)} د.ت',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),

      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            widget.onReject();
          },
          child: const Text(
            'رفض',
            style: TextStyle(color: Colors.red),
          ),
        ),

        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            widget.onAccept();
          },
          child: const Text('قبول الطلب'),
        ),
      ],
    );
  }
}
