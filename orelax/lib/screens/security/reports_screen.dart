import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/report_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/alert_model.dart';
import 'report_detail_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    // Load reports depending on user role
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final reportProvider = Provider.of<ReportProvider>(context, listen: false);
      final auth = Provider.of<AuthProvider>(context, listen: false);
      try {
        final role = (auth.user?['role'] ?? 'resident').toString();
        if (role == 'security' || role == 'admin' || role == 'maintenance') {
          reportProvider.fetchReportsForRole();
        } else {
          reportProvider.fetchMyReports();
        }
      } catch (_) {
        reportProvider.fetchMyReports();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
      ),
      body: Consumer<ReportProvider>(
        builder: (context, reportProvider, _) {
          final auth = Provider.of<AuthProvider>(context, listen: false);
          final role = (auth.user?['role'] ?? 'resident').toString();
          final reports = (role == 'security' || role == 'admin' || role == 'maintenance')
              ? reportProvider.allReports
              : reportProvider.myReports;

          final filteredReports = _selectedFilter == 'all'
              ? reports
              : reports.where((r) => r.status == _selectedFilter).toList();

          return Column(
            children: [
              // Filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    _buildFilterChip('all', 'All'),
                    const SizedBox(width: 8),
                    _buildFilterChip('pending', 'Pending'),
                    const SizedBox(width: 8),
                    _buildFilterChip('in-progress', 'In Progress'),
                    const SizedBox(width: 8),
                    _buildFilterChip('resolved', 'Resolved'),
                    const SizedBox(width: 8),
                    _buildFilterChip('rejected', 'Rejected'),
                  ],
                ),
              ),
              
              // Reports list
              Expanded(
                child: filteredReports.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.report_problem_outlined, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('No reports'),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => reportProvider.fetchMyReports(),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: filteredReports.length,
                          itemBuilder: (context, index) {
                            final report = filteredReports[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.orange.shade100,
                                  child: Icon(Icons.report, color: Colors.orange.shade700),
                                ),
                                title: Text(
                                  report.category,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  '${report.subCategory} • ${DateFormat('MMM dd, HH:mm').format(report.createdAt)}',
                                ),
                                trailing: Chip(
                                  label: Text(report.status.toUpperCase(), style: const TextStyle(fontSize: 10)),
                                  backgroundColor: _getStatusColor(report.status).withOpacity(0.2),
                                  labelStyle: TextStyle(color: _getStatusColor(report.status)),
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ReportDetailScreen(
                                        reportId: report.id,
                                        alert: Alert(
                                          id: report.id,
                                          title: report.category,
                                          message: report.description,
                                          category: report.category,
                                          subCategory: report.subCategory,
                                          location: report.location,
                                          reportedBy: report.createdByName,
                                          createdAt: report.createdAt,
                                          status: report.status,
                                          reportId: report.id,
                                          alertType: 'report',
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    return FilterChip(
      label: Text(label),
      selected: _selectedFilter == value,
      onSelected: (selected) {
        setState(() => _selectedFilter = value);
      },
      backgroundColor: Colors.grey.shade200,
      selectedColor: Colors.orange.shade700,
      labelStyle: TextStyle(
        color: _selectedFilter == value ? Colors.white : Colors.black,
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'in-progress':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
