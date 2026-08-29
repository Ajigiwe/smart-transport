import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/animated_loader.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../../passenger/screens/passenger_dashboard.dart';
import '../../driver/screens/driver_dashboard.dart';
import '../../admin/screens/admin_dashboard.dart';
import 'login_screen.dart';

/// SmartTransport GH Dashboard Router
/// Routes to role-specific dashboard based on user role
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    
    // Check if user is authenticated
    if (!authState.isAuthenticated) {
      // Redirect to login
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const LoginScreen(),
          ),
        );
      });
      return const Scaffold(
        body: FullScreenLoader(message: 'Signing you in...'),
      );
    }
    
    // Route to appropriate dashboard based on role
    if (authState.isAdmin) {
      return const AdminDashboard();
    } else if (authState.isDriver) {
      return const DriverDashboard();
    } else {
      return const PassengerDashboard();
    }
  }
}

/// SmartTransport GH Role Badge
class RoleBadge extends StatelessWidget {
  final String role;
  
  const RoleBadge({Key? key, required this.role}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    
    switch (role) {
      case 'admin':
        color = AppColors.adminColor;
        icon = Icons.admin_panel_settings_outlined;
        break;
      case 'driver':
        color = AppColors.driverColor;
        icon = Icons.directions_car_outlined;
        break;
      default:
        color = AppColors.passengerColor;
        icon = Icons.person_outlined;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: AppSpacing.iconSmall,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            role.toUpperCase(),
            style: AppTypography.labelSmall.copyWith(
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
