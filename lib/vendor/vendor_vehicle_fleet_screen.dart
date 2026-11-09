// // lib/screens/vendor_vehicle_fleet_screen.dart
// import 'package:flutter/material.dart';
// import '../app_colors.dart';
// import 'vendor_drivers_screen.dart';

// class VendorVehicleFleetScreen extends StatefulWidget {
//   const VendorVehicleFleetScreen({super.key});

//   @override
//   State<VendorVehicleFleetScreen> createState() => _VendorVehicleFleetScreenState();
// }

// class _VendorVehicleFleetScreenState extends State<VendorVehicleFleetScreen> {
//   final List<VehicleData> _vehicles = [];

//   void _addVehicle() {
//     setState(() {
//       _vehicles.add(VehicleData());
//     });
//   }

//   void _removeVehicle(int index) {
//     setState(() {
//       _vehicles.removeAt(index);
//     });
//   }

//   @override
//   void initState() {
//     super.initState();
//     _addVehicle(); // Add first vehicle by default
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF9FAFB),
//       appBar: AppBar(
//             backgroundColor: Color(0xFFF9FAFB),
//         elevation: 0,
//         shape: const Border(
//           bottom: BorderSide(
//             color: Color.fromARGB(255, 179, 178, 178),
//             width: 1,
//           ),
//         ),
//            titleSpacing: 0,
//         leading: IconButton(
//           icon: Container(
//             padding: const EdgeInsets.all(6),
//             decoration: BoxDecoration(
//               color: Color.fromRGBO(230, 231, 242, 1),
//               borderRadius: BorderRadius.circular(25),
//             ),
//             child: const Icon(
//               Icons.arrow_back_ios_new,
//               color: AppColors.textPrimary,
//               size: 16,
//             ),
//           ),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: const Text(
//           'Vendor Profile Setup',
//           style: TextStyle(
//             color: AppColors.textPrimary,
//             fontSize: 18,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//       ),
//       body: ListView(
//         padding: const EdgeInsets.all(24),
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               const Text(
//                 'Vehicle Fleet Details',
//                 style: TextStyle(
//                   fontSize: 24,
//                   fontWeight: FontWeight.bold,
//                   color: AppColors.primary,
//                 ),
//               ),
//               // ← Changed: smaller container (36×36) and icon size (18)
//               Container(
//                 width: 36,
//                 height: 36,
//                 decoration: const BoxDecoration(
//                   color: AppColors.primary,
//                   shape: BoxShape.circle,
//                 ),
//                 child: IconButton(
//                   icon: const Icon(Icons.add, color: Colors.white, size: 18),
//                   onPressed: _addVehicle,
//                   padding: EdgeInsets.zero,
//                 ),
//               ),
//             ],
//           ),
//           const Divider(), // ← Added: divider below heading
//           const SizedBox(height: 32),
//           ..._vehicles.asMap().entries.map((entry) {
//             return _buildVehicleCard(entry.key, entry.value);
//           }).toList(),
//           const SizedBox(height: 40),
//           SizedBox(
//             width: double.infinity,
//             height: 56,
//             child: ElevatedButton(
//               onPressed: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) => const VendorDriversScreen(),
//                   ),
//                 );
//               },
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: AppColors.primary,
//                 foregroundColor: Colors.white,
//                 elevation: 0,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(28),
//                 ),
//               ),
//               child: const Text(
//                 'Next',
//                 style: TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildVehicleCard(int index, VehicleData vehicle) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 24),
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: const Color(0xFFF0F2F5), // ← Changed: grey background (was Colors.white)
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all( // ← Added: visible border
//           color: Colors.grey.shade300,
//           width: 1.5,
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withValues(alpha: 0.04),
//             blurRadius: 10,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 'Vehicle ${index + 1}',
//                 style: const TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                   color: AppColors.primary,
//                 ),
//               ),
//               Container(
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: IconButton(
//                   icon: const Icon(Icons.delete_outline, color: AppColors.textPrimary),
//                   onPressed: () => _removeVehicle(index),
//                   padding: const EdgeInsets.all(8),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 20),
//           _buildDropdownField(
//             label: 'Vehicle Type',
//             hint: 'Select vehicle type',
//             value: vehicle.type,
//             items: ['Sedan', 'SUV', 'Van', 'Minibus', 'Luxury Car'],
//             onChanged: (value) {
//               setState(() {
//                 vehicle.type = value;
//               });
//             },
//           ),
//           const SizedBox(height: 16),
//           _buildTextField(
//             label: 'Model',
//             hint: 'Enter vehicle model',
//             controller: vehicle.modelController,
//           ),
//           const SizedBox(height: 16),
//           _buildTextField(
//             label: 'Year',
//             hint: 'Enter manufacturing year',
//             controller: vehicle.yearController,
//             keyboardType: TextInputType.number,
//           ),
//           const SizedBox(height: 16),
//           _buildTextField(
//             label: 'Passenger Capacity',
//             hint: 'Enter passenger capacity',
//             controller: vehicle.capacityController,
//             keyboardType: TextInputType.number,
//           ),
//           const SizedBox(height: 16),
//           _buildTextField(
//             label: 'License Plate',
//             hint: 'Enter license plate number',
//             controller: vehicle.licensePlateController,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTextField({
//     required String label,
//     required String hint,
//     required TextEditingController controller,
//     TextInputType? keyboardType,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: const TextStyle(
//             fontSize: 14,
//             fontWeight: FontWeight.w500,
//             color: AppColors.textPrimary,
//           ),
//         ),
//         const SizedBox(height: 8),
//         TextField(
//           controller: controller,
//           keyboardType: keyboardType,
//           style: const TextStyle(
//             fontSize: 15,
//             color: AppColors.textPrimary,
//           ),
//           decoration: InputDecoration(
//             hintText: hint,
//             hintStyle: const TextStyle(
//               fontSize: 15,
//               color: AppColors.textSecondary,
//             ),
//             filled: true,
//             fillColor: Colors.white,
//             contentPadding: const EdgeInsets.symmetric(
//               horizontal: 16,
//               vertical: 16,
//             ),
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: BorderSide(
//                 color: Colors.grey.shade200,
//                 width: 1,
//               ),
//             ),
//             enabledBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: BorderSide(
//                 color: Colors.grey.shade200,
//                 width: 1,
//               ),
//             ),
//             focusedBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: const BorderSide(
//                 color: AppColors.primary,
//                 width: 1.5,
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildDropdownField({
//     required String label,
//     required String hint,
//     required String? value,
//     required List<String> items,
//     required ValueChanged<String?> onChanged,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: const TextStyle(
//             fontSize: 14,
//             fontWeight: FontWeight.w500,
//             color: AppColors.textPrimary,
//           ),
//         ),
//         const SizedBox(height: 8),
//         DropdownButtonFormField<String>(
//           value: value,
//           decoration: InputDecoration(
//             hintText: hint,
//             hintStyle: const TextStyle(
//               fontSize: 15,
//               color: AppColors.textSecondary,
//             ),
//             filled: true,
//             fillColor: Colors.white,
//             contentPadding: const EdgeInsets.symmetric(
//               horizontal: 16,
//               vertical: 16,
//             ),
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: BorderSide(
//                 color: Colors.grey.shade200,
//                 width: 1,
//               ),
//             ),
//             enabledBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: BorderSide(
//                 color: Colors.grey.shade200,
//                 width: 1,
//               ),
//             ),
//             focusedBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: const BorderSide(
//                 color: AppColors.primary,
//                 width: 1.5,
//               ),
//             ),
//           ),
//           icon: const Icon(
//             Icons.keyboard_arrow_down,
//             color: AppColors.textSecondary,
//           ),
//           items: items.map((item) {
//             return DropdownMenuItem(
//               value: item,
//               child: Text(
//                 item,
//                 style: const TextStyle(
//                   fontSize: 15,
//                   color: AppColors.textPrimary,
//                 ),
//               ),
//             );
//           }).toList(),
//           onChanged: onChanged,
//         ),
//       ],
//     );
//   }
// }

// class VehicleData {
//   String? type;
//   final TextEditingController modelController = TextEditingController();
//   final TextEditingController yearController = TextEditingController();
//   final TextEditingController capacityController = TextEditingController();
//   final TextEditingController licensePlateController = TextEditingController();
// }


import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../app_colors.dart';
import 'vendor_drivers_screen.dart';

class VendorVehicleFleetScreen extends StatefulWidget {
  const VendorVehicleFleetScreen({super.key});

  @override
  State<VendorVehicleFleetScreen> createState() =>
      _VendorVehicleFleetScreenState();
}

class _VendorVehicleFleetScreenState
    extends State<VendorVehicleFleetScreen> {
  final List<VehicleData> _vehicles = [];
  bool _isSaving = false;

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _addVehicle(); // default first vehicle
  }

  void _addVehicle() {
    setState(() => _vehicles.add(VehicleData()));
  }

  void _removeVehicle(int index) {
    final removed = _vehicles.removeAt(index);
    removed.dispose();
    setState(() {});
  }

  @override
  void dispose() {
    for (final v in _vehicles) {
      v.dispose();
    }
    super.dispose();
  }

  // ── Save fleet to vendors/{uid}/vehicles subcollection ────────────────
  Future<void> _saveAndNext() async {
    // Validate all vehicles have at least a model and plate
    for (int i = 0; i < _vehicles.length; i++) {
      final v = _vehicles[i];
      if (v.modelController.text.trim().isEmpty) {
        _showSnack('Vehicle ${i + 1}: please enter a model');
        return;
      }
      if (v.licensePlateController.text.trim().isEmpty) {
        _showSnack('Vehicle ${i + 1}: please enter a license plate');
        return;
      }
      if (v.type == null) {
        _showSnack('Vehicle ${i + 1}: please select a vehicle type');
        return;
      }
    }

    setState(() => _isSaving = true);

    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) {
        _showSnack('Not logged in');
        setState(() => _isSaving = false);
        return;
      }

      final batch = _firestore.batch();

      // Update vendor doc profile step
      final vendorRef = _firestore.collection('vendors').doc(uid);
      batch.update(vendorRef, {
        'profile_step': 'fleet_complete',
        'total_vehicles': _vehicles.length,
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Write each vehicle to subcollection vendors/{uid}/vehicles/{auto}
      for (final vehicle in _vehicles) {
        final vehicleRef =
            vendorRef.collection('vehicles').doc();
        batch.set(vehicleRef, {
          'vendor_id': uid,
          'type': vehicle.type ?? '',
          'model': vehicle.modelController.text.trim(),
          'year': vehicle.yearController.text.trim(),
          'seating_capacity': int.tryParse(
                  vehicle.capacityController.text.trim()) ??
              0,
          'plate_number':
              vehicle.licensePlateController.text.trim().toUpperCase(),
          'is_active': true,
          'created_at': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      if (mounted) {
        setState(() => _isSaving = false);
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const VendorDriversScreen()),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      _showSnack('Error saving: $e');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9FAFB),
        elevation: 0,
        shape: const Border(
          bottom: BorderSide(
            color: Color.fromARGB(255, 179, 178, 178),
            width: 1,
          ),
        ),
        titleSpacing: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(230, 231, 242, 1),
              borderRadius: BorderRadius.circular(25),
            ),
            child: const Icon(Icons.arrow_back_ios_new,
                color: AppColors.textPrimary, size: 16),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Vendor Profile Setup',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Vehicle Fleet Details',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.add,
                      color: Colors.white, size: 18),
                  onPressed: _addVehicle,
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 32),
          ..._vehicles.asMap().entries.map((entry) {
            return _buildVehicleCard(entry.key, entry.value);
          }),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveAndNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor:
                    AppColors.primary.withValues(alpha: 0.6),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28)),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                  : const Text('Next',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard(int index, VehicleData vehicle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Vehicle ${index + 1}',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary)),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: AppColors.textPrimary),
                  onPressed: () => _removeVehicle(index),
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildDropdownField(
            label: 'Vehicle Type',
            hint: 'Select vehicle type',
            value: vehicle.type,
            items: ['Sedan', 'SUV', 'Van', 'Minibus', 'Luxury Car'],
            onChanged: (value) =>
                setState(() => vehicle.type = value),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Model',
            hint: 'Enter vehicle model',
            controller: vehicle.modelController,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Year',
            hint: 'Enter manufacturing year',
            controller: vehicle.yearController,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Passenger Capacity',
            hint: 'Enter passenger capacity',
            controller: vehicle.capacityController,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'License Plate',
            hint: 'Enter license plate number',
            controller: vehicle.licensePlateController,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        TextField(
          cursorColor: AppColors.primary,
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(
              fontSize: 15, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
                fontSize: 15, color: AppColors.textSecondary),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: Colors.grey.shade200, width: 1)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: Colors.grey.shade200, width: 1)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                    color: AppColors.primary, width: 1.5)),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
                fontSize: 15, color: AppColors.textSecondary),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: Colors.grey.shade200, width: 1)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: Colors.grey.shade200, width: 1)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                    color: AppColors.primary, width: 1.5)),
          ),
          icon: const Icon(Icons.keyboard_arrow_down,
              color: AppColors.textSecondary),
          items: items
              .map((item) => DropdownMenuItem(
                  value: item,
                  child: Text(item,
                      style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.textPrimary))))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

// ── Vehicle data model ────────────────────────────────────────────────────
class VehicleData {
  String? type;
  final TextEditingController modelController = TextEditingController();
  final TextEditingController yearController = TextEditingController();
  final TextEditingController capacityController =
      TextEditingController();
  final TextEditingController licensePlateController =
      TextEditingController();

  void dispose() {
    modelController.dispose();
    yearController.dispose();
    capacityController.dispose();
    licensePlateController.dispose();
  }
}
