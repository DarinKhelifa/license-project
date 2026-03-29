import 'package:flutter/material.dart';

class FacilityPaymentsScreen extends StatelessWidget {
  const FacilityPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Facility Payments'),
        backgroundColor: const Color(0xFF034808),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _PaymentTile(
            resident: 'Sara A.',
            facility: 'Pool',
            amount: '2,000 DZD',
            status: 'Paid',
          ),
          _PaymentTile(
            resident: 'Karim M.',
            facility: 'Party Room',
            amount: '8,000 DZD',
            status: 'Pending',
          ),
        ],
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final String resident;
  final String facility;
  final String amount;
  final String status;

  const _PaymentTile({
    required this.resident,
    required this.facility,
    required this.amount,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final isPaid = status.toLowerCase() == 'paid';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(resident),
        subtitle: Text('$facility • $amount'),
        trailing: Chip(
          label: Text(status),
          backgroundColor: isPaid ? Colors.green.shade100 : Colors.orange.shade100,
          labelStyle: TextStyle(
            color: isPaid ? Colors.green.shade900 : Colors.orange.shade900,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

