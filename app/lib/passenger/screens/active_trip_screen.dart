import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../shared/services/api_client.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_spacing.dart';
import '../../shared/theme/app_typography.dart';

final _apiClient = ApiClient();

/// SmartTransport GH Active Trip Screen
class ActiveTripScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> route;
  final Map<String, dynamic> trip;
  
  const ActiveTripScreen({
    Key? key,
    required this.route,
    required this.trip,
  }) : super(key: key);
  
  @override
  ConsumerState<ActiveTripScreen> createState() => _ActiveTripScreenState();
}

class _ActiveTripScreenState extends ConsumerState<ActiveTripScreen> {
  final MapController _mapController = MapController();
  LatLng? _driverLocation;
  bool _isConnecting = true;
  bool _isConnected = false;
  Timer? _locationUpdateTimer;
  
  final LatLng _takoradiCenter = const LatLng(4.8989, -1.7600);
  final LatLng _startPoint = const LatLng(4.8989, -1.7600);
  final LatLng _endPoint = const LatLng(4.9050, -1.7550);
  String _driverName = '';
  WebSocket? _wsChannel;

  @override
  void initState() {
    super.initState();
    _loadTripData();
    _connectToWebSocket();
  }
  
  @override
  void dispose() {
    _locationUpdateTimer?.cancel();
    _wsChannel?.close();
    super.dispose();
  }

  Future<void> _loadTripData() async {
    try {
      final tripId = widget.trip['id'];
      final details = await _apiClient.getTripDetails(tripId);
      if (mounted) {
        setState(() {
          _driverName = details['driver']?['name'] ?? 'Unknown Driver';
        });
      }
      // Load location history
      final locations = await _apiClient.getTripLocations(tripId);
      if (locations.isNotEmpty && mounted) {
        final lastLoc = locations.last;
        setState(() {
          _driverLocation = LatLng(lastLoc['lat'], lastLoc['lng']);
        });
        _mapController.move(_driverLocation!, _mapController.zoom);
      }
    } catch (_) {}
  }

  void _connectToWebSocket() async {
    setState(() {
      _isConnecting = true;
    });
    try {
      final tripId = widget.trip['id'];
      final wsUrl = _apiClient.baseUrl.replaceFirst('http', 'ws');
      _wsChannel = await WebSocket.connect('$wsUrl/trips/ws/$tripId');
      _wsChannel!.listen(
        (message) {
          final data = json.decode(message);
          if (data['type'] == 'location_update' && mounted) {
            final newLoc = LatLng(data['lat'], data['lng']);
            setState(() {
              _driverLocation = newLoc;
              _isConnecting = false;
              _isConnected = true;
            });
            _mapController.move(newLoc, _mapController.zoom);
          }
        },
        onDone: () {
          if (mounted) setState(() => _isConnected = false);
        },
        onError: (_) {
          if (mounted) {
            setState(() {
              _isConnecting = false;
              _isConnected = false;
            });
          }
        },
      );
      setState(() {
        _isConnecting = false;
        _isConnected = true;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _isConnecting = false;
          _isConnected = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Track Trip'),
        backgroundColor: AppColors.surface,
        actions: [
          // Connection Status
          Container(
            margin: const EdgeInsets.all(AppSpacing.sm),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: _isConnected
                  ? AppColors.success.withOpacity(0.1)
                  : AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _isConnected ? AppColors.success : AppColors.warning,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  _isConnecting ? 'Connecting...' : 'Live',
                  style: AppTypography.labelSmall.copyWith(
                    color: _isConnected ? AppColors.success : AppColors.warning,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Map
          Expanded(
            child: _buildMap(),
          ),
          
          // Trip Info Panel
          _buildTripInfoPanel(),
        ],
      ),
    );
  }
  
  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        center: _takoradiCenter,
        zoom: 15.0,
      ),
      children: [
        // Map Tiles
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.smarttransport_gh',
        ),
        
        // Route Line
        PolylineLayer(
          polylines: [
            Polyline(
              points: [_startPoint, _endPoint],
              color: AppColors.accent,
              strokeWidth: 4.0,
            ),
          ],
        ),
        
        // Markers
        MarkerLayer(
          markers: [
            // Start Point
            Marker(
              point: _startPoint,
              width: 40.0,
              height: 40.0,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.circle,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
            
            // End Point
            Marker(
              point: _endPoint,
              width: 40.0,
              height: 40.0,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.location_on,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
            
            // Driver Location
            if (_driverLocation != null)
              Marker(
                point: _driverLocation!,
                width: 50.0,
                height: 50.0,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.directions_bus,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildTripInfoPanel() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.screenPaddingHorizontal),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            
            // Trip Status
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                  ),
                  child: const Icon(
                    Icons.directions_bus,
                    color: AppColors.success,
                    size: AppSpacing.iconLarge,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.route['name'],
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Driver: ${_driverName.isNotEmpty ? _driverName : (widget.trip['driver_name'] ?? 'Driver')}',
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                  ),
                  child: Text(
                    'On the way',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textInverse,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            // ETA and Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatusItem(
                  icon: Icons.access_time_outlined,
                  label: 'ETA',
                  value: widget.trip['estimated_arrival'],
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: AppColors.border,
                ),
                _StatusItem(
                  icon: Icons.location_on_outlined,
                  label: 'Distance',
                  value: '2.3 km',
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: AppColors.border,
                ),
                _StatusItem(
                  icon: Icons.people_outlined,
                  label: 'Passengers',
                  value: '4',
                ),
              ],
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    text: 'Cancel Trip',
                    onPressed: () {
                      // TODO: Cancel trip
                    },
                    backgroundColor: AppColors.error,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: PrimaryButton(
                    text: 'Contact Driver',
                    onPressed: () {
                      // TODO: Open phone dialer
                    },
                    backgroundColor: AppColors.accent,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Status Item Widget
class _StatusItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  
  const _StatusItem({
    required this.icon,
    required this.label,
    required this.value,
  });
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          size: AppSpacing.iconMedium,
          color: AppColors.textTertiary,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
        Text(
          value,
          style: AppTypography.labelMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
