import 'dart:async';

import 'package:flutter/material.dart';

import '../services/api_service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() =>
      _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  static const orange = Color(0xFFFF6B00);

  bool loading = true;

  Map<String, dynamic> statistics = {};

  List<Map<String, dynamic>> activeOrders = [];
  List<Map<String, dynamic>> restaurants = [];
  List<Map<String, dynamic>> drivers = [];
  List<Map<String, dynamic>> allOrders = [];

  Timer? _refreshTimer;

  int selectedPage = 0;

  @override
  void initState() {
    super.initState();

    loadDashboard();

    _refreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) {
        if (!loading) {
          loadDashboard(
            showLoading: false,
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  // =========================================================
  // LOAD DASHBOARD
  // =========================================================

  Future<void> loadDashboard({
    bool showLoading = true,
  }) async {
    if (showLoading && mounted) {
      setState(() {
        loading = true;
      });
    }

    try {
      final response =
          await ApiService.get(
        '/admin/dashboard',
      );

      if (!mounted) return;

      final rawStatistics =
          response['statistics'] ?? {};

      final rawActiveOrders =
          response['active_orders'] ?? [];

      setState(() {
        statistics =
            Map<String, dynamic>.from(
          rawStatistics,
        );

        activeOrders =
            List<Map<String, dynamic>>.from(
          rawActiveOrders.map(
            (order) =>
                Map<String, dynamic>.from(
              order,
            ),
          ),
        );

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
  // LOAD RESTAURANTS
  // =========================================================

  Future<void> loadRestaurants() async {
    try {
      final response =
          await ApiService.get(
        '/admin/restaurants',
      );

      if (!mounted) return;

      final raw =
          response['restaurants'] ?? [];

      setState(() {
        restaurants =
            List<Map<String, dynamic>>.from(
          raw.map(
            (item) =>
                Map<String, dynamic>.from(
              item,
            ),
          ),
        );
      });
    } catch (error) {
      if (!mounted) return;

      _showError(error);
    }
  }

  // =========================================================
  // LOAD DRIVERS
  // =========================================================

  Future<void> loadDrivers() async {
    try {
      final response =
          await ApiService.get(
        '/admin/drivers',
      );

      if (!mounted) return;

      final raw =
          response['drivers'] ?? [];

      setState(() {
        drivers =
            List<Map<String, dynamic>>.from(
          raw.map(
            (item) =>
                Map<String, dynamic>.from(
              item,
            ),
          ),
        );
      });
    } catch (error) {
      if (!mounted) return;

      _showError(error);
    }
  }

  // =========================================================
  // LOAD ALL ORDERS
  // =========================================================

  Future<void> loadAllOrders() async {
    try {
      final response =
          await ApiService.get(
        '/admin/orders',
      );

      if (!mounted) return;

      final raw =
          response['orders'] ?? [];

      setState(() {
        allOrders =
            List<Map<String, dynamic>>.from(
          raw.map(
            (item) =>
                Map<String, dynamic>.from(
              item,
            ),
          ),
        );
      });
    } catch (error) {
      if (!mounted) return;

      _showError(error);
    }
  }

  // =========================================================
  // PAGE SELECTION
  // =========================================================

  Future<void> changePage(
    int page,
  ) async {
    setState(() {
      selectedPage = page;
      loading = true;
    });

    try {
      if (page == 0) {
        await loadDashboard(
          showLoading: false,
        );
      } else if (page == 1) {
        await loadRestaurants();
      } else if (page == 2) {
        await loadDrivers();
      } else if (page == 3) {
        await loadAllOrders();
      }
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  // =========================================================
  // HELPERS
  // =========================================================

  double _number(
    dynamic value,
  ) {
    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  int _integer(
    dynamic value,
  ) {
    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  String _money(
    dynamic value,
  ) {
    return '${_number(value).toStringAsFixed(3)} د.ت';
  }

  void _showMessage(
    String message,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content:
              Text(message),
        ),
      );
  }

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

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text(
          _pageTitle(),
        ),
        actions: [
          IconButton(
            icon:
                const Icon(
              Icons.refresh,
            ),
            onPressed:
                loading
                    ? null
                    : () =>
                        _refreshCurrentPage(),
          ),
          IconButton(
            icon:
                const Icon(
              Icons.notifications_none,
            ),
            onPressed: () {},
          ),
        ],
      ),

      drawer:
          _buildDrawer(),

      body:
          loading
              ? const Center(
                  child:
                      CircularProgressIndicator(
                    color: orange,
                  ),
                )
              : RefreshIndicator(
                  onRefresh:
                      _refreshCurrentPage,
                  child:
                      _buildCurrentPage(),
                ),
    );
  }

  String _pageTitle() {
    switch (selectedPage) {
      case 1:
        return 'إدارة المطاعم';
      case 2:
        return 'إدارة السائقين';
      case 3:
        return 'جميع الطلبات';
      default:
        return 'لوحة الإدارة';
    }
  }

  Future<void>
      _refreshCurrentPage() async {
    if (selectedPage == 0) {
      await loadDashboard(
        showLoading: false,
      );
    } else if (selectedPage == 1) {
      await loadRestaurants();
    } else if (selectedPage == 2) {
      await loadDrivers();
    } else if (selectedPage == 3) {
      await loadAllOrders();
    }
  }

  // =========================================================
  // DRAWER
  // =========================================================

  Widget _buildDrawer() {
    return Drawer(
      child:
          SafeArea(
        child:
            Column(
          children: [

            Container(
              width:
                  double.infinity,
              padding:
                  const EdgeInsets
                      .all(
                22,
              ),
              child:
                  Column(
                children: [

                  Container(
                    width: 70,
                    height: 70,
                    decoration:
                        BoxDecoration(
                      color:
                          orange,
                      borderRadius:
                          BorderRadius.circular(
                        20,
                      ),
                    ),
                    child:
                        const Icon(
                      Icons
                          .local_shipping,
                      color:
                          Colors.white,
                      size:
                          38,
                    ),
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  const Text(
                    'HADROUG DELIVERY',
                    style:
                        TextStyle(
                      fontSize:
                          18,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 4,
                  ),

                  const Text(
                    'لوحة الإدارة',
                    style:
                        TextStyle(
                      color:
                          Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(),

            _drawerItem(
              icon:
                  Icons.dashboard,
              title:
                  'لوحة التحكم',
              page:
                  0,
            ),

            _drawerItem(
              icon:
                  Icons.restaurant,
              title:
                  'إدارة المطاعم',
              page:
                  1,
            ),

            _drawerItem(
              icon:
                  Icons.two_wheeler,
              title:
                  'إدارة السائقين',
              page:
                  2,
            ),

            _drawerItem(
              icon:
                  Icons.receipt_long,
              title:
                  'جميع الطلبات',
              page:
                  3,
            ),

            const Spacer(),

            const Divider(),

            ListTile(
              leading:
                  const Icon(
                Icons.bar_chart,
              ),
              title:
                  const Text(
                'التقارير',
              ),
              onTap: () {
                Navigator.pop(
                  context,
                );

                _showMessage(
                  'قسم التقارير قادم في الخطوة التالية',
                );
              },
            ),

            ListTile(
              leading:
                  const Icon(
                Icons.logout,
                color:
                    Colors.red,
              ),
              title:
                  const Text(
                'تسجيل الخروج',
              ),
              onTap: () {
                Navigator.pop(
                  context,
                );

                _showMessage(
                  'تسجيل الخروج سنربطه مع AuthService لاحقًا',
                );
              },
            ),

            const SizedBox(
              height: 10,
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String title,
    required int page,
  }) {
    final selected =
        selectedPage == page;

    return ListTile(
      selected:
          selected,
      selectedColor:
          orange,
      leading:
          Icon(icon),
      title:
          Text(title),
      onTap: () async {
        Navigator.pop(
          context,
        );

        await changePage(
          page,
        );
      },
    );
  }

  // =========================================================
  // CURRENT PAGE
  // =========================================================

  Widget _buildCurrentPage() {
    switch (selectedPage) {
      case 1:
        return _restaurantsPage();

      case 2:
        return _driversPage();

      case 3:
        return _ordersPage();

      default:
        return _dashboardPage();
    }
  }

  // =========================================================
  // DASHBOARD
  // =========================================================

  Widget _dashboardPage() {
    final restaurantCount =
        _integer(
      statistics['restaurants'],
    );

    final driverCount =
        _integer(
      statistics['drivers'],
    );

    final onlineDrivers =
        _integer(
      statistics[
          'online_drivers'],
    );

    final todayOrders =
        _integer(
      statistics[
          'today_orders'],
    );

    final todayRevenue =
        statistics[
            'today_revenue'] ??
        0;

    final balanceDue =
        statistics[
            'total_balance_due'] ??
        0;

    return SingleChildScrollView(
      physics:
          const AlwaysScrollableScrollPhysics(),
      padding:
          const EdgeInsets.all(
        16,
      ),
      child:
          Column(
        crossAxisAlignment:
            CrossAxisAlignment
                .start,
        children: [

          const Text(
            'نظرة عامة',
            style:
                TextStyle(
              fontSize: 25,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 5,
          ),

          const Text(
            'بيانات النظام في الوقت الحالي',
            style:
                TextStyle(
              color:
                  Colors.grey,
            ),
          ),

          const SizedBox(
            height: 20,
          ),

          GridView.count(
            crossAxisCount:
                2,
            shrinkWrap:
                true,
            physics:
                const NeverScrollableScrollPhysics(),
            mainAxisSpacing:
                12,
            crossAxisSpacing:
                12,
            childAspectRatio:
                1.35,
            children: [

              _statCard(
                icon:
                    Icons.restaurant,
                title:
                    'المطاعم',
                value:
                    restaurantCount
                        .toString(),
              ),

              _statCard(
                icon:
                    Icons.two_wheeler,
                title:
                    'السائقون',
                value:
                    driverCount
                        .toString(),
              ),

              _statCard(
                icon:
                    Icons
                        .online_prediction,
                title:
                    'السائقون المتصلون',
                value:
                    onlineDrivers
                        .toString(),
              ),

              _statCard(
                icon:
                    Icons.receipt_long,
                title:
                    'طلبات اليوم',
                value:
                    todayOrders
                        .toString(),
              ),
            ],
          ),

          const SizedBox(
            height: 15,
          ),

          _financeCard(
            icon:
                Icons.payments,
            title:
                'دخل اليوم',
            value:
                _money(
              todayRevenue,
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          _financeCard(
            icon:
                Icons.account_balance_wallet,
            title:
                'إجمالي المبالغ المستحقة',
            value:
                _money(
              balanceDue,
            ),
          ),

          const SizedBox(
            height: 28,
          ),

          Row(
            mainAxisAlignment:
                MainAxisAlignment
                    .spaceBetween,
            children: [

              const Text(
                'الطلبات النشطة',
                style:
                    TextStyle(
                  fontSize: 21,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              Text(
                '${activeOrders.length}',
                style:
                    const TextStyle(
                  color:
                      orange,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 12,
          ),

          if (activeOrders.isEmpty)
            _emptyCard(
              icon:
                  Icons
                      .local_shipping_outlined,
              text:
                  'لا توجد طلبات نشطة',
            )
          else
            ...activeOrders.map(
              (order) =>
                  Padding(
                padding:
                    const EdgeInsets
                        .only(
                  bottom: 10,
                ),
                child:
                    _activeOrderCard(
                  order,
                ),
              ),
            ),

          const SizedBox(
            height: 20,
          ),
        ],
      ),
    );
  }

  // =========================================================
  // RESTAURANTS
  // =========================================================

  Widget _restaurantsPage() {
    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),
      padding:
          const EdgeInsets.all(
        16,
      ),
      children: [

        Row(
          mainAxisAlignment:
              MainAxisAlignment
                  .spaceBetween,
          children: [

            const Text(
              'المطاعم',
              style:
                  TextStyle(
                fontSize: 24,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            Text(
              '${restaurants.length}',
              style:
                  const TextStyle(
                color:
                    orange,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ],
        ),

        const SizedBox(
          height: 15,
        ),

        if (restaurants.isEmpty)
          _emptyCard(
            icon:
                Icons.restaurant,
            text:
                'لا توجد مطاعم',
          )
        else
          ...restaurants.map(
            (restaurant) =>
                Padding(
              padding:
                  const EdgeInsets
                      .only(
                bottom: 12,
              ),
              child:
                  _restaurantCard(
                restaurant,
              ),
            ),
          ),
      ],
    );
  }

  Widget _restaurantCard(
    Map<String, dynamic> restaurant,
  ) {
    final name =
        restaurant['name']
                ?.toString() ??
            'مطعم';

    final address =
        restaurant['address']
                ?.toString() ??
            '';

    final phone =
        restaurant['phone']
                ?.toString() ??
            '';

    final balance =
        restaurant[
            'balance_due'];

    final active =
        restaurant[
                'is_active'] ==
            true ||
        restaurant[
                'is_active']
            .toString() ==
            '1';

    return Card(
      child:
          Padding(
        padding:
            const EdgeInsets
                .all(
          16,
        ),
        child:
            Column(
          crossAxisAlignment:
              CrossAxisAlignment
                  .start,
          children: [

            Row(
              children: [

                Container(
                  padding:
                      const EdgeInsets
                          .all(
                    12,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        orange.withOpacity(
                      .1,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                  ),
                  child:
                      const Icon(
                    Icons.restaurant,
                    color:
                        orange,
                  ),
                ),

                const SizedBox(
                  width: 12,
                ),

                Expanded(
                  child:
                      Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [

                      Text(
                        name,
                        style:
                            const TextStyle(
                          fontSize:
                              17,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      if (phone
                          .isNotEmpty)
                        Text(
                          phone,
                          style:
                              const TextStyle(
                            color:
                                Colors.grey,
                          ),
                        ),
                    ],
                  ),
                ),

                _activeBadge(
                  active,
                ),
              ],
            ),

            const SizedBox(
              height: 15,
            ),

            if (address.isNotEmpty)
              Row(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 20,
                    color: orange,
                  ),
                  const SizedBox(
                    width: 7,
                  ),
                  Expanded(
                    child:
                        Text(address),
                  ),
                ],
              ),

            const SizedBox(
              height: 12,
            ),

            Container(
              width:
                  double.infinity,
              padding:
                  const EdgeInsets
                      .all(
                12,
              ),
              decoration:
                  BoxDecoration(
                color:
                    Colors.grey.shade100,
                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
              ),
              child:
                  Row(
                mainAxisAlignment:
                    MainAxisAlignment
                        .spaceBetween,
                children: [

                  const Text(
                    'المبلغ المستحق',
                    style:
                        TextStyle(
                      color:
                          Colors.grey,
                    ),
                  ),

                  Text(
                    _money(
                      balance,
                    ),
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.bold,
                      color:
                          orange,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            SizedBox(
              width:
                  double.infinity,
              child:
                  OutlinedButton.icon(
                onPressed: () {
                  _showRestaurantDetails(
                    restaurant,
                  );
                },
                icon:
                    const Icon(
                  Icons.visibility,
                ),
                label:
                    const Text(
                  'عرض التفاصيل',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // DRIVERS
  // =========================================================

  Widget _driversPage() {
    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),
      padding:
          const EdgeInsets.all(
        16,
      ),
      children: [

        Row(
          mainAxisAlignment:
              MainAxisAlignment
                  .spaceBetween,
          children: [

            const Text(
              'السائقون',
              style:
                  TextStyle(
                fontSize: 24,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            Text(
              '${drivers.length}',
              style:
                  const TextStyle(
                color:
                    orange,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ],
        ),

        const SizedBox(
          height: 15,
        ),

        if (drivers.isEmpty)
          _emptyCard(
            icon:
                Icons.two_wheeler,
            text:
                'لا توجد بيانات للسائقين',
          )
        else
          ...drivers.map(
            (driver) =>
                Padding(
              padding:
                  const EdgeInsets
                      .only(
                bottom: 12,
              ),
              child:
                  _driverCard(
                driver,
              ),
            ),
          ),
      ],
    );
  }

  Widget _driverCard(
    Map<String, dynamic> driver,
  ) {
    final name =
        driver['full_name']
                ?.toString() ??
            'سائق';

    final phone =
        driver['phone']
                ?.toString() ??
            '';

    final vehicle =
        driver['vehicle_type']
                ?.toString() ??
            '';

    final online =
        driver[
                'is_online'] ==
            true ||
        driver[
                'is_online']
            .toString() ==
            '1';

    final available =
        driver[
                'is_available'] ==
            true ||
        driver[
                'is_available']
            .toString() ==
            '1';

    final completed =
        _integer(
      driver[
          'total_completed_orders'],
    );

    final currentOrders =
        _integer(
      driver[
          'current_orders_count'],
    );

    return Card(
      child:
          Padding(
        padding:
            const EdgeInsets
                .all(
          16,
        ),
        child:
            Column(
          crossAxisAlignment:
              CrossAxisAlignment
                  .start,
          children: [

            Row(
              children: [

                Container(
                  padding:
                      const EdgeInsets
                          .all(
                    12,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        orange.withOpacity(
                      .1,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                  ),
                  child:
                      const Icon(
                    Icons.two_wheeler,
                    color:
                        orange,
                  ),
                ),

                const SizedBox(
                  width: 12,
                ),

                Expanded(
                  child:
                      Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [

                      Text(
                        name,
                        style:
                            const TextStyle(
                          fontSize:
                              17,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      if (phone
                          .isNotEmpty)
                        Text(
                          phone,
                          style:
                              const TextStyle(
                            color:
                                Colors.grey,
                          ),
                        ),

                      if (vehicle
                          .isNotEmpty)
                        Text(
                          vehicle,
                          style:
                              const TextStyle(
                            color:
                                Colors.grey,
                          ),
                        ),
                    ],
                  ),
                ),

                _onlineBadge(
                  online,
                ),
              ],
            ),

            const SizedBox(
              height: 15,
            ),

            Row(
              children: [

                Expanded(
                  child:
                      _smallStat(
                    title:
                        'الحالة',
                    value:
                        available
                            ? 'متاح'
                            : 'مشغول',
                  ),
                ),

                const SizedBox(
                  width: 8,
                ),

                Expanded(
                  child:
                      _smallStat(
                    title:
                        'الطلب الحالي',
                    value:
                        currentOrders
                            .toString(),
                  ),
                ),

                const SizedBox(
                  width: 8,
                ),

                Expanded(
                  child:
                      _smallStat(
                    title:
                        'مكتمل',
                    value:
                        completed
                            .toString(),
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
  // ORDERS
  // =========================================================

  Widget _ordersPage() {
    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),
      padding:
          const EdgeInsets.all(
        16,
      ),
      children: [

        Row(
          mainAxisAlignment:
              MainAxisAlignment
                  .spaceBetween,
          children: [

            const Text(
              'جميع الطلبات',
              style:
                  TextStyle(
                fontSize: 24,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            Text(
              '${allOrders.length}',
              style:
                  const TextStyle(
                color:
                    orange,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ],
        ),

        const SizedBox(
          height: 15,
        ),

        if (allOrders.isEmpty)
          _emptyCard(
            icon:
                Icons.receipt_long,
            text:
                'لا توجد طلبات',
          )
        else
          ...allOrders.map(
            (order) =>
                Padding(
              padding:
                  const EdgeInsets
                      .only(
                bottom: 10,
              ),
              child:
                  _orderHistoryCard(
                order,
              ),
            ),
          ),
      ],
    );
  }

  Widget _orderHistoryCard(
    Map<String, dynamic> order,
  ) {
    final id =
        order['id']
                ?.toString() ??
            '';

    final restaurant =
        order[
                    'restaurant_name']
                ?.toString() ??
            'مطعم';

    final driver =
        order['driver_name']
                ?.toString() ??
            'لم يتم تعيين سائق';

    final customer =
        order['customer_name']
                ?.toString() ??
            'زبون';

    final address =
        order[
                    'customer_address']
                ?.toString() ??
            '';

    final status =
        order['status']
                ?.toString() ??
            '';

    final food =
        order[
            'food_amount'];

    return Card(
      child:
          ListTile(
        contentPadding:
            const EdgeInsets
                .all(
          14,
        ),

        leading:
            Container(
          padding:
              const EdgeInsets
                  .all(
            10,
          ),
          decoration:
              BoxDecoration(
            color:
                orange.withOpacity(
              .1,
            ),
            borderRadius:
                BorderRadius.circular(
              12,
            ),
          ),
          child:
              const Icon(
            Icons.receipt_long,
            color:
                orange,
          ),
        ),

        title:
            Text(
          '#$id - $customer',
          style:
              const TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),

        subtitle:
            Padding(
          padding:
              const EdgeInsets
                  .only(
            top: 7,
          ),
          child:
              Column(
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,
            children: [

              Text(
                restaurant,
              ),

              const SizedBox(
                height: 3,
              ),

              Text(
                'السائق: $driver',
              ),

              if (address
                  .isNotEmpty) ...[
                const SizedBox(
                  height: 3,
                ),
                Text(
                  address,
                  maxLines:
                      2,
                  overflow:
                      TextOverflow
                          .ellipsis,
                ),
              ],

              const SizedBox(
                height: 5,
              ),

              Text(
                'قيمة الطلب: ${_money(food)}',
              ),
            ],
          ),
        ),

        trailing:
            _statusBadge(
          status,
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
    final id =
        order['id']
                ?.toString() ??
            '';

    final restaurant =
        order[
                    'restaurant_name']
                ?.toString() ??
            'مطعم';

    final customer =
        order[
                    'customer_name']
                ?.toString() ??
            'زبون';

    final driver =
        order[
                    'driver_name']
                ?.toString() ??
            'بانتظار السائق';

    final status =
        order['status']
                ?.toString() ??
            '';

    return Card(
      child:
          Padding(
        padding:
            const EdgeInsets
                .all(
          15,
        ),
        child:
            Column(
          crossAxisAlignment:
              CrossAxisAlignment
                  .start,
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

                _statusBadge(
                  status,
                ),
              ],
            ),

            const SizedBox(
              height: 12,
            ),

            Text(
              restaurant,
              style:
                  const TextStyle(
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 5,
            ),

            Text(
              'الزبون: $customer',
            ),

            const SizedBox(
              height: 5,
            ),

            Text(
              'السائق: $driver',
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // RESTAURANT DETAILS
  // =========================================================

  void _showRestaurantDetails(
    Map<String, dynamic> restaurant,
  ) {
    showModalBottomSheet(
      context: context,
      showDragHandle:
          true,
      builder: (_) {
        return Padding(
          padding:
              const EdgeInsets
                  .all(
            20,
          ),
          child:
              Column(
            mainAxisSize:
                MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,
            children: [

              Text(
                restaurant[
                            'name']
                        ?.toString() ??
                    'مطعم',
                style:
                    const TextStyle(
                  fontSize:
                      23,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 18,
              ),

              _detailRow(
                Icons.phone,
                'الهاتف',
                restaurant[
                            'phone']
                        ?.toString() ??
                    '-',
              ),

              _detailRow(
                Icons.location_on,
                'العنوان',
                restaurant[
                            'address']
                        ?.toString() ??
                    '-',
              ),

              _detailRow(
                Icons
                    .account_balance_wallet,
                'المبلغ المستحق',
                _money(
                  restaurant[
                      'balance_due'],
                ),
              ),

              _detailRow(
                Icons.circle,
                'الحالة',
                _restaurantStatus(
                  restaurant[
                      'is_active'],
                ),
              ),

              const SizedBox(
                height: 15,
              ),

              SizedBox(
                width:
                    double.infinity,
                child:
                    ElevatedButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                    );

                    _showMessage(
                      'تفعيل وتعطيل المطعم سنربطه بالـ Backend في الخطوة القادمة',
                    );
                  },
                  child:
                      const Text(
                    'إدارة حالة المطعم',
                  ),
                ),
              ),

              const SizedBox(
                height: 10,
              ),
            ],
          ),
        );
      },
    );
  }

  String _restaurantStatus(
    dynamic value,
  ) {
    final active =
        value == true ||
            value
                    ?.toString() ==
                '1';

    return active
        ? 'نشط'
        : 'غير نشط';
  }

  // =========================================================
  // UI HELPERS
  // =========================================================

  Widget _statCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Card(
      child:
          Padding(
        padding:
            const EdgeInsets
                .all(
          15,
        ),
        child:
            Column(
          mainAxisAlignment:
              MainAxisAlignment
                  .center,
          children: [

            Icon(
              icon,
              color:
                  orange,
              size:
                  30,
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              value,
              style:
                  const TextStyle(
                fontSize:
                    24,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 3,
            ),

            Text(
              title,
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                color:
                    Colors.grey,
                fontSize:
                    12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _financeCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Card(
      child:
          Padding(
        padding:
            const EdgeInsets
                .all(
          18,
        ),
        child:
            Row(
          children: [

            Container(
              padding:
                  const EdgeInsets
                      .all(
                12,
              ),
              decoration:
                  BoxDecoration(
                color:
                    orange.withOpacity(
                  .1,
                ),
                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
              ),
              child:
                  Icon(
                icon,
                color:
                    orange,
              ),
            ),

            const SizedBox(
              width: 14,
            ),

            Expanded(
              child:
                  Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [

                  Text(
                    title,
                    style:
                        const TextStyle(
                      color:
                          Colors.grey,
                    ),
                  ),

                  const SizedBox(
                    height: 4,
                  ),

                  Text(
                    value,
                    style:
                        const TextStyle(
                      fontSize:
                          21,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _smallStat({
    required String title,
    required String value,
  }) {
    return Container(
      padding:
          const EdgeInsets
              .all(
        10,
      ),
      decoration:
          BoxDecoration(
        color:
            Colors.grey.shade100,
        borderRadius:
            BorderRadius.circular(
          10,
        ),
      ),
      child:
          Column(
        children: [

          Text(
            value,
            style:
                const TextStyle(
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
              color:
                  Colors.grey,
              fontSize:
                  11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _activeBadge(
    bool active,
  ) {
    return Container(
      padding:
          const EdgeInsets
              .symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration:
          BoxDecoration(
        color:
            active
                ? Colors.green
                    .withOpacity(
                    .1,
                  )
                : Colors.red
                    .withOpacity(
                    .1,
                  ),
        borderRadius:
            BorderRadius.circular(
          20,
        ),
      ),
      child:
          Text(
        active
            ? 'نشط'
            : 'غير نشط',
        style:
            TextStyle(
          color:
              active
                  ? Colors.green
                  : Colors.red,
          fontSize:
              11,
          fontWeight:
              FontWeight.bold,
        ),
      ),
    );
  }

  Widget _onlineBadge(
    bool online,
  ) {
    return Container(
      padding:
          const EdgeInsets
              .symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration:
          BoxDecoration(
        color:
            online
                ? Colors.green
                    .withOpacity(
                    .1,
                  )
                : Colors.grey
                    .withOpacity(
                    .15,
                  ),
        borderRadius:
            BorderRadius.circular(
          20,
        ),
      ),
      child:
          Text(
        online
            ? 'متصل'
            : 'غير متصل',
        style:
            TextStyle(
          color:
              online
                  ? Colors.green
                  : Colors.grey,
          fontSize:
              11,
          fontWeight:
              FontWeight.bold,
        ),
      ),
    );
  }

  Widget _statusBadge(
    String status,
  ) {
    String text;

    switch (status) {
      case 'pending':
        text = 'في الانتظار';
        break;

      case 'dispatching':
        text = 'البحث عن سائق';
        break;

      case 'offered':
        text = 'بانتظار السائق';
        break;

      case 'accepted':
        text = 'مقبول';
        break;

      case 'driver_arrived':
        text = 'السائق وصل';
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
        text = 'تم التوصيل';
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
          const EdgeInsets
              .symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration:
          BoxDecoration(
        color:
            orange.withOpacity(
          .1,
        ),
        borderRadius:
            BorderRadius.circular(
          20,
        ),
      ),
      child:
          Text(
        text,
        style:
            const TextStyle(
          color:
              orange,
          fontSize:
              11,
          fontWeight:
              FontWeight.bold,
        ),
      ),
    );
  }

  Widget _detailRow(
    IconData icon,
    String title,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets
              .only(
        bottom: 13,
      ),
      child:
          Row(
        crossAxisAlignment:
            CrossAxisAlignment
                .start,
        children: [

          Icon(
            icon,
            color:
                orange,
            size:
                20,
          ),

          const SizedBox(
            width: 10,
          ),

          Text(
            '$title: ',
            style:
                const TextStyle(
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          Expanded(
            child:
                Text(
              value,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyCard({
    required IconData icon,
    required String text,
  }) {
    return Card(
      child:
          Padding(
        padding:
            const EdgeInsets
                .all(
          30,
        ),
        child:
            Column(
          children: [

            Icon(
              icon,
              size:
                  50,
              color:
                  Colors.grey,
            ),

            const SizedBox(
              height: 10,
            ),

            Text(
              text,
              style:
                  const TextStyle(
                color:
                    Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
