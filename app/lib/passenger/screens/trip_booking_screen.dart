import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/services/api_client.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_spacing.dart';
import '../../shared/theme/app_typography.dart';
import 'booking_confirmation_screen.dart';

final _apiClient = ApiClient();

/// SmartTransport GH Trip Booking Screen
class TripBookingScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> route;
  
  const TripBookingScreen({
    Key? key,
    required this.route,
  }) : super(key: key);
  
  @override
  ConsumerState<TripBookingScreen> createState() => _TripBookingScreenState();
}

class _TripBookingScreenState extends ConsumerState<TripBookingScreen> {
  List<Map<String, dynamic>> _availableTrips = [];
  Map<String, dynamic>? _selectedTrip;
  bool _isLoading = false;
  int _selectedPassengers = 1;
  
  @override
  void initState() {
    super.initState();
    _loadAvailableTrips();
  }
  
  Future<void> _loadAvailableTrips() async {
    setState(() => _isLoading = true);
    try {
      final routeId = widget.route['id'];
      final trips = await _apiClient.getTrips(routeId: routeId);
      // Enrich trips with driver/vehicle details
      final enrichedTrips = <Map<String, dynamic>>[];
      for (final trip in trips) {
        try {
          final details = await _apiClient.getTripDetails(trip['id']);
          enrichedTrips.add({
            ...trip,
            'driver_name': details['driver']?['name'] ?? 'Unknown Driver',
            'vehicle_plate': details['vehicle']?['plate_number'] ?? 'N/A',
            'capacity': details['vehicle']?['capacity'] ?? 4,
            'seats_available': (details['vehicle']?['capacity'] ?? 4) - 1,
            'departure_time': trip['started_at'] != null
                ? DateTime.parse(trip['started_at']).toString().substring(11, 16)
                : 'Scheduled',
            'estimated_arrival': 'N/A',
          });
        } catch (_) {
          enrichedTrips.add({
            ...trip,
            'driver_name': 'Unknown Driver',
            'vehicle_plate': 'N/A',
            'capacity': 4,
            'seats_available': 3,
            'departure_time': 'Scheduled',
            'estimated_arrival': 'N/A',
          });
        }
      }
      _availableTrips = enrichedTrips;
    } catch (e) {
      _availableTrips = [];
    }
    setState(() => _isLoading = false);
  }
  
  void _proceedToBooking() {
    if (_selectedTrip == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a trip'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BookingConfirmationScreen(
          route: widget.route,
          trip: _selectedTrip!,
          passengers: _selectedPassengers,
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Book Trip'),
        backgroundColor: AppColors.surface,
      ),
      body: Column(
        children: [
          // Route Info Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.screenPaddingHorizontal),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.route['name'],
                  style: AppTypography.h3.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${widget.route['start_point']} → ${widget.route['end_point']}',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Icon(
                      Icons.attach_money_outlined,
                      size: AppSpacing.iconSmall,
                      color: AppColors.success,
                    ),
                    Text(
                      'GHS ${widget.route['fare'].toStringAsFixed(2)}',
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Passenger Count
          Padding(
            padding: const EdgeInsets.all(AppSpacing.screenPaddingHorizontal),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Passengers',
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: _selectedPassengers > 1
                          ? () => setState(() => _selectedPassengers--)
                          : null,
                      color: _selectedPassengers > 1
                          ? AppColors.accent
                          : AppColors.textTertiary,
                    ),
                    Text(
                      '$_selectedPassengers',
                      style: AppTypography.h3.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: _selectedPassengers < 5
                          ? () => setState(() => _selectedPassengers++)
                          : null,
                      color: _selectedPassengers < 5
                          ? AppColors.accent
                          : AppColors.textTertiary,
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const Divider(),
          
          // Available Trips Header
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPaddingHorizontal,
              vertical: AppSpacing.sm,
            ),
            child: Text(
              'Available Trips',
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          
          // Available Trips List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _availableTrips.isEmpty
                    ? _buildEmptyState()
                    : _buildTripList(),
          ),
          
          // Book Button
          Container(
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
            child: PrimaryButton(
              text: _selectedTrip != null
                  ? 'Book Now - GHS ${(widget.route['fare'] * _selectedPassengers).toStringAsFixed(2)}'
                  : 'Select a Trip',
              onPressed: _selectedTrip != null ? _proceedToBooking : null,
              isLoading: false,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.directions_bus_outlined,
            size: 64,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No trips available',
            style: AppTypography.h4.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Check back later for scheduled trips',
            style: AppTypography.bodySmall,
          ),
        ],
      ),
    );
  }
  
  Widget _buildTripList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPaddingHorizontal,
        vertical: AppSpacing.sm,
      ),
      itemCount: _availableTrips.length,
      itemBuilder: (context, index) {
        final trip = _availableTrips[index];
        final isSelected = _selectedTrip?['id'] == trip['id'];
        
        return _TripCard(
          trip: trip,
          isSelected: isSelected,
          onTap: () {
            setState(() {
              _selectedTrip = isSelected ? null : trip;
            });
          },
        );
      },
    );
  }
}

/// Trip Card Widget
class _TripCard extends StatelessWidget {
  final Map<String, dynamic> trip;
  final bool isSelected;
  final VoidCallback onTap;
  
  const _TripCard({
    required this.trip,
    required this.isSelected,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppColors.accent.withOpacity(0.2)
                  : AppColors.shadow,
              blurRadius: isSelected ? 8 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Driver Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.passengerColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                  ),
                  child: const Icon(
                    Icons.person_outlined,
                    color: AppColors.passengerColor,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                
                // Trip Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trip['driver_name'],
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Vehicle: ${trip['vehicle_plate']}',
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                ),
                
                // Selection Indicator
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    border: Border.all(
                      color: isSelected ? AppColors.accent : AppColors.border,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          color: AppColors.textInverse,
                          size: 16,
                        )
                      : null,
                ),
              ],
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            // Trip Details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Departure Time
                _TripDetail(
                  icon: Icons.access_time_outlined,
                  label: 'Departs',
                  value: trip['departure_time'],
                ),
                
                // Arrival Time
                _TripDetail(
                  icon: Icons.access_time_filled,
                  label: 'Arrives',
                  value: trip['estimated_arrival'],
                ),
                
                // Seats Available
                _TripDetail(
                  icon: Icons.event_seat_outlined,
                  label: 'Seats',
                  value: '${trip['seats_available']}/${trip['capacity']}',
                  isWarning: trip['seats_available'] <= 3,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Trip Detail Widget
class _TripDetail extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isWarning;
  
  const _TripDetail({
    required this.icon,
    required this.label,
    required this.value,
    this.isWarning = false,
  });
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          size: AppSpacing.iconSmall,
          color: isWarning ? AppColors.warning : AppColors.textTertiary,
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
            color: isWarning ? AppColors.warning : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
