class NoiseLogModel {
  final String id;
  final String childId;
  final double decibel;
  final String status; // Quiet, Normal, Loud, Danger
  final String timestamp;
  final String? note;

  NoiseLogModel({
    required this.id,
    required this.childId,
    required this.decibel,
    required this.status,
    required this.timestamp,
    this.note,
  });

  bool get isDanger => decibel >= 80.0;
  bool get isLoud => decibel >= 65.0 && decibel < 80.0;
  bool get isNormal => decibel >= 40.0 && decibel < 65.0;
  bool get isQuiet => decibel < 40.0;

  String get statusDisplay {
    if (decibel >= 85) return 'Nguy hiểm (Báo động la hét)';
    if (decibel >= 70) return 'Ồn ào (Ô nhiễm âm thanh)';
    if (decibel >= 45) return 'Bình thường (Sinh hoạt)';
    return 'Yên tĩnh (Phù hợp học tập)';
  }

  factory NoiseLogModel.fromJson(Map<String, dynamic> json) {
    return NoiseLogModel(
      id: json['id'] ?? '',
      childId: json['child_id'] ?? '',
      decibel: (json['decibel'] as num?)?.toDouble() ?? 40.0,
      status: json['status'] ?? 'Normal',
      timestamp: json['timestamp'] ?? '',
      note: json['note'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'child_id': childId,
      'decibel': decibel,
      'status': status,
      'timestamp': timestamp,
      'note': note,
    };
  }
}
