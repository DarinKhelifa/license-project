import 'package:flutter/material.dart';

class FacilitiesListScreen extends StatelessWidget {
  const FacilitiesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final facilities = const [
      ('Pool', Icons.pool),
      ('Party Room', Icons.celebration_outlined),
      ('Nursery', Icons.child_care_outlined),
      ('Gym', Icons.fitness_center),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Facilities List'),
        backgroundColor: const Color(0xFF034808),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: const Color(0xFF034808),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Facility'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: facilities.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final (name, icon) = facilities[index];
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF034808),
                child: Icon(icon, color: Colors.white),
              ),
              title: Text(name),
              subtitle: const Text('Manage details, capacity, and status'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Edit',
                    onPressed: () =>
                        Navigator.pushNamed(context, '/fm-facility-details'),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    tooltip: 'Delete',
                    onPressed: () {},
                    icon: const Icon(Icons.delete_outline),
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

