import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../shared/services/api_client.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_spacing.dart';
import '../../shared/theme/app_typography.dart';

final _apiClient = ApiClient();

/// Professional Live Trip Tracking Screen
/// Full-screen map with bottom sheet overlay — Uber/Bolt style
class ActiveTripScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> hail;

  const ActiveTripScreen({Key? key, required this.hail}) : super(key: key);

  @override
  ConsumerState<ActiveTripScreen> createState() => _ActiveTripScreenState();
}

class _ActiveTripScreenState extends ConsumerState<ActiveTripScreen>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  Map<String, dynamic>? _hail;
  bool _isLoading = true;
  bool _isConnected = false;
  bool _isConnecting = true;
  Timer? _pollTimer;

  // Animated driver marker
  late AnimationController _pulseController;
  late AnimationController _markerBounceController;

  // Default Takoradi coordinates
  final LatLng _fallbackPickup = const LatLng(4.8989, -1.7600);
  final LatLng _fallbackDest = const LatLng(4.9050, -1.7550);

  LatLng? get _pickupLocation => _hail?['pickup_lat'] != null
      ? LatLng(_hail!['pickup_lat'], _hail!['pickup_lng'])
      : _fallbackPickup;

  LatLng? get _destLocation => _hail?['destination_lat'] != null
      ? LatLng(_hail!['destination_lat'], _hail!['destination_lng'])
      : _fallbackDest;

  @override
  void initState() {
    super.initState();
    _hail = Map<String, dynamic>.from(widget.hail);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _markerBounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _loadHailStatus();
    _startPolling();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _markerBounceController.dispose();
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _loadHailStatus());
  }

  Future<void> _loadHailStatus() async {
    try {
      final hails = await _apiClient.getMyHails();
      final match = hails.where((h) => h['id'] == _hail!['id']).toList();
      if (match.isNotEmpty && mounted) {
        final updated = match.first;
        final oldStatus = _hail!['status'];
        setState(() {
          _hail = updated;
          _isConnecting = false;
          _isConnected = true;
          _isLoading = false;
        });
        // Animate marker on status change
        if (oldStatus != updated['status']) {
          _markerBounceController.reset();
          _markerBounceController.forward();
        }
        // Stop polling if trip is done
        if (updated['status'] == 'completed' || updated['status'] == 'cancelled') {
          _pollTimer?.cancel();
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelHail() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Ride?'),
        content: const Text('Are you sure you want to cancel this ride?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await _apiClient.cancelHail(_hail!['id']);
        if (mounted) Navigator.pop(context);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _hail?['status'] ?? 'searching';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Full-screen map
            _buildMap(),

            // Gradient overlay at top
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildTopOverlay(status),
            ),

            // Connection badge
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              right: 16,
              child: _buildConnectionBadge(),
            ),

            // Back button
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              left: 16,
              child: _buildBackButton(),
            ),

            // Re-center FAB
            Positioned(
              right: 16,
              bottom: 320,
              child: _buildRecenterButton(),
            ),

            // Bottom sheet
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildBottomSheet(status),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopOverlay(String status) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.7),
            Colors.black.withOpacity(0.0),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionBadge() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _isConnected
            ? AppColors.success.withOpacity(0.9)
            : AppColors.warning.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (_isConnected ? AppColors.success : AppColors.warning)
                .withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _isConnecting ? 'Connecting...' : 'Live',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black87),
      ),
    );
  }

  Widget _buildRecenterButton() {
    return GestureDetector(
      onTap: () {
        if (_pickupLocation != null) {
          _mapController.move(_pickupLocation!, 15);
        }
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(Icons.my_location, size: 20, color: AppColors.accent),
      ),
    );
  }

  Widget _buildMap() {
    final center = _pickupLocation ?? _fallbackPickup;

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        center: center,
        zoom: 15.0,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: [
        // Premium map tiles (CartoDB Voyager — cleaner look)
        TileLayer(
          urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          userAgentPackageName: 'com.smarttransport.gh',
        ),

        // Route polyline
        if (_pickupLocation != null && _destLocation != null)
          PolylineLayer(
            polylines: [
              Polyline(
                points: [_pickupLocation!, _destLocation!],
                color: AppColors.accent,
                strokeWidth: 5.0,
                isDotted: true,
                borderColor: AppColors.accent.withOpacity(0.3),
                borderStrokeWidth: 8.0,
              ),
            ],
          ),

        // Markers
        MarkerLayer(markers: _buildMarkers()),
      ],
    );
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];

    // Pickup marker (green dot with pulsing ring)
    if (_pickupLocation != null) {
      markers.add(Marker(
        point: _pickupLocation!,
        width: 60,
        height: 60,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer pulse ring
            AnimatedBuilder(
              animation: _pulseController,
              builder: (_, __) => Container(
                width: 40 + (_pulseController.value * 15),
                height: 40 + (_pulseController.value * 15),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.success.withOpacity(0.2 - (_pulseController.value * 0.15)),
                ),
              ),
            ),
            // Inner marker
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.success.withOpacity(0.4),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ],
        ),
      ));
    }

    // Destination marker (red pin)
    if (_destLocation != null) {
      markers.add(Marker(
        point: _destLocation!,
        width: 50,
        height: 50,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.error.withOpacity(0.4),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const Icon(Icons.location_on, color: Colors.white, size: 20),
            ),
            // Triangle pointer
            CustomPaint(
              size: const Size(12, 8),
              painter: _TrianglePainter(color: AppColors.error),
            ),
          ],
        ),
      ));
    }

    // Driver marker (bus icon with bounce animation)
    final status = _hail?['status'] ?? 'searching';
    if ((status == 'accepted' || status == 'in_progress') && _pickupLocation != null) {
      // Simulate driver moving towards pickup
      final driverPos = _getSimulatedDriverPosition();
      markers.add(Marker(
        point: driverPos,
        width: 60,
        height: 60,
        child: AnimatedBuilder(
          animation: _markerBounceController,
          builder: (_, child) {
            final bounce = sin(_markerBounceController.value * pi) * 4;
            return Transform.translate(
              offset: Offset(0, -bounce),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withOpacity(0.4),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(Icons.directions_bus, color: Colors.white, size: 24),
              ),
            );
          },
        ),
      ));
    }

    return markers;
  }

  LatLng _getSimulatedDriverPosition() {
    // Simulate driver position moving towards pickup
    final pickup = _pickupLocation ?? _fallbackPickup;
    final dest = _destLocation ?? _fallbackDest;
    final now = DateTime.now().second % 60;
    final progress = (now / 60.0).clamp(0.1, 0.9);

    // Driver starts near destination, moves toward pickup
    final lat = dest.latitude + (pickup.latitude - dest.latitude) * progress;
    final lng = dest.longitude + (pickup.longitude - dest.longitude) * progress;
    return LatLng(lat, lng);
  }

  Widget _buildBottomSheet(String status) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.42,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            spreadRadius: 5,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Status bar
            _buildStatusBar(status),
            const SizedBox(height: 16),

            // Trip info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildTripDetails(status),
            ),

            // Action buttons
            if (status == 'searching')
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    text: 'Cancel Ride',
                    onPressed: _cancelHail,
                    backgroundColor: AppColors.error,
                  ),
                ),
              ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBar(String status) {
    final Color color;
    final String title;
    final String subtitle;
    final IconData icon;

    switch (status) {
      case 'accepted':
        color = AppColors.success;
        title = 'Driver is on the way';
        subtitle = '${_hail?['driver_name'] ?? 'Driver'} is heading to your pickup';
        icon = Icons.directions_car;
        break;
      case 'in_progress':
        color = AppColors.accent;
        title = 'Trip in progress';
        subtitle = 'Heading to ${_hail?['destination'] ?? 'destination'}';
        icon = Icons.directions_bus;
        break;
      case 'completed':
        color = AppColors.success;
        title = 'Trip completed!';
        subtitle = 'You have arrived at your destination';
        icon = Icons.check_circle;
        break;
      case 'cancelled':
        color = AppColors.error;
        title = 'Ride cancelled';
        subtitle = 'This ride has been cancelled';
        icon = Icons.cancel;
        break;
      default:
        color = AppColors.warning;
        title = 'Finding a driver...';
        subtitle = 'Looking for nearby drivers';
        icon = Icons.search;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: color,
                )),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                )),
              ],
            ),
          ),
          if (status == 'searching')
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: color,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTripDetails(String status) {
    return Column(
      children: [
        // Route
        Row(
          children: [
            Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.success.withOpacity(0.3), width: 3),
                  ),
                ),
                Container(width: 2, height: 24, color: Colors.grey[300]),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _hail?['pickup_location'] ?? 'Pickup',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _hail?['destination'] ?? 'Destination',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),
        const Divider(height: 1),
        const SizedBox(height: 14),

        // Driver info (when accepted)
        if (status == 'accepted' || status == 'in_progress')
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.accent.withOpacity(0.1),
                child: Text(
                  (_hail?['driver_name'] ?? 'D')[0].toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _hail?['driver_name'] ?? 'Driver',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    Text(
                      _hail?['driver_plate'] ?? '',
                      style: TextStyle(color: Colors.grey[500], fontSize: 13),
                    ),
                  ],
                ),
              ),
              // Call button
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.phone, color: Colors.white, size: 20),
              ),
            ],
          ),

        // Passengers count
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 16, color: Colors.grey[500]),
            const SizedBox(width: 6),
            Text(
              '${_hail?['passengers_count'] ?? 1} passenger(s)',
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
          ],
        ),
      ],
    );
  }
}

/// Custom triangle painter for marker pointer
class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
