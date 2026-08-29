import 'dart:async';
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

/// SmartTransport GH Driver Active Trip Screen
class ActiveTripScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> trip;
  
  const ActiveTripScreen({
    Key? key,
    required this.trip,
  }) : super(key: key);
  
  @override
  ConsumerState<ActiveTripScreen> createState() => _ActiveTripScreenState();
}

class _ActiveTripScreenState extends ConsumerState<ActiveTripScreen> {
  final MapController _mapController = MapController();
  bool _isTripActive = false;
  bool _isBroadcasting = false;
  Timer? _locationBroadcastTimer;
  LatLng? _currentLocation;
  int _tripDuration = 0;
  Timer? _durationTimer;
  
  // Placeholder coordinates for Takoradi
  final LatLng _takoradiCenter = const LatLng(4.8989, -1.7600);
  final LatLng _startPoint = const LatLng(4.8989, -1.7600);
  final LatLng _endPoint = const LatLng(4.9050, -1.7550);
  
  @override
  void initState() {
    super.initState();
    _currentLocation = _startPoint;
  }
  
  @override
  void dispose() {
    _locationBroadcastTimer?.cancel();
    _durationTimer?.cancel();
    super.dispose();
  }
  
  void _startTrip() async {
    try {
      await _apiClient.updateTrip(widget.trip['id'], {'status': 'active'});
    } catch (_) {}
    setState(() {
      _isTripActive = true;
      _isBroadcasting = true;
    });
    
    // Start broadcasting location
    _startLocationBroadcast();
    
    // Start trip duration timer
    _durationTimer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (mounted) {
          setState(() {
            _tripDuration++;
          });
        }
      },
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Trip started! Broadcasting location...'),
        backgroundColor: AppColors.success,
      ),
    );
  }
  
  void _startLocationBroadcast() {
    // Simulate location updates
    _locationBroadcastTimer = Timer.periodic(
      const Duration(seconds: 5),
      (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        
        // Simulate movement towards destination
        final progress = (timer.tick * 0.05).clamp(0.0, 1.0);
        final newLat = _startPoint.latitude + 
            progress * (_endPoint.latitude - _startPoint.latitude);
        final newLng = _startPoint.longitude + 
            progress * (_endPoint.longitude - _startPoint.longitude);
        
        setState(() {
          _currentLocation = LatLng(newLat, newLng);
        });
        
        // Pan map to current location
        if (_currentLocation != null) {
          _mapController.move(_currentLocation!, _mapController.zoom);
        }
        
        // Location broadcasting is simulated; in production send via WebSocket
      },
    );
  }
  
  void _pauseBroadcasting() {
    setState(() {
      _isBroadcasting = false;
    });
    _locationBroadcastTimer?.cancel();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Location broadcasting paused'),
        backgroundColor: AppColors.warning,
      ),
    );
  }
  
  void _resumeBroadcasting() {
    setState(() {
      _isBroadcasting = true;
    });
    _startLocationBroadcast();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Location broadcasting resumed'),
        backgroundColor: AppColors.success,
      ),
    );
  }
  
  Future<void> _endTrip() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Trip?'),
        content: const Text('Are you sure you want to end this trip?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('End Trip'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      _locationBroadcastTimer?.cancel();
      _durationTimer?.cancel();
      try {
        await _apiClient.updateTrip(widget.trip['id'], {'status': 'completed'});
      } catch (_) {}
      setState(() {
        _isTripActive = false;
        _isBroadcasting = false;
      });
      if (mounted) {
        _showTripSummary();
      }
    }
  }
  
  void _showTripSummary() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline,
                color: AppColors.success,
                size: 48,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Trip Completed!',
              style: AppTypography.h3.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            
            // Trip Summary
            _SummaryRow(
              label: 'Route',
              value: widget.trip['route_name'],
            ),
            const SizedBox(height: AppSpacing.sm),
            _SummaryRow(
              label: 'Duration',
              value: _formatDuration(_tripDuration),
            ),
            const SizedBox(height: AppSpacing.sm),
            _SummaryRow(
              label: 'Passengers',
              value: '${widget.trip['passengers_booked']}',
            ),
            const SizedBox(height: AppSpacing.sm),
            _SummaryRow(
              label: 'Earnings',
              value: 'GHS ${widget.trip['total_fare'].toStringAsFixed(2)}',
              isHighlight: true,
            ),
            
            const SizedBox(height: AppSpacing.xl),
            
            PrimaryButton(
              text: 'Back to Dashboard',
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to dashboard
              },
            ),
          ],
        ),
      ),
    );
  }
  
  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Active Trip'),
        backgroundColor: AppColors.surface,
        actions: [
          // Broadcasting Status
          Container(
            margin: const EdgeInsets.all(AppSpacing.sm),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: _isBroadcasting
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
                    color: _isBroadcasting ? AppColors.success : AppColors.warning,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  _isBroadcasting ? 'Broadcasting' : 'Paused',
                  style: AppTypography.labelSmall.copyWith(
                    color: _isBroadcasting ? AppColors.success : AppColors.warning,
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
              color: AppColors.accent.withOpacity(0.5),
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
            
            // Current Location (Driver)
            if (_currentLocation != null)
              Marker(
                point: _currentLocation!,
                width: 50.0,
                height: 50.0,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.driverColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.driverColor.withOpacity(0.3),
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
                    color: _isTripActive
                        ? AppColors.success.withOpacity(0.1)
                        : AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                  ),
                  child: Icon(
                    _isTripActive ? Icons.directions_bus : Icons.play_circle_outline,
                    color: _isTripActive ? AppColors.success : AppColors.warning,
                    size: AppSpacing.iconLarge,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.trip['route_name'],
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _isTripActive ? 'Trip in progress' : 'Ready to start',
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                ),
                // Duration
                if (_isTripActive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.driverColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                    ),
                    child: Text(
                      _formatDuration(_tripDuration),
                      style: AppTypography.h4.copyWith(
                        color: AppColors.driverColor,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            // Trip Details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatusItem(
                  icon: Icons.people_outlined,
                  label: 'Passengers',
                  value: '${widget.trip['passengers_booked']}',
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: AppColors.border,
                ),
                _StatusItem(
                  icon: Icons.attach_money_outlined,
                  label: 'Earnings',
                  value: 'GHS ${widget.trip['total_fare'].toStringAsFixed(2)}',
                  valueColor: AppColors.success,
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: AppColors.border,
                ),
                _StatusItem(
                  icon: Icons.access_time_outlined,
                  label: 'Departs',
                  value: widget.trip['departure_time'],
                ),
              ],
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            // Action Buttons
            if (!_isTripActive)
              PrimaryButton(
                text: 'Start Trip',
                onPressed: _startTrip,
                icon: Icons.play_circle_outline,
                backgroundColor: AppColors.success,
              )
            else
              Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      text: _isBroadcasting ? 'Pause' : 'Resume',
                      onPressed: _isBroadcasting ? _pauseBroadcasting : _resumeBroadcasting,
                      backgroundColor: _isBroadcasting ? AppColors.warning : AppColors.accent,
                      icon: _isBroadcasting ? Icons.pause_outlined : Icons.play_arrow_outlined,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: PrimaryButton(
                      text: 'End Trip',
                      onPressed: _endTrip,
                      backgroundColor: AppColors.error,
                      icon: Icons.stop_outlined,
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
  final Color? valueColor;
  
  const _StatusItem({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
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
            color: valueColor ?? AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Summary Row Widget
class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlight;
  
  const _SummaryRow({
    required this.label,
    required this.value,
    this.isHighlight = false,
  });
  
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(
            color: isHighlight ? AppColors.accent : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
