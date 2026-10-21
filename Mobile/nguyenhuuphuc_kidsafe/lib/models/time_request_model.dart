class TimeRequestModel {
  final String id;
  final String childId;
  final String childName;
  final int minutesRequested;
  final String reason;
  final String status; // pending, approved, rejected
  final String createdAt;

  TimeRequestModel({
    required this.id,
    required this.childId,
    required this.childName,
    required this.minutesRequested,
    required this.reason,
    required this.status,
    required this.createdAt,
  });

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isApproved => status.toLowerCase() == 'approved';
  int get requestedMinutes => minutesRequested;

  factory TimeRequestModel.fromJson(Map<String, dynamic> json) {
    return TimeRequestModel(
      id: json['id']?.toString() ?? '',
      childId: json['childId']?.toString() ?? json['child_id']?.toString() ?? '',
      childName: json['childName']?.toString() ?? json['child_name']?.toString() ?? 'Bé',
      minutesRequested: json['minutesRequested'] ?? json['minutes_requested'] ?? 30,
      reason: json['reason']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      createdAt: json['createdAt']?.toString() ?? json['created_at']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'childId': childId,
      'childName': childName,
      'minutesRequested': minutesRequested,
      'reason': reason,
      'status': status,
      'createdAt': createdAt,
    };
  }
}
