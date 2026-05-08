import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AccessLogsScreen extends StatefulWidget {
  const AccessLogsScreen({super.key});

  @override
  State<AccessLogsScreen> createState() => _AccessLogsScreenState();
}

class _AccessLogsScreenState extends State<AccessLogsScreen> {
  final List<Map<String, dynamic>> _accessLogs = [];
  int? _hoveredIndex;
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    _loadMockData();
  }

  void _loadMockData() {
    // Mock access logs - QR code scans
    _accessLogs.addAll([
      {'name': 'John Doe', 'action': 'Entry', 'time': DateTime.now().subtract(const Duration(hours: 2))},
      {'name': 'Jane Smith', 'action': 'Exit', 'time': DateTime.now().subtract(const Duration(hours: 3))},
      {'name': 'Security Guard', 'action': 'Entry', 'time': DateTime.now().subtract(const Duration(hours: 4))},
      {'name': 'Mike Johnson', 'action': 'Exit', 'time': DateTime.now().subtract(const Duration(hours: 5))},
      {'name': 'Sarah Connor', 'action': 'Entry', 'time': DateTime.now().subtract(const Duration(hours: 6))},
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Access Logs'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            // Simple filter chips: All / Entry / Exit
            Row(
              children: [
                const Text('Filter:', style: TextStyle(fontSize: 14, color: Colors.grey)),
                const SizedBox(width: 12),
                ChoiceChip(
                  label: const Text('All'),
                  selected: _filter == 'All',
                  onSelected: (s) => setState(() => _filter = 'All'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Entry'),
                  selected: _filter == 'Entry',
                  onSelected: (s) => setState(() => _filter = 'Entry'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Exit'),
                  selected: _filter == 'Exit',
                  onSelected: (s) => setState(() => _filter = 'Exit'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // prepare filtered logs
            Builder(
              builder: (context) {
                final filtered = _filter == 'All'
                    ? _accessLogs
                    : _accessLogs.where((l) => (l['action'] ?? '').toString().toLowerCase() == _filter.toLowerCase()).toList();
                return Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.history, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text('No access logs'),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 24),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final log = filtered[index];
                            final time = log['time'] as DateTime;
                            final isEntry = log['action'] == 'Entry';

                            final isHovered = _hoveredIndex == index && _filter == 'All' ? _hoveredIndex == index : _hoveredIndex == index;
                            return MouseRegion(
                              onEnter: (_) {
                                if (_hoveredIndex != index) setState(() => _hoveredIndex = index);
                              },
                              onExit: (_) {
                                if (_hoveredIndex == index) setState(() => _hoveredIndex = null);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                curve: Curves.easeOut,
                                margin: const EdgeInsets.only(bottom: 12),
                                transform: Matrix4.identity()..translate(0.0, isHovered ? -4.0 : 0.0),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                decoration: BoxDecoration(
                                  color: isHovered ? const Color(0xFFF9FBFF) : Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: isHovered ? const Color(0xFFB9CAE6) : Colors.transparent,
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isHovered ? Colors.black.withOpacity(0.08) : Colors.black.withOpacity(0.04),
                                      blurRadius: isHovered ? 20 : 12,
                                      offset: Offset(0, isHovered ? 10 : 6),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: isEntry ? const Color(0xFFDFF6EA) : const Color(0xFFFFF1F1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isEntry ? Icons.login : Icons.logout,
                                        color: isEntry ? const Color(0xFF2E9E53) : const Color(0xFFB00020),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            log['name'] ?? 'Unknown',
                                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            DateFormat('MMM dd, HH:mm').format(time),
                                            style: TextStyle(color: Colors.grey.shade600),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isEntry ? const Color(0xFFDFF6EA) : const Color(0xFFFFF1F1),
                                        borderRadius: BorderRadius.circular(999),
                                        border: Border.all(color: isEntry ? const Color(0xFF2E9E53).withOpacity(0.15) : const Color(0xFFB00020).withOpacity(0.12)),
                                      ),
                                      child: Text(
                                        (log['action'] ?? '').toString().toUpperCase(),
                                        style: TextStyle(
                                          color: isEntry ? const Color(0xFF2E9E53) : const Color(0xFFB00020),
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                );
              },
            ),
            Expanded(
              child: _accessLogs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.history, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No access logs'),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: _accessLogs.length,
                      itemBuilder: (context, index) {
                        final log = _accessLogs[index];
                        final time = log['time'] as DateTime;
                        final isEntry = log['action'] == 'Entry';

                        final isHovered = _hoveredIndex == index;
                        return MouseRegion(
                          onEnter: (_) {
                            if (_hoveredIndex != index) setState(() => _hoveredIndex = index);
                          },
                          onExit: (_) {
                            if (_hoveredIndex == index) setState(() => _hoveredIndex = null);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.easeOut,
                            margin: const EdgeInsets.only(bottom: 12),
                            transform: Matrix4.identity()..translate(0.0, isHovered ? -4.0 : 0.0),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            decoration: BoxDecoration(
                              color: isHovered ? const Color(0xFFF9FBFF) : Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isHovered ? const Color(0xFFB9CAE6) : Colors.transparent,
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isHovered ? Colors.black.withOpacity(0.08) : Colors.black.withOpacity(0.04),
                                  blurRadius: isHovered ? 20 : 12,
                                  offset: Offset(0, isHovered ? 10 : 6),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: isEntry ? const Color(0xFFDFF6EA) : const Color(0xFFFFF1F1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isEntry ? Icons.login : Icons.logout,
                                    color: isEntry ? const Color(0xFF2E9E53) : const Color(0xFFB00020),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        log['name'] ?? 'Unknown',
                                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        DateFormat('MMM dd, HH:mm').format(time),
                                        style: TextStyle(color: Colors.grey.shade600),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isEntry ? const Color(0xFFDFF6EA) : const Color(0xFFFFF1F1),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(color: isEntry ? const Color(0xFF2E9E53).withOpacity(0.15) : const Color(0xFFB00020).withOpacity(0.12)),
                                  ),
                                  child: Text(
                                    (log['action'] ?? '').toString().toUpperCase(),
                                    style: TextStyle(
                                      color: isEntry ? const Color(0xFF2E9E53) : const Color(0xFFB00020),
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

