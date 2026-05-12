import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/customer_model.dart';

class CustomerController extends ChangeNotifier {
  List<CustomerModel> _customers = [];
  List<CustomerModel> _filteredCustomers = [];
  bool _isLoading = false;
  int _currentPage = 1;
  final int _rowsPerPage = 10;
  Map<String, int> _orderCountMap = {};

  List<CustomerModel> get customers => _customers;
  List<CustomerModel> get paginatedData {
    final startIndex = (_currentPage - 1) * _rowsPerPage;
    final endIndex = startIndex + _rowsPerPage;
    return _filteredCustomers.sublist(
      startIndex,
      endIndex > _filteredCustomers.length
          ? _filteredCustomers.length
          : endIndex,
    );
  }

  bool get isLoading => _isLoading;
  int get currentPage => _currentPage;
  int get rowsPerPage => _rowsPerPage;
  int get totalPages => (_filteredCustomers.length / _rowsPerPage).ceil();
  Map<String, int> get orderCountMap => _orderCountMap;

  Future<void> fetchCustomers() async {
    _isLoading = true;
    notifyListeners();
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();
      _customers = snapshot.docs
          .map((doc) => CustomerModel.fromMap(doc.data()))
          .toList();
      _filteredCustomers = _customers;
      await _fetchOrderCounts();
    } catch (e) {
      // Handle error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchOrderCounts() async {
    for (var customer in _customers) {
      final orderSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: customer.id)
          .get();
      _orderCountMap[customer.id] = orderSnapshot.docs.length;
    }
  }

  void search(String query) {
    if (query.isEmpty) {
      _filteredCustomers = _customers;
    } else {
      _filteredCustomers = _customers.where((customer) {
        return customer.firstName.toLowerCase().contains(query.toLowerCase()) ||
            customer.lastName.toLowerCase().contains(query.toLowerCase()) ||
            customer.email.toLowerCase().contains(query.toLowerCase()) ||
            customer.phone.contains(query);
      }).toList();
    }
    _currentPage = 1;
    notifyListeners();
  }

  void changePage(int page) {
    _currentPage = page;
    notifyListeners();
  }

  Future<void> delete(String id) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(id).delete();
      _customers.removeWhere((c) => c.id == id);
      _filteredCustomers.removeWhere((c) => c.id == id);
      _orderCountMap.remove(id);
      notifyListeners();
    } catch (e) {
      // Handle error
    }
  }

  Future<List<Map<String, dynamic>>> getOrders(String customerId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: customerId)
          .get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      return [];
    }
  }
}
