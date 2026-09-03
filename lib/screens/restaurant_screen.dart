import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const HadrougDeliveryApp());
}

// ============================================================
// APP
// ============================================================

class HadrougDeliveryApp extends StatelessWidget {
  const HadrougDeliveryApp({super.key});

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

        scaffoldBackgroundColor: const Color(0xFFF5F6F8),

        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFF6B00),
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFFFF6B00),
              width: 2,
            ),
          ),
        ),
      ),

      home: const RestaurantDashboard(),
    );
  }
}

// ============================================================
// ORDER MODEL
// ============================================================

enum OrderStatus {
  searching,
  driverAccepted,
  waitingVerification,
  pickedUp,
  delivering,
  completed,
  cancelled,
}

class DeliveryOrder {
  String id;
  String customer;
  String customerPhone;
  String location;
  double price;
  String time;
  OrderStatus status;

  String? driverName;
  String? driverPhone;
  String? verificationCode;

  DateTime createdAt;

  DeliveryOrder({
    required this.id,
    required this.customer,
    required this.customerPhone,
    required this.location,
    required this.price,
    required this.time,
    required this.status,
    required this.createdAt,
    this.driverName,
    this.driverPhone,
    this.verificationCode,
  });
}

// ============================================================
// RESTAURANT DASHBOARD
// ============================================================

class RestaurantDashboard extends StatefulWidget {
  const RestaurantDashboard({super.key});

  @override
  State<RestaurantDashboard> createState() =>
      _RestaurantDashboardState();
}

class _RestaurantDashboardState
    extends State<RestaurantDashboard> {

  final Color orange = const Color(0xFFFF6B00);

  int availableDrivers = 5;

  double totalDue = 85.500;

  int orderCounter = 103;

  final List<DeliveryOrder> orders = [];

  Timer? liveTimer;

  @override
  void initState() {
    super.initState();

    _loadDemoOrders();

    // تحديث الواجهة كل ثانية
    // في النسخة الحقيقية سيأتي هذا من Socket.IO.
    liveTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  // ==========================================================
  // DEMO ORDERS
  // ==========================================================

  void _loadDemoOrders() {
    orders.addAll([
      DeliveryOrder(
        id: '#101',
        customer: 'أحمد بن علي',
        customerPhone: '20 111 222',
        location: '35.8256,10.6369',
        price: 25,
        time: '12:30',
        status: OrderStatus.delivering,
        createdAt: DateTime.now(),
        driverName: 'محمد',
        driverPhone: '22 333 444',
      ),

      DeliveryOrder(
        id: '#102',
        customer: 'محمد الطرابلسي',
        customerPhone: '21 444 555',
        location: 'سوسة، حي الرياض',
        price: 18.5,
        time: '13:15',
        status: OrderStatus.searching,
        createdAt: DateTime.now(),
      ),

      DeliveryOrder(
        id: '#103',
        customer: 'سارة التونسي',
        customerPhone: '25 666 777',
        location: '35.8300,10.6400',
        price: 32,
        time: '11:00',
        status: OrderStatus.completed,
        createdAt: DateTime.now(),
        driverName: 'علي',
      ),
    ]);
  }

  // ==========================================================
  // CREATE ORDER
  // ==========================================================

  void _showNewOrderDialog() {

    final customerController =
        TextEditingController();

    final phoneController =
        TextEditingController();

    final locationController =
        TextEditingController();

    final priceController =
        TextEditingController();

    final notesController =
        TextEditingController();

    showDialog(
      context: context,

      builder: (dialogContext) {

        return Directionality(
          textDirection: TextDirection.rtl,

          child: AlertDialog(
            title: const Text(
              'إنشاء طلب توصيل',
              textAlign: TextAlign.center,
            ),

            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),

            content: SizedBox(
              width: 450,

              child: SingleChildScrollView(
                child: Column(
                  children: [

                    _field(
                      controller: customerController,
                      label: 'اسم الزبون',
                      icon: Icons.person_outline,
                    ),

                    const SizedBox(height: 12),

                    _field(
                      controller: phoneController,
                      label: 'رقم هاتف الزبون',
                      icon: Icons.phone_outlined,
                      keyboardType:
                          TextInputType.phone,
                    ),

                    const SizedBox(height: 12),

                    _field(
                      controller: locationController,
                      label:
                          'موقع الزبون أو رابط WhatsApp',
                      icon: Icons.location_on_outlined,
                    ),

                    const SizedBox(height: 12),

                    _field(
                      controller: priceController,
                      label: 'قيمة الطلب بالدينار',
                      icon: Icons.payments_outlined,
                      keyboardType:
                          const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),

                    const SizedBox(height: 12),

                    _field(
                      controller: notesController,
                      label: 'ملاحظات اختيارية',
                      icon: Icons.notes_outlined,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),

            actions: [

              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                child: const Text('إلغاء'),
              ),

              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 13,
                  ),
                ),

                icon: const Icon(
                  Icons.delivery_dining,
                ),

                label: const Text(
                  'إرسال للسائق',
                ),

                onPressed: () {

                  if (customerController.text
                          .trim()
                          .isEmpty ||
                      locationController.text
                          .trim()
                          .isEmpty ||
                      priceController.text
                          .trim()
                          .isEmpty) {

                    ScaffoldMessenger.of(context)
                        .showSnackBar(
                      const SnackBar(
                        content: Text(
                          'يرجى إدخال اسم الزبون والموقع وقيمة الطلب',
                        ),
                      ),
                    );

                    return;
                  }

                  final price =
                      double.tryParse(
                            priceController.text
                                .replaceAll(',', '.'),
                          ) ??
                          0;

                  Navigator.pop(dialogContext);

                  _createOrder(
                    customer:
                        customerController.text.trim(),

                    phone:
                        phoneController.text.trim(),

                    location:
                        locationController.text.trim(),

                    price: price,

                    notes:
                        notesController.text.trim(),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,

      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
    );
  }

  // ==========================================================
  // CREATE ORDER LOGIC
  // ==========================================================

  void _createOrder({
    required String customer,
    required String phone,
    required String location,
    required double price,
    required String notes,
  }) {

    orderCounter++;

    final order = DeliveryOrder(
      id: '#$orderCounter',
      customer: customer,
      customerPhone: phone,
      location: location,
      price: price,
      time: _currentTime(),
      status: OrderStatus.searching,
      createdAt: DateTime.now(),
    );

    setState(() {
      orders.insert(0, order);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: orange,
        content: Text(
          'تم إرسال الطلب ${order.id} لأقرب سائق',
        ),
      ),
    );

    // محاكاة نظام البحث عن السائق.
    _simulateDriverDispatch(order);
  }

  // ==========================================================
  // SIMULATE DISPATCH
  // ==========================================================

  Future<void> _simulateDriverDispatch(
    DeliveryOrder order,
  ) async {

    await Future.delayed(
      const Duration(seconds: 2),
    );

    if (!mounted) return;

    if (order.status != OrderStatus.searching) {
      return;
    }

    // محاكاة العثور على أقرب سائق
    setState(() {
      order.driverName = 'سائق ${Random().nextInt(8) + 1}';
      order.driverPhone = '2X XXX XXX';
      order.status = OrderStatus.driverAccepted;

      availableDrivers =
          max(0, availableDrivers - 1);
    });

    _showDriverAccepted(order);

    // بعد مدة تظهر مرحلة انتظار التحقق
    await Future.delayed(
      const Duration(seconds: 8),
    );

    if (!mounted) return;

    if (order.status ==
        OrderStatus.driverAccepted) {

      setState(() {
        order.status =
            OrderStatus.waitingVerification;
      });
    }
  }

  // ==========================================================
  // DRIVER ACCEPTED
  // ==========================================================

  void _showDriverAccepted(
    DeliveryOrder order,
  ) {

    showDialog(
      context: context,

      builder: (context) {

        return Directionality(
          textDirection: TextDirection.rtl,

          child: AlertDialog(

            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(22),
            ),

            icon: Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 65,
            ),

            title: const Text(
              'تم قبول الطلب',
              textAlign: TextAlign.center,
            ),

            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                Text(
                  'السائق ${order.driverName}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'في طريقه إلى المطعم',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                  ),
                ),

                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(18),

                  decoration: BoxDecoration(
                    color:
                        orange.withOpacity(0.08),
                    borderRadius:
                        BorderRadius.circular(16),
                  ),

                  child: Column(
                    children: [

                      const Text(
                        'كود التحقق',
                      ),

                      const SizedBox(height: 8),

                      Text(
                        _generateCode(order),
                        style: TextStyle(
                          color: orange,
                          fontSize: 32,
                          fontWeight:
                              FontWeight.w900,
                          letterSpacing: 8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            actions: [

              SizedBox(
                width: double.infinity,

                child: ElevatedButton(
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor: orange,
                    foregroundColor:
                        Colors.white,
                  ),

                  onPressed: () {
                    Navigator.pop(context);
                  },

                  child: const Text(
                    'حسنًا',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================================
  // GENERATE 4 DIGIT CODE
  // ==========================================================

  String _generateCode(
    DeliveryOrder order,
  ) {

    if (order.verificationCode != null) {
      return order.verificationCode!;
    }

    final code =
        (1000 +
                Random().nextInt(9000))
            .toString();

    order.verificationCode = code;

    return code;
  }

  // ==========================================================
  // VERIFY DRIVER
  // ==========================================================

  void _verifyDriver(
    DeliveryOrder order,
  ) {

    final controller =
        TextEditingController();

    final correctCode =
        _generateCode(order);

    showDialog(
      context: context,

      builder: (context) {

        return Directionality(
          textDirection: TextDirection.rtl,

          child: AlertDialog(

            title: const Text(
              'تأكيد استلام الطلب',
              textAlign: TextAlign.center,
            ),

            content: Column(
              mainAxisSize: MainAxisSize.min,

              children: [

                Text(
                  'السائق: ${order.driverName}',
                ),

                const SizedBox(height: 18),

                TextField(
                  controller: controller,

                  keyboardType:
                      TextInputType.number,

                  maxLength: 4,

                  textAlign: TextAlign.center,

                  decoration:
                      const InputDecoration(
                    labelText:
                        'أدخل كود السائق',
                    prefixIcon:
                        Icon(Icons.lock_outline),
                  ),
                ),
              ],
            ),

            actions: [

              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },

                child: const Text(
                  'إلغاء',
                ),
              ),

              ElevatedButton(
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor: orange,
                  foregroundColor:
                      Colors.white,
                ),

                onPressed: () {

                  if (controller.text ==
                      correctCode) {

                    Navigator.pop(context);

                    setState(() {
                      order.status =
                          OrderStatus.pickedUp;

                      availableDrivers++;
                    });

                    _showSuccess(
                      'تم التحقق من السائق وتسليم الطلب',
                    );

                    _simulateDelivery(order);

                  } else {

                    ScaffoldMessenger.of(context)
                        .showSnackBar(
                      const SnackBar(
                        content: Text(
                          'الكود غير صحيح',
                        ),
                        backgroundColor:
                            Colors.red,
                      ),
                    );
                  }
                },

                child: const Text(
                  'تأكيد',
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================================
  // SIMULATE DELIVERY
  // ==========================================================

  Future<void> _simulateDelivery(
    DeliveryOrder order,
  ) async {

    await Future.delayed(
      const Duration(seconds: 4),
    );

    if (!mounted) return;

    setState(() {
      order.status =
          OrderStatus.delivering;
    });

    await Future.delayed(
      const Duration(seconds: 8),
    );

    if (!mounted) return;

    setState(() {
      order.status =
          OrderStatus.completed;

      totalDue += 1;
    });

    _showSuccess(
      'تم إكمال الطلب ${order.id}',
    );
  }

  // ==========================================================
  // SUCCESS
  // ==========================================================

  void _showSuccess(String message) {

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        backgroundColor: Colors.green,
        content: Text(message),
      ),
    );
  }

  // ==========================================================
  // OPEN GOOGLE MAPS
  // ==========================================================

  Future<void> _openMaps(
    String location,
  ) async {

    Uri uri;

    if (location.startsWith('http')) {

      uri = Uri.parse(location);

    } else {

      uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(location)}',
      );
    }

    if (await canLaunchUrl(uri)) {

      await launchUrl(
        uri,
        mode:
            LaunchMode.externalApplication,
      );

    } else {

      if (!mounted) return;

      _showSuccess(
        'تعذر فتح Google Maps',
      );
    }
  }

  // ==========================================================
  // ORDER DETAILS
  // ==========================================================

  void _openOrder(
    DeliveryOrder order,
  ) {

    Navigator.push(
      context,

      MaterialPageRoute(
        builder: (_) =>
            OrderDetailsScreen(
          order: order,
          onVerify: () =>
              _verifyDriver(order),
          onOpenMaps: () =>
              _openMaps(order.location),
        ),
      ),
    );
  }

  // ==========================================================
  // CURRENT TIME
  // ==========================================================

  String _currentTime() {

    final now = DateTime.now();

    final hour =
        now.hour.toString().padLeft(2, '0');

    final minute =
        now.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    liveTimer?.cancel();
    super.dispose();
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {

    final activeOrders =
        orders.where(
          (order) =>
              order.status !=
                  OrderStatus.completed &&
              order.status !=
                  OrderStatus.cancelled,
        ).length;

    final completedOrders =
        orders.where(
          (order) =>
              order.status ==
              OrderStatus.completed,
        ).length;

    return Directionality(
      textDirection: TextDirection.rtl,

      child: Scaffold(

        appBar: AppBar(

          title: const Text(
            'لوحة تحكم المطعم',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),

          actions: [

            IconButton(
              tooltip: 'الإشعارات',

              icon: Stack(
                children: [

                  const Icon(
                    Icons.notifications_outlined,
                  ),

                  if (activeOrders > 0)
                    Positioned(
                      right: 0,
                      top: 0,

                      child: Container(
                        width: 9,
                        height: 9,

                        decoration:
                            const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),

              onPressed: () {
                _showNotifications();
              },
            ),

            IconButton(
              tooltip: 'تسجيل الخروج',

              icon: const Icon(
                Icons.logout,
              ),

              onPressed: () {
                _showLogout();
              },
            ),
          ],
        ),

        body: RefreshIndicator(

          onRefresh: () async {

            await Future.delayed(
              const Duration(
                milliseconds: 600,
              ),
            );

            setState(() {});
          },

          child: ListView(

            padding:
                const EdgeInsets.all(16),

            children: [

              // ==================================================
              // RESTAURANT HEADER
              // ==================================================

              _buildRestaurantHeader(),

              const SizedBox(height: 18),

              // ==================================================
              // LIVE STATUS
              // ==================================================

              _buildLiveStatus(),

              const SizedBox(height: 20),

              // ==================================================
              // DAILY REPORT
              // ==================================================

              const Text(
                'التقرير اليومي',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              Row(
                children: [

                  Expanded(
                    child: _statCard(
                      title:
                          'السائقون المتاحون',
                      value:
                          '$availableDrivers',
                      icon:
                          Icons.delivery_dining,
                      color:
                          Colors.blue,
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: _statCard(
                      title:
                          'الطلبات اليوم',
                      value:
                          '${orders.length}',
                      icon:
                          Icons.receipt_long,
                      color:
                          orange,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Row(
                children: [

                  Expanded(
                    child: _statCard(
                      title:
                          'الطلبات النشطة',
                      value:
                          '$activeOrders',
                      icon:
                          Icons.local_shipping,
                      color:
                          Colors.purple,
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: _statCard(
                      title:
                          'المكتملة',
                      value:
                          '$completedOrders',
                      icon:
                          Icons.check_circle,
                      color:
                          Colors.green,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              _buildMoneyCard(),

              const SizedBox(height: 22),

              // ==================================================
              // NEW ORDER
              // ==================================================

              SizedBox(
                height: 58,

                child: ElevatedButton.icon(

                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        orange,
                    foregroundColor:
                        Colors.white,

                    elevation: 3,

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        16,
                      ),
                    ),
                  ),

                  onPressed:
                      _showNewOrderDialog,

                  icon: const Icon(
                    Icons.add_circle_outline,
                    size: 27,
                  ),

                  label: const Text(
                    'إنشاء طلب توصيل جديد',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // ==================================================
              // ORDERS
              // ==================================================

              Row(
                mainAxisAlignment:
                    MainAxisAlignment
                        .spaceBetween,

                children: [

                  const Text(
                    'الطلبات والنشاط',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  TextButton(
                    onPressed: () {
                      _showAllOrders();
                    },

                    child: const Text(
                      'عرض الكل',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              if (orders.isEmpty)
                _emptyOrders()
              else

                ...orders
                    .map(
                      (order) =>
                          _orderCard(order),
                    )
                    .toList(),

              const SizedBox(height: 30),

              // ==================================================
              // FOOTER
              // ==================================================

              Center(
                child: Text(
                  'HADROUG DELIVERY • Restaurant',
                  style: TextStyle(
                    color:
                        Colors.grey.shade500,
                    fontSize: 12,
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // RESTAURANT HEADER
  // ==========================================================

  Widget _buildRestaurantHeader() {

    return Container(
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            orange,
            orange.withOpacity(0.78),
          ],
        ),

        borderRadius:
            BorderRadius.circular(22),

        boxShadow: [
          BoxShadow(
            color:
                orange.withOpacity(0.20),
            blurRadius: 18,
            offset:
                const Offset(0, 7),
          ),
        ],
      ),

      child: Row(
        children: [

          Container(
            width: 62,
            height: 62,

            decoration:
                const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),

            child: Icon(
              Icons.restaurant,
              color: orange,
              size: 32,
            ),
          ),

          const SizedBox(width: 14),

          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                Text(
                  'مطعمك',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                SizedBox(height: 4),

                Text(
                  'مرحبًا بك في HADROUG DELIVERY',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          const Icon(
            Icons.verified,
            color: Colors.white,
            size: 27,
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // LIVE STATUS
  // ==========================================================

  Widget _buildLiveStatus() {

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 12,
      ),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(15),
      ),

      child: Row(
        children: [

          Container(
            width: 11,
            height: 11,

            decoration:
                const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),

          const SizedBox(width: 10),

          const Text(
            'النظام يعمل بشكل طبيعي',
            style: TextStyle(
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const Spacer(),

          Text(
            'متصل',
            style: TextStyle(
              color: Colors.green.shade700,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // STAT CARD
  // ==========================================================

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {

    return Container(
      padding: const EdgeInsets.all(15),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(17),

        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(0.035),
            blurRadius: 12,
            offset:
                const Offset(0, 5),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          Container(
            width: 42,
            height: 42,

            decoration: BoxDecoration(
              color:
                  color.withOpacity(0.11),
              shape: BoxShape.circle,
            ),

            child: Icon(
              icon,
              color: color,
              size: 23,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            value,
            style: const TextStyle(
              fontSize: 25,
              fontWeight:
                  FontWeight.w900,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            title,
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,

            style: TextStyle(
              color:
                  Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // MONEY CARD
  // ==========================================================

  Widget _buildMoneyCard() {

    return Container(
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(17),

        border: Border.all(
          color:
              Colors.green.withOpacity(0.13),
        ),
      ),

      child: Row(
        children: [

          Container(
            width: 54,
            height: 54,

            decoration: BoxDecoration(
              color:
                  Colors.green.withOpacity(
                0.11,
              ),

              shape: BoxShape.circle,
            ),

            child: const Icon(
              Icons.payments_outlined,
              color: Colors.green,
              size: 28,
            ),
          ),

          const SizedBox(width: 14),

          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                Text(
                  'المبلغ المستحق',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),

                SizedBox(height: 4),
              ],
            ),
          ),

          Text(
            '${totalDue.toStringAsFixed(3)} د.ت',
            style: const TextStyle(
              fontSize: 20,
              fontWeight:
                  FontWeight.w900,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // ORDER CARD
  // ==========================================================

  Widget _orderCard(
    DeliveryOrder order,
  ) {

    final color =
        _statusColor(order.status);

    return Container(
      margin:
          const EdgeInsets.only(bottom: 12),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(18),

        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(0.035),
            blurRadius: 10,
            offset:
                const Offset(0, 4),
          ),
        ],
      ),

      child: InkWell(

        borderRadius:
            BorderRadius.circular(18),

        onTap: () {
          _openOrder(order);
        },

        child: Padding(
          padding:
              const EdgeInsets.all(16),

          child: Column(
            children: [

              Row(
                children: [

                  Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 7,
                    ),

                    decoration:
                        BoxDecoration(
                      color:
                          color.withOpacity(
                        0.10,
                      ),

                      borderRadius:
                          BorderRadius.circular(
                        10,
                      ),
                    ),

                    child: Text(
                      order.id,
                      style: TextStyle(
                        color: color,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: Text(
                      order.customer,
                      style:
                          const TextStyle(
                        fontSize: 17,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),

                  _statusChip(
                    order.status,
                  ),
                ],
              ),

              const SizedBox(height: 13),

              const Divider(
                height: 1,
              ),

              const SizedBox(height: 13),

              Row(
                children: [

                  Icon(
                    Icons.payments_outlined,
                    size: 18,
                    color:
                        Colors.grey.shade600,
                  ),

                  const SizedBox(width: 6),

                  Text(
                    '${order.price.toStringAsFixed(3)} د.ت',
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(width: 18),

                  Icon(
                    Icons.access_time,
                    size: 17,
                    color:
                        Colors.grey.shade600,
                  ),

                  const SizedBox(width: 5),

                  Text(order.time),

                  const Spacer(),

                  if (order.driverName != null)
                    Text(
                      order.driverName!,
                      style: TextStyle(
                        color:
                            Colors.grey.shade700,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [

                  Expanded(
                    child: OutlinedButton.icon(
                      style:
                          OutlinedButton.styleFrom(
                        foregroundColor:
                            orange,

                        side:
                            BorderSide(
                          color: orange
                              .withOpacity(
                            0.45,
                          ),
                        ),
                      ),

                      onPressed: () {
                        _openMaps(
                          order.location,
                        );
                      },

                      icon: const Icon(
                        Icons.map_outlined,
                        size: 19,
                      ),

                      label: const Text(
                        'الخريطة',
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: ElevatedButton.icon(
                      style:
                          ElevatedButton.styleFrom(
                        backgroundColor:
                            color,
                        foregroundColor:
                            Colors.white,
                      ),

                      onPressed: () {
                        _openOrder(order);
                      },

                      icon: Icon(
                        order.status ==
                                OrderStatus.completed
                            ? Icons.visibility
                            : Icons.navigation,
                        size: 19,
                      ),

                      label: Text(
                        order.status ==
                                OrderStatus.completed
                            ? 'التفاصيل'
                            : 'متابعة الطلب',
                      ),
                    ),
                  ),
                ],
              ),

              // ==================================================
              // VERIFY BUTTON
              // ==================================================

              if (order.status ==
                      OrderStatus.driverAccepted ||
                  order.status ==
                      OrderStatus.waitingVerification)
                Padding(
                  padding:
                      const EdgeInsets.only(
                    top: 10,
                  ),

                  child: SizedBox(
                    width:
                        double.infinity,

                    child: ElevatedButton.icon(
                      style:
                          ElevatedButton.styleFrom(
                        backgroundColor:
                            Colors.green,
                        foregroundColor:
                            Colors.white,
                      ),

                      onPressed: () {
                        _verifyDriver(
                          order,
                        );
                      },

                      icon: const Icon(
                        Icons.verified_user,
                      ),

                      label: const Text(
                        'تأكيد وصول السائق وإدخال الكود',
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // STATUS CHIP
  // ==========================================================

  Widget _statusChip(
    OrderStatus status,
  ) {

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),

      decoration: BoxDecoration(
        color:
            _statusColor(status)
                .withOpacity(0.11),

        borderRadius:
            BorderRadius.circular(20),
      ),

      child: Text(
        _statusText(status),

        style: TextStyle(
          color:
              _statusColor(status),
          fontSize: 11,
          fontWeight:
              FontWeight.bold,
        ),
      ),
    );
  }

  // ==========================================================
  // STATUS TEXT
  // ==========================================================

  String _statusText(
    OrderStatus status,
  ) {

    switch (status) {

      case OrderStatus.searching:
        return 'البحث عن سائق';

      case OrderStatus.driverAccepted:
        return 'السائق قبل';

      case OrderStatus.waitingVerification:
        return 'بانتظار التحقق';

      case OrderStatus.pickedUp:
        return 'تم الاستلام';

      case OrderStatus.delivering:
        return 'جاري التوصيل';

      case OrderStatus.completed:
        return 'مكتمل';

      case OrderStatus.cancelled:
        return 'ملغى';
    }
  }

  // ==========================================================
  // STATUS COLOR
  // ==========================================================

  Color _statusColor(
    OrderStatus status,
  ) {

    switch (status) {

      case OrderStatus.searching:
        return Colors.orange;

      case OrderStatus.driverAccepted:
        return Colors.blue;

      case OrderStatus.waitingVerification:
        return Colors.deepOrange;

      case OrderStatus.pickedUp:
        return Colors.indigo;

      case OrderStatus.delivering:
        return Colors.blue;

      case OrderStatus.completed:
        return Colors.green;

      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  // ==========================================================
  // EMPTY
  // ==========================================================

  Widget _emptyOrders() {

    return Container(
      padding:
          const EdgeInsets.all(35),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
      ),

      child: Column(
        children: [

          Icon(
            Icons.receipt_long_outlined,
            size: 55,
            color:
                Colors.grey.shade400,
          ),

          const SizedBox(height: 12),

          const Text(
            'لا توجد طلبات',
            style: TextStyle(
              fontSize: 18,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // ALL ORDERS
  // ==========================================================

  void _showAllOrders() {

    Navigator.push(
      context,

      MaterialPageRoute(
        builder: (_) =>
            AllOrdersScreen(
          orders: orders,
          onOpen: (order) {
            _openOrder(order);
          },
        ),
      ),
    );
  }

  // ==========================================================
  // NOTIFICATIONS
  // ==========================================================

  void _showNotifications() {

    showModalBottomSheet(
      context: context,

      showDragHandle: true,

      builder: (context) {

        return Directionality(
          textDirection:
              TextDirection.rtl,

          child: SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.all(18),

              child: Column(
                mainAxisSize:
                    MainAxisSize.min,

                children: [

                  const Text(
                    'الإشعارات',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 15),

                  ...orders
                      .where(
                        (o) =>
                            o.status !=
                            OrderStatus.completed,
                      )
                      .take(4)
                      .map(
                        (o) => ListTile(
                          leading: Icon(
                            Icons.notifications,
                            color:
                                _statusColor(
                              o.status,
                            ),
                          ),

                          title: Text(
                            '${o.id} • ${_statusText(o.status)}',
                          ),

                          subtitle: Text(
                            o.customer,
                          ),

                          onTap: () {
                            Navigator.pop(
                              context,
                            );

                            _openOrder(o);
                          },
                        ),
                      ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ==========================================================
  // LOGOUT
  // ==========================================================

  void _showLogout() {

    showDialog(
      context: context,

      builder: (context) {

        return AlertDialog(
          title: const Text(
            'تسجيل الخروج',
          ),

          content: const Text(
            'هل تريد تسجيل الخروج؟',
          ),

          actions: [

            TextButton(
              onPressed: () =>
                  Navigator.pop(context),

              child: const Text(
                'إلغاء',
              ),
            ),

            ElevatedButton(
              onPressed: () {

                Navigator.pop(context);

                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  const SnackBar(
                    content: Text(
                      'تم تسجيل الخروج',
                    ),
                  ),
                );
              },

              child: const Text(
                'خروج',
              ),
            ),
          ],
        );
      },
    );
  }
}

// ============================================================
// ORDER DETAILS / TRACKING
// ============================================================

class OrderDetailsScreen extends StatefulWidget {

  final DeliveryOrder order;

  final VoidCallback onVerify;

  final VoidCallback onOpenMaps;

  const OrderDetailsScreen({
    super.key,
    required this.order,
    required this.onVerify,
    required this.onOpenMaps,
  });

  @override
  State<OrderDetailsScreen> createState() =>
      _OrderDetailsScreenState();
}

class _OrderDetailsScreenState
    extends State<OrderDetailsScreen> {

  Timer? timer;

  double driverProgress = 0.35;

  @override
  void initState() {
    super.initState();

    timer = Timer.periodic(
      const Duration(seconds: 2),
      (_) {

        if (!mounted) return;

        if (widget.order.status ==
            OrderStatus.delivering) {

          setState(() {

            driverProgress += 0.04;

            if (driverProgress > 0.95) {
              driverProgress = 0.35;
            }
          });
        }
      },
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final order = widget.order;

    return Directionality(
      textDirection: TextDirection.rtl,

      child: Scaffold(

        appBar: AppBar(
          title: Text(
            'متابعة ${order.id}',
          ),
        ),

        body: ListView(

          padding:
              const EdgeInsets.all(16),

          children: [

            // ==================================================
            // ORDER HEADER
            // ==================================================

            Container(
              padding:
                  const EdgeInsets.all(18),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(20),
              ),

              child: Row(
                children: [

                  Container(
                    width: 58,
                    height: 58,

                    decoration:
                        BoxDecoration(
                      color: Colors.orange
                          .withOpacity(
                        0.12,
                      ),
                      shape:
                          BoxShape.circle,
                    ),

                    child: const Icon(
                      Icons.receipt_long,
                      color:
                          Color(0xFFFF6B00),
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [

                        Text(
                          order.id,
                          style:
                              const TextStyle(
                            fontSize: 20,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          order.customer,
                          style: TextStyle(
                            color:
                                Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  _statusChip(
                    order.status,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ==================================================
            // TRACKING CARD
            // ==================================================

            _buildTrackingCard(order),

            const SizedBox(height: 16),

            // ==================================================
            // DRIVER
            // ==================================================

            if (order.driverName != null)
              _buildDriverCard(order),

            const SizedBox(height: 16),

            // ==================================================
            // ORDER INFO
            // ==================================================

            _buildInfoCard(order),

            const SizedBox(height: 16),

            // ==================================================
            // MAP
            // ==================================================

            SizedBox(
              height: 55,

              child: ElevatedButton.icon(
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(
                    0xFFFF6B00,
                  ),

                  foregroundColor:
                      Colors.white,
                ),

                onPressed:
                    widget.onOpenMaps,

                icon: const Icon(
                  Icons.map,
                ),

                label: const Text(
                  'فتح موقع الزبون في Google Maps',
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            if (order.status ==
                    OrderStatus.driverAccepted ||
                order.status ==
                    OrderStatus.waitingVerification)

              SizedBox(
                height: 55,

                child: ElevatedButton.icon(
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.green,
                    foregroundColor:
                        Colors.white,
                  ),

                  onPressed:
                      widget.onVerify,

                  icon: const Icon(
                    Icons.verified_user,
                  ),

                  label: const Text(
                    'تأكيد السائق بالكود',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // TRACKING CARD
  // ==========================================================

  Widget _buildTrackingCard(
    DeliveryOrder order,
  ) {

    return Container(
      padding:
          const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          const Text(
            'حالة الطلب',
            style: TextStyle(
              fontSize: 18,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          _step(
            title:
                'تم إنشاء الطلب',
            done: true,
            icon:
                Icons.add_task,
          ),

          _line(),

          _step(
            title:
                'السائق قبل الطلب',
            done:
                order.status.index >=
                    OrderStatus.driverAccepted.index,
            icon:
                Icons.delivery_dining,
          ),

          _line(),

          _step(
            title:
                'تم التحقق واستلام الطلب',
            done:
                order.status.index >=
                    OrderStatus.pickedUp.index,
            icon:
                Icons.verified,
          ),

          _line(),

          _step(
            title:
                'السائق في الطريق',
            done:
                order.status ==
                        OrderStatus.delivering ||
                    order.status ==
                        OrderStatus.completed,
            icon:
                Icons.navigation,
          ),

          _line(),

          _step(
            title:
                'تم التسليم',
            done:
                order.status ==
                    OrderStatus.completed,
            icon:
                Icons.check_circle,
          ),

          if (order.status ==
              OrderStatus.delivering) ...[

            const SizedBox(height: 20),

            const Text(
              'السائق يتحرك نحو الزبون...',
              style: TextStyle(
                color: Colors.blue,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            LinearProgressIndicator(
              value: driverProgress,
              minHeight: 7,
              borderRadius:
                  BorderRadius.circular(10),
            ),
          ],
        ],
      ),
    );
  }

  Widget _step({
    required String title,
    required bool done,
    required IconData icon,
  }) {

    return Row(
      children: [

        Container(
          width: 42,
          height: 42,

          decoration: BoxDecoration(
            color: done
                ? Colors.green
                    .withOpacity(0.12)
                : Colors.grey
                    .withOpacity(0.10),

            shape: BoxShape.circle,
          ),

          child: Icon(
            icon,
            color:
                done ? Colors.green : Colors.grey,
            size: 21,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontWeight:
                  done
                      ? FontWeight.bold
                      : FontWeight.normal,

              color:
                  done
                      ? Colors.black
                      : Colors.grey,
            ),
          ),
        ),

        if (done)
          const Icon(
            Icons.check,
            color: Colors.green,
          ),
      ],
    );
  }

  Widget _line() {

    return Container(
      margin:
          const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 3,
      ),

      height: 20,

      width: 2,

      color:
          Colors.grey.withOpacity(0.25),
    );
  }

  // ==========================================================
  // DRIVER CARD
  // ==========================================================

  Widget _buildDriverCard(
    DeliveryOrder order,
  ) {

    return Container(
      padding:
          const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
      ),

      child: Row(
        children: [

          Container(
            width: 55,
            height: 55,

            decoration:
                const BoxDecoration(
              color: Color(0xFFE3F2FD),
              shape: BoxShape.circle,
            ),

            child: const Icon(
              Icons.person,
              color: Colors.blue,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                const Text(
                  'السائق',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),

                Text(
                  order.driverName!,
                  style:
                      const TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                if (order.driverPhone != null)
                  Text(
                    order.driverPhone!,
                    style: TextStyle(
                      color:
                          Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ),

          IconButton(
            onPressed: () {},

            icon: const Icon(
              Icons.phone,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // INFO CARD
  // ==========================================================

  Widget _buildInfoCard(
    DeliveryOrder order,
  ) {

    return Container(
      padding:
          const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
      ),

      child: Column(
        children: [

          _infoRow(
            'الزبون',
            order.customer,
            Icons.person_outline,
          ),

          _infoRow(
            'الهاتف',
            order.customerPhone,
            Icons.phone_outlined,
          ),

          _infoRow(
            'الموقع',
            order.location,
            Icons.location_on_outlined,
          ),

          _infoRow(
            'قيمة الطلب',
            '${order.price.toStringAsFixed(3)} د.ت',
            Icons.payments_outlined,
          ),

          _infoRow(
            'وقت الإنشاء',
            order.time,
            Icons.access_time,
          ),
        ],
      ),
    );
  }

  Widget _infoRow(
    String title,
    String value,
    IconData icon,
  ) {

    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 14,
      ),

      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          Icon(
            icon,
            size: 20,
            color:
                const Color(
              0xFFFF6B00,
            ),
          ),

          const SizedBox(width: 10),

          Text(
            '$title: ',
            style:
                const TextStyle(
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color:
                    Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(
    OrderStatus status,
  ) {

    Color color;

    switch (status) {

      case OrderStatus.searching:
        color = Colors.orange;
        break;

      case OrderStatus.driverAccepted:
        color = Colors.blue;
        break;

      case OrderStatus.waitingVerification:
        color = Colors.deepOrange;
        break;

      case OrderStatus.pickedUp:
        color = Colors.indigo;
        break;

      case OrderStatus.delivering:
        color = Colors.blue;
        break;

      case OrderStatus.completed:
        color = Colors.green;
        break;

      case OrderStatus.cancelled:
        color = Colors.red;
        break;
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),

      decoration: BoxDecoration(
        color:
            color.withOpacity(0.11),

        borderRadius:
            BorderRadius.circular(20),
      ),

      child: Text(
        _statusText(status),

        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight:
              FontWeight.bold,
        ),
      ),
    );
  }

  String _statusText(
    OrderStatus status,
  ) {

    switch (status) {

      case OrderStatus.searching:
        return 'البحث عن سائق';

      case OrderStatus.driverAccepted:
        return 'السائق قبل';

      case OrderStatus.waitingVerification:
        return 'بانتظار التحقق';

      case OrderStatus.pickedUp:
        return 'تم الاستلام';

      case OrderStatus.delivering:
        return 'جاري التوصيل';

      case OrderStatus.completed:
        return 'مكتمل';

      case OrderStatus.cancelled:
        return 'ملغى';
    }
  }
}

// ============================================================
// ALL ORDERS SCREEN
// ============================================================

class AllOrdersScreen extends StatelessWidget {

  final List<DeliveryOrder> orders;

  final Function(DeliveryOrder) onOpen;

  const AllOrdersScreen({
    super.key,
    required this.orders,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {

    return Directionality(
      textDirection: TextDirection.rtl,

      child: Scaffold(

        appBar: AppBar(
          title:
              const Text('جميع الطلبات'),
        ),

        body: orders.isEmpty

            ? const Center(
                child: Text(
                  'لا توجد طلبات',
                ),
              )

            : ListView.builder(
                padding:
                    const EdgeInsets.all(16),

                itemCount:
                    orders.length,

                itemBuilder:
                    (context, index) {

                  final order =
                      orders[index];

                  return Card(
                    margin:
                        const EdgeInsets.only(
                      bottom: 10,
                    ),

                    child: ListTile(

                      leading:
                          CircleAvatar(
                        backgroundColor:
                            Colors.orange
                                .withOpacity(
                          0.12,
                        ),

                        child: const Icon(
                          Icons.receipt,
                          color:
                              Color(
                            0xFFFF6B00,
                          ),
                        ),
                      ),

                      title: Text(
                        '${order.id} • ${order.customer}',
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      subtitle: Text(
                        '${order.price.toStringAsFixed(3)} د.ت • ${order.time}',
                      ),

                      trailing:
                          const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                      ),

                      onTap: () {
                        onOpen(order);
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }
}
