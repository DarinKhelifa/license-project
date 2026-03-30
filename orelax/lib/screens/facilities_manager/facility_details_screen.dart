import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'booking_screen.dart';

class FacilityDetailsScreen extends StatefulWidget {
  final String facilityName;
  
  const FacilityDetailsScreen({super.key, required this.facilityName});

  @override
  State<FacilityDetailsScreen> createState() => _FacilityDetailsScreenState();
}

class _FacilityDetailsScreenState extends State<FacilityDetailsScreen> {
  int _currentImageIndex = 0;
  late PageController _pageController;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadFavoriteStatus();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadFavoriteStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isFavorite = prefs.getBool('favorite_${widget.facilityName}') ?? false;
    });
  }

  Future<void> _toggleFavorite() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isFavorite = !_isFavorite;
    });
    await prefs.setBool('favorite_${widget.facilityName}', _isFavorite);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isFavorite ? 'Added to favorites' : 'Removed from favorites'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  List<String> _getFacilityImages() {
    switch (widget.facilityName) {
      case 'Pool':
        return [
          'assets/images/pool1.jpg',
          'assets/images/pool2.jpg',
          'assets/images/pool3.jpg',
          'assets/images/pool4.jpg',
        ];
      case 'Party Room':
        return [
          'assets/images/partyroom1.jpg',
          'assets/images/partyroom2.jpg',
          'assets/images/partyroom3.jpg',
          'assets/images/partyroom4.jpg',
        ];
      case 'Nursery':
        return [
          'assets/images/childcare1.jpg',
          'assets/images/childcare2.jpg',
          'assets/images/childcare3.jpg',
          'assets/images/childcare4.jpg',
          'assets/images/childcare5.jpg',
        ];
      case 'Gym':
        return [
          'assets/images/gym1.jpg',
          'assets/images/gym2.jpg',
          'assets/images/gym3.jpg',
          'assets/images/gym4.jpg',
        ];
      default:
        return [];
    }
  }

  Map<String, dynamic> _getFacilityDetails() {
    switch (widget.facilityName) {
      case 'Pool':
        return {
          'name': 'Swimming Pool',
          'hours': '08:00 - 22:00',
          'capacity': '40 people',
          'status': true,
          'price': 'Free for residents',
          'features': [
            'Olympic-size pool',
            'Kids pool section',
            'Lifeguard on duty',
            'Shower & changing rooms',
            'Sun loungers',
            'Poolside cafe',
          ],
          'rules': [
            'Swimwear required',
            'No running',
            'Children under 12 must be supervised',
            'No glass containers',
          ],
          'description': 'Dive into relaxation at our stunning swimming pool. Whether you\'re looking for a vigorous workout or a peaceful float, our Olympic-sized pool offers the perfect escape. The separate kids\' pool ensures safe fun for the little ones.',
        };
      case 'Party Room':
        return {
          'name': 'Party Room',
          'hours': '10:00 - 23:00',
          'capacity': '25 people',
          'status': true,
          'price': '2000 DZD/hour (residents)',
          'features': [
            'Sound system',
            'Projector & screen',
            'Kitchenette',
            'Tables & chairs',
            'Decoration allowed',
            'Cleaning service included',
          ],
          'rules': [
            'No smoking inside',
            'Music volume limited after 22:00',
            'Clean up after use',
            'Book at least 24h in advance',
          ],
          'description': 'Celebrate life\'s special moments in our elegant party room. Perfect for birthdays, anniversaries, and community gatherings. The space comes fully equipped with modern amenities to make your event unforgettable.',
        };
      case 'Nursery':
        return {
          'name': 'Nursery',
          'hours': '08:00 - 18:00',
          'capacity': '15 children',
          'status': true,
          'price': '500 DZD/day',
          'features': [
            'Qualified staff',
            'Educational toys',
            'Outdoor play area',
            'Nap time facilities',
            'Healthy snacks included',
            'Daily activities',
          ],
          'rules': [
            'Registration required',
            'Medical form needed',
            'Pickup on time',
            'No outside food allowed',
          ],
          'description': 'A safe and nurturing environment for your little ones. Our professional staff provides engaging activities that promote learning and development. Rest assured your children are in good hands while you go about your day.',
        };
      case 'Gym':
        return {
          'name': 'Fitness Center',
          'hours': '24/7 Access',
          'capacity': '30 people',
          'status': true,
          'price': 'Free for residents',
          'features': [
            'Cardio machines',
            'Free weights',
            'Strength equipment',
            'Yoga studio',
            'Personal trainers',
            'Lockers & showers',
          ],
          'rules': [
            'Proper athletic attire required',
            'Wipe equipment after use',
            'No food in workout area',
            'Access card required',
          ],
          'description': 'Stay fit and healthy in our state-of-the-art fitness center. Equipped with the latest machines and free weights, plus a dedicated yoga studio. Open 24/7 so you can work out on your schedule.',
        };
      default:
        return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    final images = _getFacilityImages();
    final details = _getFacilityDetails();
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: CustomScrollView(
        slivers: [
          // Hero Image with Swipe
          SliverAppBar(
            expandedHeight: 350,
            pinned: true,
            backgroundColor: Colors.black,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  // PageView for swiping images
                  PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentImageIndex = index;
                      });
                    },
                    itemCount: images.length,
                    itemBuilder: (context, index) {
                      return Hero(
                        tag: 'facility_image_${widget.facilityName}_$index',
                        child: Image.asset(
                          images[index],
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      );
                    },
                  ),
                  // Gradient Overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.5),
                          Colors.black.withOpacity(0.8),
                        ],
                        stops: const [0.5, 0.8, 1.0],
                      ),
                    ),
                  ),
                  // Image Counter & Dot Indicator
                  Positioned(
                    bottom: 20,
                    left: 0,
                    right: 0,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(images.length, (index) {
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: _currentImageIndex == index ? 24 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _currentImageIndex == index 
                                    ? const Color(0xFFFFD700)
                                    : Colors.white.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_currentImageIndex + 1} / ${images.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                onPressed: _toggleFavorite,
                icon: Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: _isFavorite ? Colors.red : Colors.white,
                ),
              ),
              IconButton(
                onPressed: () {
                  // Share facility
                },
                icon: const Icon(Icons.share, color: Colors.white),
              ),
            ],
          ),
          
          // Content
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF5F5F5),
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  
                  // Title & Status
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                details['name'],
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF034808),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                details['description'],
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: (details['status'] as bool)
                                ? Colors.green.withOpacity(0.2)
                                : Colors.red.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: (details['status'] as bool) ? Colors.green : Colors.red,
                            ),
                          ),
                          child: Text(
                            (details['status'] as bool) ? 'Open' : 'Closed',
                            style: TextStyle(
                              color: (details['status'] as bool) ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Info Cards
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        _buildInfoCard(
                          icon: Icons.access_time,
                          label: 'Hours',
                          value: details['hours'],
                        ),
                        const SizedBox(width: 12),
                        _buildInfoCard(
                          icon: Icons.people_outline,
                          label: 'Capacity',
                          value: details['capacity'],
                        ),
                        const SizedBox(width: 12),
                        _buildInfoCard(
                          icon: Icons.attach_money,
                          label: 'Price',
                          value: details['price'],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Features
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Features & Amenities',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF034808),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: (details['features'] as List<String>).map((feature) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.grey.shade200),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.check_circle, size: 14, color: Color(0xFF034808)),
                                  const SizedBox(width: 6),
                                  Text(
                                    feature,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Rules
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Rules & Guidelines',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF034808),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...(details['rules'] as List<String>).map((rule) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    rule,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Booking Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BookingScreen(
                                facilityName: widget.facilityName,
                                facilityDetails: details,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF034808),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.book_online),
                            SizedBox(width: 8),
                            Text(
                              'Book Now',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF034808), size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF034808),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}