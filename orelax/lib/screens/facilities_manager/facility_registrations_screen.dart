import 'package:flutter/material.dart';

class FacilityRegistrationsScreen extends StatelessWidget {
  const FacilityRegistrationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Facility Registrations'),
        backgroundColor: const Color(0xFF034808),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _registrationCard(
            context,
            resident: 'Sara A.',
            facility: 'Pool',
            slot: 'Mon 17:00',
          ),
          _registrationCard(
            context,
            resident: 'Karim M.',
            facility: 'Party Room',
            slot: 'Sat 19:00',
          ),
        ],
      ),
    );
  }

  Widget _registrationCard(
    BuildContext context, {
    required String resident,
    required String facility,
    required String slot,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              resident,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text('Facility: $facility'),
            Text('Requested slot: $slot'),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () {},
                  child: const Text('Refuse'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF034808),
                  ),
                  onPressed: () {},
                  child: const Text('Accept'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

