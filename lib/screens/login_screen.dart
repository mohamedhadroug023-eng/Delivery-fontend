import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/auth_service.dart';

import 'restaurant_screen.dart';
import 'driver_screen.dart';
import 'admin_screen.dart';
import 'register_screen.dart'; // استيراد صفحة التسجيل

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

  Future<void> login() async {
    final phone = phoneController.text.trim();
    final password = passwordController.text;

    if (phone.isEmpty || password.isEmpty) {
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

    try {
      final response = await ApiService.post(
        '/auth/login',
        {
          'phone': phone,
          'password': password,
        },
      );

      if (!mounted) return;

      if (response['success'] != true) {
        throw Exception(
          response['message'] ?? 'فشل تسجيل الدخول',
        );
      }

      final token = response['token'];
      final user = response['user'];

      if (token == null || user == null) {
        throw Exception('استجابة غير صحيحة من الخادم');
      }

      final serverRole = user['role'];
      final userId = user['id'];

      if (serverRole != widget.role) {
        throw Exception(
          'هذا الحساب لا ينتمي إلى قسم ${title}',
        );
      }

      await AuthService.saveSession(
        token: token.toString(),
        role: serverRole.toString(),
        userId: int.parse(userId.toString()),
      );

      if (!mounted) return;

      Widget screen;

      switch (serverRole) {
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
          throw Exception('نوع حساب غير معروف');
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => screen,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      String message = error.toString();

      if (message.startsWith('Exception: ')) {
        message = message.substring(11);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
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
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: loading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
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
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'استعادة كلمة المرور ستكون متاحة لاحقًا',
                    ),
                  ),
                );
              },
              child: const Text(
                'نسيت كلمة المرور؟',
              ),
            ),

            // زر الانتقال لإنشاء الحساب بناءً على الدور المختار
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('ليس لديك حساب؟'),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RegisterScreen(role: widget.role),
                      ),
                    );
                  },
                  child: const Text(
                    'سجل الآن',
                    style: TextStyle(
                      color: Color(0xFFFF6B00),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
