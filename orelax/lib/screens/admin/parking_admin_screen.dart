import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class ParkingAdminScreen extends StatefulWidget {
  final String residenceId;

  const ParkingAdminScreen({
    required this.residenceId,
    super.key,
  });

  @override
  State<ParkingAdminScreen> createState() => _ParkingAdminScreenState();
}

class _ParkingAdminScreenState extends State<ParkingAdminScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _reservations = [];
  String? _errorMessage;
  String? _selectedFilter = 'pending'; // pending, approved, rejected, all

  @override
  void initState() {
    super.initState();
    _loadReservations();
  }

  Future<void> _loadReservations() async {
    setState(() => _loading = true);

    try {
      final reservations =
          await ApiService.getResidenceReservations(widget.residenceId);
      
      if (mounted) {
        setState(() {
          _reservations =
              List<Map<String, dynamic>>.from(reservations);
          _errorMessage = null;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _approveReservation(String reservationId) async {
    try {
      await ApiService.approveReservation(widget.residenceId, reservationId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reservation approved!'),
          backgroundColor: Colors.green,
        ),
      );
      _loadReservations();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectReservation(String reservationId) async {
    final controller = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Reservation'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter rejection reason (optional)',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reject'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (result != true) return;

    try {
      await ApiService.rejectReservation(
        widget.residenceId,
        reservationId,
        rejectionReason: controller.text.isNotEmpty ? controller.text : null,
      );
      controller.dispose();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reservation rejected!'),
            backgroundColor: Colors.orange,
          ),
        );
        _loadReservations();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> _getFilteredReservations() {
    if (_selectedFilter == 'all') {
      return _reservations;
    }
    return _reservations
        .where((res) => res['status'] == _selectedFilter)
        .toList();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _getFilteredReservations();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Parking Reservations'),
        backgroundColor: const Color(0xFF034808),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: $_errorMessage'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadReservations,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Filter chips
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: ['pending', 'approved', 'rejected', 'all']
                              .map((status) {
                            final isSelected = _selectedFilter == status;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: FilterChip(
                                label: Text(
                                  status.replaceFirst(
                                    status[0],
                                    status[0].toUpperCase(),
                                  ),
                                ),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() => _selectedFilter = status);
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    // Reservations list
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
                              child: Text(
                                'No ${_selectedFilter == 'all' ? 'reservations' : _selectedFilter + ' reservations'} found',
                              ),
                            )
                          : ListView.builder(
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final reservation = filtered[index];
                                final status = reservation['status'];

                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Header with status
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              reservation['spotCode'] ?? 'N/A',
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Chip(
                                              label: Text(status),
                                              backgroundColor: _getStatusColor(
                                                status,
                                              ),
                                              labelStyle: const TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        // Resident info
                                        Text(
                                          'Resident: ${reservation['residentName'] ?? 'N/A'}',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                        Text(
                                          'Apartment: ${reservation['apartmentRef'] ?? 'N/A'}',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                        const SizedBox(height: 8),
                                        // Dates
                                        Text(
                                          'From: ${DateTime.parse(reservation['startDate']).toString().split(' ')[0]}',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        Text(
                                          'To: ${DateTime.parse(reservation['endDate']).toString().split(' ')[0]}',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        const SizedBox(height: 12),
                                        // Action buttons (only for pending)
                                        if (status == 'pending')
                                          Row(
                                            children: [
                                              Expanded(
                                                child: ElevatedButton.icon(
                                                  onPressed: () =>
                                                      _approveReservation(
                                                    reservation['_id'],
                                                  ),
                                                  icon: const Icon(
                                                    Icons.check_circle,
                                                  ),
                                                  label:
                                                      const Text('Approve'),
                                                  style: ElevatedButton
                                                      .styleFrom(
                                                    backgroundColor:
                                                        Colors.green,
                                                    foregroundColor:
                                                        Colors.white,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: ElevatedButton.icon(
                                                  onPressed: () =>
                                                      _rejectReservation(
                                                    reservation['_id'],
                                                  ),
                                                  icon: const Icon(
                                                    Icons.cancel,
                                                  ),
                                                  label: const Text('Reject'),
                                                  style: ElevatedButton
                                                      .styleFrom(
                                                    backgroundColor:
                                                        Colors.red,
                                                    foregroundColor:
                                                        Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}
