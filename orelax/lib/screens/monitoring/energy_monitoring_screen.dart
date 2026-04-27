import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/energy_provider.dart';

class EnergyMonitoringScreen extends StatefulWidget {
  const EnergyMonitoringScreen({super.key});

  @override
  State<EnergyMonitoringScreen> createState() => _EnergyMonitoringScreenState();
}

class _EnergyMonitoringScreenState extends State<EnergyMonitoringScreen> {
  int _selectedDays = 7;
  String? _selectedDevice;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final provider = Provider.of<EnergyProvider>(context, listen: false);
    await provider.fetchCurrentReadings();
    await provider.fetchHistoricalData(days: _selectedDays);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<EnergyProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Energy Monitoring'),
        backgroundColor: const Color(0xFF034808),
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<int>(
            onSelected: (days) {
              setState(() => _selectedDays = days);
              provider.fetchHistoricalData(days: days);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 1, child: Text('Last 24h')),
              const PopupMenuItem(value: 7, child: Text('Last 7 days')),
              const PopupMenuItem(value: 30, child: Text('Last 30 days')),
            ],
            icon: const Icon(Icons.calendar_today),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [ 
              // Total Consumption Card
              _buildTotalCard(provider),
              const SizedBox(height: 20),
              
              // Alerts Section
              if (provider.alerts.isNotEmpty) ...[
                _buildAlertsSection(provider),
                const SizedBox(height: 20),
              ],
              
              // Current Readings Grid
              const Text(
                'Live Readings',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildReadingsGrid(provider),
              const SizedBox(height: 20),
              
              // Consumption Chart
              const Text(
                'Consumption Trend',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildConsumptionChart(provider),
              const SizedBox(height: 20),
              
              // Summary Stats
              _buildSummaryStats(provider),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTotalCard(EnergyProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF034808), Color(0xFF066A14)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Total Consumption',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            provider.getFormattedTotal(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Across ${provider.currentReadings.length} devices',
            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsSection(EnergyProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Alerts',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
        ),
        const SizedBox(height: 8),
        ...provider.alerts.map((alert) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning, color: Colors.red),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert['deviceName'] ?? 'Unknown Device',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'High consumption: ${alert['value']} kWh (Threshold: ${alert['threshold']} kWh)',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildReadingsGrid(EnergyProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.currentReadings.isEmpty) {
      return const Center(
        child: Text('No energy data available'),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: provider.currentReadings.length,
      itemBuilder: (context, index) {
        final reading = provider.currentReadings[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getDeviceIcon(reading['readingType']),
                size: 32,
                color: const Color(0xFF034808),
              ),
              const SizedBox(height: 8),
              Text(
                reading['deviceName'] ?? 'Unknown',
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '${reading['value']} ${reading['unit'] ?? 'kWh'}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF034808),
                ),
              ),
              Text(
                _formatTime(reading['timestamp']),
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConsumptionChart(EnergyProvider provider) {
    if (provider.chartData.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: Text('No chart data available')),
      );
    }

    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 40),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text('${value.toInt()}:00', style: const TextStyle(fontSize: 10));
                },
                reservedSize: 30,
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: provider.chartData.map((point) {
                return FlSpot(point['hour'].toDouble(), point['average']);
              }).toList(),
              isCurved: true,
              color: const Color(0xFF034808),
              barWidth: 3,
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFF034808).withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryStats(EnergyProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Summary',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Total',
                  '${provider.summary['total']?.toStringAsFixed(1) ?? '0'} kWh',
                  Icons.electric_bolt,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Average',
                  '${provider.summary['average']?.toStringAsFixed(1) ?? '0'} kWh',
                  Icons.trending_up,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Peak',
                  '${provider.summary['peak']?.toStringAsFixed(1) ?? '0'} kWh',
                  Icons.bolt,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 24, color: const Color(0xFF034808)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  IconData _getDeviceIcon(String? type) {
    switch (type) {
      case 'electricity':
        return Icons.electric_bolt;
      case 'water':
        return Icons.water_drop;
      case 'gas':
        return Icons.local_fire_department;
      default:
        return Icons.devices;
    }
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final time = DateTime.parse(timestamp);
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }
}