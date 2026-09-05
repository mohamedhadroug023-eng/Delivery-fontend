import 'dart:async';

import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/auth_service.dart';

import 'role_selection_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  bool loading = true;
  bool refreshing = false;

  Map<String, dynamic> statistics = {};

  List<dynamic> activeOrders = [];
  List<dynamic> restaurants = [];
  List<dynamic> drivers = [];
  List<dynamic> allOrders = [];

  Timer? _refreshTimer;

  int selectedPage = 0;

  @override
  void initState() {
    super.initState();

    loadAllData();

    _refreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) {
        if (!loading) {
          loadAllData(
            silent: true,
          );
        }
      },
    );
  }

  /* =========================================================
     LOAD ALL DATA
  ========================================================= */

  Future<void> loadAllData({
    bool silent = false,
  }) async {
    if (!silent && mounted) {
      setState(() {
        loading = true;
      });
    }

    try {
      final dashboard =
          await ApiService.get(
        '/admin/dashboard',
      );

      final restaurantResponse =
          await ApiService.get(
        '/admin/restaurants',
      );

      final driverResponse =
          await ApiService.get(
        '/admin/drivers',
      );

      final orderResponse =
          await ApiService.get(
        '/admin/orders',
      );

      if (!mounted) return;

      setState(() {
        statistics =
            Map<String, dynamic>.from(
          dashboard['statistics'] ??
              {},
        );

        activeOrders =
            List<dynamic>.from(
          dashboard['active_orders'] ??
              [],
        );

        restaurants =
            List<dynamic>.from(
          restaurantResponse[
                  'restaurants'] ??
              [],
        );

        drivers =
            List<dynamic>.from(
          driverResponse['drivers'] ??
              [],
        );

        allOrders =
            List<dynamic>.from(
          orderResponse['orders'] ??
              [],
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

  /* =========================================================
     REFRESH
  ========================================================= */

  Future<void> refreshData() async {
    if (refreshing) return;

    setState(() {
      refreshing = true;
    });

    await loadAllData(
      silent: true,
    );
  }

  /* =========================================================
     RESTAURANT STATUS
  ========================================================= */

  Future<void> updateRestaurantStatus(
    Map<String, dynamic> restaurant,
  ) async {
    final id =
        int.tryParse(
      restaurant['id'].toString(),
    );

    if (id == null) {
      showMessage(
        'معرّف المطعم غير صالح',
        isError: true,
      );
      return;
    }

    final currentStatus =
        restaurant['is_active'] == true ||
        restaurant['is_active'] == 1;

    final newStatus = !currentStatus;

    if (!newStatus) {
      final confirmed =
          await showConfirmDialog(
        title: 'تعطيل المطعم',
        message:
            'هل تريد تعطيل هذا المطعم؟\n\n'
            'سيتم أيضًا تعطيل حساب الدخول الخاص به.',
        confirmText: 'تعطيل',
      );

      if (!confirmed) return;
    }

    try {
      showLoadingDialog();

      await ApiService.patch(
        '/admin/restaurants/$id/status',
        {
          'is_active': newStatus,
        },
      );

      if (!mounted) return;

      Navigator.of(context).pop();

      showMessage(
        newStatus
            ? 'تم تفعيل المطعم بنجاح'
            : 'تم تعطيل المطعم بنجاح',
      );

      await loadAllData(
        silent: true,
      );
    } catch (error) {
      if (!mounted) return;

      Navigator.of(context).pop();

      showMessage(
        _cleanError(error),
        isError: true,
      );
    }
  }

  /* =========================================================
     DRIVER STATUS
  ========================================================= */

  Future<void> updateDriverStatus(
    Map<String, dynamic> driver,
  ) async {
    final id =
        int.tryParse(
      driver['id'].toString(),
    );

    if (id == null) {
      showMessage(
        'معرّف السائق غير صالح',
        isError: true,
      );
      return;
    }

    final currentStatus =
        driver['is_active'] == true ||
        driver['is_active'] == 1;

    final newStatus = !currentStatus;

    if (!newStatus) {
      final confirmed =
          await showConfirmDialog(
        title: 'تعطيل السائق',
        message:
            'هل تريد تعطيل هذا السائق؟\n\n'
            'سيتم إخراجه من حالة الاتصال تلقائيًا.',
        confirmText: 'تعطيل',
      );

      if (!confirmed) return;
    }

    try {
      showLoadingDialog();

      await ApiService.patch(
        '/admin/drivers/$id/status',
        {
          'is_active': newStatus,
        },
      );

      if (!mounted) return;

      Navigator.of(context).pop();

      showMessage(
        newStatus
            ? 'تم تفعيل السائق بنجاح'
            : 'تم تعطيل السائق بنجاح',
      );

      await loadAllData(
        silent: true,
      );
    } catch (error) {
      if (!mounted) return;

      Navigator.of(context).pop();

      showMessage(
        _cleanError(error),
        isError: true,
      );
    }
  }

  /* =========================================================
     LOGOUT
  ========================================================= */

  Future<void> logout() async {
    final confirmed =
        await showConfirmDialog(
      title: 'تسجيل الخروج',
      message:
          'هل تريد تسجيل الخروج من لوحة الإدارة؟',
      confirmText: 'خروج',
    );

    if (!confirmed) return;

    _refreshTimer?.cancel();

    await AuthService.logout();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) =>
            const RoleSelectionScreen(),
      ),
      (route) => false,
    );
  }

  /* =========================================================
     HELPERS
  ========================================================= */

  String _cleanError(Object error) {
    String message = error.toString();

    if (message.startsWith(
      'Exception: ',
    )) {
      message =
          message.substring(11);
    }

    return message;
  }

  void showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? Colors.red : null,
      ),
    );
  }

  Future<bool> showConfirmDialog({
    required String title,
    required String message,
    required String confirmText,
  }) async {
    final result =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(false);
              },
              child: const Text(
                'إلغاء',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(true);
              },
              child: Text(
                confirmText,
              ),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  void showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }

  /* =========================================================
     FORMAT MONEY
  ========================================================= */

  String money(dynamic value) {
    final number =
        double.tryParse(
              value?.toString() ?? '',
            ) ??
            0;

    return '${number.toStringAsFixed(3)} د.ت';
  }

  /* =========================================================
     STATUS
  ========================================================= */

  String statusText(
    dynamic status,
  ) {
    switch (status?.toString()) {
      case 'pending':
        return 'في الانتظار';

      case 'dispatching':
        return 'جاري البحث عن سائق';

      case 'offered':
        return 'عرض عند السائق';

      case 'accepted':
        return 'تم القبول';

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
        return status?.toString() ??
            'غير معروف';
    }
  }

  Color statusColor(
    dynamic status,
  ) {
    switch (status?.toString()) {
      case 'delivered':
        return Colors.green;

      case 'cancelled':
      case 'failed':
        return Colors.red;

      case 'offered':
      case 'dispatching':
        return Colors.orange;

      case 'accepted':
      case 'driver_arrived':
      case 'picked_up':
      case 'delivering':
        return Colors.blue;

      default:
        return Colors.grey;
    }
  }

  /* =========================================================
     DRAWER
  ========================================================= */

  Widget buildDrawer() {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.all(24),
              child: const Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 32,
                    child: Icon(
                      Icons.admin_panel_settings,
                      size: 35,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'HADROUG DELIVERY',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'لوحة الإدارة',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(),

            drawerItem(
              icon: Icons.dashboard,
              title: 'لوحة التحكم',
              index: 0,
            ),

            drawerItem(
              icon: Icons.restaurant,
              title: 'إدارة المطاعم',
              index: 1,
            ),

            drawerItem(
              icon: Icons.delivery_dining,
              title: 'إدارة السائقين',
              index: 2,
            ),

            drawerItem(
              icon: Icons.receipt_long,
              title: 'جميع الطلبات',
              index: 3,
            ),

            const Spacer(),

            const Divider(),

            ListTile(
              leading: const Icon(
                Icons.refresh,
              ),
              title: const Text(
                'تحديث البيانات',
              ),
              onTap: () {
                Navigator.of(
                  context,
                ).pop();

                refreshData();
              },
            ),

            ListTile(
              leading: const Icon(
                Icons.logout,
                color: Colors.red,
              ),
              title: const Text(
                'تسجيل الخروج',
                style: TextStyle(
                  color: Colors.red,
                ),
              ),
              onTap: () {
                Navigator.of(
                  context,
                ).pop();

                logout();
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

  Widget drawerItem({
    required IconData icon,
    required String title,
    required int index,
  }) {
    final selected =
        selectedPage == index;

    return ListTile(
      selected: selected,
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        setState(() {
          selectedPage = index;
        });

        Navigator.of(context).pop();
      },
    );
  }

  /* =========================================================
     DASHBOARD
  ========================================================= */

  Widget buildDashboard() {
    return RefreshIndicator(
      onRefresh: refreshData,
      child: ListView(
        padding:
            const EdgeInsets.all(16),
        children: [
          const Text(
            'لوحة التحكم',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'نظرة مباشرة على نظام HADROUG DELIVERY',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 20),

          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics:
                const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.45,
            children: [
              statCard(
                title: 'المطاعم',
                value:
                    '${statistics['restaurants'] ?? 0}',
                icon: Icons.restaurant,
              ),
              statCard(
                title: 'السائقون',
                value:
                    '${statistics['drivers'] ?? 0}',
                icon:
                    Icons.delivery_dining,
              ),
              statCard(
                title: 'السائقون المتصلون',
                value:
                    '${statistics['online_drivers'] ?? 0}',
                icon: Icons.wifi,
              ),
              statCard(
                title: 'طلبات اليوم',
                value:
                    '${statistics['today_orders'] ?? 0}',
                icon:
                    Icons.shopping_bag,
              ),
              statCard(
                title: 'إيرادات اليوم',
                value: money(
                  statistics[
                      'today_revenue'],
                ),
                icon:
                    Icons.account_balance_wallet,
              ),
              statCard(
                title: 'المستحقات',
                value: money(
                  statistics[
                      'total_balance_due'],
                ),
                icon:
                    Icons.payments,
              ),
            ],
          ),

          const SizedBox(height: 25),

          sectionTitle(
            'الطلبات النشطة',
            activeOrders.length,
          ),

          const SizedBox(height: 10),

          if (activeOrders.isEmpty)
            emptyCard(
              icon:
                  Icons.local_shipping_outlined,
              text:
                  'لا توجد طلبات نشطة حاليًا',
            )
          else
            ...activeOrders.map(
              (order) =>
                  orderCard(order),
            ),
        ],
      ),
    );
  }

  /* =========================================================
     RESTAURANTS PAGE
  ========================================================= */

  Widget buildRestaurantsPage() {
    return RefreshIndicator(
      onRefresh: refreshData,
      child: ListView(
        padding:
            const EdgeInsets.all(16),
        children: [
          const Text(
            'إدارة المطاعم',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            '${restaurants.length} مطعم',
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 18),

          if (restaurants.isEmpty)
            emptyCard(
              icon: Icons.restaurant,
              text:
                  'لا توجد مطاعم',
            )
          else
            ...restaurants.map(
              (restaurant) =>
                  restaurantCard(
                Map<String, dynamic>.from(
                  restaurant,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /* =========================================================
     DRIVERS PAGE
  ========================================================= */

  Widget buildDriversPage() {
    return RefreshIndicator(
      onRefresh: refreshData,
      child: ListView(
        padding:
            const EdgeInsets.all(16),
        children: [
          const Text(
            'إدارة السائقين',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            '${drivers.length} سائق',
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 18),

          if (drivers.isEmpty)
            emptyCard(
              icon:
                  Icons.delivery_dining,
              text:
                  'لا توجد بيانات سائقين',
            )
          else
            ...drivers.map(
              (driver) =>
                  driverCard(
                Map<String, dynamic>.from(
                  driver,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /* =========================================================
     ORDERS PAGE
  ========================================================= */

  Widget buildOrdersPage() {
    return RefreshIndicator(
      onRefresh: refreshData,
      child: ListView(
        padding:
            const EdgeInsets.all(16),
        children: [
          const Text(
            'جميع الطلبات',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            '${allOrders.length} طلب',
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 18),

          if (allOrders.isEmpty)
            emptyCard(
              icon:
                  Icons.receipt_long,
              text:
                  'لا توجد طلبات',
            )
          else
            ...allOrders.map(
              (order) =>
                  orderCard(order),
            ),
        ],
      ),
    );
  }

  /* =========================================================
     STAT CARD
  ========================================================= */

  Widget statCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding:
            const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 28,
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              maxLines: 1,
              overflow:
                  TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /* =========================================================
     RESTAURANT CARD
  ========================================================= */

  Widget restaurantCard(
    Map<String, dynamic> restaurant,
  ) {
    final active =
        restaurant['is_active'] == true ||
            restaurant['is_active'] == 1;

    final name =
        restaurant['name']?.toString() ??
            'مطعم';

    final phone =
        restaurant['phone']?.toString() ??
            'غير متوفر';

    final address =
        restaurant['address']?.toString() ??
            'غير متوفر';

    final balance =
        restaurant['balance_due'];

    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  child: Icon(
                    Icons.restaurant,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        name,
                        style:
                            const TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      Text(
                        phone,
                        style:
                            const TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

                statusBadge(
                  active
                      ? 'نشط'
                      : 'متوقف',
                  active
                      ? Colors.green
                      : Colors.red,
                ),
              ],
            ),

            const SizedBox(height: 14),

            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    address,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                const Icon(
                  Icons.payments_outlined,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Text(
                  'المستحق: ${money(balance)}',
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child:
                      OutlinedButton.icon(
                    onPressed: () {
                      showRestaurantDetails(
                        restaurant,
                      );
                    },
                    icon: const Icon(
                      Icons.info_outline,
                    ),
                    label:
                        const Text(
                      'التفاصيل',
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child:
                      ElevatedButton.icon(
                    onPressed: () =>
                        updateRestaurantStatus(
                      restaurant,
                    ),
                    icon: Icon(
                      active
                          ? Icons.block
                          : Icons.check_circle,
                    ),
                    label: Text(
                      active
                          ? 'تعطيل'
                          : 'تفعيل',
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

  /* =========================================================
     DRIVER CARD
  ========================================================= */

  Widget driverCard(
    Map<String, dynamic> driver,
  ) {
    final active =
        driver['is_active'] == true ||
            driver['is_active'] == 1;

    final online =
        driver['is_online'] == true ||
            driver['is_online'] == 1;

    final available =
        driver['is_available'] == true ||
            driver['is_available'] == 1;

    final name =
        driver['full_name']?.toString() ??
            'سائق';

    final phone =
        driver['phone']?.toString() ??
            'غير متوفر';

    final vehicle =
        driver['vehicle_type']?.toString() ??
            'غير محدد';

    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  child: Icon(
                    Icons.delivery_dining,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style:
                            const TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      Text(
                        phone,
                        style:
                            const TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

                statusBadge(
                  active
                      ? 'نشط'
                      : 'متوقف',
                  active
                      ? Colors.green
                      : Colors.red,
                ),
              ],
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: infoBox(
                    icon: Icons.two_wheeler,
                    title: 'المركبة',
                    value: vehicle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: infoBox(
                    icon: Icons.wifi,
                    title: 'الاتصال',
                    value: online
                        ? 'Online'
                        : 'Offline',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: infoBox(
                    icon: Icons.check_circle,
                    title: 'متاح',
                    value: available
                        ? 'نعم'
                        : 'لا',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: infoBox(
                    icon:
                        Icons.shopping_bag,
                    title: 'طلبات مكتملة',
                    value:
                        '${driver['total_completed_orders'] ?? 0}',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child:
                      ElevatedButton.icon(
                    onPressed: () =>
                        updateDriverStatus(
                      driver,
                    ),
                    icon: Icon(
                      active
                          ? Icons.block
                          : Icons.check_circle,
                    ),
                    label: Text(
                      active
                          ? 'تعطيل السائق'
                          : 'تفعيل السائق',
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

  /* =========================================================
     ORDER CARD
  ========================================================= */

  Widget orderCard(
    dynamic rawOrder,
  ) {
    final order =
        Map<String, dynamic>.from(
      rawOrder,
    );

    final status =
        order['status'];

    final restaurant =
        order['restaurant_name']
                ?.toString() ??
            'مطعم غير معروف';

    final driver =
        order['driver_name']
                ?.toString() ??
            'لم يتم تعيين سائق';

    final customer =
        order['customer_name']
                ?.toString() ??
            'زبون';

    final address =
        order['customer_address']
                ?.toString() ??
            'العنوان غير متوفر';

    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '#${order['id'] ?? '-'}',
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.bold,
                    fontSize: 17,
                  ),
                ),

                const Spacer(),

                statusBadge(
                  statusText(status),
                  statusColor(status),
                ),
              ],
            ),

            const Divider(),

            infoRow(
              Icons.restaurant,
              'المطعم',
              restaurant,
            ),

            infoRow(
              Icons.person,
              'الزبون',
              customer,
            ),

            infoRow(
              Icons.delivery_dining,
              'السائق',
              driver,
            ),

            infoRow(
              Icons.location_on_outlined,
              'العنوان',
              address,
            ),

            const Divider(),

            Row(
              children: [
                Expanded(
                  child: Text(
                    'قيمة الطعام\n${money(order['food_amount'])}',
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ),

                Expanded(
                  child: Text(
                    'أجرة السائق\n${money(order['driver_fee'])}',
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ),

                Expanded(
                  child: Text(
                    'رسوم HADROUG\n${money(order['hadroug_fee'])}',
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.w600,
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

  /* =========================================================
     RESTAURANT DETAILS
  ========================================================= */

  void showRestaurantDetails(
    Map<String, dynamic> restaurant,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        final active =
            restaurant['is_active'] ==
                    true ||
                restaurant['is_active'] ==
                    1;

        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.all(20),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  restaurant['name']
                          ?.toString() ??
                      'مطعم',
                  style:
                      const TextStyle(
                    fontSize: 23,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 18),

                infoRow(
                  Icons.phone,
                  'الهاتف',
                  restaurant['phone']
                          ?.toString() ??
                      'غير متوفر',
                ),

                infoRow(
                  Icons.email,
                  'البريد',
                  restaurant['email']
                          ?.toString() ??
                      'غير متوفر',
                ),

                infoRow(
                  Icons.location_on,
                  'العنوان',
                  restaurant['address']
                          ?.toString() ??
                      'غير متوفر',
                ),

                infoRow(
                  Icons.payments,
                  'الرصيد المستحق',
                  money(
                    restaurant[
                        'balance_due'],
                  ),
                ),

                const SizedBox(height: 14),

                statusBadge(
                  active
                      ? 'الحساب نشط'
                      : 'الحساب متوقف',
                  active
                      ? Colors.green
                      : Colors.red,
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  /* =========================================================
     SMALL WIDGETS
  ========================================================= */

  Widget sectionTitle(
    String title,
    int count,
  ) {
    return Row(
      children: [
        Text(
          title,
          style:
              const TextStyle(
            fontSize: 20,
            fontWeight:
                FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        CircleAvatar(
          radius: 12,
          child: Text(
            '$count',
            style:
                const TextStyle(
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget emptyCard({
    required IconData icon,
    required String text,
  }) {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(35),
        child: Column(
          children: [
            Icon(
              icon,
              size: 50,
              color: Colors.grey,
            ),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign:
                  TextAlign.center,
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

  Widget statusBadge(
    String text,
    Color color,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration:
          BoxDecoration(
        color:
            color.withOpacity(0.12),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight:
              FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget infoRow(
    IconData icon,
    String title,
    String value,
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
            size: 19,
          ),
          const SizedBox(width: 8),
          Text(
            '$title: ',
            style:
                const TextStyle(
              fontWeight:
                  FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget infoBox({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding:
          const EdgeInsets.all(10),
      decoration:
          BoxDecoration(
        borderRadius:
            BorderRadius.circular(10),
        border: Border.all(
          color:
              Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style:
                      const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /* =========================================================
     BUILD
  ========================================================= */

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
              padding:
                  EdgeInsets.all(16),
              child:
                  SizedBox(
                width: 18,
                height: 18,
                child:
                    CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              ),
            )
          else
            IconButton(
              onPressed: refreshData,
              icon: const Icon(
                Icons.refresh,
              ),
            ),
        ],
      ),

      drawer: buildDrawer(),

      body: loading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : IndexedStack(
              index: selectedPage,
              children: [
                buildDashboard(),
                buildRestaurantsPage(),
                buildDriversPage(),
                buildOrdersPage(),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
