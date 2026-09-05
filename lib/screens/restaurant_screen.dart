import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/api_service.dart';

class RestaurantScreen extends StatefulWidget {
  const RestaurantScreen({super.key});

  @override
  State<RestaurantScreen> createState() =>
      _RestaurantScreenState();
}

class _RestaurantScreenState
    extends State<RestaurantScreen> {
  static const orange = Color(0xFFFF6B00);

  bool loading = true;
  bool creatingOrder = false;
  bool verifyingOtp = false;

  Map<String, dynamic>? restaurant;
  List<Map<String, dynamic>> orders = [];

  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();

    loadData();

    _refreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) {
        if (!loading &&
            !creatingOrder &&
            !verifyingOtp) {
          loadData(
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
  // LOAD DATA
  // =========================================================

  Future<void> loadData({
    bool showLoading = true,
  }) async {
    if (showLoading && mounted) {
      setState(() {
        loading = true;
      });
    }

    try {
      final profileResponse =
          await ApiService.get(
        '/restaurant/profile',
      );

      final ordersResponse =
          await ApiService.get(
        '/restaurant/orders',
      );

      if (!mounted) return;

      final profileData =
          Map<String, dynamic>.from(
        profileResponse['restaurant'] ??
            {},
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

      if (showLoading) {
        _showError(error);
      }
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
      _showMessage(
        'يرجى إدخال جميع البيانات المطلوبة',
      );
      return;
    }

    final lat =
        double.tryParse(latitude.trim());

    final lng =
        double.tryParse(longitude.trim());

    final amount =
        double.tryParse(
      foodAmount.trim(),
    );

    final fee = double.tryParse(
      driverFee.trim().isEmpty
          ? '0'
          : driverFee.trim(),
    );

    if (lat == null ||
        lng == null ||
        amount == null ||
        fee == null) {
      _showMessage(
        'يرجى التأكد من صحة الأرقام',
      );
      return;
    }

    if (lat < -90 ||
        lat > 90 ||
        lng < -180 ||
        lng > 180) {
      _showMessage(
        'إحداثيات الموقع غير صحيحة',
      );
      return;
    }

    if (amount <= 0 ||
        fee < 0) {
      _showMessage(
        'قيمة الطلب أو أجرة السائق غير صحيحة',
      );
      return;
    }

    setState(() {
      creatingOrder = true;
    });

    try {
      final response =
          await ApiService.post(
        '/orders',
        {
          'customer_name':
              customerName.trim(),
          'customer_phone':
              customerPhone.trim(),
          'customer_address':
              customerAddress.trim(),
          'customer_latitude':
              lat,
          'customer_longitude':
              lng,
          'food_amount':
              amount,
          'driver_fee':
              fee,
        },
      );

      if (!mounted) return;

      if (response['success'] != true) {
        throw Exception(
          response['message'] ??
              'فشل إنشاء الطلب',
        );
      }

      // إغلاق نافذة إنشاء الطلب
      Navigator.of(context).pop();

      _showMessage(
        'تم نشر الطلب بنجاح 🚀',
      );

      await loadData(
        showLoading: false,
      );
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
  // VERIFY PICKUP OTP
  // =========================================================

  Future<bool> verifyPickupOtp({
    required int orderId,
    required String otp,
  }) async {
    final cleanOtp =
        otp.trim();

    if (!RegExp(
      r'^\d{4}$',
    ).hasMatch(cleanOtp)) {
      _showMessage(
        'رمز OTP يجب أن يتكون من 4 أرقام',
      );

      return false;
    }

    setState(() {
      verifyingOtp = true;
    });

    try {
      final response =
          await ApiService.post(
        '/restaurant/orders/verify-pickup',
        {
          'order_id':
              orderId,
          'otp':
              cleanOtp,
        },
      );

      if (!mounted) return false;

      if (response['success'] != true) {
        throw Exception(
          response['message'] ??
              'فشل تأكيد الاستلام',
        );
      }

      _showMessage(
        'تم تأكيد استلام الطلب بنجاح ✅',
      );

      await loadData(
        showLoading: false,
      );

      return true;
    } catch (error) {
      if (!mounted) return false;

      _showError(error);

      return false;
    } finally {
      if (mounted) {
        setState(() {
          verifyingOtp = false;
        });
      }
    }
  }

  // =========================================================
  // OPEN GOOGLE MAPS
  // =========================================================

  Future<void> _openMaps({
    required double? latitude,
    required double? longitude,
  }) async {
    if (latitude == null ||
        longitude == null) {
      _showMessage(
        'إحداثيات الموقع غير متوفرة',
      );
      return;
    }

    final uri = Uri.parse(
      'https://www.google.com/maps/dir/'
      '?api=1'
      '&destination=$latitude,$longitude'
      '&travelmode=driving',
    );

    try {
      final opened =
          await launchUrl(
        uri,
        mode:
            LaunchMode.externalApplication,
      );

      if (!opened && mounted) {
        _showMessage(
          'تعذر فتح Google Maps',
        );
      }
    } catch (_) {
      if (mounted) {
        _showMessage(
          'حدث خطأ أثناء فتح الخريطة',
        );
      }
    }
  }

  // =========================================================
  // HELPERS
  // =========================================================

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

  bool _isActiveOrder(
    Map<String, dynamic> order,
  ) {
    final status =
        order['status']
            ?.toString();

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
    final now =
        DateTime.now();

    return orders.where(
      (order) {
        final createdAt =
            DateTime.tryParse(
          order['created_at']
                  ?.toString() ??
              '',
        );

        if (createdAt == null) {
          return false;
        }

        return createdAt.year ==
                now.year &&
            createdAt.month ==
                now.month &&
            createdAt.day ==
                now.day;
      },
    ).length;
  }

  int get activeOrdersCount {
    return orders
        .where(
          _isActiveOrder,
        )
        .length;
  }

  List<Map<String, dynamic>>
      get activeOrders {
    return orders
        .where(
          _isActiveOrder,
        )
        .toList();
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
            const Text(
          'لوحة المطعم',
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
                        loadData(),
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
      body: loading
          ? const Center(
              child:
                  CircularProgressIndicator(
                color: orange,
              ),
            )
          : RefreshIndicator(
              onRefresh: () =>
                  loadData(
                showLoading:
                    false,
              ),
              child:
                  SingleChildScrollView(
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

                    Text(
                      restaurant?[
                                  'name']
                              ?.toString() ??
                          'المطعم',
                      style:
                          const TextStyle(
                        fontSize: 25,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 5,
                    ),

                    const Text(
                      'ملخص اليوم',
                      style:
                          TextStyle(
                        color:
                            Colors.grey,
                      ),
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    Row(
                      children: [
                        Expanded(
                          child:
                              _statCard(
                            icon: Icons
                                .receipt_long,
                            title:
                                'طلبات اليوم',
                            value:
                                todayOrdersCount
                                    .toString(),
                          ),
                        ),
                        const SizedBox(
                          width: 12,
                        ),
                        Expanded(
                          child:
                              _statCard(
                            icon: Icons
                                .local_shipping,
                            title:
                                'طلبات نشطة',
                            value:
                                activeOrdersCount
                                    .toString(),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    _moneyCard(),

                    const SizedBox(
                      height: 25,
                    ),

                    SizedBox(
                      width:
                          double.infinity,
                      height: 58,
                      child:
                          ElevatedButton
                              .icon(
                        onPressed:
                            creatingOrder
                                ? null
                                : () {
                                    _showNewOrderDialog(
                                      context,
                                    );
                                  },
                        icon:
                            const Icon(
                          Icons.add,
                        ),
                        label:
                            const Text(
                          'إنشاء طلب توصيل',
                          style:
                              TextStyle(
                            fontSize:
                                17,
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 28,
                    ),

                    const Text(
                      'الطلبات الحالية',
                      style:
                          TextStyle(
                        fontSize: 21,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    if (activeOrders
                        .isEmpty)
                      _emptyOrdersCard()
                    else
                      ...activeOrders.map(
                        (order) =>
                            Padding(
                          padding:
                              const EdgeInsets
                                  .only(
                            bottom: 12,
                          ),
                          child:
                              _orderCard(
                            order,
                          ),
                        ),
                      ),

                    const SizedBox(
                      height: 15,
                    ),

                    const Text(
                      'إجراءات سريعة',
                      style:
                          TextStyle(
                        fontSize: 21,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    Row(
                      children: [
                        Expanded(
                          child:
                              _quickAction(
                            icon: Icons
                                .history,
                            title:
                                'سجل الطلبات',
                            onTap:
                                _showHistoryDialog,
                          ),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        Expanded(
                          child:
                              _quickAction(
                            icon: Icons
                                .bar_chart,
                            title:
                                'التقارير',
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
        padding:
            const EdgeInsets.all(
          16,
        ),
        child:
            Column(
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
      ),
    );
  }

  // =========================================================
  // MONEY CARD
  // =========================================================

  Widget _moneyCard() {
    final balance =
        restaurant?[
            'balance_due'];

    final balanceNumber =
        double.tryParse(
              balance
                      ?.toString() ??
                  '',
            ) ??
            0;

    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(
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
                  const Icon(
                Icons
                    .account_balance_wallet,
                color: orange,
              ),
            ),
            const SizedBox(
              width: 15,
            ),
            Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                const Text(
                  'المبلغ المستحق',
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
                  '${balanceNumber.toStringAsFixed(3)} د.ت',
                  style:
                      const TextStyle(
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
        padding:
            const EdgeInsets.all(
          25,
        ),
        child:
            Center(
          child:
              Column(
            children: const [
              Icon(
                Icons
                    .inbox_outlined,
                size: 50,
                color:
                    Colors.grey,
              ),
              SizedBox(
                height: 10,
              ),
              Text(
                'لا توجد طلبات نشطة حاليًا',
                style:
                    TextStyle(
                  color:
                      Colors.grey,
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
        int.tryParse(
              order['id']
                      ?.toString() ??
                  '',
            ) ??
            0;

    final customer =
        order['customer_name']
                    ?.toString()
                    .trim()
                    .isNotEmpty ==
                true
            ? order[
                    'customer_name']
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
        order['status']
                ?.toString() ??
            '';

    final foodAmount =
        _toDouble(
      order['food_amount'],
    );

    final driverFee =
        _toDouble(
      order['driver_fee'],
    );

    final customerLat =
        _toDoubleNullable(
      order[
          'customer_latitude'],
    );

    final customerLng =
        _toDoubleNullable(
      order[
          'customer_longitude'],
    );

    return Card(
      child: Padding(
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
              height: 15,
            ),

            Row(
              children: [
                const Icon(
                  Icons.person,
                  color: orange,
                ),
                const SizedBox(
                  width: 8,
                ),
                Expanded(
                  child:
                      Text(customer),
                ),
              ],
            ),

            if (phone.isNotEmpty) ...[
              const SizedBox(
                height: 10,
              ),
              Row(
                children: [
                  const Icon(
                    Icons.phone,
                    color: orange,
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  Text(phone),
                ],
              ),
            ],

            const SizedBox(
              height: 10,
            ),

            Row(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                const Icon(
                  Icons.location_on,
                  color: orange,
                ),
                const SizedBox(
                  width: 8,
                ),
                Expanded(
                  child:
                      Text(address),
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
                      _infoBox(
                    title:
                        'قيمة الطلب',
                    value:
                        '${foodAmount.toStringAsFixed(3)} د.ت',
                    icon: Icons
                        .restaurant,
                  ),
                ),
                const SizedBox(
                  width: 8,
                ),
                Expanded(
                  child:
                      _infoBox(
                    title:
                        'أجرة السائق',
                    value:
                        '${driverFee.toStringAsFixed(3)} د.ت',
                    icon: Icons
                        .two_wheeler,
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 12,
            ),

            if (status ==
                'driver_arrived')
              SizedBox(
                width:
                    double.infinity,
                child:
                    ElevatedButton
                        .icon(
                  onPressed:
                      verifyingOtp
                          ? null
                          : () {
                              _showOtpDialog(
                                orderId:
                                    id,
                              );
                            },
                  icon:
                      const Icon(
                    Icons.verified,
                  ),
                  label:
                      const Text(
                    'تأكيد استلام الطلب بـ OTP',
                  ),
                ),
              ),

            if (status ==
                    'accepted' ||
                status ==
                    'driver_arrived' ||
                status ==
                    'picked_up' ||
                status ==
                    'delivering') ...[
              const SizedBox(
                height: 10,
              ),
              SizedBox(
                width:
                    double.infinity,
                child:
                    OutlinedButton
                        .icon(
                  onPressed: () {
                    _openMaps(
                      latitude:
                          customerLat,
                      longitude:
                          customerLng,
                    );
                  },
                  icon:
                      const Icon(
                    Icons.map,
                  ),
                  label:
                      const Text(
                    'فتح موقع الزبون',
                  ),
                ),
              ),
            ],

            if (status ==
                'accepted') ...[
              const SizedBox(
                height: 8,
              ),
              _infoMessage(
                'السائق قبل الطلب وسيصل إلى المطعم لاستلامه.',
              ),
            ],

            if (status ==
                'driver_arrived') ...[
              const SizedBox(
                height: 8,
              ),
              _infoMessage(
                'السائق وصل للمطعم. أدخل رمز OTP الظاهر لدى السائق لتأكيد الاستلام.',
              ),
            ],

            if (status ==
                'picked_up') ...[
              const SizedBox(
                height: 8,
              ),
              _infoMessage(
                'تم استلام الطلب من المطعم.',
              ),
            ],

            if (status ==
                'delivering') ...[
              const SizedBox(
                height: 8,
              ),
              _infoMessage(
                'السائق في طريقه إلى الزبون.',
              ),
            ],
          ],
        ),
      ),
    );
  }

  // =========================================================
  // INFO BOX
  // =========================================================

  Widget _infoBox({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding:
          const EdgeInsets.all(
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
        children: [
          Icon(
            icon,
            color: orange,
            size: 22,
          ),
          const SizedBox(
            width: 8,
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
                    fontSize: 11,
                  ),
                ),
                const SizedBox(
                  height: 3,
                ),
                Text(
                  value,
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

  // =========================================================
  // INFO MESSAGE
  // =========================================================

  Widget _infoMessage(
    String text,
  ) {
    return Container(
      width:
          double.infinity,
      padding:
          const EdgeInsets.all(
        12,
      ),
      decoration:
          BoxDecoration(
        color:
            orange.withOpacity(
          .08,
        ),
        borderRadius:
            BorderRadius.circular(
          12,
        ),
      ),
      child:
          Text(
        text,
        style:
            const TextStyle(
          fontSize: 13,
        ),
      ),
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

      case 'delivered':
        text = 'تم التوصيل';
        break;

      case 'cancelled':
        text = 'ملغى';
        break;

      case 'failed':
        text = 'فشل الطلب';
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
        horizontal: 10,
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
      child:
          InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(
          18,
        ),
        child:
            Padding(
          padding:
              const EdgeInsets.all(
            18,
          ),
          child:
              Column(
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
                title,
                textAlign:
                    TextAlign.center,
                style:
                    const TextStyle(
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
  // OTP DIALOG
  // =========================================================

  void _showOtpDialog({
    required int orderId,
  }) {
    final otpController =
        TextEditingController();

    showDialog(
      context: context,
      barrierDismissible:
          false,
      builder:
          (dialogContext) {
        return AlertDialog(
          title:
              const Text(
            'تأكيد استلام الطلب',
          ),
          content:
              Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [

              const Icon(
                Icons
                    .verified_user,
                color: orange,
                size: 55,
              ),

              const SizedBox(
                height: 12,
              ),

              const Text(
                'اطلب من السائق رمز OTP المكون من 4 أرقام.',
                textAlign:
                    TextAlign.center,
              ),

              const SizedBox(
                height: 18,
              ),

              TextField(
                controller:
                    otpController,
                autofocus:
                    true,
                maxLength:
                    4,
                textAlign:
                    TextAlign.center,
                keyboardType:
                    TextInputType
                        .number,
                decoration:
                    const InputDecoration(
                  labelText:
                      'رمز OTP',
                  hintText:
                      '0000',
                  prefixIcon:
                      Icon(
                    Icons.lock,
                  ),
                ),
              ),
            ],
          ),
          actions: [

            TextButton(
              onPressed:
                  verifyingOtp
                      ? null
                      : () {
                          Navigator.of(
                            dialogContext,
                          ).pop();
                        },
              child:
                  const Text(
                'إلغاء',
              ),
            ),

            ElevatedButton(
              onPressed:
                  verifyingOtp
                      ? null
                      : () async {
                          final success =
                              await verifyPickupOtp(
                            orderId:
                                orderId,
                            otp:
                                otpController
                                    .text,
                          );

                          if (success &&
                              dialogContext
                                  .mounted) {
                            Navigator.of(
                              dialogContext,
                            ).pop();
                          }
                        },
              child:
                  verifyingOtp
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(
                            color:
                                Colors.white,
                            strokeWidth:
                                2,
                          ),
                        )
                      : const Text(
                          'تأكيد',
                        ),
            ),
          ],
        );
      },
    );
  }

  // =========================================================
  // HISTORY
  // =========================================================

  void _showHistoryDialog() {
    final history =
        orders.where(
      (order) {
        final status =
            order['status']
                ?.toString();

        return [
          'delivered',
          'cancelled',
          'failed',
        ].contains(status);
      },
    ).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled:
          true,
      showDragHandle:
          true,
      builder: (_) {
        return SizedBox(
          height:
              MediaQuery.of(
                    context,
                  ).size.height *
                  .75,
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

                const Text(
                  'سجل الطلبات',
                  style:
                      TextStyle(
                    fontSize: 22,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 15,
                ),

                Expanded(
                  child:
                      history.isEmpty
                          ? const Center(
                              child:
                                  Text(
                                'لا توجد طلبات سابقة',
                              ),
                            )
                          : ListView
                              .separated(
                              itemCount:
                                  history.length,
                              separatorBuilder:
                                  (_, __) =>
                                      const SizedBox(
                                height:
                                    8,
                              ),
                              itemBuilder:
                                  (
                                _,
                                index,
                              ) {
                                final order =
                                    history[
                                        index];

                                return ListTile(
                                  shape:
                                      RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(
                                      12,
                                    ),
                                  ),
                                  tileColor:
                                      Colors
                                          .grey
                                          .shade100,
                                  title:
                                      Text(
                                    '#${order['id']} - ${order['customer_name'] ?? 'زبون'}',
                                  ),
                                  subtitle:
                                      Text(
                                    order['customer_address']
                                            ?.toString() ??
                                        '',
                                  ),
                                  trailing:
                                      _statusBadge(
                                    order['status']
                                            ?.toString() ??
                                        '',
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        );
      },
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
      isScrollControlled:
          true,
      showDragHandle:
          true,
      builder: (_) {
        return StatefulBuilder(
          builder:
              (
            modalContext,
            setModalState,
          ) {
            return Padding(
              padding:
                  EdgeInsets.only(
                left: 20,
                right: 20,
                bottom:
                    MediaQuery.of(
                          modalContext,
                        )
                            .viewInsets
                            .bottom +
                        20,
              ),
              child:
                  SingleChildScrollView(
                child:
                    Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [

                    const Text(
                      'طلب توصيل جديد',
                      style:
                          TextStyle(
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
                          TextInputType
                              .phone,
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
                        decimal:
                            true,
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
                        decimal:
                            true,
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
                      maxLines:
                          2,
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
                          child:
                              TextField(
                            controller:
                                latitude,
                            keyboardType:
                                const TextInputType
                                    .numberWithOptions(
                              decimal:
                                  true,
                              signed:
                                  true,
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
                          child:
                              TextField(
                            controller:
                                longitude,
                            keyboardType:
                                const TextInputType
                                    .numberWithOptions(
                              decimal:
                                  true,
                              signed:
                                  true,
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
                                    width:
                                        24,
                                    height:
                                        24,
                                    child:
                                        CircularProgressIndicator(
                                      color:
                                          Colors.white,
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

  // =========================================================
  // NUMBER HELPERS
  // =========================================================

  double _toDouble(
    dynamic value,
  ) {
    return double.tryParse(
          value?.toString() ??
              '',
        ) ??
        0;
  }

  double? _toDoubleNullable(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    return double.tryParse(
      value.toString(),
    );
  }
}
