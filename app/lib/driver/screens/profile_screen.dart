import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/services/auth_provider.dart';
import '../../shared/services/api_client.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/custom_text_field.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_spacing.dart';
import '../../shared/theme/app_typography.dart';

/// SmartTransport GH Driver Profile Screen
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);
  
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isEditing = false;
  bool _isSaving = false;
  
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;  Map<String, dynamic> _vehicleInfo = {};
  bool _isLoadingVehicle = true;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _loadVehicle();
  }

  Future<void> _loadVehicle() async {
    try {
      final vehicle = await ApiClient().getMyVehicle();
      if (mounted) {
        setState(() {
          _vehicleInfo = vehicle;
          _isLoadingVehicle = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingVehicle = false);
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }
  
  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      final user = ref.read(authProvider).user;
      if (user != null) {
        await ApiClient().updateProfile(user.id, {
          'name': _nameController.text,
          'phone': _phoneController.text,
          'email': _emailController.text,
        });
      }
      setState(() {
        _isSaving = false;
        _isEditing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Update failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppColors.surface,
        actions: [
          IconButton(
            icon: Icon(
              _isEditing ? Icons.close_outlined : Icons.edit_outlined,
            ),
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
                if (!_isEditing) {
                  // Reset controllers
                  _nameController.text = user?.name ?? '';
                  _phoneController.text = user?.phone ?? '';
                  _emailController.text = user?.email ?? '';
                }
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPaddingHorizontal),
        child: Column(
          children: [
            // Profile Header
            AppCard(
              child: Column(
                children: [
                  // Avatar
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.driverColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.driverColor.withOpacity(0.3),
                        width: 3,
                      ),
                    ),
                    child: const Icon(
                      Icons.directions_car_outlined,
                      size: 48,
                      color: AppColors.driverColor,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  
                  // Name
                  Text(
                    user?.name ?? 'Driver',
                    style: AppTypography.h3.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  
                  // Phone
                  Text(
                    user?.phone ?? '',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  
                  // Role Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.driverColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    ),
                    child: Text(
                      'DRIVER',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.driverColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppSpacing.lg),
            
            // Vehicle Info
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vehicle Information',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  
                  if (_isLoadingVehicle)
                    const Center(child: CircularProgressIndicator())
                  else if (_vehicleInfo.isEmpty)
                    Text('No vehicle assigned', style: AppTypography.bodyMedium)
                  else ...[
                    _InfoRow(
                      icon: Icons.directions_car_outlined,
                      label: 'Plate Number',
                      value: _vehicleInfo['plate_number'] ?? 'N/A',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _InfoRow(
                      icon: Icons.people_outlined,
                      label: 'Capacity',
                      value: '${_vehicleInfo['capacity'] ?? 'N/A'} passengers',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _InfoRow(
                      icon: Icons.check_circle_outlined,
                      label: 'Status',
                      value: (_vehicleInfo['status'] ?? 'unknown').toString().toUpperCase(),
                      valueColor: AppColors.success,
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: AppSpacing.lg),
            
            // Profile Form
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Personal Information',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  
                  CustomTextField(
                    label: 'Full Name',
                    controller: _nameController,
                    readOnly: !_isEditing,
                    prefixIcon: Icons.person_outlined,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  
                  CustomTextField(
                    label: 'Phone Number',
                    controller: _phoneController,
                    readOnly: !_isEditing,
                    keyboardType: TextInputType.phone,
                    prefixIcon: Icons.phone_outlined,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  
                  CustomTextField(
                    label: 'Email',
                    controller: _emailController,
                    readOnly: !_isEditing,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                  ),
                  
                  if (_isEditing) ...[
                    const SizedBox(height: AppSpacing.lg),
                    PrimaryButton(
                      text: 'Save Changes',
                      isLoading: _isSaving,
                      onPressed: _saveProfile,
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: AppSpacing.lg),
            
            // Earnings Stats
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This Month\'s Earnings',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatItem(
                        label: 'Total',
                        value: '-',
                        icon: Icons.attach_money_outlined,
                        color: AppColors.success,
                      ),
                      _StatItem(
                        label: 'Trips',
                        value: '-',
                        icon: Icons.directions_bus_outlined,
                        color: AppColors.driverColor,
                      ),
                      _StatItem(
                        label: 'Avg/Trip',
                        value: '-',
                        icon: Icons.analytics_outlined,
                        color: AppColors.accent,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppSpacing.lg),
            
            // Settings Section
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Settings',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  
                  _SettingsItem(
                    icon: Icons.notifications_outlined,
                    title: 'Notifications',
                    subtitle: 'Manage notification preferences',
                    onTap: () {
                      // TODO: Navigate to notifications settings
                    },
                  ),
                  const Divider(),
                  _SettingsItem(
                    icon: Icons.lock_outlined,
                    title: 'Change Password',
                    subtitle: 'Update your password',
                    onTap: () {
                      // TODO: Navigate to change password
                    },
                  ),
                  const Divider(),
                  _SettingsItem(
                    icon: Icons.help_outline,
                    title: 'Help & Support',
                    subtitle: 'Get help with the app',
                    onTap: () {
                      // TODO: Navigate to help
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppSpacing.lg),
            
            // Logout Button
            PrimaryButton(
              text: 'Logout',
              onPressed: () {
                ref.read(authProvider.notifier).logout();
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              backgroundColor: AppColors.error,
            ),
            
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

/// Info Row Widget
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });
  
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: AppSpacing.iconMedium,
          color: AppColors.textTertiary,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(
            color: valueColor ?? AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Stat Item Widget
class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  
  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          size: AppSpacing.iconLarge,
          color: color,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          value,
          style: AppTypography.h4.copyWith(
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

/// Settings Item Widget
class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  
  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
        ),
        child: Icon(
          icon,
          color: AppColors.textSecondary,
        ),
      ),
      title: Text(
        title,
        style: AppTypography.bodyLarge.copyWith(
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTypography.bodySmall,
      ),
      trailing: const Icon(
        Icons.chevron_right_outlined,
        color: AppColors.textTertiary,
      ),
      onTap: onTap,
    );
  }
}
