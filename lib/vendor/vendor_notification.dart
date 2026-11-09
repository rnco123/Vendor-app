// lib/screens/vendor_notification_settings_screen.dart
import 'package:flutter/material.dart';
import '../app_colors.dart';

class VendorNotificationSettingsScreen extends StatefulWidget {
  const VendorNotificationSettingsScreen({super.key});

  @override
  State<VendorNotificationSettingsScreen> createState() => _VendorNotificationSettingsScreenState();
}

class _VendorNotificationSettingsScreenState extends State<VendorNotificationSettingsScreen> {
  // Ride & Driver Notifications
  bool _newRideAssigned = true;
  bool _rideCompleted = false;
  bool _rideCancelled = false;
  bool _driverAddedRemoved = false;
  bool _driverDocumentExpiry = false;
  
  // Earnings & Payment Notifications
  bool _paymentReceived = true;
  bool _weeklyEarningReport = true;
  bool _withdrawalStatus = true;
  
  // Promotions & System Updates
  bool _promotionalOffers = false;
  bool _systemUpdates = true;
  
  // Sound & Alert Preferences
  bool _notificationSounds = false;
  bool _vibration = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
           backgroundColor: Color(0xFFF9FAFB),
        elevation: 0,
        shape: const Border(
          bottom: BorderSide(
            color: Color.fromARGB(255, 179, 178, 178),
            width: 1,
          ),
        ),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Color.fromRGBO(230, 231, 242, 1),
              borderRadius: BorderRadius.circular(25),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: AppColors.textPrimary,
              size: 16,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
           titleSpacing: 0,
        title: const Text(
          'Notification Settings',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ride & Driver Notifications
            _buildSectionHeader(
              icon: Icons.notifications_outlined,
              title: 'Ride & Driver Notifications',
            ),
            const SizedBox(height: 16),
            _buildNotificationItem(
              title: 'New Ride Assigned',
              description: 'When a new booking is assigned to any driver in the fleet.',
              value: _newRideAssigned,
              onChanged: (value) {
                setState(() {
                  _newRideAssigned = value;
                });
              },
            ),
            _buildNotificationItem(
              title: 'Ride Completed',
              description: 'When a driver successfully completes a ride.',
              value: _rideCompleted,
              onChanged: (value) {
                setState(() {
                  _rideCompleted = value;
                });
              },
            ),
            _buildNotificationItem(
              title: 'Ride Cancelled',
              description: 'If a ride is cancelled by passenger or driver.',
              value: _rideCancelled,
              onChanged: (value) {
                setState(() {
                  _rideCancelled = value;
                });
              },
            ),
            _buildNotificationItem(
              title: 'Driver Added / Removed',
              description: 'When a new driver joins or leaves the company.',
              value: _driverAddedRemoved,
              onChanged: (value) {
                setState(() {
                  _driverAddedRemoved = value;
                });
              },
            ),
            _buildNotificationItem(
              title: 'Driver Document Expiry',
              description: 'Reminder for expiring licenses or vehicle papers.',
              value: _driverDocumentExpiry,
              onChanged: (value) {
                setState(() {
                  _driverDocumentExpiry = value;
                });
              },
            ),
            const SizedBox(height: 24),
            
            // Earnings & Payment Notifications
            _buildSectionHeader(
              icon: Icons.attach_money,
              title: 'Earnings & Payment Notifications',
            ),
            const SizedBox(height: 16),
            _buildNotificationItem(
              title: 'Payment Received',
              description: 'Get notified when a ride payment is successfully reflected in your vendor account.',
              value: _paymentReceived,
              onChanged: (value) {
                setState(() {
                  _paymentReceived = value;
                });
              },
            ),
            _buildNotificationItem(
              title: 'Weekly Earning Report',
              description: 'Summary of total rides, commission, and earnings every week.',
              value: _weeklyEarningReport,
              onChanged: (value) {
                setState(() {
                  _weeklyEarningReport = value;
                });
              },
            ),
            _buildNotificationItem(
              title: 'Withdrawal Status',
              description: 'When withdrawal request is processed or completed.',
              value: _withdrawalStatus,
              onChanged: (value) {
                setState(() {
                  _withdrawalStatus = value;
                });
              },
            ),
            const SizedBox(height: 24),
            
            // Promotions & System Updates
            _buildSectionHeader(
              icon: Icons.card_giftcard_outlined,
              title: 'Promotions & System Updates',
            ),
            const SizedBox(height: 16),
            _buildNotificationItem(
              title: 'Promotional Offers',
              description: 'Discounts or incentives for vendors (e.g., reduced commission week).',
              value: _promotionalOffers,
              onChanged: (value) {
                setState(() {
                  _promotionalOffers = value;
                });
              },
            ),
            _buildNotificationItem(
              title: 'System Updates',
              description: 'App feature changes or maintenance announcements.',
              value: _systemUpdates,
              onChanged: (value) {
                setState(() {
                  _systemUpdates = value;
                });
              },
            ),
            const SizedBox(height: 24),
            
            // Sound & Alert Preferences
            _buildSectionHeader(
              icon: Icons.volume_up_outlined,
              title: 'Sound & Alert Preferences',
            ),
            const SizedBox(height: 16),
            _buildNotificationItem(
              title: 'Notification Sounds',
              description: '',
              value: _notificationSounds,
              onChanged: (value) {
                setState(() {
                  _notificationSounds = value;
                });
              },
            ),
            _buildNotificationItem(
              title: 'Vibration',
              description: '',
              value: _vibration,
              onChanged: (value) {
                setState(() {
                  _vibration = value;
                });
              },
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppColors.primary,
          size: 22,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationItem({
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool isLast = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: isLast 
              ? BorderSide.none 
              : BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          Switch(
            value: value,
            onChanged: onChanged,
             activeColor: const Color(0xFFF9FAFB),
            activeTrackColor: AppColors.primary,
            inactiveThumbColor: const Color(0xFFF9FAFB),
            inactiveTrackColor: const Color(0xFFE8E8E8),
          ),
        ],
      ),
    );
  }
}