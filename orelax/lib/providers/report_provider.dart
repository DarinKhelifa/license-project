import 'package:flutter/material.dart';
import '../models/report_model.dart';
import '../services/api_service.dart';

class ReportProvider extends ChangeNotifier {
  List<Report> _myReports = [];
  bool _isLoading = false;
  String? _error;

  List<Report> get myReports => _myReports;
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
}