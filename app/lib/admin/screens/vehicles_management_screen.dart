import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/services/auth_provider.dart';
import '../../shared/models/vehicle.dart';
import '../../shared/models/user.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/custom_text_field.dart';
import '../../shared/widgets/animated_loader.dart';
import '../../shared/widgets/premium_app_bar.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_spacing.dart';
import '../../shared/theme/app_typography.dart';

/// SmartTransport GH Vehicles Management Screen
class VehiclesManagementScreen extends ConsumerStatefulWidget {
  const VehiclesManagementScreen({Key? key}) : super(key: key);
  
  @override
  ConsumerState<VehiclesManagementScreen> createState() => _VehiclesManagementScreenState();
}

class _VehiclesManagementScreenState extends ConsumerState<VehiclesManagementScreen> {
  List<Vehicle> _vehicles = [];
  bool _isLoading = false;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }
  
  Future<void> _loadVehicles() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final apiClient = ref.read(apiClientProvider);
      final data = await apiClient.getVehicles();
      setState(() {
        _vehicles = data.map((json) => Vehicle.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load vehicles: ${e.toString()}';
      });
    }
  }
  
  Future<void> _createVehicle(Map<String, dynamic> data) async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.createVehicle(data);
      final newVehicle = Vehicle.fromJson(response);
      setState(() => _vehicles.add(newVehicle));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vehicle created'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create vehicle: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }
  
  Future<void> _updateVehicle(int vehicleId, Map<String, dynamic> data) async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.updateVehicle(vehicleId, data);
      final updatedVehicle = Vehicle.fromJson(response);
      setState(() {
        final index = _vehicles.indexWhere((v) => v.id == vehicleId);
        if (index != -1) _vehicles[index] = updatedVehicle;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vehicle updated'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update vehicle: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }
  
  Future<void> _deleteVehicle(int vehicleId) async {
    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.deleteVehicle(vehicleId);
      setState(() => _vehicles.removeWhere((v) => v.id == vehicleId));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vehicle deleted'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete vehicle: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }
  
  void _showAddEditVehicleDialog({Vehicle? vehicle}) {
    final isEditing = vehicle != null;
    final plateController = TextEditingController(text: vehicle?.plateNumber ?? '');
    final capacityController = TextEditingController(text: vehicle?.capacity.toString() ?? '14');
    String selectedStatus = vehicle?.status ?? 'active';
    int? selectedDriverId = vehicle?.driverId;
    List<User> _drivers = [];
    bool _loadingDrivers = true;
    
    // Load available drivers
    _loadDrivers() async {
      try {
        final apiClient = ref.read(apiClientProvider);
        final data = await apiClient.getUsers(role: 'driver');
        _drivers = data.map((json) => User.fromJson(json)).toList();
        _loadingDrivers = false;
      } catch (e) {
        _loadingDrivers = false;
      }
    }
    
    _loadDrivers();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Reload drivers if needed
          if (_loadingDrivers && _drivers.isEmpty) {
            _loadDrivers().then((_) => setDialogState(() {}));
          }
          
          return AlertDialog(
            title: Text(isEditing ? 'Edit Vehicle' : 'Add New Vehicle'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomTextField(label: 'Plate Number', controller: plateController, hint: 'e.g., GR-1234-20'),
                  const SizedBox(height: AppSpacing.md),
                  CustomTextField(label: 'Capacity', controller: capacityController, keyboardType: TextInputType.number, hint: 'e.g., 14'),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'active', child: Text('Active')),
                      DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                      DropdownMenuItem(value: 'maintenance', child: Text('Maintenance')),
                    ],
                    onChanged: (value) => setDialogState(() => selectedStatus = value!),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<int>(
                    value: selectedDriverId,
                    decoration: const InputDecoration(labelText: 'Assign Driver (optional)', border: OutlineInputBorder()),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('No driver')),
                      ..._drivers.map((driver) => DropdownMenuItem(
                        value: driver.id,
                        child: Text('${driver.name} (${driver.phone})'),
                      )),
                    ],
                    onChanged: (value) => setDialogState(() => selectedDriverId = value),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
              TextButton(
                onPressed: () {
                  if (plateController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter plate number'), backgroundColor: AppColors.error),
                    );
                    return;
                  }
                  
                  final vehicleData = {
                    'plate_number': plateController.text,
                    'capacity': int.tryParse(capacityController.text) ?? 14,
                    'status': selectedStatus,
                    'driver_id': selectedDriverId,
                  };
                  
                  Navigator.of(context).pop();
                  
                  if (isEditing) {
                    _updateVehicle(vehicle.id, vehicleData);
                  } else {
                    _createVehicle(vehicleData);
                  }
                },
                child: Text(isEditing ? 'Update' : 'Add'),
              ),
            ],
          );
        },
      ),
    );
  }
  
  void _deleteVehicleDialog(Vehicle vehicle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Vehicle?'),
        content: Text('Are you sure you want to delete "${vehicle.plateNumber}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteVehicle(vehicle.id);
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
        title: 'Manage Vehicles',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadVehicles,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditVehicleDialog(),
        backgroundColor: AppColors.accent,
        child: const Icon(Icons.add_outlined, color: AppColors.textInverse),
      ),
      body: _isLoading
          ? const Center(
              child: VehicleDriveLoader(
                message: 'Loading fleet vehicles...',
              ),
            )

          : _error != null
              ? _buildErrorState()
              : _vehicles.isEmpty
                  ? _buildEmptyState()
                  : _buildVehiclesList(),
    );
  }
  
  Widget _buildErrorState() {
    final is401 = _error?.contains('401') == true;
    final message = is401
        ? 'Session expired or invalid permissions.\nLog in as Admin to access vehicle fleet.'
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
                    if (success) _loadVehicles();
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            SizedBox(
              width: 220,
              child: SecondaryButton(
                text: 'Retry',
                onPressed: _loadVehicles,
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
          const Icon(Icons.directions_car_outlined, size: 64, color: AppColors.textTertiary),
          const SizedBox(height: AppSpacing.md),
          Text('No vehicles yet', style: AppTypography.h4.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.sm),
          Text('Add your first vehicle', style: AppTypography.bodySmall),
        ],
      ),
    );
  }
  
  Widget _buildVehiclesList() {
    return RefreshIndicator(
      onRefresh: _loadVehicles,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        itemCount: _vehicles.length,
        itemBuilder: (context, index) {
          final vehicle = _vehicles[index];
          return _VehicleCard(
            vehicle: vehicle,
            onEdit: () => _showAddEditVehicleDialog(vehicle: vehicle),
            onDelete: () => _deleteVehicleDialog(vehicle),
          );
        },
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  
  const _VehicleCard({required this.vehicle, required this.onEdit, required this.onDelete});
  
  @override
  Widget build(BuildContext context) {
    final statusColor = vehicle.status == 'active' 
        ? AppColors.success 
        : vehicle.status == 'maintenance' 
            ? AppColors.warning 
            : AppColors.textTertiary;
    final hasDriver = vehicle.driverId != null;
    
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(AppSpacing.radiusSmall)),
                child: Icon(Icons.directions_car_outlined, color: statusColor, size: AppSpacing.iconMedium),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(vehicle.plateNumber, style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: AppSpacing.xs),
                    Text('Capacity: ${vehicle.capacity} passengers', style: AppTypography.bodySmall),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(AppSpacing.radiusSmall)),
                child: Text(vehicle.status.toUpperCase(), style: AppTypography.labelSmall.copyWith(color: statusColor)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Icon(Icons.person_outlined, size: AppSpacing.iconSmall, color: AppColors.textTertiary),
              const SizedBox(width: AppSpacing.xs),
              Text(
                hasDriver ? 'Driver ID: ${vehicle.driverId}' : 'No driver assigned',
                style: AppTypography.bodySmall.copyWith(color: hasDriver ? AppColors.textPrimary : AppColors.warning),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(icon: const Icon(Icons.edit_outlined, size: AppSpacing.iconMedium), color: AppColors.accent, onPressed: onEdit),
              IconButton(icon: const Icon(Icons.delete_outline, size: AppSpacing.iconMedium), color: AppColors.error, onPressed: onDelete),
            ],
          ),
        ],
      ),
    );
  }
}
