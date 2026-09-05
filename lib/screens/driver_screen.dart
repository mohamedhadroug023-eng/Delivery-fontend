import 'package:flutter/material.dart';

import '../services/api_service.dart';

class DriverScreen extends StatefulWidget {
  const DriverScreen({super.key});

  @override
  State<DriverScreen> createState() => _DriverScreenState();
}

class _DriverScreenState extends State<DriverScreen> {
  static const orange = Color(0xFFFF6B00);

  bool loading = true;
  bool updatingStatus = false;
  bool processingOrder = false;

  bool online = false;

  Map<String, dynamic>? driver;

  List<Map<String, dynamic>> orders = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  // =========================================================
  // LOAD DATA
  // =========================================================

  Future<void> loadData() async {
    if (!mounted) return;

    setState(() {
      loading = true;
    });

    try {
      final profileResponse =
          await ApiService.get('/driver/profile');

      final ordersResponse =
          await ApiService.get('/driver/orders');

      if (!mounted) return;

      final profileData =
          Map<String, dynamic>.from(
        profileResponse['driver'] ?? {},
      );

      final rawOrders =
          ordersResponse['orders'] ?? [];

      final ordersData =
          List<Map<String, dynamic>>.from(
        rawOrders.map(
          (order) =>
              Map<String, dynamic>.from(order),
        ),
      );

      setState(() {
        driver = profileData;
        orders = ordersData;

        online =
            profileData['is_online'] == true ||
            profileData['is_online'] == 1;

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
  // UPDATE ONLINE STATUS
  // =========================================================

  Future<void> updateOnlineStatus(
    bool value,
  ) async {
    if (updatingStatus) return;

    setState(() {
      updatingStatus = true;
    });

    try {
      final response =
          await ApiService.patch(
        '/driver/online',
        {
          'is_online': value,
        },
      );

      if (!mounted) return;

      if (response['success'] != true) {
        throw Exception(
          response['message'] ??
              'فشل تغيير حالة السائق',
        );
      }

      setState(() {
        online = value;
      });

      _showMessage(
        value
            ? 'أصبحت متاحًا لاستقبال الطلبات'
            : 'أصبحت غير متاح لاستقبال الطلبات',
      );
    } catch (error) {
      if (!mounted) return;

      _showError(error);
    } finally {
      if (!mounted) return;

      setState(() {
        updatingStatus = false;
      });
    }
  }

  // =========================================================
  // CURRENT ORDER
  // =========================================================

  Map<String, dynamic>? get currentOrder {
    for (final order in orders) {
      final status =
          order['status']?.toString();

      if ([
        'offered',
        'accepted',
        'driver_arrived',
        'pickup_verified',
        'picked_up',
        'delivering',
      ].contains(status)) {
        return order;
      }
    }

    return null;
  }

  // =========================================================
  // TODAY ORDERS
  // =========================================================

  int get todayOrdersCount {
    final now = DateTime.now();

    return orders.where((order) {
      final date =
          DateTime.tryParse(
        order['created_at']?.toString() ?? '',
      );

      if (date == null) {
        return false;
      }

      return date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    }).length;
  }

  // =========================================================
  // TODAY INCOME
  // =========================================================

  double get todayIncome {
    final now = DateTime.now();

    double total = 0;

    for (final order in orders) {
      final date =
          DateTime.tryParse(
        order['created_at']?.toString() ?? '',
      );

      if (date == null) {
        continue;
      }

      if (date.year != now.year ||
          date.month != now.month ||
          date.day != now.day) {
        continue;
      }

      if (order['status']?.toString() !=
          'delivered') {
        continue;
      }

      final fee =
          double.tryParse(
                order['driver_fee']
                        ?.toString() ??
                    '0',
              ) ??
              0;

      total += fee;
    }

    return total;
  }

  // =========================================================
  // ACCEPT ORDER
  // =========================================================

  Future<void> acceptOrder(
    Map<String, dynamic> order,
  ) async {
    if (processingOrder) return;

    final orderId = order['id'];

    if (orderId == null) {
      _showMessage(
        'رقم الطلب غير موجود',
      );
      return;
    }

    setState(() {
      processingOrder = true;
    });

    try {
      final response =
          await ApiService.post(
        '/driver/orders/accept',
        {
          'order_id': orderId,
        },
      );

      if (!mounted) return;

      if (response['success'] != true) {
        throw Exception(
          response['message'] ??
              'تعذر قبول الطلب',
        );
      }

      _showMessage(
        'تم قبول الطلب بنجاح',
      );

      await loadData();
    } catch (error) {
      if (!mounted) return;

      _showError(error);
    } finally {
      if (!mounted) return;

      setState(() {
        processingOrder = false;
      });
    }
  }

  // =========================================================
  // REJECT ORDER
  // =========================================================

  Future<void> rejectOrder(
    Map<String, dynamic> order,
  ) async {
    if (processingOrder) return;

    final orderId = order['id'];

    if (orderId == null) {
      _showMessage(
        'رقم الطلب غير موجود',
      );
      return;
    }

    setState(() {
      processingOrder = true;
    });

    try {
      final response =
          await ApiService.post(
        '/driver/orders/reject',
        {
          'order_id': orderId,
        },
      );

      if (!mounted) return;

      if (response['success'] != true) {
        throw Exception(
          response['message'] ??
              'تعذر رفض الطلب',
        );
      }

      _showMessage(
        'تم رفض الطلب',
      );

      await loadData();
    } catch (error) {
      if (!mounted) return;

      _showError(error);
    } finally {
      if (!mounted) return;

      setState(() {
        processingOrder = false;
      });
    }
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'مساحة السائق',
        ),
        actions: [
          IconButton(
            onPressed:
                loading ? null : loadData,
            icon: const Icon(
              Icons.refresh,
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.notifications_none,
            ),
          ),
        ],
      ),

      body: loading
          ? const Center(
              child:
                  CircularProgressIndicator(
                color: orange,
              ),
            )
          : RefreshIndicator(
              onRefresh: loadData,
              child:
                  SingleChildScrollView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                padding:
                    const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _statusCard(),

                    const SizedBox(
                      height: 15,
                    ),

                    Row(
                      children: [
                        Expanded(
                          child: _stat(
                            Icons.receipt_long,
                            'طلبات اليوم',
                            todayOrdersCount
                                .toString(),
                          ),
                        ),
                        const SizedBox(
                          width: 12,
                        ),
                        Expanded(
                          child: _stat(
                            Icons.payments,
                            'الدخل اليوم',
                            '${todayIncome.toStringAsFixed(3)} د.ت',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 25,
                    ),

                    const Align(
                      alignment:
                          Alignment.centerRight,
                      child: Text(
                        'الطلب الحالي',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    _currentOrder(),

                    const SizedBox(
                      height: 25,
                    ),

                    const Align(
                      alignment:
                          Alignment.centerRight,
                      child: Text(
                        'سجل الطلبات',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    _ordersHistory(),
                  ],
                ),
              ),
            ),
    );
  }

  // =========================================================
  // STATUS CARD
  // =========================================================

  Widget _statusCard() {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 13,
              height: 13,
              decoration:
                  BoxDecoration(
                color: online
                    ? Colors.green
                    : Colors.red,
                shape: BoxShape.circle,
              ),
            ),

            const SizedBox(
              width: 10,
            ),

            Expanded(
              child: Text(
                online
                    ? 'أنت متاح لاستقبال الطلبات'
                    : 'أنت غير متاح',
                style:
                    const TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),

            updatingStatus
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2,
                      color: orange,
                    ),
                  )
                : Switch(
                    value: online,
                    activeColor: orange,
                    onChanged:
                        updateOnlineStatus,
                  ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // STAT CARD
  // =========================================================

  Widget _stat(
    IconData icon,
    String title,
    String value,
  ) {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(15),
        child: Column(
          children: [
            Icon(
              icon,
              color: orange,
              size: 28,
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              value,
              style:
                  const TextStyle(
                fontSize: 19,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 3,
            ),

            Text(
              title,
              style:
                  const TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // CURRENT ORDER
  // =========================================================

  Widget _currentOrder() {
    final order = currentOrder;

    if (order == null) {
      return Card(
        child: Padding(
          padding:
              const EdgeInsets.all(18),
          child: Column(
            children: [
              const Icon(
                Icons.delivery_dining,
                size: 55,
                color: Colors.grey,
              ),

              const SizedBox(
                height: 10,
              ),

              const Text(
                'لا يوجد طلب حالي',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 5,
              ),

              const Text(
                'عند وصول طلب جديد سيظهر هنا',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final status =
        order['status']?.toString() ??
            '';

    if (status == 'offered') {
      return _offerCard(order);
    }

    return _acceptedOrderCard(order);
  }

  // =========================================================
  // NEW OFFER CARD
  // =========================================================

  Widget _offerCard(
    Map<String, dynamic> order,
  ) {
    final id =
        order['id']?.toString() ?? '';

    final restaurant =
        order['restaurant_name']
                ?.toString() ??
            'المطعم';

    final restaurantAddress =
        order['restaurant_address']
                ?.toString() ??
            '';

    final customer =
        order['customer_name']
                ?.toString()
                .trim()
                .isNotEmpty ==
            true
        ? order['customer_name']
            .toString()
        : 'الزبون';

    final address =
        order['customer_address']
                ?.toString() ??
            '';

    final fee =
        double.tryParse(
              order['driver_fee']
                      ?.toString() ??
                  '0',
            ) ??
            0;

    return Card(
      elevation: 4,
      child: Padding(
        padding:
            const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
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
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                _statusBadge(
                  'offered',
                ),
              ],
            ),

            const SizedBox(
              height: 18,
            ),

            const Text(
              'طلب توصيل جديد',
              style: TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 15,
            ),

            _infoRow(
              Icons.store,
              restaurant,
            ),

            if (restaurantAddress
                .isNotEmpty) ...[
              const SizedBox(
                height: 8,
              ),
              _infoRow(
                Icons.location_on,
                restaurantAddress,
              ),
            ],

            const Divider(
              height: 25,
            ),

            _infoRow(
              Icons.person,
              customer,
            ),

            const SizedBox(
              height: 8,
            ),

            _infoRow(
              Icons.location_on,
              address,
            ),

            const SizedBox(
              height: 15,
            ),

            Row(
              children: [
                const Icon(
                  Icons.payments,
                  color: orange,
                ),
                const SizedBox(
                  width: 8,
                ),
                Text(
                  'أجرة السائق: ${fee.toStringAsFixed(3)} د.ت',
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 20,
            ),

            Row(
              children: [
                Expanded(
                  child:
                      ElevatedButton.icon(
                    onPressed:
                        processingOrder
                            ? null
                            : () =>
                                acceptOrder(
                                  order,
                                ),
                    style:
                        ElevatedButton
                            .styleFrom(
                      backgroundColor:
                          Colors.green,
                      foregroundColor:
                          Colors.white,
                      padding:
                          const EdgeInsets
                              .symmetric(
                        vertical: 13,
                      ),
                    ),
                    icon:
                        processingOrder
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth:
                                      2,
                                  color:
                                      Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons
                                    .check,
                              ),
                    label: const Text(
                      'قبول',
                    ),
                  ),
                ),

                const SizedBox(
                  width: 10,
                ),

                Expanded(
                  child:
                      OutlinedButton.icon(
                    onPressed:
                        processingOrder
                            ? null
                            : () =>
                                rejectOrder(
                                  order,
                                ),
                    style:
                        OutlinedButton
                            .styleFrom(
                      foregroundColor:
                          Colors.red,
                      side:
                          const BorderSide(
                        color:
                            Colors.red,
                      ),
                      padding:
                          const EdgeInsets
                              .symmetric(
                        vertical: 13,
                      ),
                    ),
                    icon: const Icon(
                      Icons.close,
                    ),
                    label: const Text(
                      'رفض',
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

  // =========================================================
  // ACCEPTED ORDER CARD
  // =========================================================

  Widget _acceptedOrderCard(
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
        : 'الزبون';

    final phone =
        order['customer_phone']
                ?.toString() ??
            '';

    final address =
        order['customer_address']
                ?.toString() ??
            '';

    final restaurant =
        order['restaurant_name']
                ?.toString() ??
            'المطعم';

    final restaurantAddress =
        order['restaurant_address']
                ?.toString() ??
            '';

    final fee =
        double.tryParse(
              order['driver_fee']
                      ?.toString() ??
                  '0',
            ) ??
            0;

    final status =
        order['status']?.toString() ??
            '';

    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
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
                    fontSize: 17,
                  ),
                ),
                _statusBadge(status),
              ],
            ),

            const SizedBox(
              height: 18,
            ),

            _infoRow(
              Icons.store,
              restaurant,
            ),

            if (restaurantAddress
                .isNotEmpty) ...[
              const SizedBox(
                height: 8,
              ),
              _infoRow(
                Icons.location_on,
                restaurantAddress,
              ),
            ],

            const Divider(
              height: 25,
            ),

            _infoRow(
              Icons.person,
              customer,
            ),

            if (phone.isNotEmpty) ...[
              const SizedBox(
                height: 10,
              ),
              _infoRow(
                Icons.phone,
                phone,
              ),
            ],

            const SizedBox(
              height: 10,
            ),

            _infoRow(
              Icons.location_on,
              address,
            ),

            const SizedBox(
              height: 15,
            ),

            Row(
              children: [
                const Icon(
                  Icons.payments,
                  color: orange,
                ),
                const SizedBox(
                  width: 8,
                ),
                Text(
                  'أجرة السائق: ${fee.toStringAsFixed(3)} د.ت',
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 18,
            ),

            SizedBox(
              width:
                  double.infinity,
              child:
                  OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(
                  Icons.map,
                ),
                label: const Text(
                  'فتح الخريطة',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // ORDERS HISTORY
  // =========================================================

  Widget _ordersHistory() {
    if (orders.isEmpty) {
      return Card(
        child: ListTile(
          leading: const Icon(
            Icons.history,
            color: orange,
          ),
          title: const Text(
            'لا توجد طلبات',
          ),
          subtitle: const Text(
            'ستظهر طلباتك هنا',
          ),
        ),
      );
    }

    return Column(
      children:
          orders.map((order) {
        final id =
            order['id']?.toString() ??
                '';

        final status =
            order['status']
                    ?.toString() ??
                '';

        final customer =
            order['customer_name']
                    ?.toString()
                    .trim()
                    .isNotEmpty ==
                true
            ? order['customer_name']
                .toString()
            : 'الزبون';

        final fee =
            double.tryParse(
                  order['driver_fee']
                          ?.toString() ??
                      '0',
                ) ??
                0;

        return Card(
          margin:
              const EdgeInsets.only(
            bottom: 10,
          ),
          child: ListTile(
            leading: const Icon(
              Icons.delivery_dining,
              color: orange,
            ),
            title: Text(
              '#$id - $customer',
            ),
            subtitle: Text(
              'أجرة السائق: ${fee.toStringAsFixed(3)} د.ت',
            ),
            trailing:
                _statusBadge(status),
          ),
        );
      }).toList(),
    );
  }

  // =========================================================
  // INFO ROW
  // =========================================================

  Widget _infoRow(
    IconData icon,
    String text,
  ) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: orange,
        ),

        const SizedBox(
          width: 8,
        ),

        Expanded(
          child: Text(text),
        ),
      ],
    );
  }

  // =========================================================
  // STATUS BADGE
  // =========================================================

  Widget _statusBadge(
    String status,
  ) {
    String text;

    switch (status) {
      case 'offered':
        text = 'عرض جديد';
        break;

      case 'accepted':
        text = 'تم القبول';
        break;

      case 'driver_arrived':
        text = 'وصلت للمطعم';
        break;

      case 'pickup_verified':
        text = 'تم التأكيد';
        break;

      case 'picked_up':
        text = 'تم الاستلام';
        break;

      case 'delivering':
        text = 'قيد التوصيل';
        break;

      case 'delivered':
        text = 'تم التسليم';
        break;

      case 'cancelled':
        text = 'ملغى';
        break;

      case 'failed':
        text = 'فشل';
        break;

      default:
        text = status.isEmpty
            ? 'غير معروف'
            : status;
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration:
          BoxDecoration(
        color:
            orange.withOpacity(.1),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style:
            const TextStyle(
          color: orange,
          fontSize: 11,
          fontWeight:
              FontWeight.bold,
        ),
      ),
    );
  }

  // =========================================================
  // MESSAGE
  // =========================================================

  void _showMessage(
    String message,
  ) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // =========================================================
  // ERROR
  // =========================================================

  void _showError(
    Object error,
  ) {
    String message =
        error.toString();

    if (message.startsWith(
      'Exception: ',
    )) {
      message =
          message.substring(11);
    }

    _showMessage(message);
  }
}
