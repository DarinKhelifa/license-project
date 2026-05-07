import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class VisitorsScreen extends StatefulWidget {
  const VisitorsScreen({super.key});

  @override
  State<VisitorsScreen> createState() => _VisitorsScreenState();
}

class _VisitorsScreenState extends State<VisitorsScreen> {
  final List<Map<String, dynamic>> _visitors = [];

  bool _isLoading = false;
  String? _error;
  int? _hoveredVisitorIndex;

  @override
  void initState() {
    super.initState();
    _loadData();
  }
  Future<void> _loadData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final role = (auth.user?['role'] ?? 'resident').toString();

      List<Map<String, dynamic>> guests = [];
      if (role == 'security' || role == 'admin') {
        final data = await ApiService.getAllGuests();
        guests = data;
      } else {
        final residentId = auth.user?['id'] ?? auth.user?['_id'] ?? '';
        if (residentId.isNotEmpty) {
          final data = await ApiService.getGuestsForResident(residentId.toString());
          guests = data;
        }
      }

      setState(() {
        _visitors.clear();
        _visitors.addAll(guests.map((g) => {
          'name': g['name'] ?? g['guest']?['name'] ?? 'Guest',
          'apartment': g['host'] ?? '',
          'purpose': g['purpose'] ?? g['visitDate'] ?? '',
          'timeIn': DateTime.tryParse(g['createdAt'] ?? '') ?? DateTime.now(),
        }));
      });
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final visitsThisMonth = _visitors.where((visitor) {
      final timeIn = visitor['timeIn'] as DateTime?;
      return timeIn != null && timeIn.year == now.year && timeIn.month == now.month;
    }).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text(
          'Visitors',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: const Color(0xFFF4F6FA),
        foregroundColor: const Color(0xFF1C2430),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : (_error != null)
              ? Center(child: Text('Error: $_error'))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF034808), Color(0xFF213B28)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF034808).withOpacity(0.18),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Security Overview',
                                        style: TextStyle(
                                          color: Color(0xFFB8C6DB),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      SizedBox(height: 18),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 54,
                                  height: 54,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: const Icon(
                                    Icons.shield_outlined,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: _overviewStat(
                                    value: '${_visitors.length}',
                                    label: 'TOTAL VISITS',
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _overviewStat(
                                    value: '$visitsThisMonth',
                                    label: 'VISITS THIS MONTH',
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _overviewStat(
                                    value: '0',
                                    label: 'FAILED ATTEMPTS',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Recent History',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1C2430),
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: _visitors.isEmpty ? null : () {},
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF8C6A2B),
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'VIEW ALL',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_visitors.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.person_outline,
                                size: 56,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No visitors',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Visitor history will appear here once guests are recorded.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ..._visitors.asMap().entries.map((entry) {
                          final index = entry.key;
                          final visitor = entry.value;
                          final timeIn = visitor['timeIn'] as DateTime?;
                          return _historyCard(
                            visitor,
                            timeIn,
                            index: index,
                            isHovered: _hoveredVisitorIndex == index,
                          );
                        }),
                    ],
                  ),
                ),
    );
  }

  Widget _overviewStat({required String value, required String label}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.78),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _historyCard(
    Map<String, dynamic> visitor,
    DateTime? timeIn, {
    required int index,
    required bool isHovered,
  }) {
    final name = visitor['name']?.toString() ?? 'Unknown';
    final apartment = visitor['apartment']?.toString() ?? '';
    final purpose = visitor['purpose']?.toString() ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'V';
    final accentColor = _accentForName(name);

    return MouseRegion(
      onEnter: (_) {
        if (_hoveredVisitorIndex != index) {
          setState(() => _hoveredVisitorIndex = index);
        }
      },
      onExit: (_) {
        if (_hoveredVisitorIndex == index) {
          setState(() => _hoveredVisitorIndex = null);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(bottom: 14),
        transform: Matrix4.identity()..translate(0.0, isHovered ? -2.0 : 0.0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isHovered ? const Color(0xFFF9FBFF) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isHovered ? const Color(0xFFB9CAE6) : Colors.transparent,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isHovered ? Colors.black.withOpacity(0.08) : Colors.black.withOpacity(0.05),
              blurRadius: isHovered ? 24 : 18,
              offset: Offset(0, isHovered ? 10 : 8),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                initial,
                style: TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1C2430),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    apartment.isNotEmpty ? apartment : 'Lobby / Entry',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    purpose.isNotEmpty ? purpose : 'Visitor check-in',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  timeIn == null ? '—' : _formatTime(timeIn),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1C2430),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timeIn == null ? '' : _formatDate(timeIn),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _accentForName(String name) {
    final palette = [
      const Color(0xFF00A693),
      const Color(0xFF6F42C1),
      const Color(0xFF0D6EFD),
      const Color(0xFFDC3545),
      const Color(0xFF198754),
    ];
    return palette[name.codeUnits.fold<int>(0, (sum, code) => sum + code) % palette.length];
  }

  String _formatTime(DateTime value) {
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final suffix = value.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }

  String _formatDate(DateTime value) {
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return '${months[value.month - 1]} ${value.day.toString().padLeft(2, '0')}, ${value.year}';
  }
}

