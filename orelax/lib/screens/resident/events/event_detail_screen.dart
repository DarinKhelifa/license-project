import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../../../models/event_model.dart';
import '../../../widgets/home_bottom_nav_bar.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/event_provider.dart';
import 'edit_event_screen.dart';

class EventDetailScreen extends StatefulWidget {
  final Event event;

  const EventDetailScreen({super.key, required this.event});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  late Event _event;

  @override
  void initState() {
    super.initState();
    _event = widget.event;
  }

  Future<void> _refreshEvent() async {
    final provider = Provider.of<EventProvider>(context, listen: false);
    try {
      await provider.fetchEvents();
      final refreshed = provider.getEventById(_event.id);
      if (refreshed != null) setState(() => _event = refreshed);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final event = _event;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(event.title),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Image
              if (event.imageBase64 != null && event.imageBase64!.trim().isNotEmpty)
                Container(
                  height: 250,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: MemoryImage(base64Decode(event.imageBase64!)),
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              else
                Container(
                  height: 150,
                  width: double.infinity,
                  color: event.categoryColor.withOpacity(0.2),
                  child: Center(
                    child: Text(
                      event.categoryIcon,
                      style: const TextStyle(fontSize: 70),
                    ),
                  ),
                ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category Chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: event.categoryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(event.categoryIcon),
                          const SizedBox(width: 6),
                          Text(
                            event.category.toUpperCase(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: event.categoryColor,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                    Text(event.title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: _InfoCard(icon: Icons.calendar_today, label: 'Date', value: DateFormat('EEEE, MMM dd, yyyy').format(event.date)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _InfoCard(icon: Icons.access_time, label: 'Time', value: event.time),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _InfoCard(icon: Icons.location_on, label: 'Location', value: event.location)),
                        const SizedBox(width: 12),
                        Expanded(child: _InfoCard(icon: Icons.people, label: 'Capacity', value: event.capacity > 0 ? '${event.currentRegistrations}/${event.capacity}' : 'Unlimited')),
                      ],
                    ),

                    const SizedBox(height: 24),
                    const Text('About this event', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(event.description, style: TextStyle(fontSize: 16, height: 1.5, color: Colors.grey)),

                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                      child: Row(children: [
                        const CircleAvatar(backgroundColor: Color(0xFF034808), child: Icon(Icons.person, color: Colors.white)),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Organized by', style: TextStyle(fontSize: 12, color: Colors.grey)), Text(event.createdByName, style: const TextStyle(fontWeight: FontWeight.bold))])),
                      ]),
                    ),

                    const SizedBox(height: 32),

                    // Action buttons (edit / remove only for creator when pending)
                    Builder(builder: (context) {
                      final auth = Provider.of<AuthProvider>(context, listen: false);
                      final userId = auth.userId ?? auth.user?['id'];
                      final isCreator = userId != null && userId == event.createdBy;
                      final isPending = event.approvedAt == null && (event.approvedBy == null || event.approvedBy!.isEmpty);

                      if (isCreator && isPending) {
                        return Row(children: [
                          Expanded(
                            child: SizedBox(
                              height: 50,
                              child: ElevatedButton(
                                onPressed: () async {
                                  final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => EditEventScreen(event: event)));
                                  if (result == true) {
                                    await _refreshEvent();
                                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event updated')));
                                  }
                                },
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF034808), foregroundColor: Colors.white),
                                child: const Text('Edit Event', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: 50,
                              child: OutlinedButton(
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Remove Event'),
                                      content: const Text('Remove this event before it is approved? This will delete it.'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx, false),
                                          child: const Text('No'),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx, true),
                                          child: const Text('Yes'),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirm == true) {
                                    final provider = Provider.of<EventProvider>(context, listen: false);
                                    final ok = await provider.cancelEvent(event.id);
                                    if (ok) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Event removed')),
                                        );
                                      }
                                      Navigator.pop(context, true);
                                    } else {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text(provider.error ?? 'Failed to remove event')),
                                        );
                                      }
                                    }
                                  }
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(color: Colors.red),
                                ),
                                child: const Text(
                                  'Remove Event',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                        ]);
                      }

                      return const SizedBox.shrink();
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: HomeBottomNavBar(currentIndex: 0),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoCard({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 20, color: const Color(0xFF034808)),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500), maxLines: 2, overflow: TextOverflow.ellipsis),
      ]),
    );
  }
}
