import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../services/api_service.dart';

class TemperatureScreen extends StatefulWidget {
  const TemperatureScreen({Key? key}) : super(key: key);

  @override
  State<TemperatureScreen> createState() => _TemperatureScreenState();
}

class _TemperatureScreenState extends State<TemperatureScreen> {
  // Placeholder values; will be wired to IoT later
  double _temperature = 24.3;
  double _humidity = 48.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Environment'),
        backgroundColor: const Color(0xFF1A5C2A),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: ApiService.getEnvironmentCurrent(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final readings = snapshot.data ?? [];
          if (readings.isEmpty) {
            return Center(child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('No environment readings found.'),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Refresh'),
                ),
              ],
            ));
          }

          // Use first device reading by default
          final first = readings.first;
          final temp = first['temperature']?.toDouble() ?? _temperature;
          final hum = first['humidity']?.toDouble() ?? _humidity;

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
