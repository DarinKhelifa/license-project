import 'package:flutter/material.dart';
import 'package:orelax/widgets/custom_bottom_nav_bar.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../models/alert_model.dart';
import '../../providers/alert_provider.dart';
import '../../services/api_service.dart';

class ReportDetailScreen extends StatefulWidget {
  final String reportId;
  final Alert alert;

  const ReportDetailScreen({
    super.key,
    required this.reportId,
    required this.alert,
  });

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  String _selectedStatus = '';
  Map<String, dynamic>? _reportData;
  bool _isLoading = true;
  String _resolutionNotes = '';

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.alert.status;
    _loadReportDetails();
  }

  Future<void> _loadReportDetails() async {
    try {
      final reports = await ApiService.getReportsForRole();
      final report = reports.firstWhere((r) => r['id'] == widget.reportId);
      setState(() {
        _reportData = report;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading report details: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus() async {
    if (_selectedStatus == widget.alert.status) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    
    try {
      await ApiService.updateReportStatus(widget.reportId, _selectedStatus);
      
      // Update alert provider
      final alertProvider = Provider.of<AlertProvider>(context, listen: false);
      await alertProvider.updateAlertStatus(widget.reportId, _selectedStatus);

      // Send notification to resident if status changed to resolved
      if (_selectedStatus == 'resolved') {
        try {
          await _sendReportTreatedNotification(
            residentId: widget.alert.reportedBy,
            reportId: widget.reportId,
            reportCategory: widget.alert.category,
            resolutionNotes: _resolutionNotes,
          );
          print('✅ Notification sent to resident for treated report');
        } catch (e) {
          print('⚠️ Failed to send notification: $e');
          // Continue anyway - status was updated successfully
        }
      }
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated to ${_selectedStatus.toUpperCase()}'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update status'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _sendReportTreatedNotification({
    required String residentId,
    required String reportId,
    required String reportCategory,
    required String resolutionNotes,
  }) async {
    final token = await ApiService.getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/notifications'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'userId': residentId,
        'title': 'Report Resolved',
        'message': 'Your $reportCategory report has been resolved.',
        'type': 'report_resolved',
        'data': {
          'reportId': reportId,
          'category': reportCategory,
          'resolutionNotes': resolutionNotes,
        }
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to send treated report notification');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        bottomNavigationBar: CustomBottomNavBar(currentIndex: 2),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 2),
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Report Details'),
        backgroundColor: const Color(0xFF034808),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.check_circle_outline),
            onPressed: _updateStatus,
            tooltip: 'Update Status',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Dropdown
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Update Status',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedStatus,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      items: [
                        const DropdownMenuItem(value: 'pending', child: Text('Pending')),
                        const DropdownMenuItem(value: 'in-progress', child: Text('In Progress')),
                        const DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
                        const DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedStatus = value!);
                      },
                    ),
                    if (_selectedStatus == 'resolved')
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: TextField(
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Add resolution notes...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onChanged: (value) => _resolutionNotes = value,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Report Details
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Report Information',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow('Category', widget.alert.category),
                    const SizedBox(height: 12),
                    _buildDetailRow('Type', widget.alert.subCategory),
                    const SizedBox(height: 12),
                    _buildDetailRow('Location', widget.alert.location),
                    const SizedBox(height: 12),
                    _buildDetailRow('Reported By', widget.alert.reportedBy),
                    const SizedBox(height: 12),
                    _buildDetailRow('Date & Time', _formatDateTime(widget.alert.createdAt)),
                    const SizedBox(height: 12),
                    _buildDetailRow('Status', widget.alert.statusText, isStatus: true),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Description
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Description',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _reportData?['description'] ?? 'No description provided',
                      style: const TextStyle(height: 1.5),
                    ),
                  ],
                ),
              ),
            ),

            // Photo if exists
            if (_reportData?['photoBase64'] != null && _reportData!['photoBase64'].isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Attached Photo',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          base64Decode(_reportData!['photoBase64']),
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _updateStatus,
        backgroundColor: const Color(0xFF034808),
        icon: const Icon(Icons.save),
        label: const Text('Update Status'),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isStatus = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        Expanded(
          child: isStatus
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.alert.statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: widget.alert.statusColor),
                  ),
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: widget.alert.statusColor,
                    ),
                  ),
                )
              : Text(
                  value,
                  style: const TextStyle(fontSize: 14),
                ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}