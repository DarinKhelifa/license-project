import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/alert_provider.dart';
import '../../providers/fire_alert_provider.dart';
import '../../models/alert_model.dart';
import 'report_detail_screen.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AlertProvider>(context, listen: false).fetchAlerts();
      try {
        Provider.of<FireAlertProvider>(context, listen: false).fetchHistory();
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final alertProvider = Provider.of<AlertProvider>(context);
    final fireAlertProvider = Provider.of<FireAlertProvider>(context);
    final alerts = alertProvider.alerts;
    
    // Filter alerts
    var filteredAlerts = alerts;
    if (_filterStatus != 'all') {
      filteredAlerts = alerts.where((a) => a.status == _filterStatus).toList();
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Security Alerts',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All Alerts'),
            Tab(text: 'Unread'),
          ],
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
        ),
        actions: [
          if (alertProvider.unreadAlerts.isNotEmpty)
            IconButton(
              icon: Badge(
                label: Text('${alertProvider.unreadAlerts.length}'),
                child: const Icon(Icons.mark_email_read),
              ),
              onPressed: () {
                alertProvider.markAllAsRead();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All alerts marked as read')),
                );
              },
            ),
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() => _filterStatus = value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All Status')),
              const PopupMenuItem(value: 'pending', child: Text('Pending')),
              const PopupMenuItem(value: 'in-progress', child: Text('In Progress')),
              const PopupMenuItem(value: 'resolved', child: Text('Resolved')),
              const PopupMenuItem(value: 'rejected', child: Text('Rejected')),
            ],
            icon: const Icon(Icons.filter_list),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // All Alerts (with fire alerts integrated)
          alertProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildCombinedAlertsList(filteredAlerts, fireAlertProvider, false),

          // Unread (with unread fire alerts)
          _buildUnreadAlertsList(alertProvider, fireAlertProvider),
        ],
      ),
    );
  }

  Widget _buildCombinedAlertsList(List<Alert> regularAlerts, FireAlertProvider fireAlerts, bool unreadOnly) {
    if (regularAlerts.isEmpty && fireAlerts.alerts.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        await Provider.of<AlertProvider>(context, listen: false).fetchAlerts();
        await fireAlerts.fetchHistory();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: regularAlerts.length + fireAlerts.alerts.length,
        itemBuilder: (context, index) {
          // Show fire alerts first
          if (index < fireAlerts.alerts.length) {
            final fireAlert = fireAlerts.alerts[index];
            return _buildFireAlertCard(fireAlert, fireAlerts);
          } else {
            final alert = regularAlerts[index - fireAlerts.alerts.length];
            final isUnread = !alert.isRead;
            return _buildAlertCard(alert, isUnread);
          }
        },
      ),
    );
  }

  Widget _buildUnreadAlertsList(AlertProvider alertProvider, FireAlertProvider fireAlerts) {
    final unreadAlerts = alertProvider.unreadAlerts;
    
    if (unreadAlerts.isEmpty && fireAlerts.alerts.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        await alertProvider.fetchAlerts();
        await fireAlerts.fetchHistory();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: unreadAlerts.length + fireAlerts.alerts.length,
        itemBuilder: (context, index) {
          if (index < fireAlerts.alerts.length) {
            final fireAlert = fireAlerts.alerts[index];
            return _buildFireAlertCard(fireAlert, fireAlerts);
          } else {
            final alert = unreadAlerts[index - fireAlerts.alerts.length];
            return _buildAlertCard(alert, true);
          }
        },
      ),
    );
  }

  Widget _buildFireAlertCard(dynamic fireAlert, FireAlertProvider fp) {
    final date = '${fireAlert.timestamp.day.toString().padLeft(2, '0')} ${_monthName(fireAlert.timestamp.month)} ${fireAlert.timestamp.year}';
    final time = '${fireAlert.timestamp.hour.toString().padLeft(2, '0')}:${fireAlert.timestamp.minute.toString().padLeft(2, '0')}:${fireAlert.timestamp.second.toString().padLeft(2, '0')}';
    final isActive = fireAlert.status.toLowerCase() == 'active';

    return GestureDetector(
      onTap: () {
        // Show fire alert detail
        _showFireAlertDetail(fireAlert);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isActive ? Colors.red.withOpacity(0.05) : Colors.green.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? Colors.red : Colors.green,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: (isActive ? Colors.red : Colors.green).withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isActive ? Colors.red.withOpacity(0.15) : Colors.green.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '🔥',
                  style: TextStyle(fontSize: 24),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fire Alert',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isActive ? Colors.red.shade800 : Colors.green.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$date • $time',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isActive ? '🔴 ACTIVE - Immediate action required' : '✅ Acknowledged - Safe',
                      style: TextStyle(
                        fontSize: 12,
                        color: isActive ? Colors.red : Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (isActive)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onPressed: () {
                    fp.acknowledge(fireAlert.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Fire alert acknowledged')),
                    );
                  },
                  child: const Text('Ack', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFireAlertDetail(dynamic fireAlert) {
    final date = '${fireAlert.timestamp.day.toString().padLeft(2, '0')} ${_monthName(fireAlert.timestamp.month)} ${fireAlert.timestamp.year}';
    final time = '${fireAlert.timestamp.hour.toString().padLeft(2, '0')}:${fireAlert.timestamp.minute.toString().padLeft(2, '0')}:${fireAlert.timestamp.second.toString().padLeft(2, '0')}';
    final isActive = fireAlert.status.toLowerCase() == 'active';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('🔥', style: TextStyle(fontSize: 32)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Fire Alert Details',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isActive ? 'Status: ACTIVE' : 'Status: ACKNOWLEDGED',
                        style: TextStyle(
                          color: isActive ? Colors.red : Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildDetailRow('Date', date),
            const SizedBox(height: 16),
            _buildDetailRow('Time', time),
            const SizedBox(height: 16),
            _buildDetailRow('Status', isActive ? 'ACTIVE - Action Required' : 'ACKNOWLEDGED - Safe'),
            const SizedBox(height: 24),
            if (isActive)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () {
                    Provider.of<FireAlertProvider>(context, listen: false).acknowledge(fireAlert.id);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Fire alert acknowledged')),
                    );
                  },
                  child: const Text('Acknowledge Fire Alert', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  String _monthName(int m) {
    const names = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return names[m-1];
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No alerts yet',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'When residents submit reports, they will appear here',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(Alert alert, bool isUnread) {
    return GestureDetector(
      onTap: () async {
        if (!alert.isRead) {
          await Provider.of<AlertProvider>(context, listen: false).markAsRead(alert.id);
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReportDetailScreen(
              reportId: alert.reportId,
              alert: alert,
            ),
          ),
        ).then((_) {
          Provider.of<AlertProvider>(context, listen: false).fetchAlerts();
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isUnread ? const Color(0xFF034808).withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUnread ? const Color(0xFF034808) : Colors.grey.shade200,
            width: isUnread ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: alert.category == 'Security' 
                          ? Colors.red.withOpacity(0.1) 
                          : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      alert.category == 'Security' ? Icons.security : Icons.build,
                      color: alert.category == 'Security' ? Colors.red : Colors.orange,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alert.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Reported by ${alert.reportedBy}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isUnread)
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Color(0xFF034808),
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: Colors.grey),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert.message,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        alert.location,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.access_time, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        _formatTime(alert.createdAt),
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildStatusChip(alert.statusText, alert.statusColor),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ReportDetailScreen(
                                reportId: alert.reportId,
                                alert: alert,
                              ),
                            ),
                          );
                        },
                        child: const Text('View Details'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    
    if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}