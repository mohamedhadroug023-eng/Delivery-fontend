import 'dart:async';

import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/socket_service.dart';
import '../widgets/map_button.dart';
import 'role_selection_screen.dart';

class RestaurantScreen extends StatefulWidget {
  const RestaurantScreen({super.key});

  @override
  State<RestaurantScreen> createState() =>
      _RestaurantScreenState();
}

class _RestaurantScreenState
    extends State<RestaurantScreen> {
  final SocketService _socketService =
      SocketService();

  Timer? _refreshTimer;

  bool loading = true;
  bool refreshing = false;
  bool socketConnected = false;

  Map<String, dynamic> profile = {};
  List<dynamic> orders = [];

  @override
  void initState() {
    super.initState();

    loadData();
    _connectSocket();

    _refreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => loadData(silent: true),
    );
  }

  // =========================================================
  // DATA
  // =========================================================

  Future<void> loadData({
    bool silent = false,
  }) async {
    if (!silent && mounted) {
      setState(() {
        loading = true;
      });
    }

    try {
      final results = await Future.wait([
        ApiService.get('/restaurant/profile'),
        ApiService.get('/restaurant/orders'),
      ]);

      if (!mounted) return;

      setState(() {
        profile =
            Map<String, dynamic>.from(
          results[0],
        );

        orders =
            List<dynamic>.from(
          results[1]['orders'] ?? [],
        );

        loading = false;
        refreshing = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        loading = false;
        refreshing = false;
      });

      if (!silent) {
        showMessage(
          _cleanError(error),
          isError: true,
        );
      }
    }
  }

  Future<void> refreshData() async {
    if (refreshing) return;

    setState(() {
      refreshing = true;
    });

    await loadData();
  }

  // =========================================================
  // CREATE ORDER DIALOG (B2B)
  // =========================================================

  void _showCreateOrderDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();
    final foodAmountController = TextEditingController();
    final driverFeeController = TextEditingController(text: '3.000');
    
    // إحداثيات افتراضية (مثلاً مركز سوسة أو إحداثيات مؤقتة إذا لم يتم تحديدها بدقة)
    final latController = TextEditingController(text: '35.8256');
    final lngController = TextEditingController(text: '10.6369');

    bool creating = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.add_shopping_cart, color: Colors.blue),
                  SizedBox(width: 10),
                  Text('إنشاء طلب جديد (B2B)'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'اسم الحريف (الزبون)',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'هاتف الحريف',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: addressController,
                      decoration: const InputDecoration(
                        labelText: 'عنوان التوصيل',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: foodAmountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'قيمة الأكل (د.ت)',
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: driverFeeController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'أجرة السائق (د.ت)',
                        prefixIcon: Icon(Icons.delivery_dining),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: creating ? null : () => Navigator.pop(dialogContext),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: creating
                      ? null
                      : () async {
                          final name = nameController.text.trim();
                          final phone = phoneController.text.trim();
                          final address = addressController.text.trim();
                          final foodAmount = double.tryParse(foodAmountController.text) ?? 0;
                          final driverFee = double.tryParse(driverFeeController.text) ?? 0;
                          final lat = double.tryParse(latController.text) ?? 35.8256;
                          final lng = double.tryParse(lngController.text) ?? 10.6369;

                          if (address.isEmpty || foodAmount <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('الرجاء إدخال العنوان وقيمة الأكل على الأقل'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          setDialogState(() {
                            creating = true;
                          });

                          try {
                            await ApiService.post(
                              '/restaurant/orders',
                              {
                                'customer_name': name.isEmpty ? null : name,
                                'customer_phone': phone.isEmpty ? null : phone,
                                'customer_address': address,
                                'customer_latitude': lat,
                                'customer_longitude': lng,
                                'food_amount': foodAmount,
                                'driver_fee': driverFee,
                              },
                            );

                            if (!dialogContext.mounted) return;
                            Navigator.pop(dialogContext);

                            await loadData();

                            showMessage('✅ تم إنشاء الطلب بنجاح وبدأ البحث عن سائق');
                          } catch (error) {
                            if (!dialogContext.mounted) return;
                            setDialogState(() {
                              creating = false;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(_cleanError(error)),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                  child: creating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('إنشاء الطلب'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      nameController.dispose();
      phoneController.dispose();
      addressController.dispose();
      foodAmountController.dispose();
      driverFeeController.dispose();
      latController.dispose();
      lngController.dispose();
    });
  }

  // =========================================================
  // SOCKET
  // =========================================================

  Future<void> _connectSocket() async {
    final token =
        await AuthService.getToken();

    if (token == null || token.isEmpty) {
      return;
    }

    _socketService.connect(
      serverUrl: 'http://localhost:3000',
      token: token,
      role: 'restaurant',
    );

    _socketService.on(
      'order_status_updated',
      (data) {
        if (!mounted) return;

        final event =
            Map<String, dynamic>.from(
          data ?? {},
        );

        final status =
            event['status']?.toString() ?? '';

        final orderId =
            event['order_id'];

        setState(() {
          socketConnected = true;
        });

        loadData(silent: true);

        if (status == 'driver_arrived') {
          showMessage(
            '🚗 السائق وصل إلى المطعم للطلب #$orderId',
          );

          Future.delayed(
            const Duration(milliseconds: 400),
            () {
              if (mounted) {
                _showOtpDialog(
                  orderId: orderId,
                );
              }
            },
          );
        } else if (status == 'accepted') {
          showMessage(
            '✅ تم قبول الطلب #$orderId من طرف السائق',
          );
        } else if (status == 'picked_up') {
          showMessage(
            '📦 تم استلام الطلب #$orderId',
          );
        } else if (status == 'delivering') {
          showMessage(
            '🛵 الطلب #$orderId في طريقه إلى الحريف',
          );
        } else if (status == 'delivered') {
          showMessage(
            '🎉 تم تسليم الطلب #$orderId',
          );
        }
      },
    );

    Future.delayed(
      const Duration(seconds: 2),
      () {
        if (!mounted) return;

        setState(() {
          socketConnected =
              _socketService.isConnected;
        });
      },
    );
  }

  // =========================================================
  // OTP
  // =========================================================

  void _showOtpDialog({
    dynamic orderId,
  }) {
    final controller =
        TextEditingController();

    bool verifying = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(
                    Icons.lock_outline,
                    color: Colors.orange,
                  ),
                  SizedBox(width: 10),
                  Text('رمز استلام الطلب'),
                ],
              ),
              content: Column(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  Text(
                    'السائق وصل إلى المطعم للطلب #$orderId',
                    textAlign:
                        TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: controller,
                    keyboardType:
                        TextInputType.number,
                    maxLength: 4,
                    textAlign:
                        TextAlign.center,
                    decoration:
                        const InputDecoration(
                      labelText: 'أدخل OTP',
                      hintText: '0000',
                      border:
                          OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: verifying
                      ? null
                      : () {
                          Navigator.pop(
                            dialogContext,
                          );
                        },
                  child: const Text(
                    'إلغاء',
                  ),
                ),
                ElevatedButton(
                  onPressed: verifying
                      ? null
                      : () async {
                          final otp =
                              controller.text
                                  .trim();

                          if (!RegExp(
                            r'^\d{4}$',
                          ).hasMatch(otp)) {
                            ScaffoldMessenger
                                .of(context)
                                .showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'أدخل رمزًا من 4 أرقام',
                                ),
                              ),
                            );
                            return;
                          }

                          setDialogState(() {
                            verifying = true;
                          });

                          try {
                            await ApiService.post(
                              '/restaurant/orders/verify-pickup',
                              {
                                'order_id':
                                    orderId,
                                'otp': otp,
                              },
                            );

                            if (!mounted) return;

                            Navigator.pop(
                              dialogContext,
                            );

                            await loadData();

                            showMessage(
                              '✅ تم التحقق من OTP واستلام الطلب',
                            );
                          } catch (error) {
                            if (!dialogContext.mounted) {
                              return;
                            }

                            setDialogState(() {
                              verifying = false;
                            });

                            ScaffoldMessenger
                                .of(dialogContext)
                                .showSnackBar(
                              SnackBar(
                                content: Text(
                                  _cleanError(
                                    error,
                                  ),
                                ),
                              ),
                            );
                          }
                        },
                  child: verifying
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'تحقق',
                        ),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      controller.dispose();
    });
  }

  // =========================================================
  // LOGOUT
  // =========================================================

  Future<void> logout() async {
    final confirmed =
        await showDialog<bool>(
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
                  Navigator.pop(
                context,
                false,
              ),
              child: const Text(
                'إلغاء',
              ),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(
                context,
                true,
              ),
              child: const Text(
                'خروج',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    _refreshTimer?.cancel();
    _socketService.disconnect();

    await AuthService.logout();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const RoleSelectionScreen(),
      ),
      (route) => false,
    );
  }

  // =========================================================
  // HELPERS
  // =========================================================

  String _cleanError(dynamic error) {
    return error
        .toString()
        .replaceFirst(
          'Exception: ',
          '',
        );
  }

  void showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              isError ? Colors.red : null,
        ),
      );
  }

  String money(dynamic value) {
    final number =
        double.tryParse(
              value?.toString() ?? '',
            ) ??
            0;

    return '${number.toStringAsFixed(3)} د.ت';
  }

  String statusText(String? status) {
    switch (status) {
      case 'pending':
        return 'في الانتظار';

      case 'dispatching':
        return 'جاري البحث عن سائق';

      case 'offered':
        return 'عرض على السائق';

      case 'accepted':
        return 'تم قبول الطلب';

      case 'driver_arrived':
        return 'السائق وصل';

      case 'pickup_verified':
        return 'تم التحقق';

      case 'picked_up':
        return 'تم الاستلام';

      case 'delivering':
        return 'جاري التوصيل';

      case 'delivered':
        return 'تم التسليم';

      case 'cancelled':
        return 'ملغى';

      case 'failed':
        return 'فشل';

      default:
        return status ?? 'غير معروف';
    }
  }

  Color statusColor(String? status) {
    switch (status) {
      case 'delivered':
        return Colors.green;

      case 'cancelled':
      case 'failed':
        return Colors.red;

      case 'driver_arrived':
        return Colors.orange;

      case 'accepted':
      case 'picked_up':
      case 'delivering':
        return Colors.blue;

      default:
        return Colors.grey;
    }
  }

  // =========================================================
  // PROFILE
  // =========================================================

  Widget buildProfileHeader() {
    final restaurant =
        profile['restaurant'] ??
        profile;

    final name =
        restaurant['name'] ??
        'المطعم';

    final address =
        restaurant['address'] ??
        '';

    final balance =
        restaurant['balance_due'] ??
        0;

    return Container(
      margin:
          const EdgeInsets.all(16),
      padding:
          const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF111827),
            Color(0xFF1F2937),
          ],
        ),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 55,
                height: 55,
                decoration:
                    BoxDecoration(
                  color:
                      Colors.white12,
                  borderRadius:
                      BorderRadius.circular(
                    15,
                  ),
                ),
                child: const Icon(
                  Icons.restaurant,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.toString(),
                      style:
                          const TextStyle(
                        color:
                            Colors.white,
                        fontSize: 21,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    if (address
                        .toString()
                        .isNotEmpty)
                      Text(
                        address.toString(),
                        style:
                            const TextStyle(
                          color:
                              Colors.white70,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed:
                    refreshData,
                icon: const Icon(
                  Icons.refresh,
                  color:
                      Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(
            color: Colors.white24,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment:
                MainAxisAlignment
                    .spaceBetween,
            children: [
              const Text(
                'الرصيد المستحق',
                style:
                    TextStyle(
                  color:
                      Colors.white70,
                ),
              ),
              Text(
                money(balance),
                style:
                    const TextStyle(
                  color:
                      Colors.white,
                  fontSize: 20,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================
  // STATS
  // =========================================================

  Widget buildStats() {
    final activeCount =
        orders.where((order) {
      final status =
          order['status']?.toString();

      return status != 'delivered' &&
          status != 'cancelled' &&
          status != 'failed';
    }).length;

    final completedCount =
        orders.where((order) {
      return order['status'] ==
          'delivered';
    }).length;

    return Padding(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 16,
      ),
      child: Row(
        children: [
          Expanded(
            child: _statCard(
              'الطلبات النشطة',
              activeCount.toString(),
              Icons.local_shipping,
              Colors.orange,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _statCard(
              'المكتملة',
              completedCount.toString(),
              Icons.check_circle,
              Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(16),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(
              0.06,
            ),
            blurRadius: 10,
            offset:
                const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color,
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style:
                const TextStyle(
              fontSize: 25,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          Text(
            title,
            style:
                const TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // ORDER CARD
  // =========================================================

  Widget buildOrderCard(
    dynamic rawOrder,
  ) {
    final order =
        Map<String, dynamic>.from(
      rawOrder,
    );

    final id = order['id'];

    final status =
        order['status']?.toString();

    final customer =
        order['customer_name']
                ?.toString() ??
            'حريف';

    final phone =
        order['customer_phone']
                ?.toString() ??
            '';

    final address =
        order['customer_address']
                ?.toString() ??
            '';

    final foodAmount =
        order['food_amount'];

    final driverFee =
        order['driver_fee'];

    final latitude =
        double.tryParse(
      order['customer_latitude']
              ?.toString() ??
          '',
    );

    final longitude =
        double.tryParse(
      order['customer_longitude']
              ?.toString() ??
          '',
    );

    return Container(
      margin:
          const EdgeInsets.fromLTRB(
        16,
        0,
        16,
        14,
      ),
      padding:
          const EdgeInsets.all(16),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(
              0.06,
            ),
            blurRadius: 10,
            offset:
                const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'طلب #$id',
                  style:
                      const TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration:
                    BoxDecoration(
                  color: statusColor(
                    status,
                  ).withOpacity(
                    0.12,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    20,
                  ),
                ),
                child: Text(
                  statusText(status),
                  style:
                      TextStyle(
                    color:
                        statusColor(
                      status,
                    ),
                    fontWeight:
                        FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          _infoRow(
            Icons.person_outline,
            customer,
          ),

          if (phone.isNotEmpty)
            _infoRow(
              Icons.phone_outlined,
              phone,
            ),

          _infoRow(
            Icons.location_on_outlined,
            address,
          ),

          const Divider(),

          Row(
            mainAxisAlignment:
                MainAxisAlignment
                    .spaceBetween,
            children: [
              _amountColumn(
                'قيمة الأكل',
                money(foodAmount),
              ),
              _amountColumn(
                'أجرة السائق',
                money(driverFee),
              ),
            ],
          ),

          const SizedBox(height: 12),

          if (latitude != null &&
              longitude != null)
            SizedBox(
              width: double.infinity,
              child: MapButton(
                title:
                    'فتح موقع الحريف',
                latitude: latitude,
                longitude: longitude,
              ),
            ),

          if (status ==
              'driver_arrived')
            Container(
              width: double.infinity,
              margin:
                  const EdgeInsets.only(
                top: 10,
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  _showOtpDialog(
                    orderId: id,
                  );
                },
                icon: const Icon(
                  Icons.lock_open,
                ),
                label: const Text(
                  'إدخال OTP',
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String text,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 9,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: Colors.grey[700],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text),
          ),
        ],
      ),
    );
  }

  Widget _amountColumn(
    String title,
    String value,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style:
              const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style:
              const TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // =========================================================
  // BODY
  // =========================================================

  Widget buildBody() {
    if (orders.isEmpty) {
      return RefreshIndicator(
        onRefresh: refreshData,
        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          children: [
            buildProfileHeader(),
            buildStats(),
            const SizedBox(
              height: 100,
            ),
            const Icon(
              Icons.receipt_long_outlined,
              size: 70,
              color: Colors.grey,
            ),
            const SizedBox(height: 15),
            const Center(
              child: Text(
                'لا توجد طلبات حاليًا',
                style:
                    TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: refreshData,
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        children: [
          buildProfileHeader(),
          buildStats(),
          const SizedBox(height: 20),

          const Padding(
            padding:
                EdgeInsets.symmetric(
              horizontal: 16,
            ),
            child: Text(
              'الطلبات',
              style:
                  TextStyle(
                fontSize: 21,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 12),

          ...orders.map(
            buildOrderCard,
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F7FA),

      appBar: AppBar(
        title: const Text(
          'HADROUG DELIVERY',
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding:
                const EdgeInsets.only(
              right: 8,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.circle,
                  size: 10,
                  color: socketConnected
                      ? Colors.green
                      : Colors.red,
                ),
                const SizedBox(width: 5),
                Text(
                  socketConnected
                      ? 'Live'
                      : 'Offline',
                  style:
                      const TextStyle(
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      // زر إنشاء طلب جديد عائم مخصص لنظام B2B
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateOrderDialog,
        backgroundColor: const Color(0xFF111827),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'طلب جديد',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),

      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(
                  25,
                ),
                color:
                    const Color(0xFF111827),
                child: const Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Icon(
                      Icons.restaurant,
                      color: Colors.white,
                      size: 45,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'HADROUG DELIVERY',
                      style:
                          TextStyle(
                        color:
                            Colors.white,
                        fontSize: 20,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Espace Restaurant',
                      style:
                          TextStyle(
                        color:
                            Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),

              ListTile(
                leading:
                    const Icon(
                  Icons.dashboard_outlined,
                ),
                title:
                    const Text(
                  'لوحة المطعم',
                ),
                onTap: () {
                  Navigator.pop(
                    context,
                  );
                },
              ),

              ListTile(
                leading:
                    const Icon(
                  Icons.add_shopping_cart,
                ),
                title:
                    const Text(
                  'إنشاء طلب جديد',
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showCreateOrderDialog();
                },
              ),

              ListTile(
                leading:
                    const Icon(
                  Icons.refresh,
                ),
                title:
                    const Text(
                  'تحديث البيانات',
                ),
                onTap: () {
                  Navigator.pop(
                    context,
                  );
                  refreshData();
                },
              ),

              const Spacer(),

              ListTile(
                leading:
                    const Icon(
                  Icons.logout,
                  color: Colors.red,
                ),
                title:
                    const Text(
                  'تسجيل الخروج',
                  style:
                      TextStyle(
                    color: Colors.red,
                  ),
                ),
                onTap: logout,
              ),
            ],
          ),
        ),
      ),

      body: loading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : buildBody(),
    );
  }

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _socketService.disconnect();
    super.dispose();
  }
}
