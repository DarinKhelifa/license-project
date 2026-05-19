import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../../providers/auth_provider.dart';
import '../../../services/api_service.dart';

class ParkingScreen extends StatefulWidget {
  const ParkingScreen({super.key});

  @override
  State<ParkingScreen> createState() => _ParkingScreenState();
}

class _ParkingScreenState extends State<ParkingScreen> {
  bool _loading = true;
  String? _errorMessage;
  String? _residenceId;
  String? _residenceName;
  Timer? _refreshTimer;

  List<Map<String, dynamic>> _parkingLots = [];
  Map<String, dynamic>? _selectedLot;
  Map<String, dynamic>? _selectedLotDetails;

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 1));

  @override
  void initState() {
    super.initState();
    _loadParkingData();
    // Auto-refresh parking data every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadParkingData();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadParkingData() async {
    final authProvider = context.read<AuthProvider>();
    final residenceId = authProvider.residenceId;

    if (residenceId == null || residenceId.isEmpty) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'No residence is linked to your account.';
        _loading = false;
      });
      return;
    }

    setState(() {
      _residenceId = residenceId;
      _loading = true;
      _errorMessage = null;
    });

    try {
      final data = await ApiService.getParkingLots(residenceId);
      final lots = List<Map<String, dynamic>>.from(data['parkingLots'] ?? []);

      if (!mounted) return;
      setState(() {
        _residenceName = data['residenceName']?.toString();
        _parkingLots = lots;
        _selectedLot = lots.isNotEmpty ? lots.first : null;
      });

      if (_selectedLot != null) {
        await _loadSelectedLotDetails();
      }

      if (!mounted) return;
      setState(() => _loading = false);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadSelectedLotDetails() async {
    if (_residenceId == null || _selectedLot == null) return;

    try {
      final data = await ApiService.getParkingLotDetails(
        _residenceId!,
        _selectedLot!['id'].toString(),
      );

      if (!mounted) return;
      setState(() {
        _selectedLotDetails = Map<String, dynamic>.from(data['parkingLot'] ?? {});
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.toString());
    }
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate.add(const Duration(days: 1));
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate.add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );

    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  Future<void> _reserveSpot(String spotCode) async {
    if (_residenceId == null || _selectedLot == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reserve parking spot'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Parking: ${_selectedLot!['name']}'),
            Text('Spot: $spotCode'),
            const SizedBox(height: 8),
            Text('From: ${_startDate.toString().split(' ')[0]}'),
            Text('To: ${_endDate.toString().split(' ')[0]}'),
            const SizedBox(height: 12),
            const Text(
              'The reservation will stay pending until the admin approves it.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Reserve'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ApiService.createParkingReservation(
        residenceId: _residenceId!,
        parkingLotId: _selectedLot!['id'].toString(),
        spotCode: spotCode,
        startDate: _startDate,
        endDate: _endDate,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reservation created. Waiting for approval.'),
          backgroundColor: Colors.green,
        ),
      );
      await _loadSelectedLotDetails();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _spotColor(Map<String, dynamic> spot) {
    final status = (spot['status'] ?? 'available').toString();
    switch (status) {
      case 'reserved':
        return const Color(0xFFD94B4B);
      case 'pending':
        return const Color(0xFFF2B84B);
      default:
        return const Color(0xFF4CAF50);
    }
  }

  String _spotStatusText(Map<String, dynamic> spot) {
    final reservation = spot['reservation'];
    if (reservation is Map<String, dynamic>) {
      final status = (reservation['status'] ?? spot['status'] ?? 'available').toString();
      if (status == 'approved') return 'Reserved';
      if (status == 'pending') return 'Pending';
    }
    final status = (spot['status'] ?? 'available').toString();
    return status == 'available' ? 'Free' : status.substring(0, 1).toUpperCase() + status.substring(1);
  }

  List<List<Map<String, dynamic>>> _chunkSpots(List<Map<String, dynamic>> spots, int size) {
    final chunks = <List<Map<String, dynamic>>>[];
    for (var index = 0; index < spots.length; index += size) {
      final end = index + size > spots.length ? spots.length : index + size;
      chunks.add(spots.sublist(index, end));
    }
    return chunks;
  }

  @override
  Widget build(BuildContext context) {
    final lot = _selectedLotDetails ?? _selectedLot;
    final spots = List<Map<String, dynamic>>.from(lot?['spots'] ?? const []);
    final spotRows = _chunkSpots(spots, 8);
    final reservedCount = spots.where((spot) => (spot['status'] ?? '').toString() != 'available').length;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F5EF),
      appBar: AppBar(
        title: const Text('Parking'),
        backgroundColor: const Color(0xFF034808),
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.local_parking, size: 56, color: Color(0xFF034808)),
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadParkingData,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadParkingData,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF034808), Color(0xFF0E6B16)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Parking slots',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _residenceName ?? 'Your residence',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _parkingLots.map((lotItem) {
                                final selected = _selectedLot?['id'] == lotItem['id'];
                                return ChoiceChip(
                                  selected: selected,
                                  label: Text(lotItem['name'].toString()),
                                  selectedColor: Colors.white,
                                  backgroundColor: Colors.white.withOpacity(0.18),
                                  labelStyle: TextStyle(
                                    color: selected ? const Color(0xFF034808) : Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  onSelected: (_) async {
                                    setState(() {
                                      _selectedLot = lotItem;
                                      _selectedLotDetails = null;
                                    });
                                    await _loadSelectedLotDetails();
                                  },
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _InfoCard(
                              title: 'Total spots',
                              value: '${spots.length}',
                              icon: Icons.local_parking,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _InfoCard(
                              title: 'Reserved',
                              value: '$reservedCount',
                              icon: Icons.block,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFD8E3D5)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      lot?['name']?.toString() ?? 'Parking',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    Text(
                                      '${spots.length} slots available in this lot',
                                      style: const TextStyle(
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEEF6EE),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: const Text(
                                    'Resident parking',
                                    style: TextStyle(
                                      color: Color(0xFF034808),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              height: 16,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE0E4DD),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Stack(
                                children: [
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Container(
                                      width: MediaQuery.of(context).size.width * 0.40,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFB5C8B0),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                    ),
                                  ),
                                  const Center(
                                    child: Text(
                                      'Entry lane',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (spots.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 24),
                                child: Center(
                                  child: Text('No parking slots found for this lot.'),
                                ),
                              )
                            else
                              Column(
                                children: spotRows.asMap().entries.map((entry) {
                                  final rowIndex = entry.key;
                                  final rowSpots = entry.value;

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAF6),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: const Color(0xFFE2E9DE)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Row ${rowIndex + 1}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFF034808),
                                              ),
                                            ),
                                            Text(
                                              '${rowSpots.length} slots',
                                              style: const TextStyle(
                                                color: Colors.black54,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        GridView.builder(
                                          shrinkWrap: true,
                                          physics: const NeverScrollableScrollPhysics(),
                                          itemCount: rowSpots.length,
                                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 4,
                                            childAspectRatio: 0.92,
                                            mainAxisSpacing: 10,
                                            crossAxisSpacing: 10,
                                          ),
                                          itemBuilder: (context, index) {
                                            final spot = rowSpots[index];
                                            final status = (spot['status'] ?? 'available').toString();
                                            final reserved = status != 'available';
                                            final reservation = spot['reservation'];
                                            final residentName = reservation is Map<String, dynamic>
                                                ? reservation['residentName']?.toString()
                                                : null;

                                            return GestureDetector(
                                              onTap: reserved ? null : () => _reserveSpot(spot['code'].toString()),
                                              child: AnimatedContainer(
                                                duration: const Duration(milliseconds: 180),
                                                decoration: BoxDecoration(
                                                  color: _spotColor(spot),
                                                  borderRadius: BorderRadius.circular(18),
                                                  border: Border.all(
                                                    color: reserved ? Colors.white : const Color(0xFF2E7D32),
                                                    width: 2,
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black.withOpacity(0.08),
                                                      blurRadius: 10,
                                                      offset: const Offset(0, 6),
                                                    ),
                                                  ],
                                                ),
                                                child: Stack(
                                                  children: [
                                                    Positioned(
                                                      top: 8,
                                                      right: 8,
                                                      child: Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                        decoration: BoxDecoration(
                                                          color: Colors.white.withOpacity(0.22),
                                                          borderRadius: BorderRadius.circular(999),
                                                        ),
                                                        child: Text(
                                                          _spotStatusText(spot),
                                                          style: const TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 10,
                                                            fontWeight: FontWeight.w700,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    Center(
                                                      child: Column(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: [
                                                          const Icon(
                                                            Icons.directions_car,
                                                            color: Colors.white,
                                                            size: 28,
                                                          ),
                                                          const SizedBox(height: 6),
                                                          Text(
                                                            spot['code'].toString(),
                                                            textAlign: TextAlign.center,
                                                            style: const TextStyle(
                                                              color: Colors.white,
                                                              fontWeight: FontWeight.w900,
                                                              fontSize: 13,
                                                            ),
                                                          ),
                                                          if (residentName != null && residentName.isNotEmpty) ...[
                                                            const SizedBox(height: 4),
                                                            Padding(
                                                              padding: const EdgeInsets.symmetric(horizontal: 6),
                                                              child: Text(
                                                                residentName,
                                                                maxLines: 2,
                                                                overflow: TextOverflow.ellipsis,
                                                                textAlign: TextAlign.center,
                                                                style: const TextStyle(
                                                                  color: Colors.white,
                                                                  fontSize: 10,
                                                                  fontWeight: FontWeight.w600,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFD8E3D5)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Legend',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 16,
                              runSpacing: 10,
                              children: [
                                _LegendItem(color: Color(0xFF4CAF50), label: 'Available'),
                                _LegendItem(color: Color(0xFFD94B4B), label: 'Reserved'),
                                _LegendItem(color: Color(0xFFF2B84B), label: 'Pending'),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Tap a green slot to create a pending reservation. Reserved slots show the resident name.',
                              style: TextStyle(color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _selectStartDate,
                              child: Text('From ${_startDate.toString().split(' ')[0]}'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _selectEndDate,
                              child: Text('To ${_endDate.toString().split(' ')[0]}'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _InfoCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD8E3D5)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF6EE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF034808)),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.black54, fontSize: 12)),
              Text(
                value,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }
}
