import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import 'location_service.dart';
import 'api_service.dart';

class ActiveAlertScreen extends StatefulWidget {
  final int? alertId;

  const ActiveAlertScreen({super.key, this.alertId});

  @override
  State<ActiveAlertScreen> createState() => _ActiveAlertScreenState();
}

class _ActiveAlertScreenState extends State<ActiveAlertScreen> {
  Position? _currentPosition;
  String? _address;
  bool _isLoadingLocation = true;
  bool _isCancelling = false;
  String? _locationError;
  StreamSubscription<Position>? _positionSubscription;

  @override
  void initState() {
    super.initState();
    _startLocationUpdates();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  /// Listens to real-time location stream and updates reverse geocoding on movement
  Future<void> _startLocationUpdates() async {
    try {
      // First initial location check
      final initialPosition = await LocationService.getCurrentLocation();
      if (mounted && initialPosition != null) {
        setState(() {
          _currentPosition = initialPosition;
          _isLoadingLocation = false;
        });
        _updateAddress(initialPosition.latitude, initialPosition.longitude);
      }

      // Stream continuous location changes
      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Update every 5 meters
      );

      _positionSubscription =
          Geolocator.getPositionStream(locationSettings: locationSettings)
              .listen(
                (Position position) {
                  if (mounted) {
                    setState(() {
                      _currentPosition = position;
                      _isLoadingLocation = false;
                      _locationError = null;
                    });
                    _updateAddress(position.latitude, position.longitude);
                  }
                },
                onError: (error) {
                  if (mounted) {
                    setState(() {
                      _locationError = error.toString();
                      _isLoadingLocation = false;
                    });
                  }
                },
              );
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationError = e.toString();
          _isLoadingLocation = false;
        });
      }
    }
  }

  Future<void> _updateAddress(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty && mounted) {
        Placemark place = placemarks.first;
        String street = place.street ?? '';
        String locality = place.locality ?? place.subAdministrativeArea ?? '';
        String state = place.administrativeArea ?? '';

        List<String> parts = [
          street,
          locality,
          state,
        ].where((p) => p.trim().isNotEmpty).toList();

        setState(() {
          _address = parts.isNotEmpty ? parts.join(', ') : '$lat, $lng';
        });
      }
    } catch (_) {
      if (mounted && _address == null) {
        setState(() {
          _address = '$lat, $lng';
        });
      }
    }
  }

  /// Cancels the SOS active status on backend before leaving
  Future<void> _handleCancelAlert() async {
    setState(() => _isCancelling = true);

    if (widget.alertId != null) {
      await ApiService.resolveAlert(widget.alertId!);
    }

    if (mounted) {
      setState(() => _isCancelling = false);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEF2F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFEF2F2),
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Color(0xFF0F172A)),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Pulse Red Warning Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFDC2626),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.white,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'EMERGENCY ALERT ACTIVE',
                style: TextStyle(
                  color: Color(0xFFDC2626),
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your live location is being broadcasted to responders and emergency contacts.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
              ),

              const SizedBox(height: 32),

              // Real-time GPS Location Display Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            Icon(
                              Icons.my_location,
                              color: Color(0xFFDC2626),
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'YOUR BROADCASTED LOCATION',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                        if (!_isLoadingLocation)
                          IconButton(
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                            icon: const Icon(
                              Icons.refresh,
                              size: 18,
                              color: Color(0xFF64748B),
                            ),
                            onPressed: _startLocationUpdates,
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (_isLoadingLocation)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                          child: CircularProgressIndicator(
                            color: Color(0xFFDC2626),
                          ),
                        ),
                      )
                    else if (_locationError != null)
                      Text(
                        _locationError!,
                        style: const TextStyle(
                          color: Color(0xFFDC2626),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _address ?? 'Resolving location address...',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Lat: ${_currentPosition?.latitude.toStringAsFixed(6)}, Long: ${_currentPosition?.longitude.toStringAsFixed(6)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Accuracy: ±${_currentPosition?.accuracy.toStringAsFixed(1)}m',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              const Spacer(),

              // Cancel Alert Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isCancelling ? null : _handleCancelAlert,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isCancelling
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Cancel SOS Alert',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
