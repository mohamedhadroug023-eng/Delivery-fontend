import 'package:flutter/material.dart';

void main() {
  runApp(const DeliveryApp());
}

class DeliveryApp extends StatelessWidget {
  const DeliveryApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Delivery Platform',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      home: const RoleSelectionScreen(),
    );
  }
}

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({Key? key}) : super(key: key);

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String? selectedRole; // لتحديد الدور: restaurant, driver, admin

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('منصة التوصيل الذكية'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: selectedRole == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'اختر صففتك للبدء:',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 30),
                  _buildRoleCard(
                    title: 'مطعم',
                    icon: Icons.restaurant,
                    color: Colors.orange,
                    role: 'restaurant',
                  ),
                  const SizedBox(height: 15),
                  _buildRoleCard(
                    title: 'سائق',
                    icon: Icons.delivery_dining,
                    color: Colors.blue,
                    role: 'driver',
                  ),
                  const SizedBox(height: 15),
                  _buildRoleCard(
                    title: 'إدارة',
                    icon: Icons.admin_panel_settings,
                    color: Colors.purple,
                    role: 'admin',
                  ),
                ],
              )
            : LoginForm(
                role: selectedRole!,
                onBack: () {
                  setState(() {
                    selectedRole = null;
                  });
                },
              ),
      ),
    );
  }

  Widget_buildRoleCard({
    required String title,
    required IconData icon,
    required Color color,
    required String role,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(20),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color, size: 30),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          setState(() {
            selectedRole = role;
          });
        },
      ),
    );
  }
}

class LoginForm extends StatelessWidget {
  final String role;
  final VoidCallback onBack;

  LoginForm({Key? key, required this.role, required this.onBack}) : super(key: key);

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String getRoleTitle() {
    if (role == 'restaurant') return 'تسجيل دخول المطعم';
    if (role == 'driver') return 'تسجيل دخول السائق';
    return 'تسجيل دخول الإدارة';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          getRoleTitle(),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 30),
        TextField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'البريد الإلكتروني أو رقم الهاتف',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.person),
          ),
        ),
        const SizedBox(height: 15),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'كلمة المرور',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.lock),
          ),
        ),
        const SizedBox(height: 25),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () {
            // هنا سيتم ربط التحقق لاحقاً والانتقال للوحة الخاصة بكل دور
          },
          child: const Text('دخول', style: TextStyle(fontSize: 18)),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: onBack,
          child: const Text('العودة لتغيير الصفة'),
        ),
      ],
    );
  }
}
