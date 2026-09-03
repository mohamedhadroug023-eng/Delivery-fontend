import 'package:flutter/material.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final restaurantController = TextEditingController();
  final ownerController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;
  bool obscurePassword = true;

  void register() async {
    if (restaurantController.text.trim().isEmpty ||
        ownerController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty ||
        addressController.text.trim().isEmpty ||
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

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم إرسال طلب إنشاء الحساب'),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إنشاء حساب مطعم'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [

            const SizedBox(height: 15),

            const Icon(
              Icons.restaurant,
              size: 65,
              color: Color(0xFFFF6B00),
            ),

            const SizedBox(height: 20),

            const Text(
              'بيانات المطعم',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

            TextField(
              controller: restaurantController,
              decoration: const InputDecoration(
                labelText: 'اسم المطعم',
                prefixIcon: Icon(Icons.restaurant),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: ownerController,
              decoration: const InputDecoration(
                labelText: 'اسم المسؤول',
                prefixIcon: Icon(Icons.person),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'رقم الهاتف',
                prefixIcon: Icon(Icons.phone),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: addressController,
              decoration: const InputDecoration(
                labelText: 'عنوان المطعم',
                prefixIcon: Icon(Icons.location_on),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: passwordController,
              obscureText: obscurePassword,
              decoration: InputDecoration(
                labelText: 'كلمة المرور',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      obscurePassword = !obscurePassword;
                    });
                  },
                  icon: Icon(
                    obscurePassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: loading ? null : register,
              child: loading
                  ? const CircularProgressIndicator(
                      color: Colors.white,
                    )
                  : const Text(
                      'إنشاء الحساب',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
