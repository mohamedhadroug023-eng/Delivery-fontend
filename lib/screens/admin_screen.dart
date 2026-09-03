import 'package:flutter/material.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  static const orange = Color(0xFFFF6B00);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة الإدارة'),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              'نظرة عامة',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            // =============================
            // STATISTICS
            // =============================

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.35,
              children: [

                _statCard(
                  Icons.restaurant,
                  'المطاعم',
                  '0',
                ),

                _statCard(
                  Icons.two_wheeler,
                  'السائقون',
                  '0',
                ),

                _statCard(
                  Icons.receipt_long,
                  'طلبات اليوم',
                  '0',
                ),

                _statCard(
                  Icons.payments,
                  'دخل اليوم',
                  '0.000 د.ت',
                ),
              ],
            ),

            const SizedBox(height: 15),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [

                    Container(
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: orange.withOpacity(.1),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.account_balance,
                        color: orange,
                        size: 30,
                      ),
                    ),

                    const SizedBox(width: 15),

                    const Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'إجمالي المبالغ المستحقة',
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            '0.000 د.ت',
                            style: TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            const Text(
              'الطلبات النشطة',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.location_on,
                  color: orange,
                ),
                title: const Text(
                  'لا توجد طلبات نشطة',
                ),
                subtitle: const Text(
                  'ستظهر الطلبات هنا عند بدء التوصيل',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.map),
                  onPressed: () {},
                ),
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              'الإدارة',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            _adminAction(
              Icons.restaurant_menu,
              'إدارة المطاعم',
              () {},
            ),

            _adminAction(
              Icons.people,
              'إدارة السائقين',
              () {},
            ),

            _adminAction(
              Icons.receipt_long,
              'جميع الطلبات',
              () {},
            ),

            _adminAction(
              Icons.bar_chart,
              'التقارير والإحصائيات',
              () {},
            ),

            _adminAction(
              Icons.account_balance_wallet,
              'المبالغ المستحقة',
              () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(
    IconData icon,
    String title,
    String value,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 3),

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

  Widget _adminAction(
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: orange.withOpacity(.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: orange,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_back_ios_new,
          size: 16,
        ),
      ),
    );
  }
}
