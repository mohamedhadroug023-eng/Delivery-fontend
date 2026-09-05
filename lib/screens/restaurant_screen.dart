import 'package:flutter/material.dart';

import '../services/api_service.dart';

class RestaurantScreen extends StatefulWidget {
  const RestaurantScreen({super.key});

  @override
  State<RestaurantScreen> createState() => _RestaurantScreenState();
}

class _RestaurantScreenState extends State<RestaurantScreen> {
  static const orange = Color(0xFFFF6B00);

  bool loading = true;
  bool creatingOrder = false;

  Map<String, dynamic>? restaurant;
  List<Map<String, dynamic>> orders = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  // =========================================================
  // LOAD RESTAURANT DATA
  // =========================================================

  Future<void> loadData() async {
    setState(() {
      loading = true;
    });

    try {
      final profileResponse =
          await ApiService.get('/restaurant/profile');

      final ordersResponse =
          await ApiService.get('/restaurant/orders');

      if (!mounted) return;

      final profileData =
          Map<String, dynamic>.from(
        profileResponse['restaurant'] ?? {},
      );

      final ordersData =
          List<Map<String, dynamic>>.from(
        (ordersResponse['orders'] ?? []).map(
          (order) => Map<String, dynamic>.from(order),
        ),
      );

      setState(() {
        restaurant = profileData;
        orders = ordersData;
        loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      _showError(error);
    }
  }

  // =========================================================
  // CREATE ORDER
  // =========================================================

  Future<void> createOrder({
    required String customerName,
    required String customerPhone,
    required String customerAddress,
    required String latitude,
    required String longitude,
    required String foodAmount,
    required String driverFee,
  }) async {
    if (customerAddress.trim().isEmpty ||
        latitude.trim().isEmpty ||
        longitude.trim().isEmpty ||
        foodAmount.trim().isEmpty) {
      _showMessage('يرجى إدخال جميع البيانات المطلوبة');
      return;
    }

    final lat = double.tryParse(latitude.trim());
    final lng = double.tryParse(longitude.trim());
    final amount = double.tryParse(foodAmount.trim());
    final fee = double.tryParse(
      driverFee.trim().isEmpty ? '0' : driverFee.trim(),
    );

    if (lat == null || lng == null || amount == null || fee == null) {
      _showMessage('يرجى التأكد من صحة الأرقام');
      return;
    }

    if (amount <= 0 || fee < 0) {
      _showMessage('قيمة الطلب أو أجرة السائق غير صحيحة');
      return;
    }

    setState(() {
      creatingOrder = true;
    });

    try {
      final response = await ApiService.post(
        '/orders',
        {
          'customer_name': customerName.trim(),
          'customer_phone': customerPhone.trim(),
          'customer_address': customerAddress.trim(),
          'customer_latitude': lat,
          'customer_longitude': lng,
          'food_amount': amount,
          'driver_fee': fee,
        },
      );

      if (!mounted) return;

      if (response['success'] != true) {
        throw Exception(
          response['message'] ?? 'فشل إنشاء الطلب',
        );
      }

      Navigator.pop(context);

      _showMessage(
        'تم نشر الطلب بنجاح',
      );

      await loadData();
    } catch (error) {
      if (!mounted) return;

      _showError(error);
    } finally {
      if (mounted) {
        setState(() {
          creatingOrder = false;
        });
      }
    }
  }

  // =========================================================
  // HELPERS
  // =========================================================

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  void _showError(Object error) {
    String message = error.toString();

    if (message.startsWith('Exception: ')) {
      message = message.substring(11);
    }

    _showMessage(message);
  }

  bool _isActiveOrder(Map<String, dynamic> order) {
    final status = order['status']?.toString();

    return [
      'pending',
      'dispatching',
      'offered',
      'accepted',
      'driver_arrived',
      'pickup_verified',
      'picked_up',
      'delivering',
    ].contains(status);
  }

  int get todayOrdersCount {
    final now = DateTime.now();

    return orders.where((order) {
      final createdAt = DateTime.tryParse(
        order['created_at']?.toString() ?? '',
      );

      if (createdAt == null) return false;

      return createdAt.year == now.year &&
          createdAt.month == now.month &&
          createdAt.day == now.day;
    }).length;
  }

  int get activeOrdersCount {
    return orders.where(_isActiveOrder).length;
  }

  List<Map<String, dynamic>> get activeOrders {
    return orders.where(_isActiveOrder).toList();
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة المطعم'),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh,
            ),
            onPressed: loading ? null : loadData,
          ),
          IconButton(
            icon: const Icon(
              Icons.notifications_none,
            ),
            onPressed: () {},
          ),
        ],
      ),

      body: loading
          ? const Center(
              child: CircularProgressIndicator(
                color: orange,
              ),
            )
          : RefreshIndicator(
              onRefresh: loadData,
              child: SingleChildScrollView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    // =================================================
                    // RESTAURANT NAME
                    // =================================================

                    Text(
                      restaurant?['name']?.toString() ??
                          'المطعم',
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    const Text(
                      'ملخص اليوم',
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // =================================================
                    // STATISTICS
                    // =================================================

                    Row(
                      children: [
                        Expanded(
                          child: _statCard(
                            icon:
                                Icons.receipt_long,
                            title:
                                'طلبات اليوم',
                            value:
                                todayOrdersCount
                                    .toString(),
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: _statCard(
                            icon:
                                Icons.local_shipping,
                            title:
                                'طلبات نشطة',
                            value:
                                activeOrdersCount
                                    .toString(),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // =================================================
                    // BALANCE
                    // =================================================

                    _moneyCard(),

                    const SizedBox(height: 25),

                    // =================================================
                    // NEW ORDER
                    // =================================================

                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: ElevatedButton.icon(
                        onPressed: creatingOrder
                            ? null
                            : () {
                                _showNewOrderDialog(
                                  context,
                                );
                              },
                        icon: const Icon(
                          Icons.add,
                        ),
                        label: const Text(
                          'إنشاء طلب توصيل',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // =================================================
                    // ACTIVE ORDERS
                    // =================================================

                    const Text(
                      'الطلبات الحالية',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    if (activeOrders.isEmpty)
                      _emptyOrdersCard()
                    else
                      ...activeOrders.map(
                        (order) =>
                            Padding(
                          padding:
                              const EdgeInsets.only(
                            bottom: 12,
                          ),
                          child:
                              _orderCard(order),
                        ),
                      ),

                    const SizedBox(height: 15),

                    // =================================================
                    // QUICK ACTIONS
                    // =================================================

                    const Text(
                      'إجراءات سريعة',
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
                          child: _quickAction(
                            icon: Icons.history,
                            title: 'سجل الطلبات',
                            onTap: () {},
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _quickAction(
                            icon: Icons.bar_chart,
                            title: 'التقارير',
                            onTap: () {},
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // =========================================================
  // STAT CARD
  // =========================================================

  Widget _statCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
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
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),
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

  // =========================================================
  // MONEY CARD
  // =========================================================

  Widget _moneyCard() {
    final balance =
        restaurant?['balance_due'];

    final balanceNumber =
        double.tryParse(
              balance?.toString() ?? '',
            ) ??
            0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              padding:
                  const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    orange.withOpacity(.1),
                borderRadius:
                    BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.account_balance_wallet,
                color: orange,
              ),
            ),

            const SizedBox(width: 15),

            Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'المبلغ المستحق',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${balanceNumber.toStringAsFixed(3)} د.ت',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // EMPTY ORDERS
  // =========================================================

  Widget _emptyOrdersCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Center(
          child: Column(
            children: const [
              Icon(
                Icons.inbox_outlined,
                size: 50,
                color: Colors.grey,
              ),
              SizedBox(height: 10),
              Text(
                'لا توجد طلبات نشطة حاليًا',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // ORDER CARD
  // =========================================================

  Widget _orderCard(
    Map<String, dynamic> order,
  ) {
    final id =
        order['id']?.toString() ?? '';

    final customer =
        order['customer_name']
                ?.toString()
                .trim()
                .isNotEmpty ==
            true
        ? order['customer_name']
              .toString()
        : 'زبون';

    final phone =
        order['customer_phone']
            ?.toString() ??
        '';

    final address =
        order['customer_address']
            ?.toString() ??
        '';

    final status =
        order['status']?.toString() ??
            '';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment:
                  MainAxisAlignment
                      .spaceBetween,
              children: [
                Text(
                  '#$id',
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                _statusBadge(status),
              ],
            ),

            const SizedBox(height: 15),

            Row(
              children: [
                const Icon(
                  Icons.person,
                  color: orange,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(customer),
                ),
              ],
            ),

            if (phone.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(
                    Icons.phone,
                    color: orange,
                  ),
                  const SizedBox(width: 8),
                  Text(phone),
                ],
              ),
            ],

            const SizedBox(height: 10),

            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_on,
                  color: orange,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(address),
                ),
              ],
            ),

            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              child:
                  OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(
                  Icons.map,
                ),
                label: const Text(
                  'متابعة الطلب',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // STATUS
  // =========================================================

  Widget _statusBadge(String status) {
    String text;

    switch (status) {
      case 'pending':
        text = 'في الانتظار';
        break;

      case 'dispatching':
        text = 'البحث عن سائق';
        break;

      case 'offered':
        text = 'تم إرسال الطلب';
        break;

      case 'accepted':
        text = 'تم قبول الطلب';
        break;

      case 'driver_arrived':
        text = 'السائق وصل';
        break;

      case 'pickup_verified':
        text = 'تم تأكيد الاستلام';
        break;

      case 'picked_up':
        text = 'تم استلام الطلب';
        break;

      case 'delivering':
        text = 'قيد التوصيل';
        break;

      default:
        text = status;
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: orange.withOpacity(.1),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: orange,
          fontSize: 12,
          fontWeight:
              FontWeight.bold,
        ),
      ),
    );
  }

  // =========================================================
  // QUICK ACTION
  // =========================================================

  Widget _quickAction({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(18),
        child: Padding(
          padding:
              const EdgeInsets.all(18),
          child: Column(
            children: [
              Icon(
                icon,
                color: orange,
                size: 30,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign:
                    TextAlign.center,
                style: const TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // NEW ORDER DIALOG
  // =========================================================

  void _showNewOrderDialog(
    BuildContext context,
  ) {
    final customerName =
        TextEditingController();

    final customerPhone =
        TextEditingController();

    final customerAddress =
        TextEditingController();

    final latitude =
        TextEditingController();

    final longitude =
        TextEditingController();

    final foodAmount =
        TextEditingController();

    final driverFee =
        TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) {
        return StatefulBuilder(
          builder:
              (context, setModalState) {
            return Padding(
              padding:
                  EdgeInsets.only(
                left: 20,
                right: 20,
                bottom:
                    MediaQuery.of(
                      context,
                    ).viewInsets.bottom +
                    20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    const Text(
                      'طلب توصيل جديد',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    TextField(
                      controller:
                          customerName,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'اسم الزبون',
                        prefixIcon:
                            Icon(
                          Icons.person,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    TextField(
                      controller:
                          customerPhone,
                      keyboardType:
                          TextInputType.phone,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'رقم الزبون',
                        prefixIcon:
                            Icon(
                          Icons.phone,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    TextField(
                      controller:
                          foodAmount,
                      keyboardType:
                          const TextInputType
                              .numberWithOptions(
                        decimal: true,
                      ),
                      decoration:
                          const InputDecoration(
                        labelText:
                            'قيمة الطلب',
                        prefixIcon:
                            Icon(
                          Icons
                              .account_balance_wallet,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    TextField(
                      controller:
                          driverFee,
                      keyboardType:
                          const TextInputType
                              .numberWithOptions(
                        decimal: true,
                      ),
                      decoration:
                          const InputDecoration(
                        labelText:
                            'أجرة السائق',
                        prefixIcon:
                            Icon(
                          Icons
                              .two_wheeler,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    TextField(
                      controller:
                          customerAddress,
                      maxLines: 2,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'عنوان الزبون',
                        prefixIcon:
                            Icon(
                          Icons
                              .location_on,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller:
                                latitude,
                            keyboardType:
                                const TextInputType
                                    .numberWithOptions(
                              decimal: true,
                              signed: true,
                            ),
                            decoration:
                                const InputDecoration(
                              labelText:
                                  'Latitude',
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        Expanded(
                          child: TextField(
                            controller:
                                longitude,
                            keyboardType:
                                const TextInputType
                                    .numberWithOptions(
                              decimal: true,
                              signed: true,
                            ),
                            decoration:
                                const InputDecoration(
                              labelText:
                                  'Longitude',
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    SizedBox(
                      width:
                          double.infinity,
                      child:
                          ElevatedButton(
                        onPressed:
                            creatingOrder
                                ? null
                                : () async {
                                    setModalState(
                                      () {},
                                    );

                                    await createOrder(
                                      customerName:
                                          customerName
                                              .text,
                                      customerPhone:
                                          customerPhone
                                              .text,
                                      customerAddress:
                                          customerAddress
                                              .text,
                                      latitude:
                                          latitude
                                              .text,
                                      longitude:
                                          longitude
                                              .text,
                                      foodAmount:
                                          foodAmount
                                              .text,
                                      driverFee:
                                          driverFee
                                              .text,
                                    );
                                  },
                        child:
                            creatingOrder
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child:
                                        CircularProgressIndicator(
                                      color:
                                          Colors
                                              .white,
                                      strokeWidth:
                                          2.5,
                                    ),
                                  )
                                : const Text(
                                    'نشر طلب التوصيل',
                                  ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
