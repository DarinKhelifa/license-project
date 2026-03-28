import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  
  Future<void> _grantAccess() async {
    if (!_formKey.currentState!.validate()) return;
    
    await FirebaseFirestore.instance.collection('visitors').add({
      'name': _nameController.text.trim(),
      'apartment': _apartmentController.text.trim(),
      'purpose': _purposeController.text.trim(),
      'status': 'pending',
      'timeIn': Timestamp.now(),
      'createdBy': FirebaseAuth.instance.currentUser?.uid,
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
            StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('visitors')
                  .orderBy('timeIn', descending: true)
                  .limit(50)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final visitors = snapshot.data!.docs;
                
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: visitors.length,
                  itemBuilder: (context, index) {
                    final v = visitors[index].data();
                    final timeIn = (v['timeIn'] as Timestamp).toDate();
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF034808),
                          child: Text(v['name']?.substring(0, 1) ?? 'V'),
                        ),
                        title: Text(v['name'] ?? ''),
                        subtitle: Text('Apt: ${v['apartment']} • ${v['purpose']}'),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              DateFormat('HH:mm').format(timeIn),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              DateFormat('MMM dd').format(timeIn),
                              style: TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}