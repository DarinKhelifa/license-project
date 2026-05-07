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
  int? _hoveredReportIndex;

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
      backgroundColor: const Color(0xFFF2F5F1),
      appBar: AppBar(
        title: const Text(
          'Reports',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF1F2D25),
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        toolbarHeight: 68,
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
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 14, 12, 8),
                child: _buildFilterBar(),
              ),
              Expanded(
                child: filteredReports.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.report_problem_outlined, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              'No reports',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => reportProvider.fetchMyReports(),
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                          itemCount: filteredReports.length,
                          itemBuilder: (context, index) {
                            final report = filteredReports[index];
                            return _buildReportCard(report, index);
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

  Widget _buildFilterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip('all', 'All', showCheck: true),
          const SizedBox(width: 10),
          _buildFilterChip('pending', 'Pending'),
          const SizedBox(width: 10),
          _buildFilterChip('in-progress', 'In Progress'),
          const SizedBox(width: 10),
          _buildFilterChip('resolved', 'Resolved'),
          const SizedBox(width: 10),
          _buildFilterChip('rejected', 'Rejected'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, {bool showCheck = false}) {
    final isSelected = _selectedFilter == value;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => setState(() => _selectedFilter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF213B28) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF213B28) : Colors.grey.shade300,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showCheck || isSelected) ...[
              Icon(
                isSelected ? Icons.check : Icons.circle,
                size: 16,
                color: isSelected ? Colors.white : Colors.transparent,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF5E6B6A),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(dynamic report, int index) {
    final statusColor = _getStatusColor(report.status);
    final isInProgress = report.status == 'in-progress';
    final isHovered = _hoveredReportIndex == index;

    return MouseRegion(
      onEnter: (_) {
        if (_hoveredReportIndex != index) {
          setState(() => _hoveredReportIndex = index);
        }
      },
      onExit: (_) {
        if (_hoveredReportIndex == index) {
          setState(() => _hoveredReportIndex = null);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(bottom: 12),
        transform: Matrix4.identity()..translate(0.0, isHovered ? -2.0 : 0.0),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isHovered ? const Color(0xFFFAFCFB) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isHovered ? const Color(0xFFD4E5D9) : Colors.transparent,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isHovered ? Colors.black.withOpacity(0.08) : Colors.black.withOpacity(0.05),
              blurRadius: isHovered ? 20 : 12,
              offset: Offset(0, isHovered ? 12 : 4),
            ),
          ],
        ),
        child: InkWell(
        borderRadius: BorderRadius.circular(14),
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: (isInProgress ? const Color(0xFFD7F6DD) : const Color(0xFFF0F7F1)),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isInProgress ? Icons.autorenew_rounded : Icons.report_problem_rounded,
                color: isInProgress ? const Color(0xFF2E9E53) : const Color(0xFF233B2B),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF253238),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${report.subCategory} • ${DateFormat('MMM dd, HH:mm').format(report.createdAt)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _buildStatusBadge(report.status, statusColor),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildStatusBadge(String status, Color color) {
    final label = status.toUpperCase();
    return Container(
      constraints: const BoxConstraints(minWidth: 82),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          height: 1.05,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
          color: color,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.red;
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
