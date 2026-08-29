import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/services/auth_provider.dart';
import '../../shared/models/user.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/animated_loader.dart';
import '../../shared/widgets/premium_app_bar.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_spacing.dart';
import '../../shared/theme/app_typography.dart';


/// SmartTransport GH Users Management Screen
class UsersManagementScreen extends ConsumerStatefulWidget {
  const UsersManagementScreen({Key? key}) : super(key: key);
  
  @override
  ConsumerState<UsersManagementScreen> createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends ConsumerState<UsersManagementScreen> {
  List<User> _users = [];
  bool _isLoading = false;
  String? _error;
  String _selectedRole = 'all';
  
  @override
  void initState() {
    super.initState();
    _loadUsers();
  }
  
  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final apiClient = ref.read(apiClientProvider);
      final data = await apiClient.getUsers();
      setState(() {
        _users = data.map((json) => User.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load users: ${e.toString()}';
      });
    }
  }
  
  Future<void> _toggleUserStatus(User user) async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.updateUser(user.id, {'is_active': !user.isActive});
      final updatedUser = User.fromJson(response);
      setState(() {
        final index = _users.indexWhere((u) => u.id == user.id);
        if (index != -1) _users[index] = updatedUser;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(updatedUser.isActive ? 'User activated' : 'User deactivated'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update user: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }
  
  List<User> get _filteredUsers {
    if (_selectedRole == 'all') return _users;
    return _users.where((user) => user.role.value == _selectedRole).toList();
  }
  
  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin: return AppColors.adminColor;
      case UserRole.driver: return AppColors.driverColor;
      case UserRole.passenger: return AppColors.passengerColor;
    }
  }
  
  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.admin: return Icons.admin_panel_settings_outlined;
      case UserRole.driver: return Icons.directions_car_outlined;
      case UserRole.passenger: return Icons.person_outlined;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PremiumAppBar(
        title: 'Manage Users',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadUsers,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips (Horizontally Scrollable)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPaddingHorizontal, vertical: AppSpacing.sm),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 4, offset: Offset(0, 2))],
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(label: 'All', count: _users.length, isSelected: _selectedRole == 'all', onTap: () => setState(() => _selectedRole = 'all')),
                  const SizedBox(width: AppSpacing.sm),
                  _FilterChip(label: 'Drivers', count: _users.where((u) => u.role == UserRole.driver).length, isSelected: _selectedRole == 'driver', onTap: () => setState(() => _selectedRole = 'driver'), color: AppColors.driverColor),
                  const SizedBox(width: AppSpacing.sm),
                  _FilterChip(label: 'Passengers', count: _users.where((u) => u.role == UserRole.passenger).length, isSelected: _selectedRole == 'passenger', onTap: () => setState(() => _selectedRole = 'passenger'), color: AppColors.passengerColor),
                  const SizedBox(width: AppSpacing.sm),
                  _FilterChip(label: 'Admins', count: _users.where((u) => u.role == UserRole.admin).length, isSelected: _selectedRole == 'admin', onTap: () => setState(() => _selectedRole = 'admin'), color: AppColors.adminColor),
                ],
              ),
            ),
          ),
          
          // Users List
          Expanded(
            child: _isLoading
                ? const Center(child: VehicleDriveLoader(message: 'Loading users...'))
                : _error != null
                    ? _buildErrorState()
                    : _filteredUsers.isEmpty
                        ? _buildEmptyState()
                        : _buildUsersList(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildErrorState() {
    final is401 = _error?.contains('401') == true;
    final message = is401
        ? 'Session expired or invalid permissions.\nLog in as Admin to access user management.'
        : (_error ?? 'An unexpected error occurred.');

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPaddingHorizontal),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_person_rounded, size: 64, color: AppColors.ghanaRed),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (is401) ...[
              SizedBox(
                width: 220,
                child: PrimaryButton(
                  text: 'Login as Admin',
                  backgroundColor: AppColors.ghanaGreen,
                  icon: Icons.admin_panel_settings_rounded,
                  onPressed: () async {
                    final success = await ref.read(authProvider.notifier).login('0240000001', 'admin123');
                    if (success) _loadUsers();
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            SizedBox(
              width: 220,
              child: SecondaryButton(
                text: 'Retry',
                onPressed: _loadUsers,
                icon: Icons.refresh_outlined,
              ),
            ),
          ],
        ),
      ),
    );
  }

  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.people_outlined, size: 64, color: AppColors.textTertiary),
          const SizedBox(height: AppSpacing.md),
          Text('No users found', style: AppTypography.h4.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
  
  Widget _buildUsersList() {
    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        itemCount: _filteredUsers.length,
        itemBuilder: (context, index) {
          final user = _filteredUsers[index];
          return _UserCard(
            user: user,
            roleColor: _getRoleColor(user.role),
            roleIcon: _getRoleIcon(user.role),
            onToggleStatus: () => _toggleUserStatus(user),
          );
        },
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
  
  const _FilterChip({required this.label, required this.count, required this.isSelected, required this.onTap, this.color});
  
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
            Text(label, style: AppTypography.labelMedium.copyWith(color: isSelected ? (color ?? AppColors.accent) : AppColors.textSecondary)),
            const SizedBox(width: AppSpacing.xs),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? (color ?? AppColors.accent) : AppColors.textTertiary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
              child: Text(count.toString(), style: AppTypography.labelSmall.copyWith(color: isSelected ? AppColors.textInverse : AppColors.textTertiary)),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final User user;
  final Color roleColor;
  final IconData roleIcon;
  final VoidCallback onToggleStatus;
  
  const _UserCard({required this.user, required this.roleColor, required this.roleIcon, required this.onToggleStatus});
  
  @override
  Widget build(BuildContext context) {
    return AppCard(
      backgroundColor: user.isActive ? AppColors.surface : AppColors.textTertiary.withOpacity(0.05),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: roleColor.withOpacity(0.1), borderRadius: BorderRadius.circular(AppSpacing.radiusMedium)),
            child: Icon(roleIcon, color: roleColor),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user.name,
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: user.isActive ? AppColors.textPrimary : AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 2),
                      decoration: BoxDecoration(color: roleColor.withOpacity(0.1), borderRadius: BorderRadius.circular(AppSpacing.radiusSmall)),
                      child: Text(user.role.value.toUpperCase(), style: AppTypography.labelSmall.copyWith(color: roleColor)),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(user.phone, style: AppTypography.bodySmall),
                if (user.email != null) Text(user.email!, style: AppTypography.bodySmall),
              ],
            ),
          ),
          IconButton(
            icon: Icon(user.isActive ? Icons.block_outlined : Icons.check_circle_outlined, size: AppSpacing.iconMedium),
            color: user.isActive ? AppColors.error : AppColors.success,
            onPressed: onToggleStatus,
            tooltip: user.isActive ? 'Deactivate' : 'Activate',
          ),
        ],
      ),
    );
  }
}
