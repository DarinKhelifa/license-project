import 'package:flutter/material.dart';
import 'package:orelax/widgets/custom_bottom_nav_bar.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../../../providers/event_provider.dart';
import '../../../models/event_model.dart';
import 'create_event_screen.dart';
import 'event_detail_screen.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  bool _showMyEvents = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<EventProvider>(context, listen: false);
      provider.fetchEvents();
      provider.fetchMyEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    final eventProvider = Provider.of<EventProvider>(context);
    final currentEvents = _showMyEvents ? eventProvider.myEvents : eventProvider.events;

    return Scaffold(
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 0),
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Community Events'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            onPressed: () async {
              final created = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CreateEventScreen()),
              );
              if (created == true) {
                await eventProvider.fetchMyEvents();
                await eventProvider.fetchEvents();
              }
            },
            icon: const Icon(Icons.add),
            tooltip: 'Create Event',
          ),
        ],
      ),
      body: eventProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => setState(() => _showMyEvents = false),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _showMyEvents ? Colors.white : const Color(0xFF034808),
                            foregroundColor: _showMyEvents ? Colors.black : Colors.white,
                            side: const BorderSide(color: Color(0xFF034808)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('All Events'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => setState(() => _showMyEvents = true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _showMyEvents ? const Color(0xFF034808) : Colors.white,
                            foregroundColor: _showMyEvents ? Colors.white : Colors.black,
                            side: const BorderSide(color: Color(0xFF034808)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('My Events'),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: currentEvents.isEmpty
                      ? _buildEmptyState(showMyEvents: _showMyEvents)
                      : RefreshIndicator(
                          onRefresh: () async {
                            await eventProvider.fetchEvents();
                            await eventProvider.fetchMyEvents();
                          },
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: currentEvents.length,
                            itemBuilder: (context, index) {
                              final event = currentEvents[index];
                              return _EventCard(event: event);
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState({bool showMyEvents = false}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No events yet',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            showMyEvents ? 'You have not created any events yet.' : 'Be the first to create an event!',
            style: TextStyle(color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              final created = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CreateEventScreen()),
              );
              if (created == true) {
                final provider = Provider.of<EventProvider>(context, listen: false);
                provider.fetchMyEvents();
                provider.fetchEvents();
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Create Event'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF034808),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
          ),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final Event event;

  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final provider = Provider.of<EventProvider>(context, listen: false);
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailScreen(event: event),
          ),
        );
        // If detail indicated a change (delete/update), refresh lists
        if (result == true) {
          await provider.fetchMyEvents();
          await provider.fetchEvents();
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image or Color Header
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: (event.imageBase64 != null && event.imageBase64!.trim().isNotEmpty)
                  ? Image.memory(
                      base64Decode(event.imageBase64!),
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      height: 120,
                      width: double.infinity,
                      color: event.categoryColor.withValues(alpha: 0.2),
                      child: Center(
                        child: Text(
                          event.categoryIcon,
                          style: const TextStyle(fontSize: 50),
                        ),
                      ),
                    ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Chip
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: event.categoryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(event.categoryIcon),
                            const SizedBox(width: 4),
                            Text(
                              event.category.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: event.categoryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      if (event.capacity > 0)
                        Row(
                          children: [
                            Icon(Icons.people, size: 14, color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Text(
                              '${event.currentRegistrations}/${event.capacity}',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Title
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Description
                  Text(
                    event.description,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),

                  // Date, Time, Location
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('MMM dd, yyyy').format(event.date),
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.access_time, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        event.time,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.location_on, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event.location,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}