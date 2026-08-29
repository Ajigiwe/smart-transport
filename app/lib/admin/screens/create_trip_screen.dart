import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/services/auth_provider.dart';
import '../../shared/models/route.dart';
import '../../shared/models/user.dart';
import '../../shared/models/vehicle.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_spacing.dart';
import '../../shared/theme/app_typography.dart';
import '../../shared/widgets/premium_app_bar.dart';

/// SmartTransport GH Create Trip Screen (Admin)
class CreateTripScreen extends ConsumerStatefulWidget {
  const CreateTripScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends ConsumerState<CreateTripScreen> {
  int? _selectedRouteId;
  int? _selectedDriverId;
  int? _selectedVehicleId;
  String _selectedStatus = 'scheduled';

  List<AppRoute> _routes = [];
  List<User> _drivers = [];
  List<Vehicle> _vehicles = [];
  bool _isLoading = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final routesData = await apiClient.getRoutes();
      final driversData = await apiClient.getUsers(role: 'driver');
      final vehiclesData = await apiClient.getVehicles();

      setState(() {
        _routes = routesData.map((json) => AppRoute.fromJson(json)).toList();
        _drivers = driversData.map((json) => User.fromJson(json)).toList();
        _vehicles = vehiclesData.map((json) => Vehicle.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load data: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _createTrip() async {
    if (_selectedRouteId == null || _selectedDriverId == null || _selectedVehicleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select route, driver, and vehicle'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.createTrip({
        'route_id': _selectedRouteId,
        'driver_id': _selectedDriverId,
        'vehicle_id': _selectedVehicleId,
        'status': _selectedStatus,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trip created successfully'), backgroundColor: AppColors.success),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create trip: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PremiumAppBar(
        title: 'Create Trip',
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.screenPaddingHorizontal),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.lg),

                  // Route Selection
                  Text('Route', style: AppTypography.labelLarge.copyWith(color: AppColors.textPrimary)),
                  const SizedBox(height: AppSpacing.sm),
                  DropdownButtonFormField<int>(
                    value: _selectedRouteId,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Select a route',
                    ),
                    items: _routes.map((route) => DropdownMenuItem(
                      value: route.id,
                      child: Text('${route.name} (${route.startPoint} → ${route.endPoint})'),
                    )).toList(),
                    onChanged: (value) => setState(() => _selectedRouteId = value),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Driver Selection
                  Text('Driver', style: AppTypography.labelLarge.copyWith(color: AppColors.textPrimary)),
                  const SizedBox(height: AppSpacing.sm),
                  DropdownButtonFormField<int>(
                    value: _selectedDriverId,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Select a driver',
                    ),
                    items: _drivers.map((driver) => DropdownMenuItem(
                      value: driver.id,
                      child: Text('${driver.name} (${driver.phone})'),
                    )).toList(),
                    onChanged: (value) => setState(() => _selectedDriverId = value),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Vehicle Selection
                  Text('Vehicle', style: AppTypography.labelLarge.copyWith(color: AppColors.textPrimary)),
                  const SizedBox(height: AppSpacing.sm),
                  DropdownButtonFormField<int>(
                    value: _selectedVehicleId,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Select a vehicle',
                    ),
                    items: _vehicles.where((v) => v.status == 'active').map((vehicle) => DropdownMenuItem(
                      value: vehicle.id,
                      child: Text('${vehicle.plateNumber} (Capacity: ${vehicle.capacity})'),
                    )).toList(),
                    onChanged: (value) => setState(() => _selectedVehicleId = value),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Status Selection
                  Text('Status', style: AppTypography.labelLarge.copyWith(color: AppColors.textPrimary)),
                  const SizedBox(height: AppSpacing.sm),
                  DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'scheduled', child: Text('Scheduled')),
                      DropdownMenuItem(value: 'active', child: Text('Active')),
                    ],
                    onChanged: (value) => setState(() => _selectedStatus = value!),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Create Button
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _createTrip,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.textInverse,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMedium)),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: AppColors.textInverse, strokeWidth: 2))
                          : Text('Create Trip', style: AppTypography.labelLarge.copyWith(color: AppColors.textInverse)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
