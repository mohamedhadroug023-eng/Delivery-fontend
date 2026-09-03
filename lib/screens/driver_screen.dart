import 'package:flutter/material.dart';

class DriverScreen extends StatefulWidget {
  const DriverScreen({super.key});

  @override
  State<DriverScreen> createState() => _DriverScreenState();
}

class _DriverScreenState extends State<DriverScreen> {
  static const orange = Color(0xFFFF6B00);

  bool online = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مساحة السائق'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none),
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            // STATUS

            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [

                    Container(
                      width: 13,
                      height: 13,
                      decoration: BoxDecoration(
                        color: online
                            ? Colors.green
                            : Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: Text(
                        online
                            ? 'أنت متاح لاستقبال الطلبات'
                            : 'أنت غير متاح',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    Switch(
                      value: online,
                      activeColor: orange,
                      onChanged: (value) {
                        setState(() {
                          online = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 15),

            // DAILY STATS

            Row(
              children: [
                Expanded(
                  child: _stat(
                    Icons.receipt_long,
                    'طلبات اليوم',
                    '0',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _stat(
                    Icons.payments,
                    'الدخل اليوم',
                    '0.000 د.ت',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),

            const Align(
              alignment: Alignment.centerRight,
              child: Text(
                'الطلب الحالي',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 12),

            _currentOrder(context),

            const SizedBox(height: 25),

            const Align(
              alignment: Alignment.centerRight,
              child: Text(
                'سجل الطلبات',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 12),

            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.history,
                  color: orange,
                ),
                title: const Text('لا توجد طلبات'),
                subtitle: const Text(
                  'ستظهر طلباتك هنا',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(
    IconData icon,
    String title,
    String value,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            Icon(
              icon,
              color: orange,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              title,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _currentOrder(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [

            const Icon(
              Icons.delivery_dining,
              size: 55,
              color: Colors.grey,
            ),

            const SizedBox(height: 10),

            const Text(
              'لا يوجد طلب حالي',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 5),

            const Text(
              'عند وصول طلب جديد سيظهر هنا',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 18),

            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.map),
              label: const Text('فتح الخريطة'),
            ),
          ],
        ),
      ),
    );
  }
}
