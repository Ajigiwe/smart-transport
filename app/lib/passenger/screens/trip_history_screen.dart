import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/services/api_client.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_spacing.dart';
import '../../shared/theme/app_typography.dart';

final _apiClient = ApiClient();

/// SmartTransport GH Trip History Screen
class TripHistoryScreen extends ConsumerStatefulWidget {
  const TripHistoryScreen({Key? key}) : super(key: key);
  
  @override
  ConsumerState<TripHistoryScreen> createState() => _TripHistoryScreenState();
}

class _TripHistoryScreenState extends ConsumerState<TripHistoryScreen> {
  List<Map<String, dynamic>> _trips = [];
  bool _isLoading = false;
  String _selectedFilter = 'all';
  
  @override
  void initState() {
    super.initState();
    _loadTripHistory();
  }
  
  Future<void> _loadTripHistory() async {
    setState(() => _isLoading = true);
    try {
      final bookings = await _apiClient.getBookings();
      _trips = bookings.map<Map<String, dynamic>>((b) {
        final status = b['status'] ?? 'pending';
        return {
          'id': b['id'],
          'route_name': 'Trip #${b['trip_id']}',
          'driver_name': 'Driver',
          'date': b['requested_at'] != null ? b['requested_at'].toString().substring(0, 10) : 'N/A',
          'time': b['requested_at'] != null ? b['requested_at'].toString().substring(11, 16) : 'N/A',
          'fare': 0.0,
          'status': status,
          'passengers': 1,
        };
      }).toList();
      // Enrich with trip details
      for (var trip in _trips) {
        try {
          final details = await _apiClient.getTripDetails(trip['id'] ?? 0);
          if (details['route'] != null) {
            trip['route_name'] = details['route']['name'] ?? trip['route_name'];
          }
          if (details['driver'] != null) {
            trip['driver_name'] = details['driver']['name'] ?? trip['driver_name'];
          }
        } catch (_) {}
      }
    } catch (e) {
      _trips = [];
    }
    setState(() => _isLoading = false);
  }
  
  List<Map<String, dynamic>> get _filteredTrips {
    if (_selectedFilter == 'all') return _trips;
    return _trips.where((trip) => trip['status'] == _selectedFilter).toList();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Trip History'),
        backgroundColor: AppColors.surface,
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
                  isSelected: _selectedFilter == 'all',
                  onTap: () => setState(() => _selectedFilter = 'all'),
                ),
                const SizedBox(width: AppSpacing.sm),
                _FilterChip(
                  label: 'Completed',
                  isSelected: _selectedFilter == 'completed',
                  onTap: () => setState(() => _selectedFilter = 'completed'),
                  color: AppColors.success,
                ),
                const SizedBox(width: AppSpacing.sm),
                _FilterChip(
                  label: 'Cancelled',
                  isSelected: _selectedFilter == 'cancelled',
                  onTap: () => setState(() => _selectedFilter = 'cancelled'),
                  color: AppColors.error,
                ),
              ],
            ),
          ),
          
          // Trip List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredTrips.isEmpty
                    ? _buildEmptyState()
                    : _buildTripList(),
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
            Icons.history_outlined,
            size: 64,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No trips found',
            style: AppTypography.h4.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Your trip history will appear here',
            style: AppTypography.bodySmall,
          ),
        ],
      ),
    );
  }
  
  Widget _buildTripList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.sm,
      ),
      itemCount: _filteredTrips.length,
      itemBuilder: (context, index) {
        final trip = _filteredTrips[index];
        return _TripHistoryCard(
          trip: trip,
          onTap: () {
            // TODO: Show trip details
          },
        );
      },
    );
  }
}

/// Filter Chip Widget
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;
  
  const _FilterChip({
    required this.label,
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
        child: Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: isSelected
                ? (color ?? AppColors.accent)
                : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// Trip History Card Widget
class _TripHistoryCard extends StatelessWidget {
  final Map<String, dynamic> trip;
  final VoidCallback onTap;
  
  const _TripHistoryCard({
    required this.trip,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    final isCompleted = trip['status'] == 'completed';
    
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Status Icon
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                ),
                child: Icon(
                  isCompleted ? Icons.check_circle_outline : Icons.cancel_outlined,
                  color: isCompleted ? AppColors.success : AppColors.error,
                  size: AppSpacing.iconMedium,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              
              // Route Info
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
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Driver: ${trip['driver_name']}',
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
                  color: isCompleted
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                ),
                child: Text(
                  isCompleted ? 'Completed' : 'Cancelled',
                  style: AppTypography.labelSmall.copyWith(
                    color: isCompleted ? AppColors.success : AppColors.error,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.md),
          
          // Trip Details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _TripDetail(
                icon: Icons.calendar_today_outlined,
                label: 'Date',
                value: trip['date'],
              ),
              _TripDetail(
                icon: Icons.access_time_outlined,
                label: 'Time',
                value: trip['time'],
              ),
              _TripDetail(
                icon: Icons.people_outlined,
                label: 'Passengers',
                value: '${trip['passengers']}',
              ),
              _TripDetail(
                icon: Icons.attach_money_outlined,
                label: 'Fare',
                value: 'GHS ${trip['fare'].toStringAsFixed(2)}',
                isHighlight: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Trip Detail Widget
class _TripDetail extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isHighlight;
  
  const _TripDetail({
    required this.icon,
    required this.label,
    required this.value,
    this.isHighlight = false,
  });
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          size: AppSpacing.iconSmall,
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
            color: isHighlight ? AppColors.accent : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
