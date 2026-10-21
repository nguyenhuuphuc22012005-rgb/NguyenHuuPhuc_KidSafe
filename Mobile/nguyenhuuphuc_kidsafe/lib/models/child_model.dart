class ChildModel {
  final String id;
  final String parentId;
  final String name;
  final int age;
  final String gender; // male, female
  final String? phone;
  final String avatar;
  final String deviceId;
  final int batteryLevel;
  final double latitude;
  final double longitude;
  final String lastSeen;
  final double currentNoiseDb;
  final bool isOnline;
  final int dailyScreenLimitMinutes;
  final int usedScreenMinutes;

  ChildModel({
    required this.id,
    required this.parentId,
    required this.name,
    required this.age,
    this.gender = 'male',
    this.phone,
    this.avatar = 'avatar_boy_1',
    required this.deviceId,
    this.batteryLevel = 85,
    this.latitude = 10.7769,
    this.longitude = 106.7009,
    this.lastSeen = 'Vừa xong',
    this.currentNoiseDb = 42.0,
    this.isOnline = true,
    this.dailyScreenLimitMinutes = 180,
    this.usedScreenMinutes = 65,
  });

  double get screenTimeProgress => 
      dailyScreenLimitMinutes > 0 ? (usedScreenMinutes / dailyScreenLimitMinutes).clamp(0.0, 1.0) : 0.0;

  bool get isScreenTimeExceeded => usedScreenMinutes >= dailyScreenLimitMinutes;

  int get remainingScreenMinutes => 
      (dailyScreenLimitMinutes - usedScreenMinutes).clamp(0, dailyScreenLimitMinutes);

  factory ChildModel.fromJson(Map<String, dynamic> json) {
    return ChildModel(
      id: json['id'] ?? '',
      parentId: json['parent_id'] ?? '',
      name: json['name'] ?? '',
      age: json['age'] is int ? json['age'] : int.tryParse(json['age']?.toString() ?? '0') ?? 0,
      gender: json['gender'] ?? 'male',
      phone: json['phone'],
      avatar: json['avatar'] ?? 'avatar_boy_1',
      deviceId: json['device_id'] ?? '',
      batteryLevel: json['battery_level'] is int 
          ? json['battery_level'] 
          : int.tryParse(json['battery_level']?.toString() ?? '85') ?? 85,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 10.7769,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 106.7009,
      lastSeen: json['last_seen'] ?? 'Vừa xong',
      currentNoiseDb: (json['current_noise_db'] as num?)?.toDouble() ?? 42.0,
      isOnline: json['is_online'] == 1 || json['is_online'] == true,
      dailyScreenLimitMinutes: json['daily_screen_limit_minutes'] is int
          ? json['daily_screen_limit_minutes']
          : int.tryParse(json['daily_screen_limit_minutes']?.toString() ?? '180') ?? 180,
      usedScreenMinutes: json['used_screen_minutes'] is int
          ? json['used_screen_minutes']
          : int.tryParse(json['used_screen_minutes']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'parent_id': parentId,
      'name': name,
      'age': age,
      'gender': gender,
      'phone': phone,
      'avatar': avatar,
      'device_id': deviceId,
      'battery_level': batteryLevel,
      'latitude': latitude,
      'longitude': longitude,
      'last_seen': lastSeen,
      'current_noise_db': currentNoiseDb,
      'is_online': isOnline ? 1 : 0,
      'daily_screen_limit_minutes': dailyScreenLimitMinutes,
      'used_screen_minutes': usedScreenMinutes,
    };
  }

  ChildModel copyWith({
    String? id,
    String? parentId,
    String? name,
    int? age,
    String? gender,
    String? phone,
    String? avatar,
    String? deviceId,
    int? batteryLevel,
    double? latitude,
    double? longitude,
    String? lastSeen,
    double? currentNoiseDb,
    bool? isOnline,
    int? dailyScreenLimitMinutes,
    int? usedScreenMinutes,
  }) {
    return ChildModel(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      phone: phone ?? this.phone,
      avatar: avatar ?? this.avatar,
      deviceId: deviceId ?? this.deviceId,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      lastSeen: lastSeen ?? this.lastSeen,
      currentNoiseDb: currentNoiseDb ?? this.currentNoiseDb,
      isOnline: isOnline ?? this.isOnline,
      dailyScreenLimitMinutes: dailyScreenLimitMinutes ?? this.dailyScreenLimitMinutes,
      usedScreenMinutes: usedScreenMinutes ?? this.usedScreenMinutes,
    );
  }
}
