import 'package:flutter/material.dart';
import '../models/contact_model.dart';
import '../services/api_service.dart';

class ContactProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<ContactModel> _contacts = [];
  bool _isLoading = false;

  List<ContactModel> get contacts => _contacts;
  List<ContactModel> get sosContacts => _contacts.where((c) => c.isSosContact).toList();
  bool get isLoading => _isLoading;

  Future<void> loadContacts(String childId) async {
    _isLoading = true;
    notifyListeners();

    _contacts = await _api.getContacts(childId);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addContact(ContactModel con) async {
    final created = await _api.createContact(con);
    _contacts.insert(0, created);
    notifyListeners();
  }

  Future<void> updateContact(ContactModel con) async {
    await _api.updateContact(con);
    final idx = _contacts.indexWhere((c) => c.id == con.id);
    if (idx != -1) {
      _contacts[idx] = con;
      notifyListeners();
    }
  }

  Future<void> deleteContact(String id) async {
    await _api.deleteContact(id);
    _contacts.removeWhere((c) => c.id == id);
    notifyListeners();
  }
}
