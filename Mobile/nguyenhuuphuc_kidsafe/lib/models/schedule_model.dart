class ScheduleModel {
  final String id;
  final String childId;
  final String title;
  final String startTime; // HH:mm (e.g. 19:30)
  final String endTime;   // HH:mm (e.g. 21:00)
  final String days;      // "Mon,Tue,Wed,Thu,Fri"
  final bool isActive;
  final bool blockApps;

  ScheduleModel({
    required this.id,
    required this.childId,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.days,
    this.isActive = true,
    this.blockApps = true,
  });

  String get daysDisplay {
    if (days.contains('Mon') && days.contains('Tue') && days.contains('Wed') &&
        days.contains('Thu') && days.contains('Fri') && days.contains('Sat') && days.contains('Sun')) {
      return 'Mọi ngày trong tuần';
    }
    if (days.contains('Mon') && days.contains('Tue') && days.contains('Wed') &&
        days.contains('Thu') && days.contains('Fri') && !days.contains('Sat')) {
      return 'Thứ 2 - Thứ 6';
    }
    if (days.contains('Sat') && days.contains('Sun') && !days.contains('Mon')) {
      return 'Cuối tuần (T7, CN)';
    }
    return days;
  }

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    return ScheduleModel(
      id: json['id'] ?? '',
      childId: json['childId'] ?? json['child_id'] ?? '',
      title: json['title'] ?? '',
      startTime: json['startTime'] ?? json['start_time'] ?? '19:00',
      endTime: json['endTime'] ?? json['end_time'] ?? '21:00',
      days: json['days'] ?? 'Mon,Tue,Wed,Thu,Fri',
      isActive: json['isActive'] == true || json['is_active'] == true || json['is_active'] == 1,
      blockApps: json['blockApps'] == true || json['block_apps'] == true || json['block_apps'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'childId': childId,
      'child_id': childId,
      'title': title,
      'startTime': startTime,
      'start_time': startTime,
      'endTime': endTime,
      'end_time': endTime,
      'days': days,
      'isActive': isActive,
      'is_active': isActive,
      'blockApps': blockApps,
      'block_apps': blockApps,
    };
  }

  ScheduleModel copyWith({
    String? id,
    String? childId,
    String? title,
    String? startTime,
    String? endTime,
    String? days,
    bool? isActive,
    bool? blockApps,
  }) {
    return ScheduleModel(
      id: id ?? this.id,
      childId: childId ?? this.childId,
      title: title ?? this.title,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      days: days ?? this.days,
      isActive: isActive ?? this.isActive,
      blockApps: blockApps ?? this.blockApps,
    );
  }
}
