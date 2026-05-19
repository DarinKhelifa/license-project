import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/api_service.dart';
import 'package:orelax/widgets/maintenance_bottom_nav_bar.dart';

class WorkOrdersScreen extends StatefulWidget {
  const WorkOrdersScreen({super.key});

  @override
  State<WorkOrdersScreen> createState() => _WorkOrdersScreenState();
}

class _WorkOrdersScreenState extends State<WorkOrdersScreen> {
  String _selectedFilter = 'all';
  String _selectedSubCategory = 'all';
  late Future<List<Map<String, dynamic>>> _reportsFuture;

  static const Set<String> _maintenanceSubCategories = {
    'plumbing',
    'electrical',
    'pest',
    'structural',
  };

  @override
  void initState() {
    super.initState();
    _reportsFuture = _loadReports();
  }

  Future<List<Map<String, dynamic>>> _loadReports() async {
    final reports = await ApiService.getReportsForRole();

    final maintenance = reports.where((r) {
      final category = _normalizedValue(r['category'] ?? r['type']);
      final subCategory = _normalizedValue(r['subCategory'] ?? r['subcategory']);

      if (category.contains('maintenance')) {
        return true;
      }

      return _maintenanceSubCategories.contains(subCategory);
    }).toList();

    return maintenance;
  }

  void _refresh() {
    setState(() {
      _reportsFuture = _loadReports();
    });
  }

  String _normalizedValue(dynamic value) => value.toString().trim().toLowerCase();

  String _formatLabel(String value) {
    if (value.isEmpty) return 'Unknown';
    return value
        .replaceAll('_', ' ')
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }

  String? _getReportId(Map<String, dynamic> report) {
    final id = report['id'] ?? report['reportId'] ?? report['_id'];
    return id?.toString();
  }

  String _getStatus(Map<String, dynamic> report) {
    return _normalizedValue(report['status']).isEmpty
        ? 'pending'
        : _normalizedValue(report['status']);
  }

  String _getSubCategory(Map<String, dynamic> report) {
    final value = report['subCategory'] ?? report['subcategory'] ?? report['title'];
    return _normalizedValue(value);
  }

  bool _matchesSelectedSubCategory(Map<String, dynamic> report) {
    if (_selectedSubCategory == 'all') return true;
    return _getSubCategory(report) == _selectedSubCategory;
  }

  List<String> _availableSubCategories(List<Map<String, dynamic>> reports) {
    final subCategories = reports
        .map(_getSubCategory)
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();
    subCategories.sort();
    return subCategories;
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
      bottomNavigationBar: const MaintenanceBottomNavBar(currentIndex: 0),
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
          final availableSubCategories = _availableSubCategories(reports);
          final filtered = reports.where((r) {
            final status = _getStatus(r);
            final matchesStatus = _selectedFilter == 'all' || status == _selectedFilter;
            final matchesSubCategory = _matchesSelectedSubCategory(r);
            return matchesStatus && matchesSubCategory;
          }).toList();

          if (filtered.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.build_circle_outlined, size: 56, color: Colors.grey),
                    const SizedBox(height: 12),
                    const Text(
                      'No maintenance work orders found.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _selectedSubCategory == 'all'
                          ? 'Try changing the status filter or refresh the list.'
                          : 'No reports match the selected subcategory.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  elevation: 0,
                  color: const Color(0xFFF3F8F4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.green.shade100),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Maintenance queue',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Resident reports in the maintenance category and its subcategories.',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            FilterChip(
                              label: const Text('All subcategories'),
                              selected: _selectedSubCategory == 'all',
                              onSelected: (_) => setState(() => _selectedSubCategory = 'all'),
                            ),
                            ...availableSubCategories.map((subCategory) {
                              final selected = _selectedSubCategory == subCategory;
                              return FilterChip(
                                label: Text(_formatLabel(subCategory)),
                                selected: selected,
                                onSelected: (_) => setState(() => _selectedSubCategory = subCategory),
                              );
                            }),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ...filtered.map((report) {
                  final status = _getStatus(report);
                  final createdAt = _parseDate(report['createdAt']) ?? _parseDate(report['date']);

                  final title = _formatLabel(_getSubCategory(report));
                  final description = (report['description'] ?? '').toString();
                  final location = (report['location'] ?? report['apartment'] ?? '')
                      .toString()
                      .trim();
                  final subCategory = _formatLabel(_getSubCategory(report));
                  final category = _formatLabel(_normalizedValue(report['category'] ?? report['type']));

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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$category • $subCategory',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.2),
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
                                    : DateFormat('MMM dd, HH:mm').format(createdAt),
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
                }),
              ],
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