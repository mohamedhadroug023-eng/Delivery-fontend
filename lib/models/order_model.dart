class OrderModel {
  final int id;

  final int restaurantId;
  final String restaurantName;
  final String restaurantPhone;

  final int? driverId;
  final String? driverName;
  final String? driverPhone;

  final String customerName;
  final String customerPhone;
  final String customerAddress;

  final double customerLatitude;
  final double customerLongitude;

  final double restaurantLatitude;
  final double restaurantLongitude;

  final double foodAmount;
  final double platformFee;
  final double driverFee;

  final String status;

  final String? pickupCode;

  final DateTime? createdAt;
  final DateTime? acceptedAt;
  final DateTime? pickedUpAt;
  final DateTime? deliveredAt;

  final DateTime? offerExpiresAt;

  const OrderModel({
    required this.id,
    required this.restaurantId,
    required this.restaurantName,
    required this.restaurantPhone,
    this.driverId,
    this.driverName,
    this.driverPhone,
    required this.customerName,
    required this.customerPhone,
    required this.customerAddress,
    required this.customerLatitude,
    required this.customerLongitude,
    required this.restaurantLatitude,
    required this.restaurantLongitude,
    required this.foodAmount,
    required this.platformFee,
    required this.driverFee,
    required this.status,
    this.pickupCode,
    this.createdAt,
    this.acceptedAt,
    this.pickedUpAt,
    this.deliveredAt,
    this.offerExpiresAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] ?? 0,

      restaurantId: json['restaurant_id'] ?? 0,
      restaurantName: json['restaurant_name'] ?? '',
      restaurantPhone: json['restaurant_phone'] ?? '',

      driverId: json['driver_id'],
      driverName: json['driver_name'],
      driverPhone: json['driver_phone'],

      customerName: json['customer_name'] ?? '',
      customerPhone: json['customer_phone'] ?? '',
      customerAddress: json['customer_address'] ?? '',

      customerLatitude:
          (json['customer_latitude'] ?? 0).toDouble(),

      customerLongitude:
          (json['customer_longitude'] ?? 0).toDouble(),

      restaurantLatitude:
          (json['restaurant_latitude'] ?? 0).toDouble(),

      restaurantLongitude:
          (json['restaurant_longitude'] ?? 0).toDouble(),

      foodAmount:
          (json['food_amount'] ?? 0).toDouble(),

      platformFee:
          (json['platform_fee'] ?? 0).toDouble(),

      driverFee:
          (json['driver_fee'] ?? 0).toDouble(),

      status: json['status'] ?? 'pending',

      pickupCode: json['pickup_code'],

      createdAt: _parseDate(json['created_at']),
      acceptedAt: _parseDate(json['accepted_at']),
      pickedUpAt: _parseDate(json['picked_up_at']),
      deliveredAt: _parseDate(json['delivered_at']),
      offerExpiresAt: _parseDate(json['offer_expires_at']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;

    return DateTime.tryParse(value.toString());
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,

      'restaurant_id': restaurantId,
      'restaurant_name': restaurantName,
      'restaurant_phone': restaurantPhone,

      'driver_id': driverId,
      'driver_name': driverName,
      'driver_phone': driverPhone,

      'customer_name': customerName,
      'customer_phone': customerPhone,
      'customer_address': customerAddress,

      'customer_latitude': customerLatitude,
      'customer_longitude': customerLongitude,

      'restaurant_latitude': restaurantLatitude,
      'restaurant_longitude': restaurantLongitude,

      'food_amount': foodAmount,
      'platform_fee': platformFee,
      'driver_fee': driverFee,

      'status': status,

      'pickup_code': pickupCode,

      'created_at': createdAt?.toIso8601String(),
      'accepted_at': acceptedAt?.toIso8601String(),
      'picked_up_at': pickedUpAt?.toIso8601String(),
      'delivered_at': deliveredAt?.toIso8601String(),
      'offer_expires_at': offerExpiresAt?.toIso8601String(),
    };
  }
}
