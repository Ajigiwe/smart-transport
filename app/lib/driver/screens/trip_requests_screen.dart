import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/services/api_client.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_spacing.dart';
import '../../shared/theme/app_typography.dart';

final _apiClient = ApiClient();

/// Driver Hail Requests Screen
/// Shows incoming passenger hails — driver can accept or ignore
class TripRequestsScreen extends ConsumerStatefulWidget {
  const TripRequestsScreen({super.key});

  @override
  ConsumerState<TripRequestsScreen> createState() => _TripRequestsScreenState();
}

class _TripRequestsScreenState extends ConsumerState<TripRequestsScreen> {
  List<Map<String, dynamic>> _availableHails = [];
  List<Map<String, dynamic>> _myHails = [];
  bool _isLoading = false;
  String _selectedTab = 'available';
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadHails();
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) => _loadHails());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadHails() async {
    setState(() => _isLoading = true);
    try {
      final available = await _apiClient.getAvailableHails();
      final mine = await _apiClient.getMyHails();
      if (mounted) {
        setState(() {
          _availableHails = available.cast<Map<String, dynamic>>();
          _myHails = mine.cast<Map<String, dynamic>>();
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _acceptHail(Map<String, dynamic> hail) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        ),
        title: const Text('Accept Ride?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Passenger: ${hail['passenger_name'] ?? 'Unknown'}'),
            const SizedBox(height: AppSpacing.sm),
            Text('From: ${hail['pickup_location'] ?? ''}'),
            Text('To: ${hail['destination'] ?? ''}'),
            Text('Passengers: ${hail['passengers_count'] ?? 1}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Decline'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Accept', style: TextStyle(color: AppColors.success)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _apiClient.acceptHail(hail['id']);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ride accepted! Head to ${hail['pickup_location']}'),
              backgroundColor: AppColors.success,
            ),
          );
          _loadHails();
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

  Future<void> _startTrip(Map<String, dynamic> hail) async {
    try {
      await _apiClient.startHailTrip(hail['id']);
      _loadHails();
    } catch (_) {}
  }

  Future<void> _completeTrip(Map<String, dynamic> hail) async {
    try {
      await _apiClient.completeHailTrip(hail['id']);
      _loadHails();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Ride Requests'),
        backgroundColor: AppColors.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: _loadHails,
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab bar
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
                _TabChip(
                  label: 'Available',
                  count: _availableHails.length,
                  isSelected: _selectedTab == 'available',
                  onTap: () => setState(() => _selectedTab = 'available'),
                  color: AppColors.accent,
                ),
                const SizedBox(width: AppSpacing.sm),
                _TabChip(
                  label: 'My Rides',
                  count: _myHails.length,
                  isSelected: _selectedTab == 'my',
                  onTap: () => setState(() => _selectedTab = 'my'),
                  color: AppColors.success,
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _selectedTab == 'available'
                    ? _buildAvailableHails()
                    : _buildMyHails(),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableHails() {
    if (_availableHails.isEmpty) {
      return _buildEmptyState(
        icon: Icons.search_off_rounded,
        title: 'No ride requests',
        subtitle: 'Passengers looking for rides will appear here',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.sm),
      itemCount: _availableHails.length,
      itemBuilder: (context, index) {
        final hail = _availableHails[index];
        return _HailCard(
          hail: hail,
          onAccept: () => _acceptHail(hail),
        );
      },
    );
  }

  Widget _buildMyHails() {
    if (_myHails.isEmpty) {
      return _buildEmptyState(
        icon: Icons.directions_car_outlined,
        title: 'No active rides',
        subtitle: 'Accept a ride request to get started',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.sm),
      itemCount: _myHails.length,
      itemBuilder: (context, index) {
        final hail = _myHails[index];
        return _MyHailCard(
          hail: hail,
          onStart: hail['status'] == 'accepted' ? () => _startTrip(hail) : null,
          onComplete: hail['status'] == 'in_progress' ? () => _completeTrip(hail) : null,
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppColors.textTertiary),
          const SizedBox(height: AppSpacing.md),
          Text(title, style: AppTypography.h4.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.sm),
          Text(subtitle, style: AppTypography.bodySmall),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;
  final Color color;

  const _TabChip({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : AppColors.background,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(color: isSelected ? color : AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: AppTypography.labelMedium.copyWith(
              color: isSelected ? color : AppColors.textSecondary,
            )),
            const SizedBox(width: AppSpacing.xs),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? color : AppColors.textTertiary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('$count', style: AppTypography.labelSmall.copyWith(
                color: isSelected ? Colors.white : AppColors.textTertiary,
              )),
            ),
          ],
        ),
      ),
    );
  }
}

class _HailCard extends StatelessWidget {
  final Map<String, dynamic> hail;
  final VoidCallback onAccept;

  const _HailCard({required this.hail, required this.onAccept});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Passenger info
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.accent.withOpacity(0.1),
                child: Text(
                  (hail['passenger_name'] ?? 'P')[0].toUpperCase(),
                  style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(hail['passenger_name'] ?? 'Passenger',
                        style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
                    Text('${hail['passengers_count'] ?? 1} passenger(s)',
                        style: AppTypography.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Route
          Row(
            children: [
              Icon(Icons.circle, size: 10, color: AppColors.success),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(hail['pickup_location'] ?? '',
                  style: AppTypography.bodyMedium)),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Container(width: 2, height: 20, color: AppColors.border),
          ),
          Row(
            children: [
              Icon(Icons.location_on, size: 10, color: AppColors.error),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(hail['destination'] ?? '',
                  style: AppTypography.bodyMedium, overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Accept button
          PrimaryButton(
            text: 'Accept Ride',
            onPressed: onAccept,
            icon: Icons.check_circle_outline,
            backgroundColor: AppColors.success,
          ),
        ],
      ),
    );
  }
}

class _MyHailCard extends StatelessWidget {
  final Map<String, dynamic> hail;
  final VoidCallback? onStart;
  final VoidCallback? onComplete;

  const _MyHailCard({required this.hail, this.onStart, this.onComplete});

  @override
  Widget build(BuildContext context) {
    final status = hail['status'] ?? 'accepted';
    final Color statusColor;
    final String statusLabel;

    switch (status) {
      case 'accepted':
        statusColor = AppColors.accent;
        statusLabel = 'Accepted';
        break;
      case 'in_progress':
        statusColor = AppColors.success;
        statusLabel = 'In Progress';
        break;
      case 'completed':
        statusColor = AppColors.success;
        statusLabel = 'Completed';
        break;
      case 'cancelled':
        statusColor = AppColors.error;
        statusLabel = 'Cancelled';
        break;
      default:
        statusColor = AppColors.warning;
        statusLabel = status;
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(hail['destination'] ?? '',
                        style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: AppSpacing.xs),
                    Text('From: ${hail['pickup_location'] ?? ''}',
                        style: AppTypography.bodySmall),
                  ],
                ),
              ),
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
          Row(
            children: [
              if (onStart != null)
                Expanded(
                  child: PrimaryButton(
                    text: 'Start Trip',
                    onPressed: onStart,
                    icon: Icons.play_arrow,
                    backgroundColor: AppColors.accent,
                  ),
                ),
              if (onStart != null && onComplete != null)
                const SizedBox(width: AppSpacing.md),
              if (onComplete != null)
                Expanded(
                  child: PrimaryButton(
                    text: 'Complete',
                    onPressed: onComplete,
                    icon: Icons.check_circle,
                    backgroundColor: AppColors.success,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
