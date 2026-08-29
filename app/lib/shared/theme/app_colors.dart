import 'package:flutter/material.dart';

/// SmartTransport GH Premium Color Palette
/// Palette: Modern Dark Slate, Ghana Emerald, Radiant Amber, Crimson Accent
class AppColors {
  // Slate Dark Base Colors (Premium Modern Feel)
  static const Color primary = Color(0xFF0F172A); // Deep Slate
  static const Color primaryLight = Color(0xFF1E293B); // Muted Slate
  static const Color primaryDark = Color(0xFF020617); // Pitch Dark
  
  // Ghana Flag Inspired Vibrant Accents
  static const Color ghanaRed = Color(0xFFE11D48); // Rose-tinted Crimson
  static const Color ghanaGold = Color(0xFFF59E0B); // Amber Gold
  static const Color ghanaGreen = Color(0xFF10B981); // Emerald Green
  
  // Dynamic Accent Tokens
  static const Color accent = Color(0xFFF59E0B);
  static const Color accentLight = Color(0xFFFDE68A);
  static const Color accentDark = Color(0xFFD97706);
  
  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFE11D48);
  static const Color info = Color(0xFF3B82F6);
  
  // Background & Surface Colors
  static const Color background = Color(0xFFF8FAFC); // Slate 50
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  
  // Glassmorphic Overlay Tokens
  static const Color glassSurface = Color(0xCCFFFFFF);
  static const Color glassBorder = Color(0x1F000000);
  static const Color glassDarkSurface = Color(0xCC0F172A);
  
  // Text Hierarchy Colors
  static const Color textPrimary = Color(0xFF0F172A); // Deep Charcoal
  static const Color textSecondary = Color(0xFF475569); // Slate 600
  static const Color textTertiary = Color(0xFF94A3B8); // Slate 400
  static const Color textInverse = Color(0xFFFFFFFF);
  
  // Border & Divider Colors
  static const Color border = Color(0xFFE2E8F0); // Slate 200
  static const Color borderLight = Color(0xFFF1F5F9); // Slate 100
  static const Color borderFocused = Color(0xFFF59E0B); // Amber Glow
  
  // Shadow & Ambient Glow Colors
  static const Color shadow = Color(0x0F0F172A);
  static const Color shadowMedium = Color(0x1E0F172A);
  static const Color glowGold = Color(0x35F59E0B);
  static const Color glowEmerald = Color(0x3510B981);
  static const Color glowRed = Color(0x35E11D48);
  
  // Role Specific Palette Tones
  static const Color passengerColor = Color(0xFF10B981); // Emerald
  static const Color driverColor = Color(0xFFE11D48); // Crimson
  static const Color adminColor = Color(0xFF0F172A); // Deep Slate
  
  // Premium Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient accentGradient = LinearGradient(
    colors: [ghanaGold, Color(0xFFFBBF24)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient emeraldGradient = LinearGradient(
    colors: [ghanaGreen, Color(0xFF34D399)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient crimsonGradient = LinearGradient(
    colors: [ghanaRed, Color(0xFFFB7185)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient heroGradient = LinearGradient(
    colors: [primaryDark, primary, Color(0xFF1E293B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

