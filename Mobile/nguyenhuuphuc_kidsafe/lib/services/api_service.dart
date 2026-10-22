import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/child_model.dart';
import '../models/geofence_model.dart';
import '../models/schedule_model.dart';
import '../models/contact_model.dart';
import '../models/sos_ticket_model.dart';
import '../models/time_request_model.dart';
import '../models/noise_log_model.dart';
import 'mock_data_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final MockDataService _mock = MockDataService();

  String _activeBaseUrl = 'http://192.168.1.4:8000';

  String get baseUrl => _activeBaseUrl;

  List<String> _getCandidateHosts() {
    return [
      _activeBaseUrl,
      'http://192.168.1.4:8000',
      'http://127.0.0.1:8000',
      'http://10.0.2.2:8000',
      'http://192.168.1.6:8000',
    ].toSet().toList();
  }

  Future<http.Response> _get(String path, {Duration timeout = const Duration(seconds: 3)}) async {
    for (final host in _getCandidateHosts()) {
      try {
        final res = await http.get(Uri.parse('$host$path')).timeout(timeout);
        _activeBaseUrl = host;
        return res;
      } catch (_) {}
    }
    throw Exception('Không thể kết nối đến Backend KidSafe!');
  }

  Future<http.Response> _post(String path, Map<String, dynamic> body, {Duration timeout = const Duration(seconds: 4)}) async {
    for (final host in _getCandidateHosts()) {
      try {
        final res = await http.post(
          Uri.parse('$host$path'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        ).timeout(timeout);
        _activeBaseUrl = host;
        return res;
      } catch (_) {}
    }
    throw Exception('Không thể kết nối đến Backend KidSafe (vui lòng đảm bảo server đang chạy)!');
  }

  Future<http.Response> _put(String path, Map<String, dynamic> body, {Duration timeout = const Duration(seconds: 3)}) async {
    for (final host in _getCandidateHosts()) {
      try {
        final res = await http.put(
          Uri.parse('$host$path'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        ).timeout(timeout);
        _activeBaseUrl = host;
        return res;
      } catch (_) {}
    }
    throw Exception('Không thể kết nối đến Backend KidSafe!');
  }

  Future<http.Response> _delete(String path, {Duration timeout = const Duration(seconds: 3)}) async {
    for (final host in _getCandidateHosts()) {
      try {
        final res = await http.delete(Uri.parse('$host$path')).timeout(timeout);
        _activeBaseUrl = host;
        return res;
      } catch (_) {}
    }
    throw Exception('Không thể kết nối đến Backend KidSafe!');
  }

  // --- AUTH & OTP ---
  Future<Map<String, dynamic>> login(String email, String password, {String deliveryMethod = 'email'}) async {
    try {
      final res = await _post('/api/auth/login', {
        'email': email,
        'password': password,
        'delivery_method': deliveryMethod,
      });

      if (res.statusCode == 200) {
        return jsonDecode(utf8.decode(res.bodyBytes));
      } else {
        final err = jsonDecode(utf8.decode(res.bodyBytes));
        throw Exception(err['detail'] ?? 'Email hoặc mật khẩu không chính xác!');
      }
    } catch (e) {
      // Fallback chỉ khi mất hoàn toàn kết nối mạng đến server
      if (e.toString().contains('Email hoặc mật khẩu không chính xác')) {
        rethrow;
      }
      
      // Fallback offline mock
      final user = _mock.users.firstWhere(
        (u) => u.email.toLowerCase() == email.toLowerCase(),
        orElse: () {
          String role = 'parent';
          if (email.toLowerCase() == 'nguyenhuuphuc22012005@gmail.com' || email.contains('admin')) {
            role = 'admin';
          } else if (email.contains('child') || email.contains('con')) {
            role = 'child';
          } else if (email.contains('staff')) {
            role = 'staff';
          }
          return UserModel(
            id: 'usr_mock_${DateTime.now().millisecondsSinceEpoch}',
            name: email.toLowerCase() == 'nguyenhuuphuc22012005@gmail.com' ? 'Nguyễn Hữu Phúc (Admin)' : email.split('@').first,
            email: email,
            phone: '0901234567',
            role: role,
          );
        },
      );

      final dest = deliveryMethod == 'sms' ? 'số điện thoại ${user.phone ?? "0901234567"}' : 'Gmail $email';
      return {
        'status': 'otp_required',
        'message': 'Mã OTP đã được gửi về $dest!',
        'email': email,
        'phone': user.phone ?? '0901234567',
        'delivery_method': deliveryMethod,
        'user_preview': user.toJson(),
      };
    }
  }

  Future<Map<String, dynamic>> resendOTP(String email, {String deliveryMethod = 'email'}) async {
    try {
      final res = await _post('/api/auth/resend-otp', {
        'email': email,
        'delivery_method': deliveryMethod,
      });

      if (res.statusCode == 200) {
        return jsonDecode(utf8.decode(res.bodyBytes));
      } else {
        final err = jsonDecode(utf8.decode(res.bodyBytes));
        throw Exception(err['detail'] ?? 'Không thể gửi lại mã OTP!');
      }
    } catch (_) {
      final dest = deliveryMethod == 'sms' ? 'tin nhắn SMS' : 'Gmail $email';
      return {
        'status': 'success',
        'message': 'Đã gửi lại mã OTP về $dest!',
        'email': email,
        'delivery_method': deliveryMethod,
      };
    }
  }

  Future<UserModel?> verifyOTP(String email, String otp) async {
    try {
      final res = await _post('/api/auth/verify-otp', {
        'email': email,
        'otp': otp,
      });

      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        return UserModel.fromJson(data['user']);
      } else {
        final err = jsonDecode(utf8.decode(res.bodyBytes));
        throw Exception(err['detail'] ?? 'Mã OTP không chính xác!');
      }
    } catch (e) {
      if (e.toString().contains('không chính xác') || e.toString().contains('hết hạn')) {
        rethrow;
      }
      // Khi server offline
      final existing = _mock.users.firstWhere(
        (u) => u.email.toLowerCase() == email.toLowerCase(),
        orElse: () => _mock.createUser(
          name: email.toLowerCase() == 'nguyenhuuphuc22012005@gmail.com' ? 'Nguyễn Hữu Phúc (Admin)' : email.split('@').first,
          email: email,
          role: email.toLowerCase() == 'nguyenhuuphuc22012005@gmail.com' ? 'admin' : 'parent',
        ),
      );
      return existing.copyWith(token: 'mock_token_${DateTime.now().millisecondsSinceEpoch}');
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    String role = 'parent',
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'phone': phone,
          'role': role,
        }),
      ).timeout(const Duration(seconds: 2));

      if (res.statusCode == 200) return true;
    } catch (_) {}

    _mock.createUser(name: name, email: email, role: role, phone: phone);
    return true;
  }

  // --- CHILDREN CRUD ---
  Future<List<ChildModel>> getChildren({String? parentId}) async {
    try {
      final uri = parentId != null 
          ? Uri.parse('$baseUrl/api/children?parent_id=$parentId')
          : Uri.parse('$baseUrl/api/children');
      final res = await http.get(uri).timeout(const Duration(seconds: 2));
      if (res.statusCode == 200) {
        final List data = jsonDecode(utf8.decode(res.bodyBytes));
        return data.map((e) => ChildModel.fromJson(e)).toList();
      }
    } catch (_) {}
    return _mock.getChildren(parentId: parentId);
  }

  Future<ChildModel> createChild({
    required String parentId,
    required String name,
    required int age,
    String gender = 'male',
    String? phone,
    String avatar = 'avatar_boy_1',
    int dailyLimitMinutes = 180,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/children?parent_id=$parentId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'age': age,
          'gender': gender,
          'phone': phone,
          'avatar': avatar,
          'daily_screen_limit_minutes': dailyLimitMinutes,
        }),
      ).timeout(const Duration(seconds: 2));
      if (res.statusCode == 200) {
        return _mock.createChild(
          parentId: parentId,
          name: name,
          age: age,
          gender: gender,
          phone: phone,
          avatar: avatar,
          dailyLimitMinutes: dailyLimitMinutes,
        );
      }
    } catch (_) {}
    return _mock.createChild(
      parentId: parentId,
      name: name,
      age: age,
      gender: gender,
      phone: phone,
      avatar: avatar,
      dailyLimitMinutes: dailyLimitMinutes,
    );
  }

  Future<void> updateChild(ChildModel child) async {
    try {
      await http.put(
        Uri.parse('$baseUrl/api/children/${child.id}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(child.toJson()),
      ).timeout(const Duration(seconds: 2));
    } catch (_) {}
    _mock.updateChild(child);
  }

  Future<void> deleteChild(String id) async {
    try {
      await http.delete(Uri.parse('$baseUrl/api/children/$id')).timeout(const Duration(seconds: 2));
    } catch (_) {}
    _mock.deleteChild(id);
  }

  // --- GEOFENCES CRUD ---
  Future<List<GeofenceModel>> getGeofences(String childId) async {
    try {
      final res = await _get('/api/geofences?child_id=$childId', timeout: const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final List data = jsonDecode(utf8.decode(res.bodyBytes));
        return data.map((e) => GeofenceModel.fromJson(e)).toList();
      }
    } catch (_) {}
    return _mock.getGeofences(childId);
  }

  Future<GeofenceModel> createGeofence(GeofenceModel geo) async {
    try {
      final res = await _post('/api/geofences', geo.toJson(), timeout: const Duration(seconds: 4));
      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        final created = GeofenceModel.fromJson(data);
        _mock.geofences.insert(0, created);
        return created;
      }
    } catch (_) {}
    return _mock.createGeofence(
      childId: geo.childId,
      name: geo.name,
      latitude: geo.latitude,
      longitude: geo.longitude,
      radiusMeters: geo.radiusMeters,
      notifyOnExit: geo.notifyOnExit,
      notifyOnEntry: geo.notifyOnEntry,
    );
  }

  Future<void> updateGeofence(GeofenceModel geo) async {
    try {
      await _put('/api/geofences/${geo.id}', geo.toJson(), timeout: const Duration(seconds: 4));
    } catch (_) {}
    _mock.updateGeofence(geo);
  }

  Future<void> deleteGeofence(String id) async {
    try {
      await _delete('/api/geofences/$id', timeout: const Duration(seconds: 4));
    } catch (_) {}
    _mock.deleteGeofence(id);
  }

  // --- SCHEDULES CRUD ---
  Future<List<ScheduleModel>> getSchedules(String childId) async {
    try {
      final res = await _get('/api/schedules?child_id=$childId', timeout: const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final List data = jsonDecode(utf8.decode(res.bodyBytes));
        return data.map((e) => ScheduleModel.fromJson(e)).toList();
      }
    } catch (_) {}
    return _mock.getSchedules(childId);
  }

  Future<ScheduleModel> createSchedule(ScheduleModel sch) async {
    try {
      final res = await _post('/api/schedules', sch.toJson(), timeout: const Duration(seconds: 4));
      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        final created = ScheduleModel.fromJson(data);
        _mock.schedules.insert(0, created);
        return created;
      }
    } catch (_) {}
    return _mock.createSchedule(
      childId: sch.childId,
      title: sch.title,
      startTime: sch.startTime,
      endTime: sch.endTime,
      days: sch.days,
      blockApps: sch.blockApps,
    );
  }

  Future<void> updateSchedule(ScheduleModel sch) async {
    try {
      await _put('/api/schedules/${sch.id}', sch.toJson(), timeout: const Duration(seconds: 4));
    } catch (_) {}
    _mock.updateSchedule(sch);
  }

  Future<void> deleteSchedule(String id) async {
    try {
      await _delete('/api/schedules/$id', timeout: const Duration(seconds: 4));
    } catch (_) {}
    _mock.deleteSchedule(id);
  }

  // --- CONTACTS CRUD ---
  Future<List<ContactModel>> getContacts(String childId) async {
    try {
      final res = await _get('/api/contacts?child_id=$childId', timeout: const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final List data = jsonDecode(utf8.decode(res.bodyBytes));
        return data.map((e) => ContactModel.fromJson(e)).toList();
      }
    } catch (_) {}
    return _mock.getContacts(childId);
  }

  Future<ContactModel> createContact(ContactModel con) async {
    try {
      final res = await _post('/api/contacts', con.toJson(), timeout: const Duration(seconds: 4));
      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        final created = ContactModel.fromJson(data);
        _mock.contacts.insert(0, created);
        return created;
      }
    } catch (_) {}
    return _mock.createContact(
      childId: con.childId,
      name: con.name,
      phone: con.phone,
      relationship: con.relationship,
      isSosContact: con.isSosContact,
      avatar: con.avatar,
    );
  }

  Future<void> updateContact(ContactModel con) async {
    try {
      await _put('/api/contacts/${con.id}', con.toJson(), timeout: const Duration(seconds: 4));
    } catch (_) {}
    _mock.updateContact(con);
  }

  Future<void> deleteContact(String id) async {
    try {
      await _delete('/api/contacts/$id', timeout: const Duration(seconds: 4));
    } catch (_) {}
    _mock.deleteContact(id);
  }

  // --- SOS TICKETS ---
  Future<List<SOSTicketModel>> getSOSTickets() async {
    try {
      final res = await _get('/api/sos', timeout: const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final List data = jsonDecode(utf8.decode(res.bodyBytes));
        return data.map((e) => SOSTicketModel.fromJson(e)).toList();
      }
    } catch (_) {}
    return _mock.getSOSTickets();
  }

  Future<SOSTicketModel> createSOSTicket(SOSTicketModel ticket) async {
    try {
      final res = await _post('/api/sos', ticket.toJson(), timeout: const Duration(seconds: 4));
      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        final created = SOSTicketModel.fromJson(data);
        _mock.sosTickets.insert(0, created);
        return created;
      }
    } catch (_) {}
    return _mock.createSOSTicket(
      childId: ticket.childId,
      childName: ticket.childName,
      parentName: ticket.parentName,
      parentPhone: ticket.parentPhone,
      latitude: ticket.latitude,
      longitude: ticket.longitude,
      noiseLevel: ticket.noiseLevel,
      reason: ticket.reason,
    );
  }

  Future<void> updateSOSTicketStatus(String id, String status, {String? staffId, String? notes}) async {
    try {
      await _put(
        '/api/sos/$id',
        {
          'status': status,
          'assignedStaffId': staffId,
          'assigned_staff_id': staffId,
          'resolutionNotes': notes,
          'resolution_notes': notes,
        },
        timeout: const Duration(seconds: 4),
      );
    } catch (_) {}
    _mock.updateSOSTicketStatus(id, status, staffId: staffId, notes: notes);
  }

  // --- NOISE LOGS CRUD ---
  Future<NoiseLogModel?> addNoiseLog(NoiseLogModel log) async {
    try {
      final res = await _post('/api/noise', log.toJson(), timeout: const Duration(seconds: 4));
      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        return NoiseLogModel.fromJson(data);
      }
    } catch (_) {}
    return null;
  }

  Future<List<NoiseLogModel>> getNoiseLogs(String childId) async {
    try {
      final res = await _get('/api/noise?child_id=$childId', timeout: const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final List data = jsonDecode(utf8.decode(res.bodyBytes));
        return data.map((e) => NoiseLogModel.fromJson(e)).toList();
      }
    } catch (_) {}
    return _mock.getNoiseLogs(childId);
  }

  // --- REAL-TIME NOISE TELEMETRY ---
  Future<bool> reportChildNoise({
    required String childId,
    required double decibel,
    String status = 'Normal',
    String note = 'Cập nhật từ micro máy con',
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/children/$childId/live-noise'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'decibel': decibel,
          'status': status,
          'note': note,
        }),
      ).timeout(const Duration(seconds: 2));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> getChildLiveNoise(String childId) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/children/$childId/live-noise'),
      ).timeout(const Duration(seconds: 2));
      if (res.statusCode == 200) {
        return jsonDecode(utf8.decode(res.bodyBytes));
      }
    } catch (_) {}
    return null;
  }

  // --- GHÉP NỐI THIẾT BỊ QUA MÃ QR (ASP.NET CORE & SQL SERVER) ---
  Future<ChildModel?> pairDevice({
    required String parentId,
    required String deviceId,
    String? name,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/children/pair'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'parentId': parentId,
          'deviceId': deviceId,
          'name': name,
        }),
      ).timeout(const Duration(seconds: 3));

      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        return ChildModel.fromJson(data['child']);
      }
    } catch (_) {}
    return null;
  }

  // --- BẮN TỌA ĐỘ GPS MÁY CON LÊN WEB API & SQL SERVER ---
  Future<bool> reportChildLocation({
    required String childId,
    required double latitude,
    required double longitude,
    int? batteryLevel,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/children/$childId/location'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'latitude': latitude,
          'longitude': longitude,
          'batteryLevel': batteryLevel,
        }),
      ).timeout(const Duration(seconds: 2));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // --- YÊU CẦU XIN THÊM THỜI GIAN & DUYỆT YÊU CẦU (ASP.NET CORE & SQL SERVER) ---
  Future<List<TimeRequestModel>> getTimeRequests({String? parentId, String? childId}) async {
    try {
      var path = '/api/time-requests';
      if (parentId != null) path += '?parent_id=$parentId';
      else if (childId != null) path += '?child_id=$childId';

      final res = await _get(path, timeout: const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final List list = jsonDecode(utf8.decode(res.bodyBytes));
        final result = list.map((e) => TimeRequestModel.fromJson(e)).toList();
        _mock.timeRequests = result;
        _mock.saveTimeRequestsToStorage();
        return result;
      }
    } catch (_) {}
    return _mock.timeRequests;
  }

  Future<TimeRequestModel?> createTimeRequest({
    required String childId,
    int? minutes,
    int? requestedMinutes,
    required String reason,
    String? childName,
    String? parentId,
  }) async {
    final int mins = requestedMinutes ?? minutes ?? 30;
    try {
      final res = await _post('/api/time-requests', {
        'childId': childId,
        'minutesRequested': mins,
        'reason': reason,
      }, timeout: const Duration(seconds: 3));

      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        final created = TimeRequestModel.fromJson(data['request']);
        _mock.timeRequests.insert(0, created);
        _mock.saveTimeRequestsToStorage();
        return created;
      }
    } catch (_) {}

    final req = TimeRequestModel(
      id: 'req_${DateTime.now().millisecondsSinceEpoch}',
      childId: childId,
      childName: childName ?? 'Bé',
      minutesRequested: mins,
      reason: reason,
      status: 'pending',
      createdAt: 'Vừa xong',
    );
    _mock.timeRequests.insert(0, req);
    _mock.saveTimeRequestsToStorage();
    return req;
  }

  Future<bool> reviewTimeRequest({
    required String requestId,
    String? status,
    bool? isApproved,
    String reviewer = 'Phụ Huynh',
  }) async {
    final finalStatus = status ?? (isApproved == true ? 'approved' : 'rejected');
    try {
      final res = await _put('/api/time-requests/$requestId/review', {
        'status': finalStatus,
        'reviewedBy': reviewer,
      }, timeout: const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final idx = _mock.timeRequests.indexWhere((r) => r.id == requestId);
        if (idx != -1) {
          final old = _mock.timeRequests[idx];
          _mock.timeRequests[idx] = TimeRequestModel(
            id: old.id,
            childId: old.childId,
            childName: old.childName,
            minutesRequested: old.minutesRequested,
            reason: old.reason,
            status: finalStatus,
            createdAt: old.createdAt,
          );
          _mock.saveTimeRequestsToStorage();
        }
        return true;
      }
    } catch (_) {}

    final idx = _mock.timeRequests.indexWhere((r) => r.id == requestId);
    if (idx != -1) {
      final old = _mock.timeRequests[idx];
      _mock.timeRequests[idx] = TimeRequestModel(
        id: old.id,
        childId: old.childId,
        childName: old.childName,
        minutesRequested: old.minutesRequested,
        reason: old.reason,
        status: finalStatus,
        createdAt: old.createdAt,
      );
      _mock.saveTimeRequestsToStorage();
    }
    return true;
  }
}
