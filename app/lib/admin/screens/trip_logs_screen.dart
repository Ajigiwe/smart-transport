import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/services/auth_provider.dart';
import '../../shared/models/trip.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_spacing.dart';
import '../../shared/theme/app_typography.dart';
import '../../shared/widgets/premium_app_bar.dart';

/// SmartTransport GH Trip Logs Screen
class TripLogsScreen extends ConsumerStatefulWidget {
  const TripLogsScreen({Key? key}) : super(key: key);
  
  @override
  ConsumerState<TripLogsScreen> createState() => _TripLogsScreenState();
}

class _TripLogsScreenState extends ConsumerState<TripLogsScreen> {
  List<Trip> _trips = [];
  bool _isLoading = false;
  String? _error;
  String _selectedFilter = 'all';
  
  @override
  void initState() {
    super.initState();
    _loadTripLogs();
  }
  
  Future<void> _loadTripLogs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final apiClient = ref.read(apiClientProvider);
      final data = await apiClient.getTrips();
      setState(() {
        _trips = data.map((json) => Trip.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load trips: ${e.toString()}';
      });
    }
  }
  
  List<Trip> get _filteredTrips {
    if (_selectedFilter == 'all') return _trips;
    return _trips.where((t) => t.status == _selectedFilter).toList();
  }
  
  int get _totalTrips => _trips.where((t) => t.status == 'completed').length;
  
  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
  
  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PremiumAppBar(
        title: 'Trip Logs',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadTripLogs,
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.screenPaddingHorizontal),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 4, offset: Offset(0, 2))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(icon: Icons.directions_bus_outlined, value: _totalTrips.toString(), label: 'Completed', color: AppColors.accent),
                _StatItem(icon: Icons.access_time, value: _trips.where((t) => t.status == 'active').length.toString(), label: 'Active', color: AppColors.success),
                _StatItem(icon: Icons.cancel_outlined, value: _trips.where((t) => t.status == 'cancelled').length.toString(), label: 'Cancelled', color: AppColors.error),
              ],
            ),
          ),
          
          // Filters
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPaddingHorizontal, vertical: AppSpacing.sm),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(label: 'All', isSelected: _selectedFilter == 'all', onTap: () => setState(() => _selectedFilter = 'all')),
                  const SizedBox(width: AppSpacing.sm),
                  _FilterChip(label: 'Active', isSelected: _selectedFilter == 'active', onTap: () => setState(() => _selectedFilter = 'active'), color: AppColors.success),
                  const SizedBox(width: AppSpacing.sm),
                  _FilterChip(label: 'Completed', isSelected: _selectedFilter == 'completed', onTap: () => setState(() => _selectedFilter = 'completed'), color: AppColors.info),
                  const SizedBox(width: AppSpacing.sm),
                  _FilterChip(label: 'Cancelled', isSelected: _selectedFilter == 'cancelled', onTap: () => setState(() => _selectedFilter = 'cancelled'), color: AppColors.error),
                ],
              ),
            ),
          ),
          
          // Trip List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildErrorState()
                    : _filteredTrips.isEmpty
                        ? _buildEmptyState()
                        : _buildTripsList(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: AppSpacing.md),
          Text(_error!, style: AppTypography.bodyMedium.copyWith(color: AppColors.error)),
          const SizedBox(height: AppSpacing.md),
          TextButton.icon(
            onPressed: _loadTripLogs,
            icon: const Icon(Icons.refresh_outlined),
            label: const Text('Retry'),
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
          Text('No trips found', style: AppTypography.h4.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
  
  Widget _buildTripsList() {
    return RefreshIndicator(
      onRefresh: _loadTripLogs,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        itemCount: _filteredTrips.length,
        itemBuilder: (context, index) => _TripLogCard(
          trip: _filteredTrips[index],
          formatDate: _formatDate,
          formatTime: _formatTime,
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;
  
  const _FilterChip({required this.label, required this.isSelected, required this.onTap, this.color});
  
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
        child: Text(label, style: AppTypography.labelMedium.copyWith(color: isSelected ? (color ?? AppColors.accent) : AppColors.textSecondary)),
      ),
    );
  }
}

class _TripLogCard extends StatelessWidget {
  final Trip trip;
  final String Function(DateTime) formatDate;
  final String Function(DateTime) formatTime;
  
  const _TripLogCard({required this.trip, required this.formatDate, required this.formatTime});
  
  @override
  Widget build(BuildContext context) {
    final isCompleted = trip.status == 'completed';
    final isActive = trip.status == 'active';
    
    final statusColor = isCompleted ? AppColors.success : isActive ? AppColors.success : AppColors.error;
    final statusText = isCompleted ? 'Completed' : isActive ? 'Active' : trip.status == 'scheduled' ? 'Scheduled' : 'Cancelled';
    
    final icon = isCompleted 
        ? Icons.check_circle_outline 
        : isActive 
            ? Icons.directions_bus 
            : trip.status == 'scheduled'
                ? Icons.schedule
                : Icons.cancel_outlined;
    
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(AppSpacing.radiusSmall)),
                child: Icon(icon, color: statusColor, size: AppSpacing.iconMedium),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Trip #${trip.id}', style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: AppSpacing.xs),
                    Text('Route #${trip.routeId} • Driver #${trip.driverId}', style: AppTypography.bodySmall),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(AppSpacing.radiusSmall)),
                child: Text(statusText, style: AppTypography.labelSmall.copyWith(color: statusColor)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Detail(icon: Icons.calendar_today_outlined, label: formatDate(trip.createdAt)),
              _Detail(icon: Icons.access_time, label: formatTime(trip.createdAt)),
              if (trip.startedAt != null) _Detail(icon: Icons.play_arrow_outlined, label: formatTime(trip.startedAt!)),
              if (trip.endedAt != null) _Detail(icon: Icons.stop_outlined, label: formatTime(trip.endedAt!)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isHighlight;
  
  const _Detail({required this.icon, required this.label, this.isHighlight = false});
  
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.textTertiary),
        const SizedBox(width: 4),
        Text(label, style: AppTypography.labelSmall.copyWith(color: isHighlight ? AppColors.success : AppColors.textSecondary, fontWeight: isHighlight ? FontWeight.w600 : FontWeight.w400)),
      ],
    );
  }
}
