import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/maintenance_bottom_nav_bar.dart';

class MaintenanceScheduleScreen extends StatefulWidget {
  const MaintenanceScheduleScreen({super.key});

  @override
  State<MaintenanceScheduleScreen> createState() => _MaintenanceScheduleScreenState();
}

class MaintenanceScheduleItem {
  final String id;
  final String title;
  final String notes;
  final int weekday;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final Color color;
  final DateTime createdAt;
  final DateTime updatedAt;

  MaintenanceScheduleItem({
    required this.id,
    required this.title,
    required this.notes,
    required this.weekday,
    required this.startTime,
    required this.endTime,
    required this.color,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'notes': notes,
        'weekday': weekday,
        'startHour': startTime.hour,
        'startMinute': startTime.minute,
        'endHour': endTime.hour,
        'endMinute': endTime.minute,
        'color': color.toARGB32(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory MaintenanceScheduleItem.fromMap(Map<String, dynamic> map) {
    return MaintenanceScheduleItem(
      id: (map['id'] ?? map['_id'] ?? DateTime.now().microsecondsSinceEpoch.toString()).toString(),
      title: (map['title'] ?? '').toString(),
      notes: (map['notes'] ?? map['description'] ?? '').toString(),
      weekday: int.tryParse(map['weekday'].toString()) ?? DateTime.now().weekday,
      startTime: TimeOfDay(
        hour: int.tryParse((map['startHour'] ?? 8).toString()) ?? 8,
        minute: int.tryParse((map['startMinute'] ?? 0).toString()) ?? 0,
      ),
      endTime: TimeOfDay(
        hour: int.tryParse((map['endHour'] ?? 9).toString()) ?? 9,
        minute: int.tryParse((map['endMinute'] ?? 0).toString()) ?? 0,
      ),
      color: Color(int.tryParse((map['color'] ?? 0xFF2A7D3A).toString()) ?? 0xFF2A7D3A),
      createdAt: DateTime.tryParse((map['createdAt'] ?? '').toString()) ?? DateTime.now(),
      updatedAt: DateTime.tryParse((map['updatedAt'] ?? '').toString()) ?? DateTime.now(),
    );
  }
}

class _MaintenanceScheduleScreenState extends State<MaintenanceScheduleScreen> {
  final List<MaintenanceScheduleItem> _items = [];
  SharedPreferences? _prefs;
  String? _storageKey;
  bool _isLoading = true;
  String? _errorMessage;
  int _selectedWeekday = DateTime.now().weekday;
  DateTime _currentWeekStart = _startOfWeek(DateTime.now());

  static DateTime _startOfWeek(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return normalized.subtract(Duration(days: normalized.weekday - 1));
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSchedules());
  }

  Future<void> _ensureStorageKey() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final uid = auth.userId ?? 'anonymous';
    _prefs ??= await SharedPreferences.getInstance();
    _storageKey = 'maintenance_schedule_$uid';
  }

  List<MaintenanceScheduleItem> _readCachedSchedules() {
    final raw = _prefs?.getStringList(_storageKey ?? '') ?? const [];
    final cached = <MaintenanceScheduleItem>[];

    for (final value in raw) {
      try {
        final decoded = json.decode(value) as Map<String, dynamic>;
        cached.add(MaintenanceScheduleItem.fromMap(decoded));
      } catch (_) {
        continue;
      }
    }

    return cached;
  }

  Future<void> _saveCachedSchedules() async {
    // Ensure storage key is computed for the current user before saving.
    await _ensureStorageKey();

    if (_prefs == null || _storageKey == null) return;
    try {
      final encoded = _items.map((item) {
        try {
          return json.encode(item.toJson());
        } catch (e) {
          debugPrint('Error encoding item ${item.id}: $e');
          rethrow;
        }
      }).toList();
      await _prefs!.setStringList(_storageKey!, encoded);
    } catch (error) {
      debugPrint('Error saving schedules to prefs: $error');
      rethrow;
    }
  }

  Future<void> _loadSchedules() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _ensureStorageKey();
      final cachedSchedules = _readCachedSchedules();

      _items
        ..clear()
        ..addAll(cachedSchedules);
      _items.sort((left, right) {
        final weekdayCompare = left.weekday.compareTo(right.weekday);
        if (weekdayCompare != 0) return weekdayCompare;
        return _minutesFromTime(left.startTime).compareTo(_minutesFromTime(right.startTime));
      });

      if (_selectedWeekday < 1 || _selectedWeekday > 7) {
        _selectedWeekday = DateTime.now().weekday;
      }
      _currentWeekStart = _startOfWeek(DateTime.now());
      await _saveCachedSchedules();
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _selectWeekday(int weekday) {
    setState(() {
      _selectedWeekday = weekday;
    });
  }

  void _previousWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.subtract(const Duration(days: 7));
    });
  }

  void _nextWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.add(const Duration(days: 7));
    });
  }

  void _jumpToToday() {
    setState(() {
      _selectedWeekday = DateTime.now().weekday;
      _currentWeekStart = _startOfWeek(DateTime.now());
    });
  }

  int _minutesFromTime(TimeOfDay time) => (time.hour * 60) + time.minute;

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  String _formatWeekdayTitle(int weekday) {
    final date = _currentWeekStart.add(Duration(days: weekday - 1));
    return DateFormat('EEE, MMM d').format(date);
  }

  List<MaintenanceScheduleItem> _itemsForDay(int weekday) {
    final items = _items.where((item) => item.weekday == weekday).toList();
    items.sort((left, right) => _minutesFromTime(left.startTime).compareTo(_minutesFromTime(right.startTime)));
    return items;
  }

  MaintenanceScheduleItem? _nextItemForDay(int weekday) {
    final now = TimeOfDay.now();
    final nowMinutes = _minutesFromTime(now);
    final items = _itemsForDay(weekday);
    for (final item in items) {
      if (_minutesFromTime(item.startTime) >= nowMinutes) {
        return item;
      }
    }
    return items.isEmpty ? null : items.first;
  }

  Future<void> _deleteSchedule(MaintenanceScheduleItem item) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete schedule'),
          content: Text('Remove ${item.title} from your weekly calendar?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    setState(() {
      _items.removeWhere((entry) => entry.id == item.id);
    });
    await _saveCachedSchedules();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${item.title} removed')),
    );
  }

  Future<void> _showScheduleEditor({MaintenanceScheduleItem? existing}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _ScheduleEditorSheet(
          existing: existing,
          currentWeekStart: _currentWeekStart,
          selectedWeekday: existing?.weekday ?? _selectedWeekday,
          onSave: (item) {
            setState(() {
              final index = _items.indexWhere((entry) => entry.id == item.id);
              if (index >= 0) {
                _items[index] = item;
              } else {
                _items.add(item);
              }
              _items.sort((left, right) {
                final weekdayCompare = left.weekday.compareTo(right.weekday);
                if (weekdayCompare != 0) return weekdayCompare;
                return _minutesFromTime(left.startTime).compareTo(_minutesFromTime(right.startTime));
              });
            });
            _saveCachedSchedules();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(existing == null ? 'Schedule created' : 'Schedule updated'),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeader() {
    final selectedDate = _currentWeekStart.add(Duration(days: _selectedWeekday - 1));
    final selectedItems = _itemsForDay(_selectedWeekday);
    final nextItem = _nextItemForDay(_selectedWeekday);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF10301B), Color(0xFF1A5C2A), Color(0xFF2A7D3A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x331A5C2A),
            blurRadius: 26,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weekly schedule',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Plan shifts, reminders, and tasks by day.',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(36),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  DateFormat('MMM yyyy').format(selectedDate),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _HeaderMetric(
                label: 'Today',
                value: _formatWeekdayTitle(_selectedWeekday),
              ),
              const SizedBox(width: 12),
              _HeaderMetric(
                label: 'Tasks',
                value: '${selectedItems.length}',
              ),
              const SizedBox(width: 12),
              _HeaderMetric(
                label: 'Next',
                value: nextItem == null ? 'Free' : _formatTime(nextItem.startTime),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeekStrip() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: _previousWeek,
                  icon: const Icon(Icons.chevron_left),
                  label: const Text('Prev week'),
                ),
                const Spacer(),
                Text(
                  'Week calendar',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF10301B),
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _nextWeek,
                  icon: const Icon(Icons.chevron_right),
                  label: const Text('Next week'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 96,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                final weekday = index + 1;
                final date = _currentWeekStart.add(Duration(days: index));
                final isSelected = weekday == _selectedWeekday;
                final isToday = weekday == DateTime.now().weekday &&
                    date.year == DateTime.now().year &&
                    date.month == DateTime.now().month &&
                    date.day == DateTime.now().day;
                final dayItems = _itemsForDay(weekday);

                return GestureDetector(
                  onTap: () => _selectWeekday(weekday),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 86,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(
                              colors: [Color(0xFF1A5C2A), Color(0xFF2A7D3A)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isSelected ? null : const Color(0xFFF5F8FB),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isSelected ? Colors.transparent : const Color(0xFFE6ECF2),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected ? const Color(0x331A5C2A) : Colors.black.withAlpha(10),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('EEE').format(date),
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isSelected ? Colors.white : const Color(0xFF53657A),
                              ),
                            ),
                            if (isToday)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE05C8A),
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        Text(
                          '${date.day}',
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? Colors.white : const Color(0xFF10301B),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.white.withAlpha(46) : const Color(0xFFEAF3EE),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${dayItems.length} item${dayItems.length == 1 ? '' : 's'}',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white : const Color(0xFF1A5C2A),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemCount: 7,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgendaList() {
    final items = _itemsForDay(_selectedWeekday);
    final selectedDate = _currentWeekStart.add(Duration(days: _selectedWeekday - 1));

    if (items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEAF3EE), Color(0xFFD7F0DD)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(Icons.calendar_month_outlined, color: Color(0xFF1A5C2A), size: 34),
            ),
            const SizedBox(height: 14),
            Text(
              'No schedules for ${DateFormat('EEEE').format(selectedDate)}',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF10301B),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Create a shift, task, or reminder to start building this week\'s calendar.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF617386),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _showScheduleEditor(),
              icon: const Icon(Icons.add),
              label: const Text('Add schedule'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Text(
              DateFormat('EEEE').format(selectedDate),
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF10301B),
              ),
            ),
            const Spacer(),
            Text(
              '${items.length} planned item${items.length == 1 ? '' : 's'}',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6B7A8B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...items.map((item) {
          final durationMinutes = _minutesFromTime(item.endTime) - _minutesFromTime(item.startTime);
          final durationHours = durationMinutes ~/ 60;
          final durationRest = durationMinutes % 60;
          final durationLabel = durationHours > 0
              ? '${durationHours}h ${durationRest.toString().padLeft(2, '0')}m'
              : '${durationMinutes}m';

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: item.color.withAlpha(41)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x12000000),
                    blurRadius: 18,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    margin: const EdgeInsets.only(top: 5),
                    decoration: BoxDecoration(
                      color: item.color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                              color: item.color.withAlpha(89),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                item.title,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF10301B),
                                ),
                              ),
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_horiz),
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _showScheduleEditor(existing: item);
                                }
                                if (value == 'delete') {
                                  _deleteSchedule(item);
                                }
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem<String>(value: 'edit', child: Text('Edit')),
                                PopupMenuItem<String>(value: 'delete', child: Text('Delete')),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.notes.isEmpty ? 'No extra notes' : item.notes,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            height: 1.45,
                            color: const Color(0xFF617386),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _MiniInfoChip(
                              icon: Icons.schedule_outlined,
                              label: '${_formatTime(item.startTime)} - ${_formatTime(item.endTime)}',
                              background: item.color.withAlpha(26),
                              foreground: item.color,
                            ),
                            _MiniInfoChip(
                              icon: Icons.timelapse,
                              label: durationLabel,
                              background: const Color(0xFFF3F6F9),
                              foreground: const Color(0xFF516273),
                            ),
                            const _MiniInfoChip(
                              icon: Icons.repeat,
                              label: 'Weekly',
                              background: Color(0xFFEAF3EE),
                              foreground: Color(0xFF1A5C2A),
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
        }),
      ],
    );
  }

  Widget _buildStatsCard() {
    final selectedItems = _itemsForDay(_selectedWeekday);
    final weekItemCount = _items.length;
    final totalMinutes = selectedItems.fold<int>(0, (sum, item) => sum + (_minutesFromTime(item.endTime) - _minutesFromTime(item.startTime)));
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    final productiveTime = selectedItems.isEmpty
        ? 'No planned blocks'
        : hours > 0
            ? '${hours}h ${minutes.toString().padLeft(2, '0')}m planned today'
            : '${minutes}m planned today';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1F16),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Week overview',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$weekItemCount planned item${weekItemCount == 1 ? '' : 's'} this week',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  productiveTime,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2A7D3A), Color(0xFF5DBB63)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.calendar_month, color: Colors.white, size: 36),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const MaintenanceBottomNavBar(currentIndex: 0),
      backgroundColor: const Color(0xFFF2F6F9),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showScheduleEditor(),
        backgroundColor: const Color(0xFF1A5C2A),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(
          'Add',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF7FAFC), Color(0xFFEAF3EE)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadSchedules,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Schedule',
                                    style: GoogleFonts.poppins(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF10301B),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Design your week like a calendar, then edit it in place.',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      height: 1.4,
                                      color: const Color(0xFF617386),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                IconButton(
                                  onPressed: _jumpToToday,
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: const Color(0xFF1A5C2A),
                                  ),
                                  icon: const Icon(Icons.today_outlined),
                                ),
                                const SizedBox(height: 8),
                                TextButton.icon(
                                  onPressed: () => _showScheduleEditor(),
                                  icon: const Icon(Icons.add_circle_outline),
                                  label: const Text('New'),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_errorMessage != null) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF1F1),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: const Color(0xFFF3B8B8)),
                            ),
                            child: Text(
                              _errorMessage!,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: const Color(0xFFB04545),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        _buildHeader(),
                        const SizedBox(height: 16),
                        _buildWeekStrip(),
                        const SizedBox(height: 16),
                        _buildStatsCard(),
                        const SizedBox(height: 16),
                        _buildAgendaList(),
                        const SizedBox(height: 90),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _ScheduleEditorSheet extends StatefulWidget {
  final MaintenanceScheduleItem? existing;
  final DateTime currentWeekStart;
  final int selectedWeekday;
  final Function(MaintenanceScheduleItem) onSave;

  const _ScheduleEditorSheet({
    required this.existing,
    required this.currentWeekStart,
    required this.selectedWeekday,
    required this.onSave,
  });

  @override
  State<_ScheduleEditorSheet> createState() => _ScheduleEditorSheetState();
}

class _ScheduleEditorSheetState extends State<_ScheduleEditorSheet> {
  static const List<Color> _palette = [
    Color(0xFF1A5C2A),
    Color(0xFF2A7D3A),
    Color(0xFFE05C8A),
    Color(0xFF5B8DEF),
    Color(0xFFF39C54),
  ];

  late TextEditingController _titleController;
  late TextEditingController _notesController;
  late GlobalKey<FormState> _formKey;
  late int _selectedWeekday;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.existing?.title ?? '');
    _notesController = TextEditingController(text: widget.existing?.notes ?? '');
    _formKey = GlobalKey<FormState>();
    _selectedWeekday = widget.selectedWeekday;
    _startTime = widget.existing?.startTime ?? const TimeOfDay(hour: 8, minute: 0);
    _endTime = widget.existing?.endTime ?? const TimeOfDay(hour: 9, minute: 0);
    _selectedColor = widget.existing?.color ?? _palette.first;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  int _minutesFromTime(TimeOfDay time) => (time.hour * 60) + time.minute;

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  void _handleSave() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final startMinutes = _minutesFromTime(_startTime);
    final endMinutes = _minutesFromTime(_endTime);
    if (endMinutes <= startMinutes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time')),
      );
      return;
    }

    try {
      final now = DateTime.now();
      final item = MaintenanceScheduleItem(
        id: widget.existing?.id ?? '${now.millisecondsSinceEpoch}_${_selectedWeekday}_${_minutesFromTime(_startTime)}',
        title: _titleController.text.trim(),
        notes: _notesController.text.trim(),
        weekday: _selectedWeekday >= 1 && _selectedWeekday <= 7 ? _selectedWeekday : DateTime.now().weekday,
        startTime: _startTime,
        endTime: _endTime,
        color: _selectedColor,
        createdAt: widget.existing?.createdAt ?? now,
        updatedAt: now,
      );

      widget.onSave(item);
      Navigator.pop(context);
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving schedule: $error'),
          backgroundColor: Colors.red,
        ),
      );
      debugPrint('Schedule save error: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: EdgeInsets.only(
          left: 12,
          right: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 12,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 30,
              offset: Offset(0, 18),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 54,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD7DEE8),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    widget.existing == null ? 'Create schedule' : 'Edit schedule',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF10301B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Set a task, assign it to a weekday, and keep your shift organized.',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: const Color(0xFF5A6B7D),
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _titleController,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Title',
                      prefixIcon: const Icon(Icons.title_outlined),
                      filled: true,
                      fillColor: const Color(0xFFF5F8FB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Add a title for this schedule';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Notes',
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 40),
                        child: Icon(Icons.notes_outlined),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF5F8FB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Weekday',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF10301B),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(7, (index) {
                      final weekday = index + 1;
                      final active = weekday == _selectedWeekday;
                      return ChoiceChip(
                        label: Text(DateFormat('EEE').format(widget.currentWeekStart.add(Duration(days: index)))),
                        selected: active,
                        labelStyle: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: active ? Colors.white : const Color(0xFF10301B),
                        ),
                        selectedColor: const Color(0xFF1A5C2A),
                        backgroundColor: const Color(0xFFF5F8FB),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                        onSelected: (_) => setState(() => _selectedWeekday = weekday),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _TimePickerCard(
                          label: 'Start time',
                          value: _formatTime(_startTime),
                          icon: Icons.schedule_outlined,
                          onTap: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: _startTime,
                            );
                            if (picked == null) return;
                            setState(() => _startTime = picked);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _TimePickerCard(
                          label: 'End time',
                          value: _formatTime(_endTime),
                          icon: Icons.av_timer_outlined,
                          onTap: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: _endTime,
                            );
                            if (picked == null) return;
                            setState(() => _endTime = picked);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Accent color',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF10301B),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _palette.map((color) {
                      final active = color.toARGB32() == _selectedColor.toARGB32();
                      return GestureDetector(
                        onTap: () => setState(() => _selectedColor = color),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: active ? Colors.black87 : Colors.transparent,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: color.withAlpha(71),
                                blurRadius: 10,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: active ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF1A5C2A),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                      onPressed: _handleSave,
                      child: Text(
                        widget.existing == null ? 'Create schedule' : 'Save changes',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderMetric extends StatelessWidget {
  final String label;
  final String value;

  const _HeaderMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(31),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimePickerCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  const _TimePickerCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F8FB),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFF1A5C2A)),
            const SizedBox(height: 10),
            Text(
              label,
              style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF6B7A8B)),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF10301B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;

  const _MiniInfoChip({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}
