import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';
import '../../utils/wokwi_listener.dart';

class TemperatureScreen extends StatefulWidget {
  const TemperatureScreen({Key? key}) : super(key: key);

  @override
  State<TemperatureScreen> createState() => _TemperatureScreenState();
}

class _TemperatureScreenState extends State<TemperatureScreen> {
  static const String _sharedWokwiUrl = 'https://wokwi.com/projects/464389351261648897';
  static const String _wokwiBridgeUrl = 'ws://localhost:2442';

  // Placeholder values; will be wired to IoT later
  double _temperature = 24.3;
  double _humidity = 48.0;
  bool _listeningToWokwi = false;
  String _wokwiUrl = '';
  Timer? _pollTimer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Environment'),
        backgroundColor: const Color(0xFF1A5C2A),
        actions: [
          IconButton(
            tooltip: 'Open simulator',
            icon: const Icon(Icons.developer_mode_outlined),
            onPressed: () => _showSimulatorOptions(context),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: ApiService.getEnvironmentCurrent(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final readings = snapshot.data ?? [];
          final first = readings.isNotEmpty ? readings.first : const <String, dynamic>{};
          final temp = (first['temperature'] as num?)?.toDouble() ?? _temperature;
          final hum = (first['humidity'] as num?)?.toDouble() ?? _humidity;

          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A5C2A).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SvgPicture.asset('assets/icon/thermometer-sun.svg', color: const Color(0xFF1A5C2A)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Temperature & Humidity',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A5C2A),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text('Create action — will be linked to IoT later.'),
                          ));
                        },
                        child: const Text('Create'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A5C2A).withOpacity(0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF1A5C2A).withOpacity(0.10)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.wifi_tethering, color: Color(0xFF1A5C2A)),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Live Wokwi bridge ready. In Wokwi, open Debug Web Socket and use ws://localhost:2442.',
                            style: TextStyle(fontSize: 12.5),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            await Clipboard.setData(const ClipboardData(text: _wokwiBridgeUrl));
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bridge URL copied')));
                          },
                          child: const Text('Copy URL'),
                        ),
                      ],
                    ),
                  ),
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
                  _SensorCard(
                    label: 'Temperature',
                    value: '${temp.toStringAsFixed(1)} °C',
                    color: Colors.orangeAccent,
                    icon: Icons.thermostat_outlined,
                  ),
                  const SizedBox(height: 16),
                  _SensorCard(
                    label: 'Humidity',
                    value: '${hum.toStringAsFixed(0)} %',
                    color: Colors.lightBlueAccent,
                    icon: Icons.grain,
                  ),
                  if (readings.isEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'No environment readings returned yet. Start the simulator and keep this screen open; live values will appear here as soon as the bridge receives them.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  const Text('Other device readings', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  ...readings.skip(1).map((r) => Padding(
                    padding: const EdgeInsets.only(bottom:12.0),
                    child: _SensorCard(
                      label: r['deviceName'] ?? r['deviceId'] ?? 'Device',
                      value: '${(r['temperature'] ?? '-')} ${r['unitTemp'] ?? '°C'} • ${(r['humidity'] ?? '-')} ${r['unitHum'] ?? '%'}',
                      color: Colors.grey,
                      icon: Icons.device_thermostat,
                    ),
                  ))
                ],
              ),
            ),
          );
        },
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
              Text('Simulator', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.rocket_launch_outlined),
                label: const Text('Open shared Wokwi project'),
                onPressed: () async {
                  Navigator.pop(ctx);
                  await _openSharedWokwiProject();
                },
              ),
              const SizedBox(height: 8),
              if (kIsWeb) ...[
                ElevatedButton.icon(
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open Wokwi (web)'),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await _promptAndStartWokwi(context);
                  },
                ),
                const SizedBox(height: 8),
              ],
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
        // Expect temperature/humidity values
        final t = (data['temperature'] ?? data['temp']) as num?;
        final h = (data['humidity'] ?? data['hum']) as num?;
        setState(() {
          if (t != null) _temperature = t.toDouble();
          if (h != null) _humidity = h.toDouble();
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Simulator: updated ${_temperature.toStringAsFixed(1)}°C')));
      });

      // Start polling backend for live reading (bridge injects latest reading)
      _startPolling();

      // Tell user to open the provided URL in a new tab and run the simulation
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Wokwi started'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Open the following URL in a new tab and run the simulation, then connect its Debug Web Socket to ws://localhost:2442:'),
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
      try {
        final readings = await ApiService.getEnvironmentCurrent();
        if (readings.isNotEmpty) {
          final first = readings.first;
          final t = (first['temperature'] ?? first['temp']) as num?;
          final h = (first['humidity'] ?? first['hum']) as num?;
          if (t != null || h != null) {
            if (!mounted) return;
            setState(() {
              if (t != null) _temperature = t.toDouble();
              if (h != null) _humidity = h.toDouble();
            });
          }
        }
      } catch (_) {
        // ignore polling errors
      }
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  @override
  void dispose() {
    _stopPolling();
    stopWokwiListener();
    super.dispose();
  }

  Future<void> _openSharedWokwiProject() async {
    final uri = Uri.parse(_sharedWokwiUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _openLocalSimulator(BuildContext context) {
    double temp = _temperature;
    double hum = _humidity;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Local Simulator'),
        content: StatefulBuilder(
          builder: (context, setLocalState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Temperature: ${temp.toStringAsFixed(1)} °C'),
              Slider(value: temp, min: -10, max: 50, divisions: 600, onChanged: (v) => setLocalState(() => temp = v)),
              const SizedBox(height: 8),
              Text('Humidity: ${hum.toStringAsFixed(0)} %'),
              Slider(value: hum, min: 0, max: 100, divisions: 100, onChanged: (v) => setLocalState(() => hum = v)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () {
            setState(() {
              _temperature = temp;
              _humidity = hum;
            });
            Navigator.pop(ctx);
          }, child: const Text('Send')),
        ],
      ),
    );
  }
}

class _SensorCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _SensorCard({
    Key? key,
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: color.withOpacity(0.18),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 6),
                Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }
}
