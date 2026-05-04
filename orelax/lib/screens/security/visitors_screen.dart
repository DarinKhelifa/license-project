import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class VisitorsScreen extends StatefulWidget {
  const VisitorsScreen({super.key});

  @override
  State<VisitorsScreen> createState() => _VisitorsScreenState();
}

class _VisitorsScreenState extends State<VisitorsScreen> {
  final List<Map<String, dynamic>> _visitors = [];

  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }
  Future<void> _loadData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final role = (auth.user?['role'] ?? 'resident').toString();

      List<Map<String, dynamic>> guests = [];
      if (role == 'security' || role == 'admin') {
        final data = await ApiService.getAllGuests();
        guests = data;
      } else {
        final residentId = auth.user?['id'] ?? auth.user?['_id'] ?? '';
        if (residentId.isNotEmpty) {
          final data = await ApiService.getGuestsForResident(residentId.toString());
          guests = data;
        }
      }

      setState(() {
        _visitors.clear();
        _visitors.addAll(guests.map((g) => {
          'name': g['name'] ?? g['guest']?['name'] ?? 'Guest',
          'apartment': g['host'] ?? '',
          'purpose': g['purpose'] ?? g['visitDate'] ?? '',
          'timeIn': DateTime.tryParse(g['createdAt'] ?? '') ?? DateTime.now(),
        }));
      });
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visitors'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : (_error != null)
              ? Center(child: Text('Error: $_error'))
              : _visitors.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.person_outline, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No visitors'),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _visitors.length,
                      itemBuilder: (context, index) {
                        final v = _visitors[index];
                        final timeIn = v['timeIn'] as DateTime?;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue.shade700,
                              child: Text(
                                (v['name']?.toString().isNotEmpty ?? false)
                                    ? v['name'].toString().substring(0, 1).toUpperCase()
                                    : 'V',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(
                              v['name']?.toString() ?? 'Unknown',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text('Apt: ${v['apartment']} • ${v['purpose']}'),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  timeIn == null ? '—' : '${timeIn.hour}:${timeIn.minute.toString().padLeft(2, '0')}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  timeIn == null ? '' : '${timeIn.day}/${timeIn.month}/${timeIn.year}',
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}

