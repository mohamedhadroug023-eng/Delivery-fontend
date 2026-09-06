import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  final String role; // استقبال الدور (مطعم أو سائق)

  const RegisterScreen({
    super.key,
    required this.role,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final fullNameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  
  // حقول خاصة بالمطعم فقط
  final restaurantNameController = TextEditingController();
  final addressController = TextEditingController();

  bool loading = false;
  bool obscurePassword = true;

  String get screenTitle {
    return widget.role == 'restaurant' ? 'إنشاء حساب مطعم' : 'إنشاء حساب سائق';
  }

  void register() async {
    final fullName = fullNameController.text.trim();
    final phone = phoneController.text.trim();
    final password = passwordController.text.trim();

    if (fullName.isEmpty || phone.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال الحقول الإجبارية (الاسم، الهاتف، كلمة المرور)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (widget.role == 'restaurant' && (restaurantNameController.text.trim().isEmpty || addressController.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال اسم المطعم والعنوان'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      final response = await ApiService.post(
        '/auth/register',
        {
          'full_name': fullName,
          'phone': phone,
          'email': emailController.text.trim().isEmpty ? null : emailController.text.trim(),
          'password': password,
          'role': widget.role,
          'restaurant_name': widget.role == 'restaurant' ? restaurantNameController.text.trim() : null,
          'address': widget.role == 'restaurant' ? addressController.text.trim() : null,
        },
      );

      if (!mounted) return;

      if (response['success'] != true) {
        throw Exception(response['message'] ?? 'فشل إنشاء الحساب');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إنشاء الحساب بنجاح، يمكنك تسجيل الدخول الآن'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context); // العودة لصفحة تسجيل الدخول

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
    fullNameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    restaurantNameController.dispose();
    addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRestaurant = widget.role == 'restaurant';

    return Scaffold(
      appBar: AppBar(
        title: Text(screenTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 15),

            Icon(
              isRestaurant ? Icons.restaurant : Icons.two_wheeler,
              size: 65,
              color: const Color(0xFFFF6B00),
            ),

            const SizedBox(height: 20),

            Text(
              screenTitle,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

            // الحقول الخاصة بالمطعم تظهر فقط لو كان الدور مطعم
            if (isRestaurant) ...[
              TextField(
                controller: restaurantNameController,
                decoration: const InputDecoration(
                  labelText: 'اسم المطعم',
                  prefixIcon: Icon(Icons.store),
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
            ],

            TextField(
              controller: fullNameController,
              decoration: InputDecoration(
                labelText: isRestaurant ? 'اسم المسؤول' : 'الاسم الكامل',
                prefixIcon: const Icon(Icons.person),
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
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'البريد الإلكتروني (اختياري)',
                prefixIcon: Icon(Icons.email),
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
