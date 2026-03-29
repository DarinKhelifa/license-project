import 'package:flutter/material.dart';

class FacilityDetailsScreen extends StatelessWidget {
  const FacilityDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Facility Details'),
        backgroundColor: const Color(0xFF034808),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            initialValue: 'Pool',
            decoration: const InputDecoration(labelText: 'Facility Name'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: '08:00 - 22:00',
            decoration: const InputDecoration(labelText: 'Opening Hours'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: '40',
            decoration: const InputDecoration(labelText: 'Capacity'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            value: true,
            onChanged: (_) {},
            title: const Text('Facility Active'),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save Changes'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF034808),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ],
      ),
    );
  }
}

