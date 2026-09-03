import 'package:flutter/material.dart';

void main() {
  runApp(const DeliveryApp());
}

// ============================================================
// APP
// ============================================================

class DeliveryApp extends StatelessWidget {
  const DeliveryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HADROUG DELIVERY',

      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Arial',

        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF6B00),
        ),

        scaffoldBackgroundColor: const Color(0xFFF7F7F7),

        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFF6B00),
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,

          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFFE0E0E0),
            ),
          ),

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFFE0E0E0),
            ),
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFFFF6B00),
              width: 2,
            ),
          ),

          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Colors.red,
            ),
          ),

          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Colors.red,
              width: 2,
            ),
          ),
        ),
      ),

      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: RoleSelectionScreen(),
      ),
    );
  }
}

// ============================================================
// USER ROLES
// ============================================================

enum UserRole {
  restaurant,
  driver,
  admin,
}

// ============================================================
// ROLE SELECTION SCREEN
// ============================================================

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,

      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 22,
              vertical: 20,
            ),

            child: Column(
              children: [

                const SizedBox(height: 25),

                // ==================================================
                // LOGO
                // ==================================================

                Container(
                  width: 88,
                  height: 88,

                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B00),
                    borderRadius: BorderRadius.circular(25),

                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),

                  child: const Icon(
                    Icons.delivery_dining,
                    color: Colors.white,
                    size: 50,
                  ),
                ),

                const SizedBox(height: 18),

                const Text(
                  'HADROUG',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),

                const Text(
                  'DELIVERY',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF6B00),
                    letterSpacing: 4,
                  ),
                ),

                const SizedBox(height: 28),

                const Text(
                  'اختر صفتك للبدء',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'اختر دورك للوصول إلى واجهتك الخاصة',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade600,
                  ),
                ),

                const SizedBox(height: 30),

                // ==================================================
                // ROLE CARDS
                // ==================================================

                Expanded(
                  child: ListView(
                    children: [

                      _buildRoleCard(
                        context: context,
                        title: 'مطعم',
                        subtitle: 'إدارة الطلبات والتوصيلات',
                        icon: Icons.restaurant,
                        color: const Color(0xFFFF6B00),
                        role: UserRole.restaurant,
                      ),

                      const SizedBox(height: 16),

                      _buildRoleCard(
                        context: context,
                        title: 'سائق',
                        subtitle: 'استقبال الطلبات والتوصيل',
                        icon: Icons.delivery_dining,
                        color: const Color(0xFF1976D2),
                        role: UserRole.driver,
                      ),

                      const SizedBox(height: 16),

                      _buildRoleCard(
                        context: context,
                        title: 'إدارة',
                        subtitle: 'إدارة المنصة والمستخدمين',
                        icon: Icons.admin_panel_settings,
                        color: const Color(0xFF7B1FA2),
                        role: UserRole.admin,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  'HADROUG DELIVERY © 2026',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ROLE CARD
  // ============================================================

  Widget _buildRoleCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required UserRole role,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),

      child: InkWell(
        borderRadius: BorderRadius.circular(20),

        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LoginScreen(role: role),
            ),
          );
        },

        child: Container(
          padding: const EdgeInsets.all(18),

          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),

            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),

          child: Row(
            children: [

              // ICON

              Container(
                width: 65,
                height: 65,

                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),

                child: Icon(
                  icon,
                  color: color,
                  size: 34,
                ),
              ),

              const SizedBox(width: 16),

              // TEXT

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              // ARROW

              Container(
                width: 40,
                height: 40,

                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),

                child: const Icon(
                  Icons.arrow_forward,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// LOGIN SCREEN
// ============================================================

class LoginScreen extends StatefulWidget {
  final UserRole role;

  const LoginScreen({
    super.key,
    required this.role,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  final GlobalKey<FormState> formKey =
      GlobalKey<FormState>();

  final TextEditingController identifierController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  bool obscurePassword = true;
  bool rememberMe = false;
  bool isLoading = false;

  // ============================================================
  // ROLE COLOR
  // ============================================================

  Color get roleColor {
    switch (widget.role) {
      case UserRole.restaurant:
        return const Color(0xFFFF6B00);

      case UserRole.driver:
        return const Color(0xFF1976D2);

      case UserRole.admin:
        return const Color(0xFF7B1FA2);
    }
  }

  // ============================================================
  // ROLE TITLE
  // ============================================================

  String get roleTitle {
    switch (widget.role) {
      case UserRole.restaurant:
        return 'تسجيل دخول المطعم';

      case UserRole.driver:
        return 'تسجيل دخول السائق';

      case UserRole.admin:
        return 'تسجيل دخول الإدارة';
    }
  }

  // ============================================================
  // ROLE ICON
  // ============================================================

  IconData get roleIcon {
    switch (widget.role) {
      case UserRole.restaurant:
        return Icons.restaurant;

      case UserRole.driver:
        return Icons.delivery_dining;

      case UserRole.admin:
        return Icons.admin_panel_settings;
    }
  }

  // ============================================================
  // LOGIN
  // ============================================================

  Future<void> login() async {

    if (!formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    // ========================================================
    // BACKEND WILL BE CONNECTED HERE
    //
    // POST /api/auth/login
    //
    // identifier
    // password
    // role
    //
    // ========================================================

    await Future.delayed(
      const Duration(seconds: 2),
    );

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'سيتم ربط تسجيل الدخول بالخادم لاحقًا',
        ),
        backgroundColor: roleColor,
      ),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    identifierController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {

    return Directionality(
      textDirection: TextDirection.rtl,

      child: Scaffold(

        appBar: AppBar(
          backgroundColor: roleColor,

          title: Text(
            roleTitle,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),

          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
            ),

            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),

        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),

            child: Form(
              key: formKey,

              child: Column(
                children: [

                  const SizedBox(height: 25),

                  // ==================================================
                  // ROLE ICON
                  // ==================================================

                  Container(
                    width: 110,
                    height: 110,

                    decoration: BoxDecoration(
                      color: roleColor.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),

                    child: Icon(
                      roleIcon,
                      size: 55,
                      color: roleColor,
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    roleTitle,
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'أدخل بيانات حسابك للمتابعة',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 35),

                  // ==================================================
                  // EMAIL / PHONE
                  // ==================================================

                  TextFormField(
                    controller: identifierController,

                    keyboardType:
                        TextInputType.emailAddress,

                    decoration: const InputDecoration(
                      labelText:
                          'البريد الإلكتروني أو رقم الهاتف',

                      prefixIcon: Icon(
                        Icons.person_outline,
                      ),
                    ),

                    validator: (value) {

                      if (value == null ||
                          value.trim().isEmpty) {

                        return 'يرجى إدخال البريد الإلكتروني أو رقم الهاتف';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 18),

                  // ==================================================
                  // PASSWORD
                  // ==================================================

                  TextFormField(
                    controller: passwordController,

                    obscureText: obscurePassword,

                    decoration: InputDecoration(
                      labelText: 'كلمة المرور',

                      prefixIcon: const Icon(
                        Icons.lock_outline,
                      ),

                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),

                        onPressed: () {
                          setState(() {
                            obscurePassword =
                                !obscurePassword;
                          });
                        },
                      ),
                    ),

                    validator: (value) {

                      if (value == null ||
                          value.isEmpty) {

                        return 'يرجى إدخال كلمة المرور';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 8),

                  // ==================================================
                  // REMEMBER + FORGOT
                  // ==================================================

                  Row(
                    children: [

                      Checkbox(
                        value: rememberMe,

                        activeColor: roleColor,

                        onChanged: (value) {
                          setState(() {
                            rememberMe =
                                value ?? false;
                          });
                        },
                      ),

                      const Text(
                        'تذكرني',
                      ),

                      const Spacer(),

                      TextButton(
                        onPressed: () {

                          ScaffoldMessenger.of(context)
                              .showSnackBar(
                            const SnackBar(
                              content: Text(
                                'سيتم إضافة استرجاع كلمة المرور لاحقًا',
                              ),
                            ),
                          );
                        },

                        child: Text(
                          'نسيت كلمة المرور؟',
                          style: TextStyle(
                            color: roleColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 15),

                  // ==================================================
                  // LOGIN BUTTON
                  // ==================================================

                  SizedBox(
                    width: double.infinity,
                    height: 55,

                    child: ElevatedButton(

                      style: ElevatedButton.styleFrom(
                        backgroundColor: roleColor,
                        foregroundColor: Colors.white,
                        elevation: 3,

                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(14),
                        ),
                      ),

                      onPressed:
                          isLoading ? null : login,

                      child: isLoading

                          ? const SizedBox(
                              width: 25,
                              height: 25,

                              child:
                                  CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )

                          : const Text(
                              'دخول',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  // ==================================================
                  // REGISTER
                  // ==================================================

                  if (widget.role != UserRole.admin) ...[

                    const SizedBox(height: 12),

                    TextButton(
                      onPressed: () {

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                RegisterScreen(
                              role: widget.role,
                            ),
                          ),
                        );
                      },

                      child: Text(
                        'إنشاء حساب جديد',
                        style: TextStyle(
                          color: roleColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 15),

                  // ==================================================
                  // BACK
                  // ==================================================

                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize:
                          const Size(
                        double.infinity,
                        52,
                      ),

                      side: BorderSide(
                        color:
                            roleColor.withOpacity(0.4),
                      ),

                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(14),
                      ),
                    ),

                    onPressed: () {
                      Navigator.pop(context);
                    },

                    icon: const Icon(
                      Icons.arrow_back,
                    ),

                    label: const Text(
                      'العودة لتغيير الصفة',
                    ),
                  ),

                  const SizedBox(height: 30),

                  Text(
                    'HADROUG DELIVERY',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'توصيل أسرع وأسهل',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// REGISTER SCREEN
// ============================================================

class RegisterScreen extends StatefulWidget {
  final UserRole role;

  const RegisterScreen({
    super.key,
    required this.role,
  });

  @override
  State<RegisterScreen> createState() =>
      _RegisterScreenState();
}

class _RegisterScreenState
    extends State<RegisterScreen> {

  final GlobalKey<FormState> formKey =
      GlobalKey<FormState>();

  final TextEditingController nameController =
      TextEditingController();

  final TextEditingController phoneController =
      TextEditingController();

  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool isLoading = false;

  // ============================================================
  // COLOR
  // ============================================================

  Color get roleColor {

    switch (widget.role) {
      case UserRole.restaurant:
        return const Color(0xFFFF6B00);

      case UserRole.driver:
        return const Color(0xFF1976D2);

      case UserRole.admin:
        return const Color(0xFF7B1FA2);
    }
  }

  // ============================================================
  // TITLE
  // ============================================================

  String get title {

    switch (widget.role) {

      case UserRole.restaurant:
        return 'إنشاء حساب مطعم';

      case UserRole.driver:
        return 'إنشاء حساب سائق';

      case UserRole.admin:
        return 'إنشاء حساب إدارة';
    }
  }

  // ============================================================
  // ICON
  // ============================================================

  IconData get roleIcon {

    switch (widget.role) {

      case UserRole.restaurant:
        return Icons.restaurant;

      case UserRole.driver:
        return Icons.delivery_dining;

      case UserRole.admin:
        return Icons.admin_panel_settings;
    }
  }

  // ============================================================
  // REGISTER
  // ============================================================

  Future<void> register() async {

    if (!formKey.currentState!.validate()) {
      return;
    }

    if (passwordController.text !=
        confirmPasswordController.text) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'كلمتا المرور غير متطابقتين',
          ),
        ),
      );

      return;
    }

    setState(() {
      isLoading = true;
    });

    // ========================================================
    // BACKEND WILL BE CONNECTED HERE
    //
    // POST /api/auth/register
    //
    // name
    // phone
    // email
    // password
    // role
    //
    // ========================================================

    await Future.delayed(
      const Duration(seconds: 2),
    );

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });

    // ========================================================
    // SUCCESS DIALOG
    // ========================================================

    showDialog(
      context: context,

      builder: (context) {

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(20),
          ),

          icon: Icon(
            Icons.check_circle,
            color: roleColor,
            size: 60,
          ),

          title: const Text(
            'تم إرسال الطلب',
            textAlign: TextAlign.center,
          ),

          content: const Text(
            'تم إنشاء طلب التسجيل بنجاح.\n\n'
            'سيتم مراجعة الحساب من طرف الإدارة '
            'قبل تفعيله.',
            textAlign: TextAlign.center,
          ),

          actions: [

            SizedBox(
              width: double.infinity,

              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: roleColor,
                  foregroundColor: Colors.white,
                ),

                onPressed: () {

                  Navigator.pop(context);
                  Navigator.pop(context);
                },

                child: const Text(
                  'حسنًا',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {

    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {

    return Directionality(
      textDirection: TextDirection.rtl,

      child: Scaffold(

        appBar: AppBar(
          backgroundColor: roleColor,

          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),

          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
            ),

            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),

        body: SafeArea(

          child: SingleChildScrollView(

            padding: const EdgeInsets.all(22),

            child: Form(
              key: formKey,

              child: Column(
                children: [

                  const SizedBox(height: 20),

                  // ==================================================
                  // ICON
                  // ==================================================

                  Container(
                    width: 95,
                    height: 95,

                    decoration: BoxDecoration(
                      color:
                          roleColor.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),

                    child: Icon(
                      roleIcon,
                      color: roleColor,
                      size: 48,
                    ),
                  ),

                  const SizedBox(height: 18),

                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 7),

                  Text(
                    'أدخل معلوماتك لإنشاء حساب جديد',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ==================================================
                  // NAME
                  // ==================================================

                  TextFormField(
                    controller: nameController,

                    decoration: const InputDecoration(
                      labelText: 'الاسم الكامل',

                      prefixIcon: Icon(
                        Icons.person_outline,
                      ),
                    ),

                    validator: (value) {

                      if (value == null ||
                          value.trim().isEmpty) {

                        return 'يرجى إدخال الاسم';
                      }

                      if (value.trim().length < 3) {

                        return 'الاسم قصير جدًا';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // ==================================================
                  // PHONE
                  // ==================================================

                  TextFormField(
                    controller: phoneController,

                    keyboardType:
                        TextInputType.phone,

                    decoration: const InputDecoration(
                      labelText: 'رقم الهاتف',

                      prefixIcon: Icon(
                        Icons.phone_outlined,
                      ),
                    ),

                    validator: (value) {

                      if (value == null ||
                          value.trim().isEmpty) {

                        return 'يرجى إدخال رقم الهاتف';
                      }

                      if (value.trim().length < 8) {

                        return 'رقم الهاتف غير صحيح';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // ==================================================
                  // EMAIL
                  // ==================================================

                  TextFormField(
                    controller: emailController,

                    keyboardType:
                        TextInputType.emailAddress,

                    decoration: const InputDecoration(
                      labelText:
                          'البريد الإلكتروني',

                      prefixIcon: Icon(
                        Icons.email_outlined,
                      ),
                    ),

                    validator: (value) {

                      if (value == null ||
                          value.trim().isEmpty) {

                        return 'يرجى إدخال البريد الإلكتروني';
                      }

                      if (!value.contains('@')) {

                        return 'البريد الإلكتروني غير صحيح';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // ==================================================
                  // PASSWORD
                  // ==================================================

                  TextFormField(
                    controller: passwordController,

                    obscureText:
                        obscurePassword,

                    decoration: InputDecoration(
                      labelText: 'كلمة المرور',

                      prefixIcon: const Icon(
                        Icons.lock_outline,
                      ),

                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),

                        onPressed: () {

                          setState(() {
                            obscurePassword =
                                !obscurePassword;
                          });
                        },
                      ),
                    ),

                    validator: (value) {

                      if (value == null ||
                          value.isEmpty) {

                        return 'يرجى إدخال كلمة المرور';
                      }

                      if (value.length < 6) {

                        return 'كلمة المرور يجب أن تحتوي على 6 أحرف على الأقل';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // ==================================================
                  // CONFIRM PASSWORD
                  // ==================================================

                  TextFormField(
                    controller:
                        confirmPasswordController,

                    obscureText:
                        obscureConfirmPassword,

                    decoration: InputDecoration(
                      labelText:
                          'تأكيد كلمة المرور',

                      prefixIcon: const Icon(
                        Icons.lock_reset,
                      ),

                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),

                        onPressed: () {

                          setState(() {

                            obscureConfirmPassword =
                                !obscureConfirmPassword;
                          });
                        },
                      ),
                    ),

                    validator: (value) {

                      if (value == null ||
                          value.isEmpty) {

                        return 'يرجى تأكيد كلمة المرور';
                      }

                      if (value !=
                          passwordController.text) {

                        return 'كلمتا المرور غير متطابقتين';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 28),

                  // ==================================================
                  // REGISTER BUTTON
                  // ==================================================

                  SizedBox(
                    width: double.infinity,
                    height: 55,

                    child: ElevatedButton(

                      style: ElevatedButton.styleFrom(
                        backgroundColor: roleColor,
                        foregroundColor: Colors.white,

                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(14),
                        ),
                      ),

                      onPressed:
                          isLoading
                              ? null
                              : register,

                      child: isLoading

                          ? const SizedBox(
                              width: 25,
                              height: 25,

                              child:
                                  CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )

                          : const Text(
                              'إنشاء الحساب',

                              style: TextStyle(
                                fontSize: 18,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // ==================================================
                  // LOGIN
                  // ==================================================

                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },

                    child: Text(
                      'لدي حساب بالفعل — تسجيل الدخول',

                      style: TextStyle(
                        color: roleColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  // ==================================================
                  // INFO
                  // ==================================================

                  Container(
                    padding: const EdgeInsets.all(15),

                    decoration: BoxDecoration(
                      color:
                          roleColor.withOpacity(0.07),

                      borderRadius:
                          BorderRadius.circular(14),

                      border: Border.all(
                        color:
                            roleColor.withOpacity(0.15),
                      ),
                    ),

                    child: Row(
                      children: [

                        Icon(
                          Icons.info_outline,
                          color: roleColor,
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: Text(
                            'سيتم مراجعة الحساب من طرف الإدارة قبل التفعيل.',
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  Text(
                    'HADROUG DELIVERY',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
