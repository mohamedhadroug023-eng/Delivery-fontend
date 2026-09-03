class DriverModel {
  final int id;
  final String name;
  final String phone;

  final String vehicleType;
  final String vehicleNumber;

  final bool isOnline;
  final bool isAvailable;

  final double latitude;
  final double longitude;

  final int currentOrdersCount;
  final int dailyOrders;

  final double dailyEarnings;

  const DriverModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.vehicleType,
    required this.vehicleNumber,
    required this.isOnline,
    required this.isAvailable,
    required this.latitude,
    required this.longitude,
    required this.currentOrdersCount,
    required this.dailyOrders,
    required this.dailyEarnings,
  });

  factory DriverModel.fromJson(Map<String, dynamic> json) {
    return DriverModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      vehicleType: json['vehicle_type'] ?? '',
      vehicleNumber: json['vehicle_number'] ?? '',
      isOnline: json['is_online'] ?? false,
      isAvailable: json['is_available'] ?? false,
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      currentOrdersCount: json['current_orders_count'] ?? 0,
      dailyOrders: json['daily_orders'] ?? 0,
      dailyEarnings: (json['daily_earnings'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'vehicle_type': vehicleType,
      'vehicle_number': vehicleNumber,
      'is_online': isOnline,
      'is_available': isAvailable,
      'latitude': latitude,
      'longitude': longitude,
      'current_orders_count': currentOrdersCount,
      'daily_orders': dailyOrders,
      'daily_earnings': dailyEarnings,
    };
  }
}
