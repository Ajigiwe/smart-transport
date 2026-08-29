import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/services/api_client.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_spacing.dart';
import '../../shared/theme/app_typography.dart';
import 'active_trip_screen.dart';

final _apiClient = ApiClient();

/// SmartTransport GH Trip Requests Screen
class TripRequestsScreen extends ConsumerStatefulWidget {
  const TripRequestsScreen({Key? key}) : super(key: key);
  
  @override
  ConsumerState<TripRequestsScreen> createState() => _TripRequestsScreenState();
}

class _TripRequestsScreenState extends ConsumerState<TripRequestsScreen> {
  List<Map<String, dynamic>> _tripRequests = [];
  bool _isLoading = false;
  String _selectedFilter = 'all';
  
  @override
  void initState() {
    super.initState();
    _loadTripRequests();
  }
  
  Future<void> _loadTripRequests() async {
    setState(() => _isLoading = true);
    try {
      final trips = await _apiClient.getTrips();
      _tripRequests = [];
      for (final trip in trips) {
        String routeName = 'Trip #${trip['id']}';
        double fare = 0.0;
        try {
          final details = await _apiClient.getTripDetails(trip['id']);
          routeName = details['route']?['name'] ?? routeName;
          fare = (details['route']?['fare'] ?? 0).toDouble();
        } catch (_) {}

        List<Map<String, dynamic>> requests = [];
        try {
          final bookings = await _apiClient.getBookingsForTrip(trip['id']);
          requests = bookings.map<Map<String, dynamic>>((b) => {
            'name': b['passenger_name'] ?? 'Unknown',
            'passengers': 1,
          }).toList();
        } catch (_) {}

        _tripRequests.add({
          'id': trip['id'],
          'route_name': routeName,
          'passengers_booked': requests.length,
          'seats_available': 14 - requests.length,
          'departure_time': trip['started_at'] != null
              ? DateTime.parse(trip['started_at']).toString().substring(11, 16)
              : 'Scheduled',
          'fare_per_person': fare,
          'total_fare': fare * requests.length,
          'status': trip['status'] ?? 'scheduled',
          'requests': requests,
          'trip': trip,
        });
      }
    } catch (e) {
      _tripRequests = [];
    }
    setState(() => _isLoading = false);
  }
  
  List<Map<String, dynamic>> get _filteredRequests {
    if (_selectedFilter == 'all') return _tripRequests;
    return _tripRequests.where((request) => request['status'] == _selectedFilter).toList();
  }
  
  Future<void> _acceptTrip(Map<String, dynamic> trip) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accept Trip?'),
        content: Text(
          'Accept trip on ${trip['route_name']} with ${trip['passengers_booked']} passengers?\n\n'
          'Estimated earnings: GHS ${trip['total_fare'].toStringAsFixed(2)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Accept'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        await _apiClient.updateTrip(trip['id'], {'status': 'active'});
        setState(() {
          trip['status'] = 'active';
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Trip accepted: ${trip['route_name']}'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ActiveTripScreen(trip: trip),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to accept: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }
  
  Future<void> _declineTrip(Map<String, dynamic> trip) async {
    try {
      await _apiClient.updateTrip(trip['id'], {'status': 'cancelled'});
      setState(() {
        trip['status'] = 'cancelled';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Trip declined: ${trip['route_name']}'),
            backgroundColor: AppColors.textSecondary,
          ),
        );
      }
    } catch (_) {}
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Trip Requests'),
        backgroundColor: AppColors.surface,
        actions: [
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: _loadTripRequests,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPaddingHorizontal,
              vertical: AppSpacing.sm,
            ),
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
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  count: _tripRequests.length,
                  isSelected: _selectedFilter == 'all',
                  onTap: () => setState(() => _selectedFilter = 'all'),
                ),
                const SizedBox(width: AppSpacing.sm),
                _FilterChip(
                  label: 'Pending',
                  count: _tripRequests.where((t) => t['status'] == 'pending').length,
                  isSelected: _selectedFilter == 'pending',
                  onTap: () => setState(() => _selectedFilter = 'pending'),
                  color: AppColors.warning,
                ),
                const SizedBox(width: AppSpacing.sm),
                _FilterChip(
                  label: 'Accepted',
                  count: _tripRequests.where((t) => t['status'] == 'accepted').length,
                  isSelected: _selectedFilter == 'accepted',
                  onTap: () => setState(() => _selectedFilter = 'accepted'),
                  color: AppColors.success,
                ),
              ],
            ),
          ),
          
          // Trip Requests List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredRequests.isEmpty
                    ? _buildEmptyState()
                    : _buildRequestsList(),
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
            Icons.inbox_outlined,
            size: 64,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No trip requests',
            style: AppTypography.h4.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Go online to receive trip requests',
            style: AppTypography.bodySmall,
          ),
        ],
      ),
    );
  }
  
  Widget _buildRequestsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.sm,
      ),
      itemCount: _filteredRequests.length,
      itemBuilder: (context, index) {
        final trip = _filteredRequests[index];
        return _TripRequestCard(
          trip: trip,
          onAccept: () => _acceptTrip(trip),
          onDecline: () => _declineTrip(trip),
        );
      },
    );
  }
}

/// Filter Chip Widget
class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;
  
  const _FilterChip({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
    this.color,
  });
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? (color ?? AppColors.accent).withOpacity(0.1)
              : AppColors.background,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(
            color: isSelected
                ? (color ?? AppColors.accent)
                : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: isSelected
                    ? (color ?? AppColors.accent)
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? (color ?? AppColors.accent)
                    : AppColors.textTertiary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
              child: Text(
                count.toString(),
                style: AppTypography.labelSmall.copyWith(
                  color: isSelected ? AppColors.textInverse : AppColors.textTertiary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Trip Request Card Widget
class _TripRequestCard extends StatelessWidget {
  final Map<String, dynamic> trip;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  
  const _TripRequestCard({
    required this.trip,
    required this.onAccept,
    required this.onDecline,
  });
  
  @override
  Widget build(BuildContext context) {
    final isAccepted = trip['status'] == 'accepted';
    final isDeclined = trip['status'] == 'declined';
    final isPending = trip['status'] == 'pending';
    
    return AppCard(
      backgroundColor: isAccepted
          ? AppColors.success.withOpacity(0.05)
          : isDeclined
              ? AppColors.textTertiary.withOpacity(0.05)
              : AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: isAccepted
                      ? AppColors.success.withOpacity(0.1)
                      : isDeclined
                          ? AppColors.textTertiary.withOpacity(0.1)
                          : AppColors.driverColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                ),
                child: Icon(
                  isAccepted
                      ? Icons.check_circle_outline
                      : isDeclined
                          ? Icons.cancel_outlined
                          : Icons.directions_bus_outlined,
                  color: isAccepted
                      ? AppColors.success
                      : isDeclined
                          ? AppColors.textTertiary
                          : AppColors.driverColor,
                  size: AppSpacing.iconMedium,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip['route_name'],
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Departs: ${trip['departure_time']}',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: isAccepted
                      ? AppColors.success.withOpacity(0.1)
                      : isDeclined
                          ? AppColors.textTertiary.withOpacity(0.1)
                          : AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                ),
                child: Text(
                  isAccepted ? 'Accepted' : isDeclined ? 'Declined' : 'Pending',
                  style: AppTypography.labelSmall.copyWith(
                    color: isAccepted
                        ? AppColors.success
                        : isDeclined
                            ? AppColors.textTertiary
                            : AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.md),
          
          // Passengers List
          Text(
            'Booked Passengers (${trip['passengers_booked']})',
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: (trip['requests'] as List).map<Widget>((request) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                ),
                child: Text(
                  '${request['name']} (${request['passengers']})',
                  style: AppTypography.labelSmall,
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: AppSpacing.md),
          
          // Earnings
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Estimated Earnings',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                'GHS ${trip['total_fare'].toStringAsFixed(2)}',
                style: AppTypography.h4.copyWith(
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          
          if (isPending) ...[
            const SizedBox(height: AppSpacing.md),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    text: 'Decline',
                    onPressed: onDecline,
                    backgroundColor: AppColors.textTertiary,
                    isExpanded: true,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: PrimaryButton(
                    text: 'Accept Trip',
                    onPressed: onAccept,
                    backgroundColor: AppColors.success,
                    icon: Icons.check_circle_outline,
                    isExpanded: true,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
