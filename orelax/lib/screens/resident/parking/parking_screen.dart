import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';

class ParkingScreen extends StatefulWidget {
  const ParkingScreen({super.key});

  @override
  State<ParkingScreen> createState() => _ParkingScreenState();
}

class _ParkingScreenState extends State<ParkingScreen> {
  static const int _spotCount = 12;
  late Map<String, String> _reservations; // spotId -> userName
  late String _dateKey;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reservations = {};
    _dateKey = _buildDateKey(DateTime.now());
    _loadReservations();
  }

  String _buildDateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return 'parking_reservations_\$y-\$m-\$d';
  }

  Future<void> _loadReservations() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_dateKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final map = json.decode(raw) as Map<String, dynamic>;
        _reservations = map.map((k, v) => MapEntry(k, v.toString()));
      } catch (_) {
        _reservations = {};
      }
    } else {
      _reservations = {};
    }

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _saveReservations() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dateKey, json.encode(_reservations));
  }

  Future<void> _reserveSpot(String spotId) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userName = auth.userName ?? 'You';

    if (_reservations.containsKey(spotId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This spot is already reserved')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reserve spot'),
        content: Text('Reserve spot #\$spotId for today as \$userName?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Reserve')),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _reservations[spotId] = userName);
    await _saveReservations();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Reserved spot #\$spotId')),
    );
  }

  Future<void> _cancelReservation(String spotId) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userName = auth.userName ?? 'You';
    final owner = _reservations[spotId];
    if (owner == null) return;
    if (owner != userName) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can only cancel your own reservation')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel reservation'),
        content: Text('Cancel your reservation for spot #\$spotId?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('No')),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Yes')),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _reservations.remove(spotId));
    await _saveReservations();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Cancelled reservation for spot #\$spotId')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parking'),
        backgroundColor: const Color(0xFF034808),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Parking layout — reserve a spot for today',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 1.1,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                      ),
                      itemCount: _spotCount,
                      itemBuilder: (context, index) {
                        final spotId = 'P\$${index + 1}';
                        final owner = _reservations[spotId];
                        final isTaken = owner != null;
                        return GestureDetector(
                          onTap: () => isTaken ? ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Spot #\$spotId is taken by \$owner')),
                          ) : _reserveSpot(spotId),
                          onLongPress: isTaken ? () => _cancelReservation(spotId) : null,
                          child: Container(
                            decoration: BoxDecoration(
                              color: isTaken ? Colors.red.shade400 : Colors.green.shade400,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6)],
                            ),
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.local_parking,
                                  size: 28,
                                  color: Colors.white,
                                ),
                                const SizedBox(height: 8),
                                Text('Spot #\$spotId', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                if (isTaken) ...[
                                  const SizedBox(height: 6),
                                  Text(owner!, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                ]
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Tap a free spot to reserve. Long-press your reserved spot to cancel.', style: TextStyle(fontSize: 12, color: Colors.black54)),
                  const SizedBox(height: 8),
                ],
              ),
            ),
    );
  }
}
