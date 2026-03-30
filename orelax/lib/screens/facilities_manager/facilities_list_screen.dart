import 'package:flutter/material.dart';

class FacilitiesListScreen extends StatelessWidget {
  const FacilitiesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final facilities = const [
      {
        'name': 'Pool',
        'icon': Icons.pool,
        'images': [
          'assets/images/pool1.jpg',
          'assets/images/pool2.jpg',
          'assets/images/pool3.jpg',
          'assets/images/pool4.jpg',
        ],
        'capacity': '40',
        'hours': '08:00 - 22:00',
        'status': true,
      },
      {
        'name': 'Party Room',
        'icon': Icons.celebration_outlined,
        'images': [
          'assets/images/partyroom1.jpg',
          'assets/images/partyroom2.jpg',
          'assets/images/partyroom3.jpg',
          'assets/images/partyroom4.jpg',
        ],
        'capacity': '25',
        'hours': '10:00 - 23:00',
        'status': true,
      },
      {
        'name': 'Nursery',
        'icon': Icons.child_care_outlined,
        'images': [
          'assets/images/childcare1.jpg',
          'assets/images/childcare2.jpg',
          'assets/images/childcare3.jpg',
          'assets/images/childcare4.jpg',
          'assets/images/childcare5.jpg',
        ],
        'capacity': '15',
        'hours': '08:00 - 18:00',
        'status': false,
      },
      {
        'name': 'Gym',
        'icon': Icons.fitness_center,
        'images': [
          'assets/images/gym1.jpg',
          'assets/images/gym2.jpg',
          'assets/images/gym3.jpg',
          'assets/images/gym4.jpg',
        ],
        'capacity': '30',
        'hours': '24/7',
        'status': true,
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('Manage Facilities', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF034808),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: const Color(0xFF034808),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Facility'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: facilities.length,
        itemBuilder: (context, index) {
          final facility = facilities[index];
          final mainImage = (facility['images'] as List)[0] as String;
          return Container(
            margin: const EdgeInsets.only(bottom: 20),
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Background Image
                  Image.asset(
                    mainImage,
                    fit: BoxFit.cover,
                  ),
                  // Gradient Overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.8),
                        ],
                        stops: const [0.4, 1.0],
                      ),
                    ),
                  ),
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Top Section (Icon & Actions)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white54),
                              ),
                              child: Icon(
                                facility['icon'] as IconData,
                                color: Colors.white,
                              ),
                            ),
                            Row(
                              children: [
                                _buildActionButton(
                                  icon: Icons.edit_outlined,
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/fm-facility-details',
                                      arguments: facility,
                                    );
                                  },
                                ),
                                const SizedBox(width: 8),
                                _buildActionButton(
                                  icon: Icons.delete_outline,
                                  onTap: () {},
                                  color: Colors.redAccent,
                                ),
                              ],
                            ),
                          ],
                        ),
                        // Bottom Section (Name & Info)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              facility['name'] as String,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.schedule, color: Colors.white70, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  facility['hours'] as String,
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                const SizedBox(width: 16),
                                const Icon(Icons.people_outline, color: Colors.white70, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  '${facility['capacity']} Cap.',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: (facility['status'] as bool) 
                                        ? Colors.green.withOpacity(0.2)
                                        : Colors.red.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: (facility['status'] as bool) ? Colors.green : Colors.red,
                                    ),
                                  ),
                                  child: Text(
                                    (facility['status'] as bool) ? 'Active' : 'Closed',
                                    style: TextStyle(
                                      color: (facility['status'] as bool) ? Colors.greenAccent : Colors.redAccent,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
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
        },
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required VoidCallback onTap, Color color = Colors.white}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white30),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}
