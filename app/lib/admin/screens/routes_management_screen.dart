import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/services/auth_provider.dart';
import '../../shared/models/route.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/custom_text_field.dart';
import '../../shared/widgets/animated_loader.dart';
import '../../shared/widgets/premium_app_bar.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_spacing.dart';
import '../../shared/theme/app_typography.dart';


/// SmartTransport GH Routes Management Screen
class RoutesManagementScreen extends ConsumerStatefulWidget {
  const RoutesManagementScreen({Key? key}) : super(key: key);
  
  @override
  ConsumerState<RoutesManagementScreen> createState() => _RoutesManagementScreenState();
}

class _RoutesManagementScreenState extends ConsumerState<RoutesManagementScreen> {
  List<AppRoute> _routes = [];
  bool _isLoading = false;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }
  
  Future<void> _loadRoutes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final apiClient = ref.read(apiClientProvider);
      final data = await apiClient.getRoutes();
      await Future.delayed(const Duration(milliseconds: 1000));
      if (mounted) {
        setState(() {
          _routes = data.map((json) => AppRoute.fromJson(json)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load routes: ${e.toString()}';
        });
      }
    }

  }
  
  Future<void> _createRoute(Map<String, dynamic> data) async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.createRoute(data);
      final newRoute = AppRoute.fromJson(response);
      setState(() => _routes.add(newRoute));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Route created'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create route: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }
  
  Future<void> _updateRoute(int routeId, Map<String, dynamic> data) async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.updateRoute(routeId, data);
      final updatedRoute = AppRoute.fromJson(response);
      setState(() {
        final index = _routes.indexWhere((r) => r.id == routeId);
        if (index != -1) _routes[index] = updatedRoute;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Route updated'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update route: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }
  
  Future<void> _deleteRoute(int routeId) async {
    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.deleteRoute(routeId);
      setState(() => _routes.removeWhere((r) => r.id == routeId));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Route deleted'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete route: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }
  
  void _showAddEditRouteDialog({AppRoute? route}) {
    final isEditing = route != null;
    final nameController = TextEditingController(text: route?.name ?? '');
    final startController = TextEditingController(text: route?.startPoint ?? '');
    final endController = TextEditingController(text: route?.endPoint ?? '');
    final fareController = TextEditingController(text: route?.fare.toString() ?? '');
    final stopsController = TextEditingController(text: route?.stops ?? '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Edit Route' : 'Add New Route'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                label: 'Route Name',
                controller: nameController,
                hint: 'e.g., Takoradi - Effia Nkwanta',
              ),
              const SizedBox(height: AppSpacing.md),
              CustomTextField(
                label: 'Start Point',
                controller: startController,
                hint: 'e.g., Takoradi Station',
              ),
              const SizedBox(height: AppSpacing.md),
              CustomTextField(
                label: 'End Point',
                controller: endController,
                hint: 'e.g., Effia Nkwanta',
              ),
              const SizedBox(height: AppSpacing.md),
              CustomTextField(
                label: 'Fare (GHS)',
                controller: fareController,
                keyboardType: TextInputType.number,
                hint: 'e.g., 5.00',
              ),
              const SizedBox(height: AppSpacing.md),
              CustomTextField(
                label: 'Stops (comma-separated)',
                controller: stopsController,
                hint: 'e.g., Market Circle, Junction',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.isEmpty ||
                  startController.text.isEmpty ||
                  endController.text.isEmpty ||
                  fareController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill in all required fields'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }
              
              final routeData = {
                'name': nameController.text,
                'start_point': startController.text,
                'end_point': endController.text,
                'fare': double.tryParse(fareController.text) ?? 0,
                'stops': stopsController.text.isNotEmpty ? stopsController.text : null,
              };
              
              Navigator.of(context).pop();
              
              if (isEditing) {
                _updateRoute(route.id, routeData);
              } else {
                _createRoute(routeData);
              }
            },
            child: Text(isEditing ? 'Update' : 'Add'),
          ),
        ],
      ),
    );
  }
  
  void _deleteRouteDialog(AppRoute route) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Route?'),
        content: Text('Are you sure you want to delete "${route.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteRoute(route.id);
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PremiumAppBar(
        title: 'Manage Routes',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadRoutes,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditRouteDialog(),
        backgroundColor: AppColors.accent,
        child: const Icon(Icons.add_outlined, color: AppColors.textInverse),
      ),
      body: _isLoading
          ? const Center(
              child: VehicleDriveLoader(
                message: 'Loading transport routes...',
              ),
            )

          : _error != null
              ? _buildErrorState()
              : _routes.isEmpty
                  ? _buildEmptyState()
                  : _buildRoutesList(),
    );
  }
  
  Widget _buildErrorState() {
    final is401 = _error?.contains('401') == true;
    final message = is401
        ? 'Session expired or invalid permissions.\nLog in as Admin to access route management.'
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
                    if (success) _loadRoutes();
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            SizedBox(
              width: 220,
              child: SecondaryButton(
                text: 'Retry',
                onPressed: _loadRoutes,
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
          const Icon(Icons.route_outlined, size: 64, color: AppColors.textTertiary),
          const SizedBox(height: AppSpacing.md),
          Text('No routes yet', style: AppTypography.h4.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.sm),
          Text('Add your first transport route', style: AppTypography.bodySmall),
        ],
      ),
    );
  }
  
  Widget _buildRoutesList() {
    return RefreshIndicator(
      onRefresh: _loadRoutes,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        itemCount: _routes.length,
        itemBuilder: (context, index) {
          final route = _routes[index];
          return _RouteCard(
            route: route,
            onEdit: () => _showAddEditRouteDialog(route: route),
            onDelete: () => _deleteRouteDialog(route),
          );
        },
      ),
    );
  }
}

/// Route Card Widget
class _RouteCard extends StatelessWidget {
  final AppRoute route;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  
  const _RouteCard({
    required this.route,
    required this.onEdit,
    required this.onDelete,
  });
  
  @override
  Widget build(BuildContext context) {
    final isActive = route.isActive;
    
    return AppCard(
      backgroundColor: isActive ? AppColors.surface : AppColors.textTertiary.withOpacity(0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Status Indicator
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: isActive ? AppColors.success : AppColors.textTertiary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              
              // Route Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      route.name,
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${route.startPoint} → ${route.endPoint}',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
              
              // Fare
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                ),
                child: Text(
                  'GHS ${route.fare.toStringAsFixed(2)}',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.md),
          
          // Stops
          if (route.stopsList.isNotEmpty) ...[
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: route.stopsList.map<Widget>((stop) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                  ),
                  child: Text(stop, style: AppTypography.labelSmall),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          
          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: AppSpacing.iconMedium),
                color: AppColors.accent,
                onPressed: onEdit,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: AppSpacing.iconMedium),
                color: AppColors.error,
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
