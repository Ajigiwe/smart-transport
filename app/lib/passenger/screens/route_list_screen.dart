import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/services/api_client.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/custom_text_field.dart';
import '../../shared/widgets/animated_loader.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_spacing.dart';
import '../../shared/theme/app_typography.dart';
import 'trip_booking_screen.dart';

final _apiClient = ApiClient();

/// SmartTransport GH Route List Screen
class RouteListScreen extends ConsumerStatefulWidget {
  const RouteListScreen({Key? key}) : super(key: key);
  
  @override
  ConsumerState<RouteListScreen> createState() => _RouteListScreenState();
}

class _RouteListScreenState extends ConsumerState<RouteListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  List<dynamic> _routes = [];
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  Future<void> _loadRoutes() async {
    setState(() => _isLoading = true);
    try {
      _routes = await _apiClient.getRoutes();
    } catch (e) {
      _routes = [];
    }
    setState(() => _isLoading = false);
  }
  
  List<dynamic> get _filteredRoutes {
    if (_searchQuery.isEmpty) return _routes;
    
    return _routes.where((route) {
      final name = route['name'].toString().toLowerCase();
      final startPoint = route['start_point'].toString().toLowerCase();
      final endPoint = route['end_point'].toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      
      return name.contains(query) ||
             startPoint.contains(query) ||
             endPoint.contains(query);
    }).toList();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Routes'),
        backgroundColor: AppColors.surface,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(AppSpacing.screenPaddingHorizontal),
            child: SearchField(
              controller: _searchController,
              hint: 'Search routes...',
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              onClear: () {
                setState(() {
                  _searchQuery = '';
                });
              },
            ),
          ),
          
          // Route List
          Expanded(
            child: _isLoading
                ? const FullScreenLoader(message: 'Loading routes...')
                : _filteredRoutes.isEmpty
                    ? _buildEmptyState()
                    : _buildRouteList(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.route_outlined,
            size: 64,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            _searchQuery.isNotEmpty ? 'No routes found' : 'No routes available',
            style: AppTypography.h4.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try a different search term'
                : 'Check back later for available routes',
            style: AppTypography.bodySmall,
          ),
        ],
      ),
    );
  }
  
  Widget _buildRouteList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.sm,
      ),
      itemCount: _filteredRoutes.length,
      itemBuilder: (context, index) {
        final route = _filteredRoutes[index];
        return _RouteCard(
          route: route,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => TripBookingScreen(route: route),
              ),
            );
          },
        );
      },
    );
  }
}

/// Route Card Widget
class _RouteCard extends StatelessWidget {
  final Map<String, dynamic> route;
  final VoidCallback onTap;
  
  const _RouteCard({
    required this.route,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Route Name
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.ghanaGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                ),
                child: const Icon(
                  Icons.route_outlined,
                  color: AppColors.ghanaGreen,
                  size: AppSpacing.iconMedium,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      route['name'],
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${route['start_point']} → ${route['end_point']}',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.md),
          
          // Route Details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Stops count
              Row(
                children: [
                  const Icon(
                    Icons.stop_circle_outlined,
                    size: AppSpacing.iconSmall,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(width: AppSpacing.xs),                    Text(
                      '${route['stops'] != null ? (route['stops'] as String).split(',').length : 0} stops',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              
              // Fare
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.ghanaGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                ),
                child: Text(
                  'GHS ${route['fare'].toStringAsFixed(2)}',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.ghanaGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.sm),
          
          // View Details Button
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: onTap,
                child: Text(
                  'Book Trip',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.ghanaRed,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
