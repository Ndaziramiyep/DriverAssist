import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:driver_assist/models/vehicle_model.dart';
import 'package:driver_assist/models/service_history_model.dart';
import 'package:driver_assist/utils/constants.dart';
import 'package:uuid/uuid.dart';
import 'package:driver_assist/services/notification_service.dart';

class ServiceHistoryScreen extends StatefulWidget {
  const ServiceHistoryScreen({super.key});

  @override
  State<ServiceHistoryScreen> createState() => _ServiceHistoryScreenState();
}

class _ServiceHistoryScreenState extends State<ServiceHistoryScreen> {
  List<VehicleModel> _vehicles = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchVehicles();
  }

  Future<void> _fetchVehicles() async {
    final userId = AppConstants.currentUserId;
    final snapshot = await FirebaseFirestore.instance
        .collection('vehicles')
        .where('userId', isEqualTo: userId)
        .get();
    setState(() {
      _vehicles = snapshot.docs.map((doc) => VehicleModel.fromFirestore(doc)).toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Service History'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _vehicles.isEmpty
              ? const Center(child: Text('No vehicles found.'))
              : ListView.builder(
                  itemCount: _vehicles.length,
                  itemBuilder: (context, index) {
                    final vehicle = _vehicles[index];
                    return ExpansionTile(
                      title: Text(vehicle.fullName),
                      children: [
                        _VehicleServiceHistoryList(vehicle: vehicle),
                      ],
                    );
                  },
                ),
      floatingActionButton: _vehicles.isEmpty
          ? null
          : FloatingActionButton(
              onPressed: () => _showAddServiceDialog(context),
              tooltip: 'Add Service Record',
              child: const Icon(Icons.add),
            ),
    );
  }

  void _showAddServiceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _AddServiceDialog(vehicles: _vehicles),
    );
  }
}

class _VehicleServiceHistoryList extends StatelessWidget {
  final VehicleModel vehicle;
  const _VehicleServiceHistoryList({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('service_history')
          .where('vehicleId', isEqualTo: vehicle.id)
          .orderBy('serviceDate', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: \\${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final services = snapshot.data?.docs
                .map((doc) => ServiceHistoryModel.fromFirestore(doc))
                .toList() ??
            [];
        if (services.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text('No service history.'),
          );
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: services.length,
          itemBuilder: (context, index) {
            final service = services[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16, left: 8, right: 8),
              child: ListTile(
                title: Text(service.serviceType),
                subtitle: Text('Provider: \\${service.serviceProviderName}\nDate: \\${service.serviceDate.toLocal().toString().split(' ')[0]}'),
                onTap: () => _showServiceDetails(context, service),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      tooltip: 'Edit',
                      onPressed: () => _showEditServiceDialog(context, service),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      tooltip: 'Delete',
                      onPressed: () => _confirmDelete(context, service),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showServiceDetails(BuildContext context, ServiceHistoryModel service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(service.serviceType),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Provider: \\${service.serviceProviderName}'),
            Text('Date: \\${service.serviceDate}'),
            Text('Cost: \\${service.cost}'),
            Text('Mileage: \\${service.mileage} km'),
            Text('Description: \\${service.description}'),
            if (service.notes != null) Text('Notes: \\${service.notes}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showEditServiceDialog(BuildContext context, ServiceHistoryModel service) {
    showDialog(
      context: context,
      builder: (context) => _EditServiceDialog(service: service, vehicle: vehicle),
    );
  }

  void _confirmDelete(BuildContext context, ServiceHistoryModel service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Service Record'),
        content: const Text('Are you sure you want to delete this service record?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('service_history').doc(service.id).delete();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _AddServiceDialog extends StatefulWidget {
  final List<VehicleModel> vehicles;
  const _AddServiceDialog({required this.vehicles});

  @override
  State<_AddServiceDialog> createState() => _AddServiceDialogState();
}

class _AddServiceDialogState extends State<_AddServiceDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedVehicleId;
  String _serviceType = '';
  String _providerName = '';
  String _description = '';
  String _cost = '';
  String _mileage = '';
  DateTime _serviceDate = DateTime.now();
  String _notes = '';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Service Record'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedVehicleId,
                items: widget.vehicles
                    .map((v) => DropdownMenuItem(
                          value: v.id,
                          child: Text(v.fullName),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => _selectedVehicleId = val),
                decoration: const InputDecoration(labelText: 'Vehicle'),
                validator: (val) => val == null ? 'Select vehicle' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Service Type'),
                onChanged: (val) => _serviceType = val,
                validator: (val) => val == null || val.isEmpty ? 'Enter service type' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Provider Name'),
                onChanged: (val) => _providerName = val,
                validator: (val) => val == null || val.isEmpty ? 'Enter provider name' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Description'),
                onChanged: (val) => _description = val,
                validator: (val) => val == null || val.isEmpty ? 'Enter description' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Cost'),
                keyboardType: TextInputType.number,
                onChanged: (val) => _cost = val,
                validator: (val) => val == null || val.isEmpty ? 'Enter cost' : null,
                enabled: false,
                initialValue: 'Coming soon - Payment integration will be available in a future update',
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Mileage'),
                keyboardType: TextInputType.number,
                onChanged: (val) => _mileage = val,
                validator: (val) => val == null || val.isEmpty ? 'Enter mileage' : null,
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Service Date: \\${_serviceDate.toLocal().toString().split(' ')[0]}'),
                trailing: Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _serviceDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _serviceDate = picked);
                },
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Notes (optional)'),
                onChanged: (val) => _notes = val,
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
          onPressed: _submit,
          child: const Text('Add'),
        ),
      ],
    );
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final id = const Uuid().v4();
    final service = ServiceHistoryModel(
      id: id,
      vehicleId: _selectedVehicleId!,
      serviceType: _serviceType,
      description: _description,
      serviceDate: _serviceDate,
      cost: double.tryParse(_cost) ?? 0.0,
      serviceProviderId: '',
      serviceProviderName: _providerName,
      mileage: int.tryParse(_mileage) ?? 0,
      attachments: [],
      notes: _notes.isEmpty ? null : _notes,
      isCompleted: true,
    );
    await FirebaseFirestore.instance.collection('service_history').doc(id).set(service.toMap());

    // Send notification
    final notificationService = context.read<NotificationService>();
    await notificationService.sendServiceHistoryNotification(
      userId: AppConstants.currentUserId,
      vehicleId: service.vehicleId,
      serviceType: service.serviceType,
    );

    Navigator.pop(context);
  }
}

class _EditServiceDialog extends StatefulWidget {
  final ServiceHistoryModel service;
  final VehicleModel vehicle;
  const _EditServiceDialog({required this.service, required this.vehicle});

  @override
  State<_EditServiceDialog> createState() => _EditServiceDialogState();
}

class _EditServiceDialogState extends State<_EditServiceDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _serviceType;
  late String _providerName;
  late String _description;
  late String _cost;
  late String _mileage;
  late DateTime _serviceDate;
  late String _notes;

  @override
  void initState() {
    super.initState();
    _serviceType = widget.service.serviceType;
    _providerName = widget.service.serviceProviderName;
    _description = widget.service.description;
    _cost = widget.service.cost.toString();
    _mileage = widget.service.mileage.toString();
    _serviceDate = widget.service.serviceDate;
    _notes = widget.service.notes ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Service Record'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: _serviceType,
                decoration: const InputDecoration(labelText: 'Service Type'),
                onChanged: (val) => _serviceType = val,
                validator: (val) => val == null || val.isEmpty ? 'Enter service type' : null,
              ),
              TextFormField(
                initialValue: _providerName,
                decoration: const InputDecoration(labelText: 'Provider Name'),
                onChanged: (val) => _providerName = val,
                validator: (val) => val == null || val.isEmpty ? 'Enter provider name' : null,
              ),
              TextFormField(
                initialValue: _description,
                decoration: const InputDecoration(labelText: 'Description'),
                onChanged: (val) => _description = val,
                validator: (val) => val == null || val.isEmpty ? 'Enter description' : null,
              ),
              TextFormField(
                initialValue: _cost,
                decoration: const InputDecoration(labelText: 'Cost'),
                keyboardType: TextInputType.number,
                onChanged: (val) => _cost = val,
                validator: (val) => val == null || val.isEmpty ? 'Enter cost' : null,
              ),
              TextFormField(
                initialValue: _mileage,
                decoration: const InputDecoration(labelText: 'Mileage'),
                keyboardType: TextInputType.number,
                onChanged: (val) => _mileage = val,
                validator: (val) => val == null || val.isEmpty ? 'Enter mileage' : null,
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Service Date: \\${_serviceDate.toLocal().toString().split(' ')[0]}'),
                trailing: Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _serviceDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _serviceDate = picked);
                },
              ),
              TextFormField(
                initialValue: _notes,
                decoration: const InputDecoration(labelText: 'Notes (optional)'),
                onChanged: (val) => _notes = val,
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
          onPressed: _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final updated = widget.service.copyWith(
      serviceType: _serviceType,
      serviceProviderName: _providerName,
      description: _description,
      cost: double.tryParse(_cost) ?? 0.0,
      mileage: int.tryParse(_mileage) ?? 0,
      serviceDate: _serviceDate,
      notes: _notes.isEmpty ? null : _notes,
    );
    await FirebaseFirestore.instance.collection('service_history').doc(widget.service.id).update(updated.toMap());
    Navigator.pop(context);
  }
} 