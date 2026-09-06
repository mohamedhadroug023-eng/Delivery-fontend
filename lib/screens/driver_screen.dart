import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../services/socket_service.dart';
import '../widgets/map_button.dart';

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

  final SocketService _socketService = SocketService();

  StreamSubscription<Position>? _locationSubscription;

  Timer? _offerTimer;
  int offerSecondsRemaining = 0;

  @override
  void initState() {
    super.initState();

    loadData();
    _initializeSocket();
  }

  // =========================================================
  // SOCKET
  // =========================================================

  Future<void> _initializeSocket() async {
    try {
      final token = await AuthService.getToken();

      if (token == null || token.isEmpty) {
        return;
      }

      _socketService.connect(
        serverUrl: 'http://localhost:3000',
        token: token,
        role: 'driver',
      );

      _socketService.on(
        'order_offer',
        _handleOrderOffer,
      );
    } catch (error) {
      debugPrint(
        'Socket initialization error: $error',
      );
    }
  }

  // =========================================================
  // RECEIVE ORDER
  // =========================================================

  void _handleOrderOffer(dynamic data) {
    try {
      if (data == null || data is! Map) {
        return;
      }

      final payload =
          Map<String, dynamic>.from(data);

      final orderId =
          payload['order_id'];

      if (orderId == null) {
        return;
      }

      final order = <String, dynamic>{
        'id': orderId,
        'restaurant_id':
            payload['restaurant_id'],
        'restaurant_name':
            payload['restaurant_name'],
        'restaurant_address':
            payload['restaurant_address'],
        'restaurant_latitude':
            payload['restaurant_latitude'],
        'restaurant_longitude':
            payload['restaurant_longitude'],
        'customer_name':
            payload['customer_name'],
        'customer_phone':
            payload['customer_phone'],
        'customer_address':
            payload['customer_address'],
        'customer_latitude':
            payload['customer_latitude'],
        'customer_longitude':
            payload['customer_longitude'],
        'food_amount':
            payload['food_amount'],
        'driver_fee':
            payload['driver_fee'],
        'status': 'offered',
        'offer_expires_at':
            payload['expires_at'],
      };

      if (!mounted) return;

      setState(() {
        orders.removeWhere(
          (existingOrder) =>
              existingOrder['id']
                  ?.toString() ==
              orderId.toString(),
        );

        orders.insert(
          0,
          order,
        );
      });

      _showNewOrderNotification();

      _startOfferCountdown(
        order['offer_expires_at'],
      );
    } catch (error) {
      debugPrint(
        'Order offer handling error: $error',
      );
    }
  }

  // =========================================================
  // OFFER COUNTDOWN
  // =========================================================

  void _startOfferCountdown(
    dynamic expiresAt,
  ) {
    _offerTimer?.cancel();

    final expires =
        DateTime.tryParse(
      expiresAt?.toString() ?? '',
    );

    if (expires == null) {
      return;
    }

    void updateCountdown() {
      final remaining =
          expires
              .difference(DateTime.now())
              .inSeconds;

      if (!mounted) return;

      if (remaining <= 0) {
        _offerTimer?.cancel();

        setState(() {
          offerSecondsRemaining = 0;

          orders.removeWhere(
            (order) =>
                order['status'] ==
                'offered',
          );
        });

        return;
      }

      setState(() {
        offerSecondsRemaining =
            remaining;
      });
    }

    updateCountdown();

    _offerTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => updateCountdown(),
    );
  }

  // =========================================================
  // NOTIFICATION
  // =========================================================

  void _showNewOrderNotification() {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.delivery_dining,
                color: Colors.white,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  '🚨 وصل طلب توصيل جديد',
                ),
              ),
            ],
          ),
          duration:
              Duration(seconds: 4),
          backgroundColor:
              orange,
        ),
      );
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
          await ApiService.get(
        '/driver/profile',
      );

      final ordersResponse =
          await ApiService.get(
        '/driver/orders',
      );

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
              Map<String, dynamic>.from(
            order,
          ),
        ),
      );

      final serverOnline =
          profileData['is_online'] == true ||
          profileData['is_online'] == 1;

      setState(() {
        driver = profileData;
        orders = ordersData;
        online = serverOnline;
        loading = false;
      });

      if (serverOnline) {
        await _startLocationTracking();
      }
    } catch (error) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      _showError(error);
    }
  }

  // =========================================================
  // GPS
  // =========================================================

  Future<void> _startLocationTracking() async {
    try {
      await _locationSubscription?.cancel();

      _locationSubscription = null;

      final allowed =
          await LocationService.checkPermission();

      if (!allowed) {
        if (mounted) {
          _showMessage(
            'يرجى السماح للتطبيق باستخدام الموقع حتى تتمكن من استقبال الطلبات القريبة',
          );
        }

        return;
      }

      final position =
          await LocationService.getCurrentLocation();

      if (position != null) {
        await _sendLocation(position);
      }

      _locationSubscription =
          LocationService.locationStream().listen(
        (Position position) async {
          if (!online) return;

          await _sendLocation(position);
        },
        onError: (error) {
          debugPrint(
            'GPS stream error: $error',
          );
        },
      );
    } catch (error) {
      debugPrint(
        'Start GPS error: $error',
      );
    }
  }

  Future<void> _sendLocation(
    Position position,
  ) async {
    if (!online) return;

    try {
      await ApiService.patch(
        '/driver/location',
        {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'accuracy': position.accuracy,
        },
      );

      debugPrint(
        'GPS updated: '
        '${position.latitude}, '
        '${position.longitude}',
      );
    } catch (error) {
      debugPrint(
        'Location update error: $error',
      );
    }
  }

  Future<void> _stopLocationTracking() async {
    await _locationSubscription?.cancel();

    _locationSubscription = null;
  }

  // =========================================================
  // ONLINE STATUS
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

      if (value) {
        await _startLocationTracking();
      } else {
        await _stopLocationTracking();
      }

      if (!mounted) return;

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
        order['created_at']
                ?.toString() ??
            '',
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
        order['created_at']
                ?.toString() ??
            '',
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
  // ACCEPT
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

      _offerTimer?.cancel();

      setState(() {
        offerSecondsRemaining = 0;
      });

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
  // REJECT
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

      _offerTimer?.cancel();

      setState(() {
        offerSecondsRemaining = 0;
      });

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
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    _offerTimer?.cancel();

    _locationSubscription?.cancel();

    _socketService.disconnect();

    super.dispose();
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
  // STAT
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
  // OFFER CARD
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
                _statusBadge('offered'),
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
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.all(12),
              decoration:
                  BoxDecoration(
                color:
                    orange.withOpacity(.1),
                borderRadius:
                    BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.timer,
                    color: orange,
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  Text(
                    'الوقت المتبقي: '
                    '$offerSecondsRemaining ثانية',
                    style:
                        const TextStyle(
                      color: orange,
                      fontWeight:
                          FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
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
                  'أجرة السائق: '
                  '${fee.toStringAsFixed(3)} د.ت',
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
                                Icons.check,
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
  // ACCEPTED ORDER
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

    final restaurantLatitude =
        double.tryParse(
      order['restaurant_latitude']
              ?.toString() ??
          '',
    );

    final restaurantLongitude =
        double.tryParse(
      order['restaurant_longitude']
              ?.toString() ??
          '',
    );

    final customerLatitude =
        double.tryParse(
      order['customer_latitude']
              ?.toString() ??
          '',
    );

    final customerLongitude =
        double.tryParse(
      order['customer_longitude']
              ?.toString() ??
          '',
    );

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
                _statusBadge(order['status']?.toString() ?? ''),
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
                  'أجرة السائق: '
                  '${fee.toStringAsFixed(3)} د.ت',
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
            Row(
              children: [
                Expanded(
                  child: MapButton(
                    title: 'إلى المطعم',
                    icon:
                        Icons.restaurant,
                    latitude:
                        restaurantLatitude,
                    longitude:
                        restaurantLongitude,
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: MapButton(
                    title: 'إلى الزبون',
                    icon:
                        Icons.person_pin_circle,
                    latitude:
                        customerLatitude,
                    longitude:
                        customerLongitude,
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
  // ORDERS HISTORY
  // =========================================================

  Widget _ordersHistory() {
    if (orders.isEmpty) {
      return const Card(
        child: ListTile(
          leading: Icon(
            Icons.history,
            color: orange,
          ),
          title: Text(
            'لا توجد طلبات',
          ),
          subtitle: Text(
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
              'أجرة السائق: '
              '${fee.toStringAsFixed(3)} د.ت',
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
  // MESSAGES
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
