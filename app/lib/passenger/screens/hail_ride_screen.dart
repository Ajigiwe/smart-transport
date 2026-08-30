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

/// Passenger Ride-Hailing Screen
/// Select destination → create hail → wait for driver to accept
class HailRideScreen extends ConsumerStatefulWidget {
  const HailRideScreen({super.key});

  @override
  ConsumerState<HailRideScreen> createState() => _HailRideScreenState();
}

class _HailRideScreenState extends ConsumerState<HailRideScreen>
    with SingleTickerProviderStateMixin {
  // Form state
  final _pickupController = TextEditingController(text: 'Current Location');
  final _destinationController = TextEditingController();
  int _passengers = 1;

  // Hail state
  Map<String, dynamic>? _activeHail;
  bool _isCreating = false;
  bool _isCancelling = false;
  Timer? _pollTimer;
  late AnimationController _pulseController;

  // Popular destinations in Takoradi
  final List<Map<String, String>> _popularDestinations = [
    {'name': 'Market Circle', 'icon': '🏪'},
    {'name': 'Takoradi Station', 'icon': '🚌'},
    {'name': 'Effia Nkwanta Hospital', 'icon': '🏥'},
    {'name': 'Takoradi Technical University', 'icon': '🎓'},
    {'name': 'Airport Junction', 'icon': '✈️'},
    {'name': 'Sekondi Junction', 'icon': '🔗'},
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _checkActiveHail();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _pulseController.dispose();
    _pickupController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  Future<void> _checkActiveHail() async {
    try {
      final hails = await _apiClient.getMyHails();
      final active = hails.where((h) =>
          h['status'] == 'searching' || h['status'] == 'accepted').toList();
      if (active.isNotEmpty && mounted) {
        setState(() => _activeHail = active.first);
        _startPolling();
      }
    } catch (_) {}
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (_activeHail == null) return;
      try {
        final hails = await _apiClient.getMyHails();
        final myHail = hails.where((h) => h['id'] == _activeHail!['id']).toList();
        if (myHail.isNotEmpty && mounted) {
          final updated = myHail.first;
          if (updated['status'] != _activeHail!['status']) {
            setState(() => _activeHail = updated);
          }
          if (updated['status'] == 'cancelled' || updated['status'] == 'completed') {
            _pollTimer?.cancel();
            if (mounted) {
              setState(() => _activeHail = null);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(updated['status'] == 'completed'
                      ? 'Trip completed!'
                      : 'Hail was cancelled'),
                  backgroundColor: updated['status'] == 'completed'
                      ? AppColors.success
                      : AppColors.textSecondary,
                ),
              );
            }
          }
        }
      } catch (_) {}
    });
  }

  Future<void> _createHail() async {
    if (_destinationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a destination')),
      );
      return;
    }

    setState(() => _isCreating = true);
    try {
      final hail = await _apiClient.createHail({
        'pickup_location': _pickupController.text,
        'destination': _destinationController.text,
        'passengers_count': _passengers,
      });
      setState(() {
        _activeHail = hail;
        _isCreating = false;
      });
      _startPolling();
    } catch (e) {
      setState(() => _isCreating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create hail: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _cancelHail() async {
    if (_activeHail == null) return;
    setState(() => _isCancelling = true);
    try {
      await _apiClient.cancelHail(_activeHail!['id']);
      _pollTimer?.cancel();
      setState(() {
        _activeHail = null;
        _isCancelling = false;
      });
    } catch (e) {
      setState(() => _isCancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // If there's an active hail, show the waiting/accepted screen
    if (_activeHail != null) {
      return _buildActiveHailScreen();
    }

    // Otherwise show the hail creation form
    return _buildHailForm();
  }

  Widget _buildActiveHailScreen() {
    final status = _activeHail!['status'] ?? 'searching';
    final isSearching = status == 'searching';
    final isAccepted = status == 'accepted';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isSearching ? 'Finding Driver...' : 'Trip Accepted!'),
        backgroundColor: AppColors.surface,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPaddingHorizontal),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated pulse icon
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final scale = 1.0 + (_pulseController.value * 0.15);
                  return Transform.scale(
                    scale: isSearching ? scale : 1.0,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: (isSearching ? AppColors.accent : AppColors.success)
                            .withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isSearching
                            ? Icons.search
                            : Icons.check_circle_outline,
                        size: 60,
                        color: isSearching ? AppColors.accent : AppColors.success,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.xl),

              Text(
                isSearching
                    ? 'Looking for a nearby driver...'
                    : 'Driver is on the way!',
                style: AppTypography.h2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),

              if (isSearching) ...[
                Text(
                  'We\'ll notify you when a driver accepts',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                const CircularProgressIndicator(
                  color: AppColors.accent,
                  strokeWidth: 3,
                ),
              ],

              if (isAccepted) ...[
                const SizedBox(height: AppSpacing.md),
                AppCard(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: AppColors.success.withOpacity(0.1),
                            child: const Icon(Icons.person, color: AppColors.success, size: 32),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _activeHail!['driver_name'] ?? 'Driver',
                                  style: AppTypography.bodyLarge.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  _activeHail!['driver_plate'] ?? '',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.xl),

              // Trip details
              AppCard(
                child: Column(
                  children: [
                    _TripDetailRow(
                      icon: Icons.my_location,
                      label: 'Pickup',
                      value: _activeHail!['pickup_location'] ?? '',
                      color: AppColors.success,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _TripDetailRow(
                      icon: Icons.location_on_outlined,
                      label: 'Destination',
                      value: _activeHail!['destination'] ?? '',
                      color: AppColors.error,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _TripDetailRow(
                      icon: Icons.people_outline,
                      label: 'Passengers',
                      value: '${_activeHail!['passengers_count'] ?? 1}',
                      color: AppColors.accent,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Cancel button
              PrimaryButton(
                text: _isCancelling ? 'Cancelling...' : 'Cancel Ride',
                onPressed: _isCancelling ? null : _cancelHail,
                backgroundColor: AppColors.error,
                isLoading: _isCancelling,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHailForm() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Hail a Ride'),
        backgroundColor: AppColors.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPaddingHorizontal),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.lg),

            // Pickup
            Text('Pickup Location', style: AppTypography.labelLarge),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _pickupController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.my_location, color: AppColors.success),
                hintText: 'Enter pickup location',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Destination
            Text('Where to?', style: AppTypography.h2),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _destinationController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.error),
                hintText: 'Enter destination',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                ),
              ),
              autofocus: true,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Passengers count
            Text('Passengers', style: AppTypography.labelLarge),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                _CounterButton(
                  icon: Icons.remove,
                  onTap: _passengers > 1
                      ? () => setState(() => _passengers--)
                      : null,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Text(
                    '$_passengers',
                    style: AppTypography.h2,
                  ),
                ),
                _CounterButton(
                  icon: Icons.add,
                  onTap: _passengers < 6
                      ? () => setState(() => _passengers++)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            // Popular destinations
            Text('Popular Destinations', style: AppTypography.labelLarge),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: _popularDestinations.map((dest) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _destinationController.text = dest['name']!;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      '${dest['icon']} ${dest['name']}',
                      style: AppTypography.bodySmall,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Hail button
            PrimaryButton(
              text: _isCreating ? 'Creating Request...' : 'Find Driver',
              onPressed: _isCreating ? null : _createHail,
              isLoading: _isCreating,
              icon: Icons.search,
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

class _TripDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _TripDetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: AppSpacing.sm),
        Text('$label: ', style: AppTypography.bodySmall.copyWith(
          color: AppColors.textSecondary,
        )),
        Expanded(child: Text(value, style: AppTypography.bodyMedium.copyWith(
          fontWeight: FontWeight.w500,
        ))),
      ],
    );
  }
}

class _CounterButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _CounterButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: onTap != null ? AppColors.accent : AppColors.border,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}
