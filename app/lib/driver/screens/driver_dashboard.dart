import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/services/auth_provider.dart';
import '../../shared/services/api_client.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_spacing.dart';
import '../../shared/theme/app_typography.dart';
import '../../shared/screens/login_screen.dart';
import '../../shared/widgets/loading_route.dart';
import 'trip_requests_screen.dart';
import 'trip_history_screen.dart';
import 'profile_screen.dart';

final _apiClient = ApiClient();

/// SmartTransport GH Driver Dashboard
class DriverDashboard extends ConsumerStatefulWidget {
  const DriverDashboard({Key? key}) : super(key: key);
  
  @override
  ConsumerState<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends ConsumerState<DriverDashboard> {
  int _currentIndex = 0;
  bool _isOnline = false;
  int _completedTrips = 0;
  double _totalEarnings = 0.0;
  int _pendingRequests = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final trips = await _apiClient.getTrips();
      _completedTrips = trips.where((t) => t['status'] == 'completed').length;
      _totalEarnings = 0.0;
      for (final t in trips.where((t) => t['status'] == 'completed')) {
        try {
          final details = await _apiClient.getTripDetails(t['id']);
          _totalEarnings += (details['route']?['fare'] ?? 0) as num;
        } catch (_) {}
      }
      _pendingRequests = trips.where((t) => t['status'] == 'scheduled').length;
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }
  
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Driver Dashboard'),
        actions: [
          // Profile Icon
          IconButton(
            icon: const Icon(Icons.person_outlined),
            onPressed: () {
              navigateWithLoader(context, page: const ProfileScreen(), loadingMessage: 'Loading profile...');
            },
          ),
          // Logout
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              navigateWithLoader(context, page: const LoginScreen(), loadingMessage: 'Signing out...', replace: true);
            },
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_car_outlined),
            label: 'Trips',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            label: 'History',
          ),
        ],
      ),
    );
  }
  
  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return const TripRequestsScreen();
      case 2:
        return const TripHistoryScreen();
      default:
        return _buildHomeTab();
    }
  }
  
  Widget _buildHomeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.screenPaddingVertical,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Online/Offline Toggle
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPaddingHorizontal,
            ),
            child: AppCard(
              backgroundColor: _isOnline
                  ? AppColors.success.withOpacity(0.1)
                  : AppColors.surface,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isOnline ? 'You are Online' : 'You are Offline',
                        style: AppTypography.h3.copyWith(
                          color: _isOnline ? AppColors.success : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        _isOnline
                            ? 'Ready to receive trip requests'
                            : 'Go online to start receiving trips',
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                  Switch(
                    value: _isOnline,
                    onChanged: (value) {
                      setState(() {
                        _isOnline = value;
                      });
                      // TODO: Update vehicle status via API
                    },
                    activeColor: AppColors.success,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          
          // Quick Stats
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPaddingHorizontal,
            ),
            child: Text(
              'Summary',
              style: AppTypography.h3.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'Completed',
                  value: _isLoading ? '...' : '$_completedTrips',
                  icon: Icons.check_circle_outline,
                  color: AppColors.success,
                ),
              ),
              Expanded(
                child: _StatCard(
                  title: 'Earnings',
                  value: _isLoading ? '...' : 'GHS ${_totalEarnings.toStringAsFixed(0)}',
                  icon: Icons.attach_money_outlined,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          
          // Quick Actions
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPaddingHorizontal,
            ),
            child: Text(
              'Quick Actions',
              style: AppTypography.h3.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPaddingHorizontal,
            ),
            child: Row(
              children: [
                Expanded(
                  child: _ActionCard(
                    icon: Icons.directions_car_outlined,
                    title: 'Trip Requests',
                    subtitle: 'View & accept',
                    color: AppColors.driverColor,
                    onTap: () => setState(() => _currentIndex = 1),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _ActionCard(
                    icon: Icons.history_outlined,
                    title: 'Trip History',
                    subtitle: 'View past trips',
                    color: AppColors.accent,
                    onTap: () => setState(() => _currentIndex = 2),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          
          // Active Trip (if any)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPaddingHorizontal,
            ),
            child: Text(
              'Pending Requests',
              style: AppTypography.h3.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          
          // Pending Request Card
          AppCard(
            backgroundColor: AppColors.warning.withOpacity(0.05),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                      ),
                      child: const Icon(
                        Icons.notifications_active_outlined,
                        color: AppColors.warning,
                        size: AppSpacing.iconLarge,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$_pendingRequests Trip Requests',
                            style: AppTypography.bodyLarge.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Scheduled trips available',
                            style: AppTypography.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                PrimaryButton(
                  text: 'View Requests',
                  isExpanded: false,
                  onPressed: () => setState(() => _currentIndex = 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Stat Card Widget
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
  
  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: AppSpacing.iconLarge,
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: AppTypography.h2.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                title,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Action Card Widget
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: AppSpacing.elevationSmall,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              ),
              child: Icon(
                icon,
                color: color,
                size: AppSpacing.iconLarge,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              title,
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              subtitle,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
