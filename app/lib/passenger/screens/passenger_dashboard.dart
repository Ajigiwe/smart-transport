import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/services/auth_provider.dart';
import '../../shared/services/api_client.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/animated_widgets.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_spacing.dart';
import '../../shared/theme/app_typography.dart';
import '../../shared/screens/login_screen.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/loading_route.dart';
import 'route_list_screen.dart';
import 'active_trip_screen.dart';
import 'trip_booking_screen.dart';
import 'trip_history_screen.dart';
import 'profile_screen.dart';

final _apiClient = ApiClient();

/// SmartTransport GH Passenger Dashboard
class PassengerDashboard extends ConsumerStatefulWidget {
  const PassengerDashboard({Key? key}) : super(key: key);

  @override
  ConsumerState<PassengerDashboard> createState() =>
      _PassengerDashboardState();
}

class _PassengerDashboardState extends ConsumerState<PassengerDashboard>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _navController;
  late Animation<double> _fabScale;
  List<dynamic> _routes = [];
  List<dynamic> _bookings = [];
  bool _isLoadingRoutes = true;

  @override
  void initState() {
    super.initState();
    _navController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fabScale = CurvedAnimation(parent: _navController, curve: Curves.easeOutBack);
    _navController.forward();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoadingRoutes = true);
    try {
      final routes = await _apiClient.getRoutes();
      final bookings = await _apiClient.getBookings();
      if (mounted) {
        setState(() {
          _routes = routes;
          _bookings = bookings;
          _isLoadingRoutes = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingRoutes = false);
    }
  }

  @override
  void dispose() {
    _navController.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    if (index != _currentIndex) {
      _navController.reset();
      _navController.forward();
      setState(() => _currentIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _buildBody(),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 20,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              children: [
                _NavItem(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  isActive: _currentIndex == 0,
                  onTap: () => _onNavTap(0),
                ),
                _NavItem(
                  icon: Icons.explore_rounded,
                  label: 'Routes',
                  isActive: _currentIndex == 1,
                  onTap: () => _onNavTap(1),
                ),
                _NavItem(
                  icon: Icons.location_on_rounded,
                  label: 'Track',
                  isActive: _currentIndex == 2,
                  onTap: () => _onNavTap(2),
                ),
                _NavItem(
                  icon: Icons.history_rounded,
                  label: 'History',
                  isActive: _currentIndex == 3,
                  onTap: () => _onNavTap(3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: _buildCurrentTab(),
    );
  }

  Widget _buildCurrentTab() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return const RouteListScreen();
      case 2:
        return _buildTrackTab();
      case 3:
        return const TripHistoryScreen();
      default:
        return _buildHomeTab();
    }
  }

  Widget _buildHomeTab() {
    final authState = ref.watch(authProvider);
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Gradient Header
        SliverToBoxAdapter(
          child: FadeSlideIn(
            delay: Duration.zero,
            slideOffset: const Offset(0, 0.05),
            child: Container(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.screenPaddingHorizontal,
                MediaQuery.of(context).padding.top + AppSpacing.md,
                AppSpacing.screenPaddingHorizontal,
                AppSpacing.xl,
              ),
              decoration: const BoxDecoration(
                gradient: AppColors.heroGradient,
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FadeSlideIn(
                              delay: const Duration(milliseconds: 150),
                              child: Text(
                                _getGreeting(),
                                style: AppTypography.bodyMedium.copyWith(
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            FadeSlideIn(
                              delay: const Duration(milliseconds: 250),
                              child: Text(
                                authState.user?.name ?? 'Passenger',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 300),
                        child: Row(
                          children: [
                            _HeaderIcon(
                              icon: Icons.person_rounded,
                              onTap: () => navigateWithLoader(context, page: const ProfileScreen(), loadingMessage: 'Loading profile...'),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            _HeaderIcon(
                              icon: Icons.logout_rounded,
                              onTap: () {
                                ref.read(authProvider.notifier).logout();
                                navigateWithLoader(context, page: const LoginScreen(), loadingMessage: 'Signing out...', replace: true);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // Quick Actions
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPaddingHorizontal,
              AppSpacing.lg,
              AppSpacing.screenPaddingHorizontal,
              AppSpacing.md,
            ),
            child: StaggeredColumn(
              staggerDelay: const Duration(milliseconds: 100),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ScaleTap(
                        onTap: () => _onNavTap(1),
                        child: _QuickActionCard(
                          icon: Icons.explore_rounded,
                          title: 'Find Routes',
                          subtitle: 'Browse all routes',
                          color: AppColors.ghanaGreen,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: ScaleTap(
                        onTap: () => _onNavTap(2),
                        child: _QuickActionCard(
                          icon: Icons.location_on_rounded,
                          title: 'Track Trip',
                          subtitle: 'Live location',
                          color: AppColors.ghanaGold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Section Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPaddingHorizontal,
              AppSpacing.md,
              AppSpacing.screenPaddingHorizontal,
              AppSpacing.sm,
            ),
            child: FadeSlideIn(
              delay: const Duration(milliseconds: 350),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Popular Routes',
                    style: AppTypography.h3,
                  ),
                  TextButton(
                    onPressed: () => _onNavTap(1),
                    child: const Text(
                      'View All →',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Route Cards
        SliverPadding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPaddingHorizontal,
          ),
          sliver: _isLoadingRoutes
              ? const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                )
              : SliverList(
                  delegate: SliverChildListDelegate(
                    _routes.take(3).toList().asMap().entries.map((entry) {
                      final route = entry.value;
                      final colors = [AppColors.ghanaGreen, AppColors.ghanaRed, AppColors.ghanaGold];
                      return FadeSlideIn(
                        delay: Duration(milliseconds: 400 + entry.key * 80),
                        child: _RouteCard(
                          name: route['name'] ?? '',
                          fare: 'GHS ${(route['fare'] ?? 0).toStringAsFixed(2)}',
                          color: colors[entry.key % colors.length],
                          icon: Icons.route_rounded,
                          stops: '${route['stops'] != null ? (route['stops'] as String).split(',').length : 0} stops',
                          duration: '~25 min',
                          route: route,
                        ),
                      );
                    }).toList(),
                  ),
                ),
        ),

        // Stats Section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPaddingHorizontal,
              AppSpacing.xl,
              AppSpacing.screenPaddingHorizontal,
              AppSpacing.sm,
            ),
            child: FadeSlideIn(
              delay: const Duration(milliseconds: 600),
              child: const Text('Your Stats', style: AppTypography.h3),
            ),
          ),
        ),

        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPaddingHorizontal,
            0,
            AppSpacing.screenPaddingHorizontal,
            AppSpacing.screenPaddingVertical,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              FadeSlideIn(
                delay: const Duration(milliseconds: 650),
                child: Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Total Trips',
                        value: '${_bookings.length}',
                        icon: Icons.directions_bus_rounded,
                        color: AppColors.ghanaRed,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _StatCard(
                        title: 'Routes Available',
                        value: '${_routes.length}',
                        icon: Icons.calendar_today_rounded,
                        color: AppColors.ghanaGold,
                      ),
                    ),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildTrackTab() {
    return Center(
      child: FadeSlideIn(
        delay: const Duration(milliseconds: 200),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.ghanaRed.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_on_rounded,
                size: 56,
                color: AppColors.ghanaRed,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'No Active Trip',
              style: AppTypography.h3,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Book a trip to see live tracking',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              text: 'Find Routes',
              onPressed: () => _onNavTap(1),
              isExpanded: false,
              icon: Icons.explore_rounded,
            ),
          ],
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning ☀️';
    if (hour < 17) return 'Good afternoon 🌤️';
    return 'Good evening 🌙';
  }
}

/// Navigation item with active indicator
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.ghanaGreen.withOpacity(0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: isActive ? 16 : 0,
                height: 3,
                decoration: BoxDecoration(
                  color: AppColors.ghanaGreen,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 4),
              Icon(
                icon,
                color: isActive ? AppColors.ghanaGreen : AppColors.textTertiary,
                size: 22,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: isActive ? AppColors.ghanaGreen : AppColors.textTertiary,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Quick action card
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(color: color.withOpacity(0.15), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.2),
                  color.withOpacity(0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: AppSpacing.sm + 2),
          Text(
            title,
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Route card with gradient accent
class _RouteCard extends StatelessWidget {
  final String name;
  final String fare;
  final Color color;
  final IconData icon;
  final String stops;
  final String duration;
  final Map<String, dynamic>? route;

  const _RouteCard({
    required this.name,
    required this.fare,
    required this.color,
    required this.icon,
    required this.stops,
    required this.duration,
    this.route,
  });

  @override
  Widget build(BuildContext context) {
    return ScaleTap(
      onTap: () {
        navigateWithLoader(context, page: TripBookingScreen(route: route ?? {}), loadingMessage: 'Loading route details...');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          border: Border.all(color: AppColors.borderLight, width: 1),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withOpacity(0.2),
                    color.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '$stops • $duration',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),

                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: AppColors.ghanaGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.ghanaGreen.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                fare,
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.ghanaGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Stat card
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
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: AppTypography.h2,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  title,
                  style: AppTypography.labelSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


/// Header icon button
class _HeaderIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ScaleTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

