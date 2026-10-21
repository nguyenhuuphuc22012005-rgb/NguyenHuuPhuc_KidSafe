import 'dart:math';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import '../models/child_model.dart';
import '../models/geofence_model.dart';
import '../models/schedule_model.dart';
import '../models/contact_model.dart';
import '../models/noise_log_model.dart';
import '../models/sos_ticket_model.dart';
import '../models/time_request_model.dart';

class MockDataService {
  static final MockDataService _instance = MockDataService._internal();
  factory MockDataService() => _instance;
  MockDataService._internal() {
    _initData();
  }

  final _uuid = const Uuid();

  List<UserModel> users = [];
  List<ChildModel> children = [];
  List<GeofenceModel> geofences = [];
  List<ScheduleModel> schedules = [];
  List<ContactModel> contacts = [];
  List<NoiseLogModel> noiseLogs = [];
  List<SOSTicketModel> sosTickets = [];
  List<TimeRequestModel> timeRequests = [
    TimeRequestModel(
      id: 'req_01',
      childId: 'ch_01',
      childName: 'Bé Bo (Gia Bảo)',
      minutesRequested: 30,
      reason: 'Con cần thêm 30 phút để hoàn thành bài tập tiếng Anh online ạ.',
      status: 'pending',
      createdAt: '10 phút trước',
    ),
  ];

  void _initData() {
    // 1. Initial Users
    users = [
      UserModel(
        id: 'usr_admin_01',
        name: 'Nguyễn Hữu Phúc',
        email: 'nguyenhuuphuc22012005@gmail.com',
        phone: '0901234567',
        role: 'admin',
        avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
      ),
      UserModel(
        id: 'usr_parent_01',
        name: 'Nguyễn Hữu Phúc',
        email: 'parent@kidsafe.vn',
        phone: '0988776655',
        role: 'parent',
        avatar: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150',
      ),
      UserModel(
        id: 'usr_child_01',
        name: 'Bé Bo (Thiết Bị Con)',
        email: 'child@kidsafe.vn',
        phone: '0911223344',
        role: 'child',
        avatar: 'https://images.unsplash.com/photo-1543332164-6e82f355badc?w=150',
      ),
      UserModel(
        id: 'usr_staff_01',
        name: 'Nguyễn Hữu Phúc',
        email: 'staff@kidsafe.vn',
        phone: '0909876543',
        role: 'staff',
        avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
      ),
    ];

    // 2. Initial Children
    children = [
      ChildModel(
        id: 'ch_01',
        parentId: 'usr_parent_01',
        name: 'Bé Bo (Gia Bảo)',
        age: 8,
        gender: 'male',
        phone: '0911223344',
        avatar: 'avatar_boy_1',
        deviceId: 'DEV-KID-BO-8821',
        batteryLevel: 88,
        latitude: 10.7769,
        longitude: 106.7009,
        lastSeen: 'Vừa xong',
        currentNoiseDb: 42.5,
        isOnline: true,
        dailyScreenLimitMinutes: 180,
        usedScreenMinutes: 75,
      ),
      ChildModel(
        id: 'ch_02',
        parentId: 'usr_parent_01',
        name: 'Bé Bông (Mai Anh)',
        age: 6,
        gender: 'female',
        phone: '0911223355',
        avatar: 'avatar_girl_1',
        deviceId: 'DEV-KID-BONG-9932',
        batteryLevel: 64,
        latitude: 10.7725,
        longitude: 106.6980,
        lastSeen: '5 phút trước',
        currentNoiseDb: 52.0,
        isOnline: true,
        dailyScreenLimitMinutes: 120,
        usedScreenMinutes: 45,
      ),
    ];

    // 3. Initial Geofences
    geofences = [
      GeofenceModel(
        id: 'geo_01',
        childId: 'ch_01',
        name: 'Trường Tiểu Học Nguyễn Huệ',
        latitude: 10.7769,
        longitude: 106.7009,
        radiusMeters: 250.0,
        isActive: true,
        notifyOnExit: true,
        notifyOnEntry: true,
      ),
      GeofenceModel(
        id: 'geo_02',
        childId: 'ch_01',
        name: 'Nhà Riêng (Chung cư Sunview)',
        latitude: 10.7820,
        longitude: 106.6950,
        radiusMeters: 150.0,
        isActive: true,
        notifyOnExit: true,
        notifyOnEntry: true,
      ),
      GeofenceModel(
        id: 'geo_03',
        childId: 'ch_02',
        name: 'Trường Mầm Non Họa Mi',
        latitude: 10.7725,
        longitude: 106.6980,
        radiusMeters: 200.0,
        isActive: true,
        notifyOnExit: true,
        notifyOnEntry: true,
      ),
    ];

    // 4. Initial Schedules
    schedules = [
      ScheduleModel(
        id: 'sch_01',
        childId: 'ch_01',
        title: 'Giờ Học Bài Buổi Tối',
        startTime: '19:30',
        endTime: '21:00',
        days: 'Mon,Tue,Wed,Thu,Fri',
        isActive: true,
        blockApps: true,
      ),
      ScheduleModel(
        id: 'sch_02',
        childId: 'ch_01',
        title: 'Giờ Đi Ngủ',
        startTime: '22:00',
        endTime: '06:30',
        days: 'Mon,Tue,Wed,Thu,Fri,Sat,Sun',
        isActive: true,
        blockApps: true,
      ),
      ScheduleModel(
        id: 'sch_03',
        childId: 'ch_02',
        title: 'Giờ Ngủ Trưa',
        startTime: '12:00',
        endTime: '13:30',
        days: 'Mon,Tue,Wed,Thu,Fri',
        isActive: true,
        blockApps: true,
      ),
    ];

    // 5. Initial Contacts
    contacts = [
      ContactModel(
        id: 'con_01',
        childId: 'ch_01',
        name: 'Nguyễn Hữu Phúc',
        phone: '0988776655',
        relationship: 'Bố',
        isSosContact: true,
        avatar: 'avatar_dad',
      ),
      ContactModel(
        id: 'con_02',
        childId: 'ch_01',
        name: 'Mẹ (Trần Thị Mai)',
        phone: '0977889900',
        relationship: 'Mẹ',
        isSosContact: true,
        avatar: 'avatar_mom',
      ),
      ContactModel(
        id: 'con_03',
        childId: 'ch_01',
        name: 'Cô Lan (GVCN Lớp 3A)',
        phone: '0933445566',
        relationship: 'Giáo viên',
        isSosContact: false,
        avatar: 'avatar_teacher',
      ),
      ContactModel(
        id: 'con_04',
        childId: 'ch_01',
        name: 'Cảnh Sát 113',
        phone: '113',
        relationship: 'Khẩn cấp',
        isSosContact: true,
        avatar: 'avatar_police',
      ),
    ];

    // 6. Initial Noise Logs (for FlChart)
    final now = DateTime.now();
    noiseLogs = [
      NoiseLogModel(id: 'nl_01', childId: 'ch_01', decibel: 38.0, status: 'Quiet', timestamp: '${now.hour - 3}:00', note: 'Trong lớp học'),
      NoiseLogModel(id: 'nl_02', childId: 'ch_01', decibel: 45.5, status: 'Normal', timestamp: '${now.hour - 2}:00', note: 'Giờ ra chơi'),
      NoiseLogModel(id: 'nl_03', childId: 'ch_01', decibel: 72.0, status: 'Loud', timestamp: '${now.hour - 1}:00', note: 'Căng tin trường'),
      NoiseLogModel(id: 'nl_04', childId: 'ch_01', decibel: 42.0, status: 'Quiet', timestamp: '${now.hour}:00', note: 'Phòng đọc sách'),
    ];

    // 7. Initial SOS Tickets
    sosTickets = [
      SOSTicketModel(
        id: 'sos_01',
        childId: 'ch_01',
        childName: 'Bé Bo (Gia Bảo)',
        parentName: 'Nguyễn Hữu Phúc',
        parentPhone: '0988776655',
        latitude: 10.7769,
        longitude: 106.7009,
        noiseLevel: 88.5,
        reason: 'Phát hiện tiếng ồn vượt ngưỡng (88.5 dB) và bé nhấn nút SOS!',
        status: 'pending',
        createdAt: '10 phút trước',
      ),
      SOSTicketModel(
        id: 'sos_02',
        childId: 'ch_02',
        childName: 'Bé Bông (Mai Anh)',
        parentName: 'Nguyễn Hữu Phúc',
        parentPhone: '0988776655',
        latitude: 10.7725,
        longitude: 106.6980,
        noiseLevel: 52.0,
        reason: 'Cảnh báo: Bé di chuyển ra khỏi vùng an toàn Trường mầm non',
        status: 'resolved',
        assignedStaffId: 'usr_staff_01',
        resolutionNotes: 'Đã liên hệ phụ huynh, phụ huynh đã đón bé an toàn.',
        createdAt: 'Hôm qua',
      ),
    ];
  }

  // --- USER CRUD ---
  List<UserModel> getUsers() => List.unmodifiable(users);

  UserModel createUser({
    required String name,
    required String email,
    required String role,
    String? phone,
  }) {
    final newUser = UserModel(
      id: 'usr_${_uuid.v4().substring(0, 8)}',
      name: name,
      email: email,
      role: role,
      phone: phone,
      avatar: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
    );
    users.add(newUser);
    return newUser;
  }

  void updateUser(String id, {String? name, String? phone, String? role}) {
    final idx = users.indexWhere((u) => u.id == id);
    if (idx != -1) {
      users[idx] = users[idx].copyWith(
        name: name,
        phone: phone,
        role: role,
      );
    }
  }

  void deleteUser(String id) {
    users.removeWhere((u) => u.id == id);
  }

  // --- CHILDREN CRUD ---
  List<ChildModel> getChildren({String? parentId}) {
    if (parentId != null) {
      return children.where((c) => c.parentId == parentId).toList();
    }
    return List.unmodifiable(children);
  }

  ChildModel createChild({
    required String parentId,
    required String name,
    required int age,
    String gender = 'male',
    String? phone,
    String avatar = 'avatar_boy_1',
    int dailyLimitMinutes = 180,
  }) {
    final newChild = ChildModel(
      id: 'ch_${_uuid.v4().substring(0, 8)}',
      parentId: parentId,
      name: name,
      age: age,
      gender: gender,
      phone: phone,
      avatar: avatar,
      deviceId: 'DEV-KID-${Random().nextInt(8999) + 1000}',
      batteryLevel: 95,
      latitude: 10.7769 + (Random().nextDouble() - 0.5) * 0.01,
      longitude: 106.7009 + (Random().nextDouble() - 0.5) * 0.01,
      dailyScreenLimitMinutes: dailyLimitMinutes,
      usedScreenMinutes: 20,
    );
    children.add(newChild);
    return newChild;
  }

  void updateChild(ChildModel updated) {
    final idx = children.indexWhere((c) => c.id == updated.id);
    if (idx != -1) {
      children[idx] = updated;
    }
  }

  void deleteChild(String id) {
    children.removeWhere((c) => c.id == id);
    geofences.removeWhere((g) => g.childId == id);
    schedules.removeWhere((s) => s.childId == id);
    contacts.removeWhere((c) => c.childId == id);
    noiseLogs.removeWhere((n) => n.childId == id);
  }

  // --- GEOFENCES CRUD ---
  List<GeofenceModel> getGeofences(String childId) {
    return geofences.where((g) => g.childId == childId).toList();
  }

  GeofenceModel createGeofence({
    required String childId,
    required String name,
    required double latitude,
    required double longitude,
    required double radiusMeters,
    bool notifyOnExit = true,
    bool notifyOnEntry = true,
  }) {
    final newGeo = GeofenceModel(
      id: 'geo_${_uuid.v4().substring(0, 8)}',
      childId: childId,
      name: name,
      latitude: latitude,
      longitude: longitude,
      radiusMeters: radiusMeters,
      notifyOnExit: notifyOnExit,
      notifyOnEntry: notifyOnEntry,
    );
    geofences.add(newGeo);
    return newGeo;
  }

  void updateGeofence(GeofenceModel updated) {
    final idx = geofences.indexWhere((g) => g.id == updated.id);
    if (idx != -1) {
      geofences[idx] = updated;
    }
  }

  void deleteGeofence(String id) {
    geofences.removeWhere((g) => g.id == id);
  }

  // --- SCHEDULES CRUD ---
  List<ScheduleModel> getSchedules(String childId) {
    return schedules.where((s) => s.childId == childId).toList();
  }

  ScheduleModel createSchedule({
    required String childId,
    required String title,
    required String startTime,
    required String endTime,
    required String days,
    bool blockApps = true,
  }) {
    final newSch = ScheduleModel(
      id: 'sch_${_uuid.v4().substring(0, 8)}',
      childId: childId,
      title: title,
      startTime: startTime,
      endTime: endTime,
      days: days,
      blockApps: blockApps,
    );
    schedules.add(newSch);
    return newSch;
  }

  void updateSchedule(ScheduleModel updated) {
    final idx = schedules.indexWhere((s) => s.id == updated.id);
    if (idx != -1) {
      schedules[idx] = updated;
    }
  }

  void deleteSchedule(String id) {
    schedules.removeWhere((s) => s.id == id);
  }

  // --- CONTACTS CRUD ---
  List<ContactModel> getContacts(String childId) {
    return contacts.where((c) => c.childId == childId).toList();
  }

  ContactModel createContact({
    required String childId,
    required String name,
    required String phone,
    required String relationship,
    bool isSosContact = false,
    String avatar = 'avatar_contact',
  }) {
    final newCon = ContactModel(
      id: 'con_${_uuid.v4().substring(0, 8)}',
      childId: childId,
      name: name,
      phone: phone,
      relationship: relationship,
      isSosContact: isSosContact,
      avatar: avatar,
    );
    contacts.add(newCon);
    return newCon;
  }

  void updateContact(ContactModel updated) {
    final idx = contacts.indexWhere((c) => c.id == updated.id);
    if (idx != -1) {
      contacts[idx] = updated;
    }
  }

  void deleteContact(String id) {
    contacts.removeWhere((c) => c.id == id);
  }

  // --- NOISE LOGS (Feature d) ---
  List<NoiseLogModel> getNoiseLogs(String childId) {
    return noiseLogs.where((n) => n.childId == childId).toList();
  }

  void addNoiseLog(String childId, double decibel, String status, String note) {
    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    final log = NoiseLogModel(
      id: 'nl_${_uuid.v4().substring(0, 8)}',
      childId: childId,
      decibel: decibel,
      status: status,
      timestamp: timeStr,
      note: note,
    );
    noiseLogs.insert(0, log);
    if (noiseLogs.length > 30) {
      noiseLogs.removeLast();
    }

    // Cập nhật decibel tức thì cho bé
    final idx = children.indexWhere((c) => c.id == childId);
    if (idx != -1) {
      children[idx] = children[idx].copyWith(currentNoiseDb: decibel);
    }
  }

  // --- SOS TICKETS (Staff Portal & Emergency) ---
  List<SOSTicketModel> getSOSTickets() => List.unmodifiable(sosTickets);

  SOSTicketModel createSOSTicket({
    required String childId,
    required String childName,
    String? parentName,
    String? parentPhone,
    required double latitude,
    required double longitude,
    double noiseLevel = 0.0,
    required String reason,
  }) {
    final newTicket = SOSTicketModel(
      id: 'sos_${_uuid.v4().substring(0, 8)}',
      childId: childId,
      childName: childName,
      parentName: parentName ?? 'Phụ huynh',
      parentPhone: parentPhone ?? '0988776655',
      latitude: latitude,
      longitude: longitude,
      noiseLevel: noiseLevel,
      reason: reason,
      status: 'pending',
      createdAt: 'Vừa xong',
    );
    sosTickets.insert(0, newTicket);
    return newTicket;
  }

  void updateSOSTicketStatus(String id, String status, {String? staffId, String? notes}) {
    final idx = sosTickets.indexWhere((t) => t.id == id);
    if (idx != -1) {
      sosTickets[idx] = sosTickets[idx].copyWith(
        status: status,
        assignedStaffId: staffId,
        resolutionNotes: notes,
      );
    }
  }
}
