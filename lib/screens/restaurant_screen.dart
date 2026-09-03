import 'package:flutter/material.dart';

class RestaurantScreen extends StatelessWidget {
  const RestaurantScreen({super.key});

  static const orange = Color(0xFFFF6B00);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة المطعم'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              'مطعمي',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 5),

            const Text(
              'ملخص اليوم',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 20),

            // ==============================
            // STATISTICS
            // ==============================

            Row(
              children: [
                Expanded(
                  child: _statCard(
                    icon: Icons.receipt_long,
                    title: 'طلبات اليوم',
                    value: '0',
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: _statCard(
                    icon: Icons.two_wheeler,
                    title: 'السائقون',
                    value: '0',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            _moneyCard(),

            const SizedBox(height: 25),

            // ==============================
            // NEW ORDER
            // ==============================

            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton.icon(
                onPressed: () {
                  _showNewOrderDialog(context);
                },
                icon: const Icon(Icons.add),
                label: const Text(
                  'إنشاء طلب توصيل',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),

            const Text(
              'الطلبات الحالية',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            _orderCard(
              context,
              orderNumber: '#0001',
              customer: 'لا توجد طلبات',
              status: 'لا يوجد طلب نشط',
            ),

            const SizedBox(height: 25),

            const Text(
              'إجراءات سريعة',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _quickAction(
                    icon: Icons.history,
                    title: 'سجل الطلبات',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _quickAction(
                    icon: Icons.bar_chart,
                    title: 'التقارير',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              icon,
              color: orange,
              size: 30,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _moneyCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: orange.withOpacity(.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.account_balance_wallet,
                color: orange,
              ),
            ),

            const SizedBox(width: 15),

            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'المبلغ المستحق',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  '0.000 د.ت',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _orderCard(
    BuildContext context, {
    required String orderNumber,
    required String customer,
    required String status,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  orderNumber,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(status),
                ),
              ],
            ),

            const SizedBox(height: 15),

            Row(
              children: [
                const Icon(
                  Icons.person,
                  color: orange,
                ),
                const SizedBox(width: 8),
                Text(customer),
              ],
            ),

            const SizedBox(height: 15),

            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.map),
              label: const Text('متابعة الطلب'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickAction({
    required IconData icon,
    required String title,
  }) {
    return Card(
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Icon(
                icon,
                color: orange,
                size: 30,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNewOrderDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              const Text(
                'طلب توصيل جديد',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              const TextField(
                decoration: InputDecoration(
                  labelText: 'اسم الزبون',
                  prefixIcon: Icon(Icons.person),
                ),
              ),

              const SizedBox(height: 12),

              const TextField(
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'رقم الزبون',
                  prefixIcon: Icon(Icons.phone),
                ),
              ),

              const SizedBox(height: 12),

              const TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'قيمة الطلب',
                  prefixIcon: Icon(Icons.attach_money),
                ),
              ),

              const SizedBox(height: 12),

              const TextField(
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'موقع الزبون أو رابط Google Maps',
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('نشر طلب التوصيل'),
              ),
            ],
          ),
        );
      },
    );
  }
}
