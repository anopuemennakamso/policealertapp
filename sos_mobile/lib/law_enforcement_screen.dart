import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';

import 'api_service.dart';

class LawEnforcementDashboard extends StatefulWidget {
  const LawEnforcementDashboard({super.key});

  @override
  State<LawEnforcementDashboard> createState() =>
      _LawEnforcementDashboardState();
}

class _LawEnforcementDashboardState extends State<LawEnforcementDashboard> {
  int _currentIndex = 0;
  List<Map<String, dynamic>> _allAlerts = [];
  Timer? _pollingTimer;

  // Track acknowledged alert IDs locally for dev display
  final Set<int> _acknowledgedAlerts = {};

  @override
  void initState() {
    super.initState();
    _fetchAlerts();
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _fetchAlerts(),
    );
  }

  Future<void> _fetchAlerts() async {
    final alerts = await ApiService.fetchAllActiveAlerts();
    if (mounted) {
      setState(() {
        _allAlerts = alerts;
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
    final activeAlerts = _allAlerts
        .where((a) => (a['status'] ?? 'TRIGGERED') != 'RESOLVED')
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          _currentIndex == 0
              ? 'Command Dashboard'
              : _currentIndex == 1
              ? 'Dispatch History'
              : 'Responder Profile',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchAlerts,
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildActiveAlertsTab(activeAlerts),
          _buildHistoryTab(_allAlerts),
          _buildProfileTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFFDC2626),
        unselectedItemColor: const Color(0xFF64748B),
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.emergency),
            label: 'Active SOS',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.badge), label: 'Profile'),
        ],
      ),
    );
  }

  // --- TAB 1: ACTIVE INCIDENTS ---
  Widget _buildActiveAlertsTab(List<Map<String, dynamic>> alerts) {
    if (alerts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.shield_outlined, size: 64, color: Color(0xFF94A3B8)),
            SizedBox(height: 12),
            Text(
              'All clear. No active emergency signals.',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: alerts.length,
      itemBuilder: (context, index) {
        final alert = alerts[index];
        final int alertId = alert['id'];
        final double lat = (alert['latitude'] as num).toDouble();
        final double lng = (alert['longitude'] as num).toDouble();
        final bool isAcknowledged =
            _acknowledgedAlerts.contains(alertId) ||
            alert['status'] == 'DISPATCHED';

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isAcknowledged
                  ? Colors.amber.shade400
                  : Colors.red.shade300,
              width: 1.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: isAcknowledged
                              ? Colors.amber.shade800
                              : Colors.red,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'SIGNAL #$alertId',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isAcknowledged
                            ? Colors.amber.shade100
                            : Colors.red.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isAcknowledged ? 'DISPATCHED' : 'CRITICAL SOS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isAcknowledged
                              ? Colors.amber.shade900
                              : Colors.red.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),

                // Issue Description
                const Text(
                  'INCIDENT DESCRIPTION',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  alert['description'] ??
                      alert['note'] ??
                      'Citizen triggered high-priority panic SOS signal.',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),

                // Location Details
                const Text(
                  'LOCATION',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 4),
                FutureBuilder<String>(
                  future: getAddressFromCoordinates(lat, lng),
                  builder: (context, snapshot) {
                    return Text(
                      snapshot.data ?? 'Resolving location address...',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    );
                  },
                ),
                Text(
                  'Coords: $lat, $lng',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                  ),
                ),

                const SizedBox(height: 16),

                // 2-Step Action Buttons
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: !isAcknowledged
                      ? ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber.shade800,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(
                            Icons.check_circle_outline,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'ACKNOWLEDGE SIGNAL',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            final success = await ApiService.acknowledgeAlert(
                              alertId,
                            );
                            if (success) {
                              if (mounted) {
                                setState(() {
                                  _acknowledgedAlerts.add(alertId);
                                });
                              }
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Signal #$alertId acknowledged. Citizen notified!',
                                  ),
                                ),
                              );
                            } else {
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Failed to update alert status. Check server connection.',
                                  ),
                                ),
                              );
                            }
                          },
                        )
                      : ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF16A34A),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.task_alt, color: Colors.white),
                          label: const Text(
                            'MARK CASE SOLVED',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            await ApiService.resolveAlert(alertId);
                            _fetchAlerts();
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Incident #$alertId resolved and archived.',
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
      },
    );
  }

  // --- TAB 2: DISPATCH & INCIDENT HISTORY ---
  Widget _buildHistoryTab(List<Map<String, dynamic>> allAlerts) {
    if (allAlerts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.history_toggle_off, size: 64, color: Color(0xFF94A3B8)),
            SizedBox(height: 12),
            Text(
              'No incident history recorded yet.',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: allAlerts.length,
      itemBuilder: (context, index) {
        final alert = allAlerts[index];
        final String status = alert['status'] ?? 'TRIGGERED';
        final double lat = (alert['latitude'] as num).toDouble();
        final double lng = (alert['longitude'] as num).toDouble();

        IconData statusIcon = Icons.warning_amber_rounded;
        Color statusColor = const Color(0xFFDC2626);
        String labelText = 'CRITICAL SOS';

        if (status == 'RESOLVED') {
          statusIcon = Icons.check_circle;
          statusColor = const Color(0xFF16A34A);
          labelText = 'RESOLVED';
        } else if (status == 'DISPATCHED') {
          statusIcon = Icons.local_shipping_outlined;
          statusColor = Colors.amber.shade900;
          labelText = 'DISPATCHED';
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: Icon(statusIcon, color: statusColor, size: 32),
            title: Text(
              'Emergency Signal #${alert['id']}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: FutureBuilder<String>(
              future: getAddressFromCoordinates(lat, lng),
              builder: (context, snapshot) {
                return Text(snapshot.data ?? 'Resolving location...');
              },
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                labelText,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // --- TAB 3: RESPONDER PROFILE ---
  Widget _buildProfileTab() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 40,
            backgroundColor: Color(0xFF0F172A),
            child: Icon(Icons.person, size: 48, color: Colors.white),
          ),
          const SizedBox(height: 12),
          const Text(
            'Officer / Dispatch Unit #4',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Text(
            'Central Command Station',
            style: TextStyle(color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 24),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: const [
                ListTile(
                  leading: Icon(Icons.badge_outlined, color: Color(0xFF0F172A)),
                  title: Text('Badge Code'),
                  subtitle: Text('POL-9082-HQ'),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Icons.verified_user_outlined,
                    color: Colors.green,
                  ),
                  title: Text('Duty Status'),
                  subtitle: Text('Active Dispatch Ready'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper function to convert raw coordinates into a human-readable street address
Future<String> getAddressFromCoordinates(double lat, double lng) async {
  try {
    List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
    if (placemarks.isNotEmpty) {
      Placemark place = placemarks.first;
      String street = place.street ?? '';
      String locality = place.locality ?? place.subAdministrativeArea ?? '';
      String state = place.administrativeArea ?? '';

      List<String> parts = [
        street,
        locality,
        state,
      ].where((p) => p.trim().isNotEmpty).toList();
      return parts.isNotEmpty ? parts.join(', ') : '$lat, $lng';
    }
    return '$lat, $lng';
  } catch (e) {
    return '$lat, $lng';
  }
}
