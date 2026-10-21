class SOSTicketModel {
  final String id;
  final String childId;
  final String childName;
  final String? parentName;
  final String? parentPhone;
  final double latitude;
  final double longitude;
  final double noiseLevel;
  final String reason;
  final String status; // pending, in_progress, resolved
  final String? assignedStaffId;
  final String? resolutionNotes;
  final String createdAt;

  SOSTicketModel({
    required this.id,
    required this.childId,
    required this.childName,
    this.parentName,
    this.parentPhone,
    required this.latitude,
    required this.longitude,
    this.noiseLevel = 0.0,
    required this.reason,
    this.status = 'pending',
    this.assignedStaffId,
    this.resolutionNotes,
    required this.createdAt,
  });

  bool get isPending => status == 'pending';
  bool get isInProgress => status == 'in_progress';
  bool get isResolved => status == 'resolved';

  String get statusDisplay {
    switch (status) {
      case 'pending':
        return 'Chờ tiếp nhận';
      case 'in_progress':
        return 'Đang ứng cứu';
      case 'resolved':
        return 'Đã xử lý an toàn';
      default:
        return status;
    }
  }

  factory SOSTicketModel.fromJson(Map<String, dynamic> json) {
    return SOSTicketModel(
      id: json['id'] ?? '',
      childId: json['child_id'] ?? '',
      childName: json['child_name'] ?? '',
      parentName: json['parent_name'],
      parentPhone: json['parent_phone'],
      latitude: (json['latitude'] as num?)?.toDouble() ?? 10.7769,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 106.7009,
      noiseLevel: (json['noise_level'] as num?)?.toDouble() ?? 0.0,
      reason: json['reason'] ?? '',
      status: json['status'] ?? 'pending',
      assignedStaffId: json['assigned_staff_id'],
      resolutionNotes: json['resolution_notes'],
      createdAt: json['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'child_id': childId,
      'child_name': childName,
      'parent_name': parentName,
      'parent_phone': parentPhone,
      'latitude': latitude,
      'longitude': longitude,
      'noise_level': noiseLevel,
      'reason': reason,
      'status': status,
      'assigned_staff_id': assignedStaffId,
      'resolution_notes': resolutionNotes,
      'created_at': createdAt,
    };
  }

  SOSTicketModel copyWith({
    String? id,
    String? childId,
    String? childName,
    String? parentName,
    String? parentPhone,
    double? latitude,
    double? longitude,
    double? noiseLevel,
    String? reason,
    String? status,
    String? assignedStaffId,
    String? resolutionNotes,
    String? createdAt,
  }) {
    return SOSTicketModel(
      id: id ?? this.id,
      childId: childId ?? this.childId,
      childName: childName ?? this.childName,
      parentName: parentName ?? this.parentName,
      parentPhone: parentPhone ?? this.parentPhone,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      noiseLevel: noiseLevel ?? this.noiseLevel,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      assignedStaffId: assignedStaffId ?? this.assignedStaffId,
      resolutionNotes: resolutionNotes ?? this.resolutionNotes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
