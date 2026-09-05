import 'dart:async';

import 'package:flutter/material.dart';

import '../services/api_service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  static const orange = Color(0xFFFF6B00);

  bool loading = true;
  bool refreshing = false;

  String? errorMessage;

  int restaurants = 0;
  int drivers = 0;
  int onlineDrivers = 0;
  int todayOrders = 0;
  int activeOrders = 0;

  double todayRevenue = 0;
  double totalBalanceDue = 0;

  List<Map<String, dynamic>> activeOrdersList = [];

  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();

    loadDashboard();

    _refreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) {
        loadDashboard(
          silent: true,
        );
      },
    );
  }

  // =========================================================
  // LOAD DASHBOARD
  // =========================================================

  Future<void> loadDashboard({
    bool silent = false,
  }) async {
    if (!silent && mounted) {
      setState(() {
        loading = true;
        errorMessage = null;
      });
    }

    if (silent && mounted) {
      setState(() {
        refreshing = true;
      });
    }

    try {
      final response =
          await ApiService.get(
        '/admin/dashboard',
      );

      final statistics =
          response['statistics'];

      final orders =
          response['active_orders'];

      if (!mounted) return;

      setState(() {
        restaurants =
            int.tryParse(
                  '${statistics?['restaurants'] ?? 0}',
                ) ??
                0;

        drivers =
            int.tryParse(
                  '${statistics?['drivers'] ?? 0}',
                ) ??
                0;

        onlineDrivers =
            int.tryParse(
                  '${statistics?['online_drivers'] ?? 0}',
                ) ??
                0;

        todayOrders =
            int.tryParse(
                  '${statistics?['today_orders'] ?? 0}',
                ) ??
                0;

        activeOrders =
            int.tryParse(
                  '${statistics?['active_orders'] ?? 0}',
                ) ??
                0;

        todayRevenue =
            double.tryParse(
                  '${statistics?['today_revenue'] ?? 0}',
                ) ??
                0;

        totalBalanceDue =
            double.tryParse(
                  '${statistics?['total_balance_due'] ?? 0}',
                ) ??
                0;

        activeOrdersList =
            orders is List
                ? orders
                    .map(
                      (order) =>
                          Map<String, dynamic>.from(
                        order,
                      ),
                    )
                    .toList()
                : [];

        loading = false;
        refreshing = false;
        errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        loading = false;
        refreshing = false;
        errorMessage =
            error.toString().replaceFirst(
                  'Exception: ',
                  '',
                );
      });
    }
  }

  // =========================================================
  // FORMAT MONEY
  // =========================================================

  String formatMoney(
    dynamic value,
  ) {
    final number =
        double.tryParse(
              '$value',
            ) ??
            0;

    return '${number.toStringAsFixed(3)} د.ت';
  }

  // =========================================================
  // STATUS LABEL
  // =========================================================

  String statusLabel(
    String? status,
  ) {
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
        return 'السائق وصل للمطعم';

      case 'pickup_verified':
        return 'تم التحقق';

      case 'picked_up':
        return 'تم استلام الطلب';

      case 'delivering':
        return 'جاري التوصيل';

      case 'delivered':
        return 'تم التوصيل';

      case 'cancelled':
        return 'ملغى';

      case 'failed':
        return 'فشل';

      default:
        return status ?? 'غير معروف';
    }
  }

  Color statusColor(
    String? status,
  ) {
    switch (status) {
      case 'delivered':
        return Colors.green;

      case 'cancelled':
      case 'failed':
        return Colors.red;

      case 'driver_arrived':
      case 'picked_up':
      case 'delivering':
        return Colors.blue;

      case 'accepted':
        return Colors.orange;

      case 'offered':
        return Colors.deepPurple;

      default:
        return Colors.grey;
    }
  }

  // =========================================================
  // REFRESH BUTTON
  // =========================================================

  Future<void> refreshDashboard() async {
    await loadDashboard();
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
          'لوحة الإدارة',
        ),
        actions: [
          if (refreshing)
            const Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 16,
              ),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child:
                      CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                ),
              ),
            )
          else
            IconButton(
              onPressed:
                  refreshDashboard,
              icon: const Icon(
                Icons.refresh,
              ),
            ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh:
            refreshDashboard,

        child: loading
            ? ListView(
                children: const [
                  SizedBox(
                    height: 300,
                  ),
                  Center(
                    child:
                        CircularProgressIndicator(),
                  ),
                ],
              )
            : errorMessage != null
                ? ListView(
                    padding:
                        const EdgeInsets.all(
                      24,
                    ),
                    children: [
                      const SizedBox(
                        height: 100,
                      ),

                      const Icon(
                        Icons.error_outline,
                        size: 60,
                        color: Colors.red,
                      ),

                      const SizedBox(
                        height: 20,
                      ),

                      const Center(
                        child: Text(
                          'تعذر تحميل لوحة الإدارة',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 10,
                      ),

                      Center(
                        child: Text(
                          errorMessage!,
                          textAlign:
                              TextAlign.center,
                          style: const TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 20,
                      ),

                      ElevatedButton.icon(
                        onPressed:
                            refreshDashboard,
                        icon: const Icon(
                          Icons.refresh,
                        ),
                        label: const Text(
                          'إعادة المحاولة',
                        ),
                      ),
                    ],
                  )
                : ListView(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    padding:
                        const EdgeInsets.all(
                      16,
                    ),
                    children: [

                      // =============================
                      // TITLE
                      // =============================

                      const Text(
                        'نظرة عامة',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                        height: 20,
                      ),

                      // =============================
                      // STATISTICS
                      // =============================

                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics:
                            const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio:
                            1.35,
                        children: [

                          _statCard(
                            Icons.restaurant,
                            'المطاعم',
                            '$restaurants',
                          ),

                          _statCard(
                            Icons.two_wheeler,
                            'السائقون',
                            '$drivers',
                          ),

                          _statCard(
                            Icons.receipt_long,
                            'طلبات اليوم',
                            '$todayOrders',
                          ),

                          _statCard(
                            Icons.payments,
                            'دخل اليوم',
                            formatMoney(
                              todayRevenue,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 15,
                      ),

                      // =============================
                      // ONLINE DRIVERS
                      // =============================

                      Card(
                        child: Padding(
                          padding:
                              const EdgeInsets.all(
                            20,
                          ),
                          child: Row(
                            children: [

                              Container(
                                padding:
                                    const EdgeInsets
                                        .all(
                                  13,
                                ),
                                decoration:
                                    BoxDecoration(
                                  color: Colors.green
                                      .withOpacity(
                                    .1,
                                  ),
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                    15,
                                  ),
                                ),
                                child:
                                    const Icon(
                                  Icons
                                      .wifi_tethering,
                                  color:
                                      Colors.green,
                                  size: 30,
                                ),
                              ),

                              const SizedBox(
                                width: 15,
                              ),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [

                                    const Text(
                                      'السائقون المتصلون',
                                      style:
                                          TextStyle(
                                        color:
                                            Colors.grey,
                                      ),
                                    ),

                                    const SizedBox(
                                      height: 5,
                                    ),

                                    Text(
                                      '$onlineDrivers / $drivers',
                                      style:
                                          const TextStyle(
                                        fontSize: 23,
                                        fontWeight:
                                            FontWeight
                                                .bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const Icon(
                                Icons.circle,
                                color:
                                    Colors.green,
                                size: 14,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      // =============================
                      // BALANCE DUE
                      // =============================

                      Card(
                        child: Padding(
                          padding:
                              const EdgeInsets.all(
                            20,
                          ),
                          child: Row(
                            children: [

                              Container(
                                padding:
                                    const EdgeInsets
                                        .all(
                                  13,
                                ),
                                decoration:
                                    BoxDecoration(
                                  color: orange
                                      .withOpacity(
                                    .1,
                                  ),
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                    15,
                                  ),
                                ),
                                child:
                                    const Icon(
                                  Icons
                                      .account_balance,
                                  color: orange,
                                  size: 30,
                                ),
                              ),

                              const SizedBox(
                                width: 15,
                              ),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [

                                    const Text(
                                      'إجمالي المبالغ المستحقة',
                                      style:
                                          TextStyle(
                                        color:
                                            Colors.grey,
                                      ),
                                    ),

                                    const SizedBox(
                                      height: 5,
                                    ),

                                    Text(
                                      formatMoney(
                                        totalBalanceDue,
                                      ),
                                      style:
                                          const TextStyle(
                                        fontSize: 23,
                                        fontWeight:
                                            FontWeight
                                                .bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 28,
                      ),

                      // =============================
                      // ACTIVE ORDERS
                      // =============================

                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment
                                .spaceBetween,
                        children: [

                          const Text(
                            'الطلبات النشطة',
                            style: TextStyle(
                              fontSize: 21,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          Container(
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration:
                                BoxDecoration(
                              color: orange
                                  .withOpacity(
                                .1,
                              ),
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                20,
                              ),
                            ),
                            child: Text(
                              '$activeOrders',
                              style:
                                  const TextStyle(
                                color: orange,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      if (activeOrdersList
                          .isEmpty)
                        Card(
                          child: ListTile(
                            leading:
                                const Icon(
                              Icons
                                  .location_on,
                              color: orange,
                            ),
                            title:
                                const Text(
                              'لا توجد طلبات نشطة',
                            ),
                            subtitle:
                                const Text(
                              'ستظهر الطلبات هنا عند بدء التوصيل',
                            ),
                          ),
                        )
                      else
                        ...activeOrdersList
                            .map(
                              (order) =>
                                  _activeOrderCard(
                                order,
                              ),
                            ),

                      const SizedBox(
                        height: 25,
                      ),

                      // =============================
                      // MANAGEMENT
                      // =============================

                      const Text(
                        'الإدارة',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      _adminAction(
                        Icons.restaurant_menu,
                        'إدارة المطاعم',
                        () {
                          _showComingSoon(
                            context,
                            'إدارة المطاعم',
                          );
                        },
                      ),

                      _adminAction(
                        Icons.people,
                        'إدارة السائقين',
                        () {
                          _showComingSoon(
                            context,
                            'إدارة السائقين',
                          );
                        },
                      ),

                      _adminAction(
                        Icons.receipt_long,
                        'جميع الطلبات',
                        () {
                          _showComingSoon(
                            context,
                            'جميع الطلبات',
                          );
                        },
                      ),

                      _adminAction(
                        Icons.bar_chart,
                        'التقارير والإحصائيات',
                        () {
                          _showComingSoon(
                            context,
                            'التقارير والإحصائيات',
                          );
                        },
                      ),

                      _adminAction(
                        Icons
                            .account_balance_wallet,
                        'المبالغ المستحقة',
                        () {
                          _showComingSoon(
                            context,
                            'المبالغ المستحقة',
                          );
                        },
                      ),

                      const SizedBox(
                        height: 20,
                      ),
                    ],
                  ),
      ),
    );
  }

  // =========================================================
  // STAT CARD
  // =========================================================

  Widget _statCard(
    IconData icon,
    String title,
    String value,
  ) {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(
          15,
        ),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [

            Icon(
              icon,
              color: orange,
              size: 30,
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              value,
              style:
                  const TextStyle(
                fontSize: 23,
                fontWeight:
                    FontWeight.bold,
              ),
              textAlign:
                  TextAlign.center,
            ),

            const SizedBox(
              height: 3,
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
      ),
    );
  }

  // =========================================================
  // ACTIVE ORDER CARD
  // =========================================================

  Widget _activeOrderCard(
    Map<String, dynamic> order,
  ) {
    final status =
        order['status']?.toString();

    final restaurantName =
        order['restaurant_name']
                ?.toString() ??
            'مطعم';

    final driverName =
        order['driver_name']
                ?.toString() ??
            'لم يتم تعيين سائق';

    final customerName =
        order['customer_name']
                ?.toString() ??
            'زبون';

    final address =
        order['customer_address']
                ?.toString() ??
            'العنوان غير متوفر';

    final orderId =
        order['id']?.toString() ??
            '-';

    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 10,
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(
          15,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [

            Row(
              children: [

                Container(
                  padding:
                      const EdgeInsets.all(
                    9,
                  ),
                  decoration:
                      BoxDecoration(
                    color: statusColor(
                      status,
                    ).withOpacity(
                      .1,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      12,
                    ),
                  ),
                  child: Icon(
                    Icons.receipt_long,
                    color:
                        statusColor(
                      status,
                    ),
                  ),
                ),

                const SizedBox(
                  width: 10,
                ),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [

                      Text(
                        'طلب #$orderId',
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      Text(
                        restaurantName,
                        style:
                            const TextStyle(
                          color:
                              Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration:
                      BoxDecoration(
                    color: statusColor(
                      status,
                    ).withOpacity(
                      .1,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      20,
                    ),
                  ),
                  child: Text(
                    statusLabel(
                      status,
                    ),
                    style: TextStyle(
                      color:
                          statusColor(
                        status,
                      ),
                      fontSize: 12,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const Divider(
              height: 25,
            ),

            Row(
              children: [

                const Icon(
                  Icons.person_outline,
                  size: 20,
                ),

                const SizedBox(
                  width: 8,
                ),

                Expanded(
                  child: Text(
                    customerName,
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 8,
            ),

            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [

                const Icon(
                  Icons.location_on_outlined,
                  size: 20,
                ),

                const SizedBox(
                  width: 8,
                ),

                Expanded(
                  child: Text(
                    address,
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 8,
            ),

            Row(
              children: [

                const Icon(
                  Icons.two_wheeler,
                  size: 20,
                ),

                const SizedBox(
                  width: 8,
                ),

                Expanded(
                  child: Text(
                    driverName,
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 12,
            ),

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.end,
              children: [

                Text(
                  formatMoney(
                    order['food_amount'],
                  ),
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.bold,
                    fontSize: 16,
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
  // ADMIN ACTION
  // =========================================================

  Widget _adminAction(
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 10,
      ),
      child: ListTile(
        onTap: onTap,

        leading: Container(
          padding:
              const EdgeInsets.all(
            9,
          ),
          decoration:
              BoxDecoration(
            color: orange.withOpacity(
              .1,
            ),
            borderRadius:
                BorderRadius.circular(
              12,
            ),
          ),
          child: Icon(
            icon,
            color: orange,
          ),
        ),

        title: Text(
          title,
          style:
              const TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),

        trailing:
            const Icon(
          Icons.arrow_back_ios_new,
          size: 16,
        ),
      ),
    );
  }

  // =========================================================
  // COMING SOON
  // =========================================================

  void _showComingSoon(
    BuildContext context,
    String title,
  ) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content: Text(
          '$title ستكون في الخطوة التالية',
        ),
      ),
    );
  }

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
