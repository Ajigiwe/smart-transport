import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../shared/services/auth_provider.dart';
import '../../shared/models/trip.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_spacing.dart';
import '../../shared/theme/app_typography.dart';
import '../../shared/widgets/premium_app_bar.dart';

/// SmartTransport GH Live Tracking Screen
class LiveTrackingScreen extends ConsumerStatefulWidget {
  const LiveTrackingScreen({Key? key}) : super(key: key);
  
  @override
  ConsumerState<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends ConsumerState<LiveTrackingScreen> {
  final MapController _mapController = MapController();
  List<Trip> _activeTrips = [];
  Map<int, Map<String, dynamic>> _tripLocations = {};
  bool _isLoading = false;
  Timer? _refreshTimer;
  
  final LatLng _takoradiCenter = const LatLng(4.8989, -1.7600);
  
  @override
  void initState() {
    super.initState();
    _loadActiveTrips();
    // Auto-refresh every 15 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) => _loadActiveTrips());
  }
  
  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
  
  Future<void> _loadActiveTrips() async {
    if (!_isLoading) setState(() => _isLoading = true);
    
    try {
      final apiClient = ref.read(apiClientProvider);
      final tripsData = await apiClient.getTrips(status: 'active');
      final trips = tripsData.map((json) => Trip.fromJson(json)).toList();
      
      // Fetch latest location for each trip
      final locations = <int, Map<String, dynamic>>{};
      for (final trip in trips) {
        try {
          final locationsData = await apiClient.getTripLocations(trip.id);
          if (locationsData.isNotEmpty) {
            final latest = locationsData.last;
            locations[trip.id] = {
              'lat': (latest['lat'] as num).toDouble(),
              'lng': (latest['lng'] as num).toDouble(),
              'timestamp': latest['timestamp'],
            };
          }
        } catch (_) {
          // Skip if location fetch fails
        }
      }
      
      setState(() {
        _activeTrips = trips;
        _tripLocations = locations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }
  
  Color _getMarkerColor(int index) {
    const colors = [AppColors.success, AppColors.driverColor, AppColors.accent, AppColors.adminColor, AppColors.info];
    return colors[index % colors.length];
  }
  
  @override
  Widget build(BuildContext context) {
    final tripsWithLocation = _activeTrips.where((t) => _tripLocations.containsKey(t.id)).toList();
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PremiumAppBar(
        title: 'Live Tracking',
        actions: [
          // Vehicle count badge
          Container(
            margin: const EdgeInsets.all(AppSpacing.sm),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle)),
                const SizedBox(width: AppSpacing.xs),
                Text('${tripsWithLocation.length} active', style: AppTypography.labelSmall.copyWith(color: AppColors.textInverse)),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _loadActiveTrips),
        ],
      ),
      body: Column(
        children: [
          // Map
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(center: _takoradiCenter, zoom: 13.0),
                  children: [
                    TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.example.smarttransport_gh'),
                    MarkerLayer(
                      markers: tripsWithLocation.asMap().entries.map((entry) {
                        final index = entry.key;
                        final trip = entry.value;
                        final location = _tripLocations[trip.id]!;
                        final color = _getMarkerColor(index);
                        return Marker(
                          point: LatLng(location['lat'], location['lng']),
                          width: 45.0,
                          height: 45.0,
                          child: GestureDetector(
                            onTap: () => _showTripInfo(trip, location, color),
                            child: Container(
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, spreadRadius: 2)],
                              ),
                              child: const Icon(Icons.directions_bus, color: Colors.white, size: 24),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                
                // Loading indicator
                if (_isLoading)
                  const Positioned(
                    top: AppSpacing.md,
                    left: AppSpacing.md,
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.sm),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                            SizedBox(width: AppSpacing.sm),
                            Text('Updating...'),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Trip List Panel
          _buildTripPanel(tripsWithLocation),
        ],
      ),
    );
  }
  
  void _showTripInfo(Trip trip, Map<String, dynamic> location, Color color) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSpacing.screenPaddingHorizontal),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(AppSpacing.radiusSmall)),
                  child: Icon(Icons.directions_bus, color: color, size: AppSpacing.iconLarge),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Trip #${trip.id}', style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
                      Text('Driver ID: ${trip.driverId}', style: AppTypography.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _InfoItem(icon: Icons.route_outlined, label: 'Route', value: 'Route #${trip.routeId}'),
                _InfoItem(icon: Icons.circle, label: 'Status', value: trip.status, valueColor: AppColors.success),
                _InfoItem(icon: Icons.access_time, label: 'Started', value: trip.startedAt != null ? _formatTime(trip.startedAt!) : 'N/A'),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
  
  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
  
  Widget _buildTripPanel(List<Trip> tripsWithLocation) {
    return Container(
      height: 180,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 4, offset: Offset(0, -2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.screenPaddingHorizontal, AppSpacing.md, AppSpacing.screenPaddingHorizontal, AppSpacing.sm),
            child: Text('Active Trips (${tripsWithLocation.length})', style: AppTypography.labelLarge.copyWith(color: AppColors.textSecondary)),
          ),
          Expanded(
            child: tripsWithLocation.isEmpty
                ? Center(
                    child: Text(
                      'No active trips with location data',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
                    ),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPaddingHorizontal),
                    itemCount: tripsWithLocation.length,
                    itemBuilder: (context, index) {
                      final trip = tripsWithLocation[index];
                      final location = _tripLocations[trip.id]!;
                      final color = _getMarkerColor(index);
                      return _TripChip(
                        trip: trip,
                        location: location,
                        color: color,
                        onTap: () {
                          _mapController.move(LatLng(location['lat'], location['lng']), 15.0);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  
  const _InfoItem({required this.icon, required this.label, required this.value, this.valueColor});
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: AppSpacing.iconMedium, color: AppColors.textTertiary),
        const SizedBox(height: AppSpacing.xs),
        Text(label, style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary)),
        Text(value, style: AppTypography.labelMedium.copyWith(color: valueColor ?? AppColors.textPrimary, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _TripChip extends StatelessWidget {
  final Trip trip;
  final Map<String, dynamic> location;
  final Color color;
  final VoidCallback onTap;
  
  const _TripChip({required this.trip, required this.location, required this.color, required this.onTap});
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text('Trip #${trip.id}', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text('Driver: ${trip.driverId}', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.xs),
            Text('Route: ${trip.routeId}', style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary), overflow: TextOverflow.ellipsis),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Icon(Icons.circle, size: 8, color: AppColors.success),
                const SizedBox(width: 4),
                Text(trip.status, style: AppTypography.labelSmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
