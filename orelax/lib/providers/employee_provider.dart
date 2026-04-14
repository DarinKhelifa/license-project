import 'dart:io';
import 'package:flutter/material.dart';
import '../models/employee_model.dart';
import '../services/employee_api_service.dart';

class EmployeeProvider extends ChangeNotifier {
  List<Employee> _employees = [];
  bool _isLoading = false;
  String? _error;

  List<Employee> get employees => _employees;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Fetch all employees
  Future<void> fetchEmployees() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _employees = await EmployeeApiService.getAllEmployees();
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error fetching employees: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create employee
  Future<bool> createEmployee({
    required String firstName,
    required String lastName,
    required String cinId,
    required String address,
    required String phone,
    required String email,
    required String workCategory,
    required String experience,
    File? photo,
    File? casierJudiciaire,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newEmployee = await EmployeeApiService.createEmployee(
        firstName: firstName,
        lastName: lastName,
        cinId: cinId,
        address: address,
        phone: phone,
        email: email,
        workCategory: workCategory,
        experience: experience,
        photo: photo,
        casierJudiciaire: casierJudiciaire,
      );
      _employees.insert(0, newEmployee);
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error creating employee: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete employee
  Future<bool> deleteEmployee(String employeeId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await EmployeeApiService.deleteEmployee(employeeId);
      _employees.removeWhere((e) => e.id == employeeId);
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error deleting employee: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}