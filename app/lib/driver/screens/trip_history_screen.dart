import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/services/api_client.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_spacing.dart';
import '../../shared/theme/app_typography.dart';

final _apiClient = ApiClient();

/// SmartTransport GH Driver Trip History Screen
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
      final trips = await _apiClient.getTrips();
      _trips = [];
      for (final trip in trips) {
        String routeName = 'Trip #${trip['id']}';
        double fare = 0.0;
        try {
          final details = await _apiClient.getTripDetails(trip['id']);
          routeName = details['route']?['name'] ?? routeName;
          fare = (details['route']?['fare'] ?? 0).toDouble();
        } catch (_) {}

        int durationMinutes = 0;
        if (trip['started_at'] != null && trip['ended_at'] != null) {
          final start = DateTime.parse(trip['started_at']);
          final end = DateTime.parse(trip['ended_at']);
          durationMinutes = end.difference(start).inMinutes;
        }

        _trips.add({
          'id': trip['id'],
          'route_name': routeName,
          'date': trip['created_at']?.toString().substring(0, 10) ?? 'N/A',
          'time': trip['started_at'] != null
              ? DateTime.parse(trip['started_at']).toString().substring(11, 16)
              : 'N/A',
          'passengers': 1,
          'fare': fare,
          'status': trip['status'] ?? 'scheduled',
          'duration_minutes': durationMinutes,
        });
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
  
  double get _totalEarnings {
    return _trips
        .where((trip) => trip['status'] == 'completed')
        .fold(0.0, (sum, trip) => sum + trip['fare']);
  }
  
  int get _totalTrips {
    return _trips.where((trip) => trip['status'] == 'completed').length;
  }
  
  int get _totalPassengers {
    return _trips
        .where((trip) => trip['status'] == 'completed')
        .fold<int>(0, (sum, trip) => sum + (trip['passengers'] as int));
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
          // Stats Header
          _buildStatsHeader(),
          
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
  
  Widget _buildStatsHeader() {
    return Container(
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            icon: Icons.directions_bus_outlined,
            value: _totalTrips.toString(),
            label: 'Trips',
            color: AppColors.driverColor,
          ),
          _StatItem(
            icon: Icons.people_outlined,
            value: _totalPassengers.toString(),
            label: 'Passengers',
            color: AppColors.passengerColor,
          ),
          _StatItem(
            icon: Icons.attach_money_outlined,
            value: 'GHS ${_totalEarnings.toStringAsFixed(0)}',
            label: 'Earnings',
            color: AppColors.success,
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
        return _TripHistoryCard(trip: trip);
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

/// Stat Item Widget
class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  
  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          size: AppSpacing.iconMedium,
          color: color,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: AppTypography.h3.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// Trip History Card Widget
class _TripHistoryCard extends StatelessWidget {
  final Map<String, dynamic> trip;
  
  const _TripHistoryCard({required this.trip});
  
  @override
  Widget build(BuildContext context) {
    final isCompleted = trip['status'] == 'completed';
    
    return AppCard(
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
                      '${trip['date']} • ${trip['time']}',
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
                icon: Icons.people_outlined,
                label: 'Passengers',
                value: '${trip['passengers']}',
              ),
              if (isCompleted)
                _TripDetail(
                  icon: Icons.timer_outlined,
                  label: 'Duration',
                  value: '${trip['duration_minutes']} min',
                ),
              _TripDetail(
                icon: Icons.attach_money_outlined,
                label: 'Earned',
                value: 'GHS ${trip['fare'].toStringAsFixed(2)}',
                isHighlight: isCompleted,
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
            color: isHighlight ? AppColors.success : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
