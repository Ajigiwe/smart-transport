import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/services/auth_provider.dart';
import '../../shared/models/trip.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/animated_loader.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_spacing.dart';
import '../../shared/theme/app_typography.dart';
import '../../shared/screens/login_screen.dart';
import '../../shared/widgets/premium_app_bar.dart';
import '../../shared/widgets/premium_bottom_nav.dart';
import '../../shared/widgets/loading_route.dart';
import 'routes_management_screen.dart';
import 'vehicles_management_screen.dart';
import 'users_management_screen.dart';
import 'live_tracking_screen.dart';
import 'trip_logs_screen.dart';
import 'create_trip_screen.dart';


/// SmartTransport GH Admin Dashboard
class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);
  
  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard> {
  int _currentIndex = 0;
  Map<String, dynamic>? _stats;
  bool _statsLoading = true;
  List<Trip> _recentTrips = [];
  bool _tripsLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadStats();
    _loadRecentTrips();
  }
  
  Future<void> _loadStats() async {
    setState(() => _statsLoading = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final stats = await apiClient.getDashboardStats();
      await Future.delayed(const Duration(milliseconds: 1200));
      if (mounted) {
        setState(() {
          _stats = stats;
          _statsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _statsLoading = false);
    }
  }
  
  Future<void> _loadRecentTrips() async {
    setState(() => _tripsLoading = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final data = await apiClient.getTrips();
      final trips = data.map((json) => Trip.fromJson(json)).toList();
      trips.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      await Future.delayed(const Duration(milliseconds: 1200));
      if (mounted) {
        setState(() {
          _recentTrips = trips.take(5).toList();
          _tripsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _tripsLoading = false);
    }
  }

  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PremiumAppBar(
        title: 'Admin Dashboard',
        showBackButton: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              navigateWithLoader(context, page: const LoginScreen(), loadingMessage: 'Signing out...', replace: true);
            },
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: PremiumBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
  
  Widget _buildBody() {
    switch (_currentIndex) {
      case 0: return _buildHomeTab();
      case 1: return const RoutesManagementScreen();
      case 2: return const VehiclesManagementScreen();
      case 3: return const UsersManagementScreen();
      case 4: return const LiveTrackingScreen();
      default: return _buildHomeTab();
    }
  }
  
  Widget _buildHomeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.screenPaddingVertical),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPaddingHorizontal),
            child: Text('Overview', style: AppTypography.h2.copyWith(color: AppColors.textPrimary)),
          ),
          const SizedBox(height: AppSpacing.lg),
          
          // Stats Grid
          if (_statsLoading)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: Center(
                child: VehicleDriveLoader(
                  message: 'Loading system overview...',
                ),
              ),
            )

          else ...[
            Row(
              children: [
                Expanded(child: StatCard(title: 'Active Trips', value: '${_stats?['active_trips'] ?? 0}', icon: Icons.directions_bus_outlined, iconColor: AppColors.success, trend: '+12%', isPositiveTrend: true)),
                Expanded(child: StatCard(title: 'Total Drivers', value: '${_stats?['total_drivers'] ?? 0}', icon: Icons.person_outlined, iconColor: AppColors.ghanaGold, trend: '+5%', isPositiveTrend: true)),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(child: StatCard(title: 'Total Routes', value: '${_stats?['total_routes'] ?? 0}', icon: Icons.route_outlined, iconColor: AppColors.info, trend: 'Active', isPositiveTrend: true)),
                Expanded(child: StatCard(title: 'Total Vehicles', value: '${_stats?['total_vehicles'] ?? 0}', icon: Icons.directions_car_outlined, iconColor: AppColors.ghanaRed, trend: 'Ready', isPositiveTrend: true)),
              ],
            ),

          ],
          const SizedBox(height: AppSpacing.xl),
          
          // Quick Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPaddingHorizontal),
            child: Text('Quick Actions', style: AppTypography.h3.copyWith(color: AppColors.textPrimary)),
          ),
          const SizedBox(height: AppSpacing.md),
          
          AppCard(
            child: Column(
              children: [
                _ActionTile(icon: Icons.add_circle_outline, title: 'Create New Route', subtitle: 'Add a new transport route', color: AppColors.accent, onTap: () => setState(() => _currentIndex = 1)),
                const Divider(),
                _ActionTile(icon: Icons.directions_car_outlined, title: 'Add Vehicle', subtitle: 'Register a new vehicle', color: AppColors.driverColor, onTap: () => setState(() => _currentIndex = 2)),
                const Divider(),
                _ActionTile(icon: Icons.person_add_outlined, title: 'Manage Users', subtitle: 'View and manage users', color: AppColors.passengerColor, onTap: () => setState(() => _currentIndex = 3)),
                const Divider(),
                _ActionTile(icon: Icons.map_outlined, title: 'Live Tracking', subtitle: 'View all active vehicles', color: AppColors.success, onTap: () => setState(() => _currentIndex = 4)),
                const Divider(),
                _ActionTile(icon: Icons.add_location_alt_outlined, title: 'Create Trip', subtitle: 'Schedule a new trip', color: AppColors.success, onTap: () async {
                  final result = await navigateWithLoader(context, page: const CreateTripScreen(), loadingMessage: 'Preparing trip form...');
                  if (result == true) {
                    _loadStats();
                    _loadRecentTrips();
                  }
                }),
              ],
            ),
          ),
          
          const SizedBox(height: AppSpacing.xl),
          
          // Trip Logs Preview
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPaddingHorizontal),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent Trips', style: AppTypography.h3.copyWith(color: AppColors.textPrimary)),
                TextButton(
                  onPressed: () => navigateWithLoader(context, page: const TripLogsScreen(), loadingMessage: 'Loading trip history...'),
                  child: Text('View All', style: AppTypography.labelMedium.copyWith(color: AppColors.accent)),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          
          if (_tripsLoading)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_recentTrips.isEmpty)
            AppCard(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Text('No trips yet', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
                ),
              ),
            )
          else
            AppCard(
              child: Column(
                children: _recentTrips.asMap().entries.map((entry) {
                  final trip = entry.value;
                  final isLast = entry.key == _recentTrips.length - 1;
                  return Column(
                    children: [
                      _TripPreview(trip: trip),
                      if (!isLast) const Divider(),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  
  const _ActionTile({required this.icon, required this.title, required this.subtitle, required this.color, required this.onTap});
  
  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(AppSpacing.radiusSmall)),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: AppTypography.bodyLarge),
      subtitle: Text(subtitle, style: AppTypography.bodySmall),
      trailing: const Icon(Icons.chevron_right_outlined, color: AppColors.textTertiary),
      onTap: onTap,
    );
  }
}

class _TripPreview extends StatelessWidget {
  final Trip trip;
  
  const _TripPreview({required this.trip});
  
  @override
  Widget build(BuildContext context) {
    final isCompleted = trip.status == 'completed';
    final isActive = trip.status == 'active';
    final statusColor = isCompleted ? AppColors.success : isActive ? AppColors.info : AppColors.textTertiary;
    final statusText = isCompleted ? 'Completed' : isActive ? 'Active' : trip.status == 'scheduled' ? 'Scheduled' : 'Cancelled';
    
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(AppSpacing.radiusSmall)),
          child: Icon(isCompleted ? Icons.check_circle_outline : isActive ? Icons.directions_bus : Icons.schedule, color: statusColor, size: AppSpacing.iconMedium),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Trip #${trip.id}', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w500)),
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
    );
  }
}
