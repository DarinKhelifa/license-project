import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/api_service.dart';
import 'package:orelax/widgets/custom_bottom_nav_bar.dart';

class WorkOrdersScreen extends StatefulWidget {
  const WorkOrdersScreen({super.key});

  @override
  State<WorkOrdersScreen> createState() => _WorkOrdersScreenState();
}

class _WorkOrdersScreenState extends State<WorkOrdersScreen> {
  String _selectedFilter = 'all';
  late Future<List<Map<String, dynamic>>> _reportsFuture;

  @override
  void initState() {
    super.initState();
    _reportsFuture = _loadReports();
  }

  Future<List<Map<String, dynamic>>> _loadReports() async {
    final reports = await ApiService.getReportsForRole();

    // If the backend provides a category field, prefer showing maintenance-only.
    final maintenance = reports.where((r) {
      final category = (r['category'] ?? r['type'] ?? '').toString().toLowerCase();
      if (category.isEmpty) return true;
      return category.contains('maintenance');
    }).toList();

    return maintenance;
  }

  void _refresh() {
    setState(() {
      _reportsFuture = _loadReports();
    });
  }

  String? _getReportId(Map<String, dynamic> report) {
    final id = report['_id'] ?? report['id'] ?? report['reportId'];
    return id?.toString();
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 0),
      appBar: AppBar(
        title: const Text('Work Orders'),
        backgroundColor: const Color(0xFF034808),
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => setState(() => _selectedFilter = value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All')),
              const PopupMenuItem(value: 'pending', child: Text('Pending')),
              const PopupMenuItem(value: 'in-progress', child: Text('In Progress')),
              const PopupMenuItem(value: 'resolved', child: Text('Resolved')),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(_selectedFilter.toUpperCase()),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _reportsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Failed to load work orders: ${snapshot.error}'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _refresh,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final reports = snapshot.data ?? const [];
          final filtered = _selectedFilter == 'all'
              ? reports
              : reports
                  .where((r) => (r['status'] ?? '').toString() == _selectedFilter)
                  .toList();

          if (filtered.isEmpty) {
            return const Center(child: Text('No work orders found.'));
          }

          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final report = filtered[index];

                final status = (report['status'] ?? 'pending').toString();
                final createdAt =
                    _parseDate(report['createdAt']) ?? _parseDate(report['date']);

                final title = (report['subCategory'] ?? report['title'] ?? 'Report')
                    .toString()
                    .trim();
                final description = (report['description'] ?? '').toString();
                final location = (report['location'] ?? report['apartment'] ?? '')
                    .toString()
                    .trim();

                Color statusColor;
                switch (status) {
                  case 'pending':
                    statusColor = Colors.orange;
                    break;
                  case 'in-progress':
                    statusColor = Colors.blue;
                    break;
                  case 'resolved':
                    statusColor = Colors.green;
                    break;
                  default:
                    statusColor = Colors.grey;
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                status.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (description.isNotEmpty) Text(description),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.location_on,
                                size: 16, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                location.isEmpty ? 'N/A' : location,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Icon(Icons.access_time,
                                size: 16, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text(
                              createdAt == null
                                  ? '—'
                                  : DateFormat('MMM dd, HH:mm')
                                      .format(createdAt),
                            ),
                          ],
                        ),
                        if (status != 'resolved')
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (status == 'pending')
                                  ElevatedButton(
                                    onPressed: () {
                                      final id = _getReportId(report);
                                      if (id == null) return;
                                      _updateStatus(id, 'in-progress');
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                    ),
                                    child: const Text('Start Work'),
                                  ),
                                if (status == 'in-progress')
                                  ElevatedButton(
                                    onPressed: () {
                                      final id = _getReportId(report);
                                      if (id == null) return;
                                      _updateStatus(id, 'resolved');
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                    ),
                                    child: const Text('Resolve'),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
  
  Future<void> _updateStatus(String id, String newStatus) async {
    try {
      await ApiService.updateReportStatus(id, newStatus);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status updated to $newStatus')),
      );
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: $e')),
      );
    }
  }
}