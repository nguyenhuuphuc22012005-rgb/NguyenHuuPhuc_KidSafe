import 'package:flutter/material.dart';
import '../models/sos_ticket_model.dart';
import '../services/api_service.dart';
import '../services/mock_data_service.dart';

class SOSProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  final MockDataService _mock = MockDataService();

  List<SOSTicketModel> _tickets = [];
  bool _isLoading = false;

  List<SOSTicketModel> get tickets => _tickets;
  List<SOSTicketModel> get pendingTickets => _tickets.where((t) => t.isPending).toList();
  List<SOSTicketModel> get inProgressTickets => _tickets.where((t) => t.isInProgress).toList();
  List<SOSTicketModel> get resolvedTickets => _tickets.where((t) => t.isResolved).toList();
  bool get isLoading => _isLoading;

  SOSProvider() {
    loadTickets();
  }

  Future<void> loadTickets() async {
    _isLoading = true;
    notifyListeners();

    _tickets = await _api.getSOSTickets();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> createSOS({
    required String childId,
    required String childName,
    String? parentName,
    String? parentPhone,
    required double latitude,
    required double longitude,
    double noiseLevel = 0.0,
    required String reason,
  }) async {
    final newTicket = SOSTicketModel(
      id: '',
      childId: childId,
      childName: childName,
      parentName: parentName,
      parentPhone: parentPhone,
      latitude: latitude,
      longitude: longitude,
      noiseLevel: noiseLevel,
      reason: reason,
      status: 'pending',
      createdAt: DateTime.now().toIso8601String(),
    );
    final created = await _api.createSOSTicket(newTicket);
    _tickets.insert(0, created);
    notifyListeners();
  }

  Future<void> updateTicketStatus(String id, String status, {String? staffId, String? notes}) async {
    await _api.updateSOSTicketStatus(id, status, staffId: staffId, notes: notes);
    final idx = _tickets.indexWhere((t) => t.id == id);
    if (idx != -1) {
      _tickets[idx] = _tickets[idx].copyWith(
        status: status,
        assignedStaffId: staffId,
        resolutionNotes: notes,
      );
      notifyListeners();
    }
  }
}
