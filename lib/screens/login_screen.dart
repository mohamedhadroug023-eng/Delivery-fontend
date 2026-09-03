import 'package:flutter/material.dart';

import 'restaurant_screen.dart';
import 'driver_screen.dart';
import 'admin_screen.dart';

class LoginScreen extends StatefulWidget {
  final String role;

  const LoginScreen({
    super.key,
    required this.role,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();

  bool obscurePassword = true;
  bool loading = false;

  String get title {
    switch (widget.role) {
      case 'restaurant':
        return 'دخول المطعم';
      case 'driver':
        return 'دخول السائق';
      case 'admin':
        return 'دخول الإدارة';
      default:
        return 'تسجيل الدخول';
    }
  }

  void login() async {
    if (phoneController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال جميع البيانات'),
        ),
      );
      return;
    }

    setState(() {
      loading = true;
    });

    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    setState(() {
      loading = false;
    });

    Widget screen;

    switch (widget.role) {
      case 'restaurant':
        screen = const RestaurantScreen();
        break;

      case 'driver':
        screen = const DriverScreen();
        break;

      case 'admin':
        screen = const AdminScreen();
        break;

      default:
        screen = const RestaurantScreen();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => screen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [

            const SizedBox(height: 30),

            const Icon(
              Icons.lock_outline,
              size: 70,
              color: Color(0xFFFF6B00),
            ),

            const SizedBox(height: 20),

            Text(
              title,
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 35),

            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'رقم الهاتف',
                prefixIcon: Icon(Icons.phone),
              ),
            ),

            const SizedBox(height: 18),

            TextField(
              controller: passwordController,
              obscureText: obscurePassword,
              decoration: InputDecoration(
                labelText: 'كلمة المرور',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    obscurePassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      obscurePassword = !obscurePassword;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: loading ? null : login,
              child: loading
                  ? const CircularProgressIndicator(
                      color: Colors.white,
                    )
                  : const Text(
                      'تسجيل الدخول',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),

            const SizedBox(height: 20),

            TextButton(
              onPressed: () {},
              child: const Text(
                'نسيت كلمة المرور؟',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
