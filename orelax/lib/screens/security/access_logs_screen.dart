import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AccessLogsScreen extends StatefulWidget {
  const AccessLogsScreen({super.key});

  @override
  State<AccessLogsScreen> createState() => _AccessLogsScreenState();
}

class _AccessLogsScreenState extends State<AccessLogsScreen> {
  final List<Map<String, dynamic>> _accessLogs = [];

  @override
  void initState() {
    super.initState();
    _loadMockData();
  }

  void _loadMockData() {
    // Mock access logs - QR code scans
    _accessLogs.addAll([
      {'name': 'John Doe', 'action': 'Entry', 'time': DateTime.now().subtract(const Duration(hours: 2))},
      {'name': 'Jane Smith', 'action': 'Exit', 'time': DateTime.now().subtract(const Duration(hours: 3))},
      {'name': 'Security Guard', 'action': 'Entry', 'time': DateTime.now().subtract(const Duration(hours: 4))},
      {'name': 'Mike Johnson', 'action': 'Exit', 'time': DateTime.now().subtract(const Duration(hours: 5))},
      {'name': 'Sarah Connor', 'action': 'Entry', 'time': DateTime.now().subtract(const Duration(hours: 6))},
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Access Logs'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: _accessLogs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.history, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No access logs'),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _accessLogs.length,
              itemBuilder: (context, index) {
                final log = _accessLogs[index];
                final time = log['time'] as DateTime;
                final isEntry = log['action'] == 'Entry';

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isEntry ? Colors.green : Colors.red,
                      child: Icon(
                        isEntry ? Icons.login : Icons.logout,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      log['name'] ?? 'Unknown',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${DateFormat('MMM dd, HH:mm').format(time)}',
                    ),
                    trailing: Chip(
                      label: Text(
                        log['action'] ?? '',
                        style: const TextStyle(fontSize: 10),
                      ),
                      backgroundColor: isEntry ? Colors.green.shade100 : Colors.red.shade100,
                      labelStyle: TextStyle(
                        color: isEntry ? Colors.green.shade700 : Colors.red.shade700,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

