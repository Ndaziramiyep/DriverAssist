import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver_assist/models/vehicle_model.dart';
import 'package:driver_assist/widgets/vehicle_card.dart';
import 'package:driver_assist/utils/constants.dart';
import 'package:driver_assist/utils/vehicle_constants.dart';
import 'package:driver_assist/services/notification_service.dart';

class VehicleManagementScreen extends StatefulWidget {
  const VehicleManagementScreen({super.key});

  @override
  State<VehicleManagementScreen> createState() => _VehicleManagementScreenState();
}

class _VehicleManagementScreenState extends State<VehicleManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _licensePlateController = TextEditingController();
  final _colorController = TextEditingController();
  final _fuelTypeController = TextEditingController();
  final _fuelCapacityController = TextEditingController();
  final _currentFuelLevelController = TextEditingController();
  final _mileageController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Vehicles'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddVehicleDialog(),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('vehicles')
            .where('userId', isEqualTo: AppConstants.currentUserId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final vehicles = snapshot.data?.docs
              .map((doc) => VehicleModel.fromFirestore(doc))
              .toList() ??
              [];

          if (vehicles.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.directions_car,
                    size: 64,
                    color: theme.colorScheme.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Vehicles Added',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add your first vehicle to get started',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showAddVehicleDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Vehicle'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: vehicles.length,
            itemBuilder: (context, index) {
              final vehicle = vehicles[index];
              return VehicleCard(
                vehicle: vehicle,
                onTap: () => _showVehicleDetails(vehicle),
                onEdit: () => _showEditVehicleDialog(vehicle),
                onDelete: () => _showDeleteConfirmation(vehicle),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddVehicleDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Vehicle'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _makeController,
                    decoration: const InputDecoration(labelText: 'Make'),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Please enter the make';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _modelController,
                    decoration: const InputDecoration(labelText: 'Model'),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Please enter the model';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _yearController,
                    decoration: const InputDecoration(labelText: 'Year'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Please enter the year';
                      }
                      final year = int.tryParse(value!);
                      if (year == null || 
                          year < VehicleConstants.minYear || 
                          year > VehicleConstants.maxYear) {
                        return VehicleConstants.validationMessages['year']!
                            .replaceAll('{minYear}', VehicleConstants.minYear.toString())
                            .replaceAll('{maxYear}', VehicleConstants.maxYear.toString());
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _licensePlateController,
                    decoration: const InputDecoration(labelText: 'License Plate'),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Please enter the license plate';
                      }
                      final format = VehicleConstants.licensePlateFormats[VehicleConstants.defaultCountry];
                      if (format != null && !RegExp(format).hasMatch(value!)) {
                        return VehicleConstants.validationMessages['licensePlate'];
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _colorController,
                    decoration: const InputDecoration(labelText: 'Color'),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Please enter the color';
                      }
                      return null;
                    },
                  ),
                  DropdownButtonFormField<String>(
                    value: _fuelTypeController.text.isEmpty ? null : _fuelTypeController.text,
                    decoration: const InputDecoration(labelText: 'Fuel Type'),
                    items: VehicleConstants.fuelTypes.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        _fuelTypeController.text = value;
                      }
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return VehicleConstants.validationMessages['fuelType'];
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _fuelCapacityController,
                    decoration: const InputDecoration(labelText: 'Fuel Capacity (L)'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Please enter the fuel capacity';
                      }
                      final capacity = double.tryParse(value!);
                      if (capacity == null || capacity <= 0) {
                        return 'Please enter a valid fuel capacity';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _currentFuelLevelController,
                    decoration: const InputDecoration(labelText: 'Current Fuel Level (L)'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Please enter the current fuel level';
                      }
                      final level = double.tryParse(value!);
                      if (level == null || level < 0) {
                        return 'Please enter a valid fuel level';
                      }
                      final capacity = double.tryParse(_fuelCapacityController.text);
                      if (capacity != null && level > capacity) {
                        return VehicleConstants.validationMessages['fuelLevel'];
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _mileageController,
                    decoration: const InputDecoration(labelText: 'Mileage'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Please enter the mileage';
                      }
                      final mileage = int.tryParse(value!);
                      if (mileage == null || mileage < 0) {
                        return 'Please enter a valid mileage';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _addVehicle,
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showEditVehicleDialog(VehicleModel vehicle) {
    _makeController.text = vehicle.make;
    _modelController.text = vehicle.model;
    _yearController.text = vehicle.year.toString();
    _licensePlateController.text = vehicle.licensePlate;
    _colorController.text = vehicle.color;
    _fuelTypeController.text = vehicle.fuelType;
    _fuelCapacityController.text = vehicle.fuelCapacity.toString();
    _currentFuelLevelController.text = vehicle.currentFuelLevel.toString();
    _mileageController.text = vehicle.mileage.toString();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Vehicle'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _makeController,
                    decoration: const InputDecoration(labelText: 'Make'),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Please enter the make';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _modelController,
                    decoration: const InputDecoration(labelText: 'Model'),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Please enter the model';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _yearController,
                    decoration: const InputDecoration(labelText: 'Year'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Please enter the year';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _licensePlateController,
                    decoration: const InputDecoration(labelText: 'License Plate'),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Please enter the license plate';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _colorController,
                    decoration: const InputDecoration(labelText: 'Color'),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Please enter the color';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _fuelTypeController,
                    decoration: const InputDecoration(labelText: 'Fuel Type'),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Please enter the fuel type';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _fuelCapacityController,
                    decoration: const InputDecoration(labelText: 'Fuel Capacity (L)'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Please enter the fuel capacity';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _currentFuelLevelController,
                    decoration: const InputDecoration(labelText: 'Current Fuel Level (L)'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Please enter the current fuel level';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _mileageController,
                    decoration: const InputDecoration(labelText: 'Mileage'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Please enter the mileage';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => _updateVehicle(vehicle),
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  void _showVehicleDetails(VehicleModel vehicle) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                vehicle.fullName,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _buildDetailRow('License Plate', vehicle.licensePlate),
              _buildDetailRow('Color', vehicle.color),
              _buildDetailRow('Fuel Type', vehicle.fuelType),
              _buildDetailRow(
                'Fuel Level',
                '${vehicle.fuelPercentage.toStringAsFixed(1)}%',
              ),
              _buildDetailRow('Mileage', '${vehicle.mileage} km'),
              _buildDetailRow(
                'Last Service',
                '${vehicle.lastServiceDate.day}/${vehicle.lastServiceDate.month}/${vehicle.lastServiceDate.year}',
              ),
              if (vehicle.needsService)
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.orange),
                      const SizedBox(width: 8),
                      Text(
                        'Vehicle needs service',
                        style: TextStyle(
                          color: Colors.orange[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(VehicleModel vehicle) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Vehicle'),
          content: Text(
            'Are you sure you want to delete ${vehicle.fullName}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _deleteVehicle(vehicle);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addVehicle() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final vehicle = VehicleModel(
        id: '', // Will be set by Firestore
        userId: AppConstants.currentUserId,
        make: _makeController.text.trim(),
        model: _modelController.text.trim(),
        year: int.parse(_yearController.text),
        licensePlate: _licensePlateController.text.trim().toUpperCase(),
        color: _colorController.text.trim(),
        fuelType: _fuelTypeController.text.trim(),
        fuelCapacity: double.parse(_fuelCapacityController.text),
        currentFuelLevel: double.parse(_currentFuelLevelController.text),
        mileage: int.parse(_mileageController.text),
        lastServiceDate: DateTime.now(),
        specifications: {},
        serviceHistory: [],
        isDefault: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final docRef = await FirebaseFirestore.instance.collection('vehicles').add(vehicle.toMap());
      await docRef.update({'id': docRef.id});

      // Trigger vehicle added notification
      NotificationService().sendVehicleAddedNotification(
        userId: AppConstants.currentUserId,
        vehicleId: docRef.id,
        vehicleName: vehicle.fullName, // Assuming VehicleModel has a fullName getter
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vehicle added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding vehicle: ${e.toString()}')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateVehicle(VehicleModel vehicle) async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        final updatedVehicle = vehicle.copyWith(
          make: _makeController.text,
          model: _modelController.text,
          year: int.parse(_yearController.text),
          licensePlate: _licensePlateController.text,
          color: _colorController.text,
          fuelType: _fuelTypeController.text,
          fuelCapacity: double.parse(_fuelCapacityController.text),
          currentFuelLevel: double.parse(_currentFuelLevelController.text),
          mileage: int.parse(_mileageController.text),
        );

        await FirebaseFirestore.instance
            .collection('vehicles')
            .doc(vehicle.id)
            .update(updatedVehicle.toMap());

        Navigator.pop(context);
        _clearControllers();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating vehicle: $e')),
        );
      }
    }
  }

  Future<void> _deleteVehicle(VehicleModel vehicle) async {
    try {
      await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(vehicle.id)
          .delete();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting vehicle: $e')),
      );
    }
  }

  void _clearControllers() {
    _makeController.clear();
    _modelController.clear();
    _yearController.clear();
    _licensePlateController.clear();
    _colorController.clear();
    _fuelTypeController.clear();
    _fuelCapacityController.clear();
    _currentFuelLevelController.clear();
    _mileageController.clear();
  }

  @override
  void dispose() {
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _licensePlateController.dispose();
    _colorController.dispose();
    _fuelTypeController.dispose();
    _fuelCapacityController.dispose();
    _currentFuelLevelController.dispose();
    _mileageController.dispose();
    super.dispose();
  }
}