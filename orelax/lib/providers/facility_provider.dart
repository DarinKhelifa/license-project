import 'package:flutter/material.dart';
import '../models/facility_model.dart';
import '../services/facility_api_service.dart';

class FacilityProvider extends ChangeNotifier {
  List<Facility> _facilities = [];
  bool _isLoading = false;
  String? _error;

  List<Facility> get facilities => _facilities;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Fetch all facilities
  Future<void> fetchFacilities() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _facilities = await FacilityApiService.getFacilities();
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error fetching facilities: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch single facility by ID
  Future<Facility?> getFacilityById(String id) async {
    try {
      return await FacilityApiService.getFacilityById(id);
    } catch (e) {
      debugPrint('Error fetching facility: $e');
      return null;
    }
  }

  // Create new facility
  Future<bool> createFacility(Facility facility) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newFacility = await FacilityApiService.createFacility(facility);
      _facilities.insert(0, newFacility);
      _error = null;
      return true;
    } catch (e) {
      final errorMsg = e.toString();
      _error = errorMsg;
      debugPrint('Error creating facility: $e');
      
      // Log detailed error for debugging
      if (errorMsg.contains('Could not start listening on Socket') ||
          errorMsg.contains('Connection refused')) {
        _error = 'Backend server is not running. Please check that the backend is running on localhost:5001';
      } else if (errorMsg.contains('400')) {
        _error = 'Invalid facility data. Please check all fields are filled correctly';
      } else if (errorMsg.contains('timeout') || errorMsg.contains('Time')) {
        _error = 'Request timed out. Images may be too large. Please use smaller images';
      }
      
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update existing facility
  Future<bool> updateFacility(Facility facility) async {
    _isLoading = true;
    notifyListeners();

    try {
      final updatedFacility = await FacilityApiService.updateFacility(facility);
      final index = _facilities.indexWhere((f) => f.id == facility.id);
      if (index != -1) {
        _facilities[index] = updatedFacility;
      }
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error updating facility: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete facility
  Future<bool> deleteFacility(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      await FacilityApiService.deleteFacility(id);
      _facilities.removeWhere((f) => f.id == id);
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error deleting facility: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}