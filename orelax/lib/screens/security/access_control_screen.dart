import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AccessControlScreen extends StatefulWidget {
  const AccessControlScreen({super.key});

  @override
  State<AccessControlScreen> createState() => _AccessControlScreenState();
}

class _AccessControlScreenState extends State<AccessControlScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _apartmentController = TextEditingController();
  final _purposeController = TextEditingController();

  final List<Map<String, dynamic>> _visitors = [];

  @override
  void dispose() {
    _nameController.dispose();
    _apartmentController.dispose();
    _purposeController.dispose();
    super.dispose();
  }
  
  Future<void> _grantAccess() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _visitors.insert(0, {
        'name': _nameController.text.trim(),
        'apartment': _apartmentController.text.trim(),
        'purpose': _purposeController.text.trim(),
        'status': 'pending',
        'timeIn': DateTime.now(),
      });
    });
    
    _nameController.clear();
    _apartmentController.clear();
    _purposeController.clear();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Visitor access requested')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Access Control'),
          backgroundColor: const Color(0xFF034808),
          foregroundColor: Colors.white,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Grant Access'),
              Tab(text: 'Recent Visitors'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Grant Access Tab
            Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Visitor Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _apartmentController,
                      decoration: const InputDecoration(
                        labelText: 'Apartment Number',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.home),
                      ),
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _purposeController,
                      decoration: const InputDecoration(
                        labelText: 'Purpose',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.info),
                      ),
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _grantAccess,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF034808),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text('Grant Access'),
                    ),
                  ],
                ),
              ),
            ),
            
            // Recent Visitors Tab
            _visitors.isEmpty
                ? const Center(child: Text('No recent visitors yet.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _visitors.length,
                    itemBuilder: (context, index) {
                      final v = _visitors[index];
                      final timeIn = v['timeIn'] as DateTime?;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF034808),
                            child: Text(
                              (v['name']?.toString().isNotEmpty ?? false)
                                  ? v['name'].toString().substring(0, 1)
                                  : 'V',
                            ),
                          ),
                          title: Text(v['name']?.toString() ?? ''),
                          subtitle: Text(
                            'Apt: ${v['apartment']} • ${v['purpose']}',
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                timeIn == null
                                    ? '—'
                                    : DateFormat('HH:mm').format(timeIn),
                                style:
                                    const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                timeIn == null
                                    ? ''
                                    : DateFormat('MMM dd').format(timeIn),
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}