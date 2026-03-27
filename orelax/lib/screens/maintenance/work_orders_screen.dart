import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class WorkOrdersScreen extends StatefulWidget {
  const WorkOrdersScreen({super.key});

  @override
  State<WorkOrdersScreen> createState() => _WorkOrdersScreenState();
}

class _WorkOrdersScreenState extends State<WorkOrdersScreen> {
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              const PopupMenuItem(value: 'completed', child: Text('Completed')),
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
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('maintenance_requests')
            .where('status', isNotEqualTo: _selectedFilter == 'all' ? null : _selectedFilter)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final requests = snapshot.data!.docs;
          
          if (requests.isEmpty) {
            return const Center(child: Text('No work orders found.'));
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final req = requests[index].data();
              final createdAt = (req['createdAt'] as Timestamp).toDate();
              
              Color statusColor;
              switch (req['status']) {
                case 'pending':
                  statusColor = Colors.orange;
                  break;
                case 'in-progress':
                  statusColor = Colors.blue;
                  break;
                case 'completed':
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
                              req['title'] ?? '',
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
                              req['status']?.toUpperCase() ?? '',
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
                      Text(req['description'] ?? ''),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.apartment, size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text('Apt: ${req['apartment']}'),
                          const SizedBox(width: 16),
                          Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(DateFormat('MMM dd, HH:mm').format(createdAt)),
                        ],
                      ),
                      if (req['status'] != 'completed')
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (req['status'] == 'pending')
                                ElevatedButton(
                                  onPressed: () {
                                    _updateStatus(requests[index].id, 'in-progress');
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                  ),
                                  child: const Text('Start Work'),
                                ),
                              if (req['status'] == 'in-progress')
                                ElevatedButton(
                                  onPressed: () {
                                    _updateStatus(requests[index].id, 'completed');
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                  ),
                                  child: const Text('Complete'),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
  
  Future<void> _updateStatus(String id, String newStatus) async {
    await FirebaseFirestore.instance
        .collection('maintenance_requests')
        .doc(id)
        .update({
          'status': newStatus,
          'updatedAt': FieldValue.serverTimestamp(),
        });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Status updated to $newStatus')),
    );
  }
}