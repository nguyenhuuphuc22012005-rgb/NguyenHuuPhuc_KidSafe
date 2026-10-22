class GeofenceModel {
  final String id;
  final String childId;
  final String name;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final bool isActive;
  final bool notifyOnExit;
  final bool notifyOnEntry;

  GeofenceModel({
    required this.id,
    required this.childId,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    this.isActive = true,
    this.notifyOnExit = true,
    this.notifyOnEntry = true,
  });

  factory GeofenceModel.fromJson(Map<String, dynamic> json) {
    return GeofenceModel(
      id: json['id'] ?? '',
      childId: json['childId'] ?? json['child_id'] ?? '',
      name: json['name'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 10.7769,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 106.7009,
      radiusMeters: (json['radiusMeters'] ?? json['radius_meters'] as num?)?.toDouble() ?? 200.0,
      isActive: json['isActive'] == true || json['is_active'] == true || json['is_active'] == 1,
      notifyOnExit: json['notifyOnExit'] == true || json['notify_on_exit'] == true || json['notify_on_exit'] == 1,
      notifyOnEntry: json['notifyOnEntry'] == true || json['notify_on_entry'] == true || json['notify_on_entry'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'childId': childId,
      'child_id': childId,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'radiusMeters': radiusMeters,
      'radius_meters': radiusMeters,
      'isActive': isActive,
      'is_active': isActive,
      'notifyOnExit': notifyOnExit,
      'notify_on_exit': notifyOnExit,
      'notifyOnEntry': notifyOnEntry,
      'notify_on_entry': notifyOnEntry,
    };
  }

  GeofenceModel copyWith({
    String? id,
    String? childId,
    String? name,
    double? latitude,
    double? longitude,
    double? radiusMeters,
    bool? isActive,
    bool? notifyOnExit,
    bool? notifyOnEntry,
  }) {
    return GeofenceModel(
      id: id ?? this.id,
      childId: childId ?? this.childId,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radiusMeters: radiusMeters ?? this.radiusMeters,
      isActive: isActive ?? this.isActive,
      notifyOnExit: notifyOnExit ?? this.notifyOnExit,
      notifyOnEntry: notifyOnEntry ?? this.notifyOnEntry,
    );
  }
}
