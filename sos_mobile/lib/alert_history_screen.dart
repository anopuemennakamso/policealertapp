import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'api_service.dart';

class AlertHistoryScreen extends StatefulWidget {
  const AlertHistoryScreen({super.key});

  @override
  State<AlertHistoryScreen> createState() => _AlertHistoryScreenState();
}

class _AlertHistoryScreenState extends State<AlertHistoryScreen> {
  late Future<List<Map<String, dynamic>>> _alertsFuture;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  void _loadAlerts() {
    setState(() {
      _alertsFuture = ApiService.fetchUserAlerts(1); // Hardcoded user_id for dev
    });
  }

  /// Helper function to convert raw coordinates into a street address
  Future<String> _getAddressFromCoordinates(double? lat, double? lng) async {
    if (lat == null || lng == null) return 'Location unavailable';
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String street = place.street ?? '';
        String locality = place.locality ?? place.subAdministrativeArea ?? '';
        String state = place.administrativeArea ?? '';

        List<String> parts = [street, locality, state].where((p) => p.trim().isNotEmpty).toList();
        return parts.isNotEmpty ? parts.join(', ') : 'Lat: ${lat.toStringAsFixed(4)}, Long: ${lng.toStringAsFixed(4)}';
      }
      return 'Lat: ${lat.toStringAsFixed(4)}, Long: ${lng.toStringAsFixed(4)}';
    } catch (e) {
      return 'Lat: ${lat.toStringAsFixed(4)}, Long: ${lng.toStringAsFixed(4)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Alert History',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF0F172A)),
            onPressed: _loadAlerts,
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _alertsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.history_toggle_off, size: 48, color: Color(0xFF94A3B8)),
                  const SizedBox(height: 12),
                  const Text(
                    'No alert history found.',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _loadAlerts,
                    child: const Text('Refresh'),
                  ),
                ],
              ),
            );
          }

          final alerts = snapshot.data!;

          return RefreshIndicator(
            onRefresh: () async => _loadAlerts(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: alerts.length,
              itemBuilder: (context, index) {
                final alert = alerts[index];
                final status = alert['status'] ?? 'TRIGGERED';
                final double? lat = alert['latitude'] != null ? (alert['latitude'] as num).toDouble() : null;
                final double? long = alert['longitude'] != null ? (alert['longitude'] as num).toDouble() : null;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626)),
                    ),
                    title: Text(
                      'Emergency Alert #${alert['id'] ?? (index + 1)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        FutureBuilder<String>(
                          future: _getAddressFromCoordinates(lat, long),
                          builder: (context, addressSnapshot) {
                            if (addressSnapshot.connectionState == ConnectionState.waiting) {
                              return const Text(
                                'Resolving address...',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              );
                            }
                            return Text(
                              addressSnapshot.data ?? 'Location unavailable',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0F172A),
                              ),
                            );
                          },
                        ),
                        if (lat != null && long != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Coords: ${lat.toStringAsFixed(4)}, ${long.toStringAsFixed(4)}',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                        ],
                      ],
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: status == 'RESOLVED'
                            ? const Color(0xFF16A34A).withOpacity(0.1)
                            : const Color(0xFFDC2626).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: status == 'RESOLVED'
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFDC2626),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}