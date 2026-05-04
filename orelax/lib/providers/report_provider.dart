import 'package:flutter/material.dart';
import '../models/report_model.dart';
import '../services/api_service.dart';

class ReportProvider extends ChangeNotifier {
  List<Report> _myReports = [];
  List<Report> _allReports = [];
  bool _isLoading = false;
  String? _error;

  List<Report> get myReports => _myReports;
  List<Report> get allReports => _allReports;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Create new report
  Future<bool> createReport(Report report) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await ApiService.createReport(report.toMap());
      await fetchMyReports();
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error creating report: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch user's reports
  Future<void> fetchMyReports() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await ApiService.getMyReports();
      _myReports = data.map((json) => Report.fromMap(json)).toList();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error fetching reports: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch reports for admin/security role
  Future<void> fetchReportsForRole() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await ApiService.getReportsForRole();
      _allReports = data.map((json) => Report.fromMap(json)).toList();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error fetching reports for role: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  }