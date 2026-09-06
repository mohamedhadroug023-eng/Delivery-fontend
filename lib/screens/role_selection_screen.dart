import 'package:flutter/material.dart';
import 'login_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  static const Color orange = Color(0xFFFF6B00);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [

                const SizedBox(height: 35),

                // LOGO
                Container(
                  width: 105,
                  height: 105,
                  decoration: BoxDecoration(
                    color: orange,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: orange.withOpacity(0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.delivery_dining,
                    color: Colors.white,
                    size: 62,
                  ),
                ),

                const SizedBox(height: 22),

                const Text(
                  'HADROUG',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),

                const Text(
                  'DELIVERY',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: orange,
                    letterSpacing: 4,
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  'منصة توصيل الطلبات للمطاعم والسائقين',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 45),

                const Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'اختر نوع الحساب',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                _roleCard(
                  context,
                  icon: Icons.restaurant,
                  title: 'المطعم',
                  subtitle: 'إدارة الطلبات ومتابعة السائقين',
                  role: 'restaurant',
                ),

                const SizedBox(height: 14),

                _roleCard(
                  context,
                  icon: Icons.two_wheeler,
                  title: 'السائق',
                  subtitle: 'استقبال الطلبات وتنفيذ عمليات التوصيل',
                  role: 'driver',
                ),

                const SizedBox(height: 14),

                _roleCard(
                  context,
                  icon: Icons.admin_panel_settings,
                  title: 'الإدارة',
                  subtitle: 'إدارة المطاعم والسائقين والطلبات',
                  role: 'admin',
                ),

                const SizedBox(height: 40),

                const Text(
                  'HADROUG DELIVERY © 2026',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _roleCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String role,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LoginScreen(role: role),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [

              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: orange.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: orange,
                  size: 30,
                ),
              ),

              const SizedBox(width: 15),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.arrow_back_ios_new,
                size: 18,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
