import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/services/api_client.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_spacing.dart';
import '../../shared/theme/app_typography.dart';

final _apiClient = ApiClient();

/// SmartTransport GH Booking Confirmation Screen
class BookingConfirmationScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> route;
  final Map<String, dynamic> trip;
  final int passengers;
  
  const BookingConfirmationScreen({
    Key? key,
    required this.route,
    required this.trip,
    required this.passengers,
  }) : super(key: key);
  
  @override
  ConsumerState<BookingConfirmationScreen> createState() => _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends ConsumerState<BookingConfirmationScreen> {
  bool _isBooking = false;
  bool _bookingSuccess = false;
  
  double get _totalFare => widget.route['fare'] * widget.passengers;
  
  Future<void> _confirmBooking() async {
    setState(() => _isBooking = true);
    try {
      await _apiClient.createBooking(widget.trip['id']);
      setState(() {
        _isBooking = false;
        _bookingSuccess = true;
      });
      if (mounted) _showSuccessDialog();
    } catch (e) {
      setState(() => _isBooking = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
  
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline,
                color: AppColors.success,
                size: 48,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Booking Confirmed!',
              style: AppTypography.h3.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Your trip has been booked successfully.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              text: 'Track Trip',
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            SecondaryButton(
              text: 'Back to Home',
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              isExpanded: false,
            ),
          ],
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Confirm Booking'),
        backgroundColor: AppColors.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPaddingHorizontal),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Route Info
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.passengerColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                        ),
                        child: const Icon(
                          Icons.route_outlined,
                          color: AppColors.passengerColor,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.route['name'],
                              style: AppTypography.bodyLarge.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${widget.route['start_point']} → ${widget.route['end_point']}',
                              style: AppTypography.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            // Trip Details
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trip Details',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  
                  _DetailRow(
                    icon: Icons.person_outlined,
                    label: 'Driver',
                    value: widget.trip['driver_name'],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _DetailRow(
                    icon: Icons.directions_car_outlined,
                    label: 'Vehicle',
                    value: widget.trip['vehicle_plate'],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _DetailRow(
                    icon: Icons.access_time_outlined,
                    label: 'Departure',
                    value: widget.trip['departure_time'],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _DetailRow(
                    icon: Icons.access_time_filled,
                    label: 'Arrival',
                    value: widget.trip['estimated_arrival'],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            // Price Summary
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Price Summary',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  
                  _PriceRow(
                    label: 'Fare per person',
                    value: 'GHS ${widget.route['fare'].toStringAsFixed(2)}',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _PriceRow(
                    label: 'Passengers',
                    value: '× ${widget.passengers}',
                  ),
                  const Divider(height: AppSpacing.lg),
                  _PriceRow(
                    label: 'Total',
                    value: 'GHS ${_totalFare.toStringAsFixed(2)}',
                    isTotal: true,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppSpacing.xl),
            
            // Confirmation Checkbox
            AppCard(
              backgroundColor: AppColors.accent.withOpacity(0.05),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppColors.accent,
                    size: AppSpacing.iconMedium,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Please arrive at the pickup point 5 minutes before departure time.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppSpacing.xl),
            
            // Confirm Button
            PrimaryButton(
              text: 'Confirm Booking',
              isLoading: _isBooking,
              onPressed: _confirmBooking,
              icon: Icons.check_circle_outline,
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            // Cancel Button
            SecondaryButton(
              text: 'Cancel',
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Detail Row Widget
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: AppSpacing.iconSmall,
          color: AppColors.textTertiary,
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          '$label: ',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Price Row Widget
class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;
  
  const _PriceRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });
  
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: (isTotal ? AppTypography.bodyLarge : AppTypography.bodyMedium).copyWith(
            color: AppColors.textPrimary,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: (isTotal ? AppTypography.bodyLarge : AppTypography.bodyMedium).copyWith(
            color: isTotal ? AppColors.accent : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
