// import 'package:flutter/material.dart';

// class AppColors {
//   // Primary brand color
//   static const Color primary = Color(0xFF1B5E56);
  
//   // Background colors
//   static const Color background = Color(0xFFF8F9FA);
//   static const Color cardBackground = Colors.white;
//   static const Color inputBackground = Color(0xFFF5F5F5);
  
//   // Text colors
//   static const Color textPrimary = Color(0xFF1A1A1A);
//   static const Color textSecondary = Color(0xFF6B7280);
//   static const Color textHint = Color(0xFFB0B0B0);
  
//   // Role card colors
//   static const Color passengerCardBg = Color(0xFFE8F5E9);
//   static const Color passengerCardBorder = Color(0xFF66BB6A);
//   static const Color driverCardBg = Color(0xFFFFF8E1);
//   static const Color driverCardBorder = Color(0xFFFFB300);
//   static const Color vendorCardBg = Color(0xFFE3F2FD);
//   static const Color vendorCardBorder = Color(0xFF42A5F5);
  
//   // Status colors
//   static const Color success = Color(0xFF4CAF50);
//   static const Color warning = Color(0xFFFF9800);
//   static const Color error = Color(0xFFF44336);
//   static const Color info = Color(0xFF2196F3);
  
//   // Notification icon colors
//   static const Color rideConfirmedBg = Color(0xFF2196F3);
//   static const Color paymentSuccessBg = Color(0xFF4CAF50);
//   static const Color rideUpdateBg = Color(0xFF2196F3);
//   static const Color specialOfferBg = Color(0xFFFF9800);
//   static const Color rateRideBg = Color(0xFFFFB300);
  
//   // Other colors
//   static const Color divider = Color(0xFFE0E0E0);
//   static const Color shadow = Color(0x1A000000);
  
import 'package:flutter/material.dart';

const double kBottomNavBottomGap = 8;

class AppColors {
  // Primary brand color - vibrant green from image
  static const Color primary = Color(0xFF06C167);
  
  // Background colors - dark theme
  static const Color background = Color(0xFF111111);
  static const Color cardBackground = Color(0xFF161616);
  static const Color inputBackground = Color(0xFF161616);
  
  // Text colors - dark theme
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF808080);
  static const Color textHint = Color(0xFFCCCCCC);
  
  // Role card colors - dark theme variants
  static const Color passengerCardBg = Color(0xFF1A2E1A);
  static const Color passengerCardBorder = Color(0xFF06C167);
  static const Color driverCardBg = Color(0xFF2E2A1A);
  static const Color driverCardBorder = Color(0xFFD4A017);
  static const Color vendorCardBg = Color(0xFF1A2E2E);
  static const Color vendorCardBorder = Color(0xFF17A2D4);
  
  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);
  
  // Notification icon colors
  static const Color rideConfirmedBg = Color(0xFF2196F3); // Blue
  static const Color paymentSuccessBg = Color(0xFF4CAF50); // Green
  static const Color rideUpdateBg = Color(0xFF2196F3); // Blue
  static const Color specialOfferBg = Color(0xFFFF9800); // Orange
  static const Color rateRideBg = Color(0xFFFFB300); // Yellow/Gold
  
  // Payment method colors - dark theme
  static const Color selectedPaymentBg = Color(0xFF1A2E1A); // Dark green
  static const Color selectedPaymentBorder = Color(0xFF06C167); // Primary color
  static const Color unselectedPaymentBg = Color(0xFF161616);
  static const Color unselectedPaymentBorder = Color(0xFF1F1F1F);
  
  // Other colors - dark theme
  static const Color divider = Color(0xFF1F1F1F);
  static const Color shadow = Color(0x4D000000);
  
  // Transparent
  static const Color transparent = Colors.transparent;
}