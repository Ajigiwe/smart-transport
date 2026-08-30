import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/services/api_client.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_spacing.dart';
import '../../shared/theme/app_typography.dart';

final _apiClient = ApiClient();

/// Driver Trip History — shows completed/cancelled rides with earnings
class TripHistoryScreen extends ConsumerStatefulWidget {
  const TripHistoryScreen({super.key});

  @override
  ConsumerState<TripHistoryScreen> createState() => _TripHistoryScreenState();
}

class _TripHistoryScreenState extends ConsumerState<TripHistoryScreen> {
  List<Map<String, dynamic>> _hails = [];
  bool _isLoading = false;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      final hails = await _apiClient.getMyHails();
      if (mounted) {
        setState(() => _hails = hails.cast<Map<String, dynamic>>());
      }
    } catch (e) {
      if (mounted) setState(() => _hails = []);
    }
    if (mounted) setState(() => _isLoading = false);
  }

  List<Map<String, dynamic>> get _filteredHails {
    if (_selectedFilter == 'all') return _hails;
    return _hails.where((h) => h['status'] == _selectedFilter).toList();
  }

  double get _totalEarnings => _hails
      .where((h) => h['status'] == 'completed')
      .fold(0.0, (sum, h) => sum + (h['fare_estimate'] ?? 0.0));

  int get _completedTrips => _hails.where((h) => h['status'] == 'completed').length;

  int get _totalPassengers => _hails
      .where((h) => h['status'] == 'completed')
      .fold<int>(0, (sum, h) => sum + (h['passengers_count'] ?? 1) as int);

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
          // Earnings summary
          _buildStatsHeader(),

          // Filter chips
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPaddingHorizontal,
              vertical: AppSpacing.sm,
            ),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 4, offset: Offset(0, 2))],
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(label: 'All', count: _hails.length,
                      isSelected: _selectedFilter == 'all',
                      onTap: () => setState(() => _selectedFilter = 'all')),
                  const SizedBox(width: AppSpacing.sm),
                  _FilterChip(label: 'Completed', count: _completedTrips,
                      isSelected: _selectedFilter == 'completed',
                      onTap: () => setState(() => _selectedFilter = 'completed'),
                      color: AppColors.success),
                  const SizedBox(width: AppSpacing.sm),
                  _FilterChip(label: 'Cancelled', count: _hails.where((h) => h['status'] == 'cancelled').length,
                      isSelected: _selectedFilter == 'cancelled',
                      onTap: () => setState(() => _selectedFilter = 'cancelled'),
                      color: AppColors.error),
                ],
              ),
            ),
          ),

          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredHails.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadHistory,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          itemCount: _filteredHails.length,
                          itemBuilder: (context, index) =>
                              _DriverHailCard(hail: _filteredHails[index]),
                        ),
                      ),
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
        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            icon: Icons.directions_bus_outlined,
            value: _completedTrips.toString(),
            label: 'Completed',
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
          const Icon(Icons.history_outlined, size: 64, color: AppColors.textTertiary),
          const SizedBox(height: AppSpacing.md),
          Text('No trips yet', style: AppTypography.h4.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.sm),
          Text('Accept rides to see your history here', style: AppTypography.bodySmall),
        ],
      ),
    );
  }
}

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
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isSelected ? (color ?? AppColors.accent).withOpacity(0.1) : AppColors.background,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(color: isSelected ? (color ?? AppColors.accent) : AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: AppTypography.labelMedium.copyWith(
              color: isSelected ? (color ?? AppColors.accent) : AppColors.textSecondary,
            )),
            if (count > 0) ...[
              const SizedBox(width: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? (color ?? AppColors.accent) : AppColors.textTertiary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('$count', style: AppTypography.labelSmall.copyWith(
                  color: isSelected ? Colors.white : AppColors.textTertiary,
                )),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatItem({required this.icon, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: AppSpacing.iconMedium, color: color),
        const SizedBox(height: AppSpacing.xs),
        Text(value, style: AppTypography.h3.copyWith(color: AppColors.textPrimary)),
        Text(label, style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary)),
      ],
    );
  }
}

class _DriverHailCard extends StatelessWidget {
  final Map<String, dynamic> hail;

  const _DriverHailCard({required this.hail});

  @override
  Widget build(BuildContext context) {
    final status = hail['status'] ?? 'accepted';
    final Color statusColor;
    final String statusLabel;

    switch (status) {
      case 'completed':
        statusColor = AppColors.success;
        statusLabel = 'Completed';
        break;
      case 'cancelled':
        statusColor = AppColors.error;
        statusLabel = 'Cancelled';
        break;
      case 'in_progress':
        statusColor = AppColors.warning;
        statusLabel = 'In Progress';
        break;
      default:
        statusColor = AppColors.accent;
        statusLabel = 'Accepted';
    }

    final createdAt = hail['created_at'] != null
        ? hail['created_at'].toString().substring(0, 16).replaceAll('T', ' ')
        : '';

    final fare = hail['fare_estimate'] ?? 0.0;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Status icon
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                ),
                child: Icon(
                  status == 'completed'
                      ? Icons.check_circle_outline
                      : status == 'cancelled'
                          ? Icons.cancel_outlined
                          : Icons.directions_car,
                  color: statusColor,
                  size: AppSpacing.iconMedium,
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // Route info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${hail['pickup_location'] ?? ''} → ${hail['destination'] ?? ''}',
                      style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      hail['passenger_name'] ?? 'Passenger',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),

              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                ),
                child: Text(statusLabel, style: AppTypography.labelSmall.copyWith(color: statusColor)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Details row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _DetailItem(icon: Icons.calendar_today, value: createdAt.length > 10 ? createdAt.substring(0, 10) : createdAt),
              _DetailItem(icon: Icons.access_time, value: createdAt.length > 10 ? createdAt.substring(11, 16) : ''),
              _DetailItem(icon: Icons.people_outline, value: '${hail['passengers_count'] ?? 1} pax'),
              if (status == 'completed')
                _DetailItem(icon: Icons.attach_money, value: 'GHS ${fare.toStringAsFixed(2)}', isHighlight: true),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final bool isHighlight;

  const _DetailItem({required this.icon, required this.value, this.isHighlight = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textTertiary),
        const SizedBox(width: 4),
        Text(value, style: AppTypography.labelSmall.copyWith(
          color: isHighlight ? AppColors.success : AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        )),
      ],
    );
  }
}
