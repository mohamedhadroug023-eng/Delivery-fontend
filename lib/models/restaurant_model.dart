class RestaurantModel {
  final int id;
  final String name;
  final String phone;
  final String address;

  final double latitude;
  final double longitude;

  final bool isActive;

  final double balanceDue;
  final int dailyOrders;

  const RestaurantModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.isActive,
    required this.balanceDue,
    required this.dailyOrders,
  });

  factory RestaurantModel.fromJson(Map<String, dynamic> json) {
    return RestaurantModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      isActive: json['is_active'] ?? false,
      balanceDue: (json['balance_due'] ?? 0).toDouble(),
      dailyOrders: json['daily_orders'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'is_active': isActive,
      'balance_due': balanceDue,
      'daily_orders': dailyOrders,
    };
  }
}
