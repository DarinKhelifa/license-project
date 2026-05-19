import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../utils/wokwi_listener.dart';

class AccessLogsScreen extends StatefulWidget {
  const AccessLogsScreen({super.key});

  @override
  State<AccessLogsScreen> createState() => _AccessLogsScreenState();
}

class _AccessLogsScreenState extends State<AccessLogsScreen> {
  final List<Map<String, dynamic>> _accessLogs = [];
  int? _hoveredIndex;
  String _filter = 'All';
  bool _simulatorActive = false;
  bool _listeningToWokwi = false;
  String _wokwiUrl = '';
  Timer? _pollTimer;
  static const String _wokwiBridgeUrl = 'ws://localhost:2442';
  static const String _sharedWokwiUrl = 'https://wokwi.com/projects/463863217453220865';

  static const List<String> _names = [
    'Khelifa Darine',
    'Khiri Massa',
    'Nouioua Zineb',
    'Saoissen Benchikh',
    'Rania Layachi',
    'Benmelite lyna',
  ];

  @override
  void initState() {
    super.initState();
    _loadMockData();
  }

  @override
  void dispose() {
    _stopPolling();
    stopWokwiListener();
    super.dispose();
  }

  void _loadMockData() {
    // Mock access logs - QR code scans
    _accessLogs.addAll([
      {'name': 'Khelifa Darine', 'action': 'Entry', 'time': DateTime.now().subtract(const Duration(hours: 2))},
      {'name': 'Khiri Massa', 'action': 'Exit', 'time': DateTime.now().subtract(const Duration(hours: 3))},
      {'name': 'Nouioua Zineb', 'action': 'Entry', 'time': DateTime.now().subtract(const Duration(hours: 4))},
      {'name': 'Saoissen Benchikh', 'action': 'Exit', 'time': DateTime.now().subtract(const Duration(hours: 5))},
      {'name': 'Rania Layachi', 'action': 'Entry', 'time': DateTime.now().subtract(const Duration(hours: 6))},
      {'name': 'Benmelite lyna', 'action': 'Exit', 'time': DateTime.now().subtract(const Duration(hours: 7))},
    ]);
  }

  void _addAccessLog(String name, String action) {
    setState(() {
      _accessLogs.insert(0, {
        'name': name,
        'action': action,
        'time': DateTime.now(),
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Access Logs'),
        backgroundColor: const Color(0xFF034808),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_listeningToWokwi)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: Row(
                  children: const [
                    Icon(Icons.fiber_manual_record, size: 8, color: Colors.green),
                    SizedBox(width: 6),
                    Text('Wokwi', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            )
          else if (_simulatorActive)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: Row(
                  children: const [
                    Icon(Icons.fiber_manual_record, size: 8, color: Colors.green),
                    SizedBox(width: 6),
                    Text('Simulator', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ),
          IconButton(
            tooltip: 'Open simulator',
            icon: const Icon(Icons.developer_mode_outlined),
            onPressed: () => _showSimulatorOptions(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_listeningToWokwi)
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.withOpacity(0.12)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.wifi_tethering, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(child: Text('Listening to simulator: $_wokwiUrl', style: const TextStyle(fontSize: 13))),
                      TextButton(
                        onPressed: () {
                          stopWokwiListener();
                          _stopPolling();
                          setState(() => _listeningToWokwi = false);
                        },
                        child: const Text('Stop'),
                      )
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
            // Simple filter chips: All / Entry / Exit
            Row(
              children: [
                const Text('Filter:', style: TextStyle(fontSize: 14, color: Colors.grey)),
                const SizedBox(width: 12),
                ChoiceChip(
                  label: const Text('All'),
                  selected: _filter == 'All',
                  onSelected: (selected) => setState(() {
                    _filter = 'All';
                    _hoveredIndex = null;
                  }),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Entry'),
                  selected: _filter == 'Entry',
                  onSelected: (selected) => setState(() {
                    _filter = 'Entry';
                    _hoveredIndex = null;
                  }),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Exit'),
                  selected: _filter == 'Exit',
                  onSelected: (selected) => setState(() {
                    _filter = 'Exit';
                    _hoveredIndex = null;
                  }),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Build filtered logs
            Expanded(
              child: Builder(
                builder: (context) {
                  final filtered = _filter == 'All'
                      ? _accessLogs
                      : _accessLogs.where((l) => (l['action'] ?? '').toString().toLowerCase() == _filter.toLowerCase()).toList();
                  
                  return filtered.isEmpty
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
                        );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSimulatorOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Access Log Simulator', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.open_in_new),
                label: const Text('Start Wokwi (web)'),
                onPressed: () async {
                  Navigator.pop(ctx);
                  await _promptAndStartWokwi(context);
                },
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.tune),
                label: const Text('Local simulator'),
                onPressed: () {
                  Navigator.pop(ctx);
                  _openLocalSimulator(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _promptAndStartWokwi(BuildContext context) async {
    final controller = TextEditingController(text: _sharedWokwiUrl);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Wokwi URL'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Paste Wokwi project URL'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Start')),
        ],
      ),
    );

    if (ok == true) {
      final url = controller.text.trim();
      if (url.isEmpty) return;
      setState(() {
        _wokwiUrl = url;
        _listeningToWokwi = true;
      });

      startWokwiListener((data) {
        // Parse Wokwi QR scan events for access logs
        if (data['type'] == 'qr-scan' || data['qrData'] != null) {
          final qrData = data['qrData'] as String? ?? '';
          // Extract name from QR data (assumes format like "Name" or "Name-Action")
          final parts = qrData.split('-');
          String? personName;
          String action = 'Entry';
          
          if (parts.isNotEmpty) {
            personName = parts[0].trim();
            if (parts.length > 1) {
              action = parts[1].trim().toLowerCase() == 'exit' ? 'Exit' : 'Entry';
            }
          }

          if (personName != null && personName.isNotEmpty) {
            _addAccessLog(personName, action);
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Access: $personName ($action)')),
            );
          }
        } else if (data['readings'] is List) {
          // Alternative format - readings array
          final readings = data['readings'] as List;
          for (final reading in readings) {
            if (reading is Map && reading['type'] == 'access') {
              _addAccessLog(
                reading['name'] ?? 'Unknown',
                reading['action'] ?? 'Entry',
              );
            }
          }
        }
      });

      _startPolling();

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Wokwi started'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Open the following URL in a new tab and run the simulation, then connect its Debug Web Socket to:'),
              const SizedBox(height: 8),
              SelectableText(url, style: const TextStyle(color: Colors.blue)),
              const SizedBox(height: 12),
              SelectableText(_wokwiBridgeUrl, style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
        ),
      );
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      // Polling interval for checking new access logs
      // Data will come via the Wokwi listener callback
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  void _openLocalSimulator(BuildContext context) {
    String? selectedName = _names.first;
    String? selectedAction = 'Entry';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Access Log Simulator'),
        content: StatefulBuilder(
          builder: (context, setLocalState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<String>(
                value: selectedName,
                onChanged: (v) => setLocalState(() => selectedName = v),
                isExpanded: true,
                items: _names.map((name) => DropdownMenuItem(value: name, child: Text(name))).toList(),
              ),
              const SizedBox(height: 16),
              DropdownButton<String>(
                value: selectedAction,
                onChanged: (v) => setLocalState(() => selectedAction = v),
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'Entry', child: Text('Entry')),
                  DropdownMenuItem(value: 'Exit', child: Text('Exit')),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _addAccessLog(selectedName!, selectedAction!);
              setState(() => _simulatorActive = true);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Access log added: $selectedName ($selectedAction)')),
              );
            },
            child: const Text('Add Log'),
          ),
        ],
      ),
    );
  }
}

