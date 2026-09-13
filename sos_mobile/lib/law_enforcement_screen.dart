import 'dart:async';
import 'package:flutter/material.dart';
import 'api_service.dart';

class LawEnforcementDashboard extends StatefulWidget {
  const LawEnforcementDashboard({super.key});

  @override
  State<LawEnforcementDashboard> createState() => _LawEnforcementDashboardState();
}

class _LawEnforcementDashboardState extends State<LawEnforcementDashboard> {
  List<Map<String, dynamic>> _activeAlerts = [];
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _fetchActiveAlerts();
    // Poll for new emergency signals every 5 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) => _fetchActiveAlerts());
  }

  Future<void> _fetchActiveAlerts() async {
    // Call responder API endpoint
    final alerts = await ApiService.fetchAllActiveAlerts();
    if (mounted) {
      setState(() {
        _activeAlerts = alerts;
      });
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dispatcher Command Center'),
        backgroundColor: const Color(0xFF0F172A),
      ),
      body: _activeAlerts.isEmpty
          ? const Center(child: Text('No active emergency signals.'))
          : ListView.builder(
              itemCount: _activeAlerts.length,
              itemBuilder: (context, index) {
                final alert = _activeAlerts[index];
                return Card(
                  color: Colors.red.shade50,
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    leading: const Icon(Icons.emergency, color: Colors.red, size: 36),
                    title: Text('EMERGENCY SIGNAL #${alert['id']}'),
                    subtitle: Text('Lat: ${alert['latitude']}, Long: ${alert['longitude']}'),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      onPressed: () async {
                        await ApiService.resolveAlert(alert['id']);
                        _fetchActiveAlerts();
                      },
                      child: const Text('DISPATCH / RESOLVE'),
                    ),
                  ),
                );
              },
            ),
    );
  }
}