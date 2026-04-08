import 'package:flutter/material.dart';
import '../models/event_model.dart';
import '../services/api_service.dart';

class EventProvider extends ChangeNotifier {
  List<Event> _events = [];
  List<Event> _myEvents = [];
  bool _isLoading = false;
  String? _error;

  List<Event> get events => _events;
  List<Event> get myEvents => _myEvents;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Fetch all approved events
  Future<void> fetchEvents() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await ApiService.getEvents();
      _events = data.map((json) => Event.fromMap(json)).toList();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error fetching events: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch user's own events
  Future<void> fetchMyEvents() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await ApiService.getMyEvents();
      _myEvents = data.map((json) => Event.fromMap(json)).toList();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error fetching my events: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create new event
  Future<bool> createEvent(Event event) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await ApiService.createEvent(event.toMap());
      await fetchMyEvents();
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error creating event: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update event
  Future<bool> updateEvent(Event event) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await ApiService.updateEvent(event.id, event.toMap());
      await fetchMyEvents();
      await fetchEvents();
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error updating event: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cancel event
  Future<bool> cancelEvent(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await ApiService.cancelEvent(id);
      await fetchMyEvents();
      await fetchEvents();
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error canceling event: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get event by ID
  Event? getEventById(String id) {
    try {
      return _events.firstWhere((event) => event.id == id);
    } catch (e) {
      return null;
    }
  }
}