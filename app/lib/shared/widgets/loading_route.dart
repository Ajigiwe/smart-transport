import 'package:flutter/material.dart';
import '../widgets/animated_loader.dart';
import '../theme/app_colors.dart';

/// Custom page route that shows the VehicleDriveLoader during transitions.
/// Use [navigateWithLoader] for a simpler API.
class LoadingPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final String? loadingMessage;

  LoadingPageRoute({
    required this.page,
    this.loadingMessage,
    super.settings,
  }) : super(
          transitionDuration: const Duration(milliseconds: 600),
          reverseTransitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final fadeTween = Tween<double>(begin: 0.0, end: 1.0).chain(
              CurveTween(curve: const Interval(0.3, 1.0, curve: Curves.easeOut)),
            );

            final slideTween = Tween<Offset>(
              begin: const Offset(0.05, 0.0),
              end: Offset.zero,
            ).chain(CurveTween(curve: const Interval(0.3, 1.0, curve: Curves.easeOut)));

            return FadeTransition(
              opacity: animation.drive(fadeTween),
              child: SlideTransition(
                position: animation.drive(slideTween),
                child: child,
              ),
            );
          },
        );
}

/// Navigates to [page] with the VehicleDriveLoader shown during the transition.
///
/// The loader displays for [loadingDuration] before revealing the target page.
/// If [replace] is true, uses pushReplacement instead of push.
Future<T?> navigateWithLoader<T>(
  BuildContext context, {
  required Widget page,
  String? loadingMessage,
  Duration loadingDuration = const Duration(milliseconds: 1400),
  bool replace = false,
  bool Function(Route)? predicate,
}) async {
  // Show the loader as a full-screen overlay
  final overlay = Overlay.of(context);
  final overlayEntry = OverlayEntry(
    builder: (_) => _LoaderOverlay(message: loadingMessage),
  );
  overlay.insert(overlayEntry);

  // Wait for the loading duration
  await Future.delayed(loadingDuration);

  // Remove the overlay
  overlayEntry.remove();

  // Guard against navigation after dispose
  if (!context.mounted) return null;

  // Navigate to the actual page
  if (replace) {
    return Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => page),
    );
  } else if (predicate != null) {
    return Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => page),
      predicate,
    );
  } else {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => page),
    );
  }
}

/// The full-screen loader overlay shown during navigation
class _LoaderOverlay extends StatefulWidget {
  final String? message;

  const _LoaderOverlay({this.message});

  @override
  State<_LoaderOverlay> createState() => _LoaderOverlayState();
}

class _LoaderOverlayState extends State<_LoaderOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeIn;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _fadeIn = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _opacity = CurvedAnimation(parent: _fadeIn, curve: Curves.easeIn);
    _fadeIn.forward();
  }

  @override
  void dispose() {
    _fadeIn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Material(
        color: AppColors.background,
        child: Center(
          child: VehicleDriveLoader(
            width: 240,
            height: 130,
            message: widget.message ?? 'Loading...',
          ),
        ),
      ),
    );
  }
}
