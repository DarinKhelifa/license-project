import 'package:flutter/material.dart';
import '../services/energy_service.dart';
import '../services/chat_service.dart';

class EnergyProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _currentReadings = [];
  List<Map<String, dynamic>> _chartData = [];
  Map<String, dynamic> _summary = {};
  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _alerts = [];

  List<Map<String, dynamic>> get currentReadings => _currentReadings;
  List<Map<String, dynamic>> get chartData => _chartData;
  Map<String, dynamic> get summary => _summary;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Map<String, dynamic>> get alerts => _alerts;

  EnergyProvider() {
    _setupWebSocketListener();
  }

  void _setupWebSocketListener() {
    ChatService.addNewMessageListener((data) {
      // Check if it's an energy update
      if (data['type'] == 'energy-update') {
        _updateCurrentReading(data['data']);
      } else if (data['type'] == 'energy-alert') {
        _addAlert(data['data']);
      }
    });
  }

  void _updateCurrentReading(Map<String, dynamic> reading) {
    final index = _currentReadings.indexWhere((r) => r['deviceId'] == reading['deviceId']);
    if (index != -1) {
      _currentReadings[index] = reading;
    } else {
      _currentReadings.add(reading);
    }
    notifyListeners();
  }

  /// Update a single energy reading (used by simulator)
  void updateEnergyReading(Map<String, dynamic> reading) {
    _updateCurrentReading(reading);
  }

  void _addAlert(Map<String, dynamic> alert) {
    _alerts.insert(0, alert);
    notifyListeners();
  }

  Future<void> fetchCurrentReadings() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await EnergyService.getCurrentReadings();
      final fetchedReadings = (data as List<dynamic>).cast<Map<String, dynamic>>();
      final mergedReadings = <String, Map<String, dynamic>>{};

      for (final reading in _currentReadings) {
        final deviceId = reading['deviceId']?.toString();
        if (deviceId != null && deviceId.isNotEmpty) {
          mergedReadings[deviceId] = reading;
        }
      }

      for (final reading in fetchedReadings) {
        final deviceId = reading['deviceId']?.toString();
        if (deviceId != null && deviceId.isNotEmpty) {
          mergedReadings[deviceId] = reading;
        }
      }

      _currentReadings = mergedReadings.values.toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchHistoricalData({String? deviceId, int days = 7}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await EnergyService.getHistoricalData(deviceId: deviceId, days: days);
      _chartData = (data['chartData'] as List<dynamic>).cast<Map<String, dynamic>>();
      _summary = Map<String, dynamic>.from(data['summary'] as Map);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  double getTotalConsumption() {
    return _currentReadings.fold(0.0, (sum, r) => sum + (r['value'] ?? 0));
  }

  String getFormattedTotal() {
    final total = getTotalConsumption();
    return '${total.toStringAsFixed(1)} kWh';
  }
}