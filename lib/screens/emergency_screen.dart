import 'package:flutter/material.dart';
import 'package:driver_assist/models/emergency_request_model.dart';
import 'package:driver_assist/widgets/emergency_contact_card.dart';
import 'package:driver_assist/widgets/emergency_service_card.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  EmergencyRequestType? _selectedServiceType;
  final TextEditingController _descriptionController = TextEditingController();
  bool _isRequesting = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Services'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _showServiceHistory,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main Content
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // SOS Button
              Container(
                height: 200,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.error,
                      theme.colorScheme.error.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.error.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _showSOSDialog,
                    borderRadius: BorderRadius.circular(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.emergency,
                          size: 48,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'SOS',
                          style: theme.textTheme.headlineLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap for Emergency Assistance',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Emergency Services
              Text(
                'Emergency Services',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.3,
                children: [
                  EmergencyServiceCard(
                    icon: Icons.local_gas_station,
                    title: 'Fuel Delivery',
                    subtitle: 'Emergency fuel delivery to your location',
                    onTap: () => _showServiceRequestDialogSim('Fuel Delivery'),
                  ),
                  EmergencyServiceCard(
                    icon: Icons.build,
                    title: 'Mechanic',
                    subtitle: '24/7 roadside assistance',
                    onTap: () => _showServiceRequestDialogSim('Mechanic'),
                  ),
                  EmergencyServiceCard(
                    icon: Icons.directions_car,
                    title: 'Towing',
                    subtitle: 'Vehicle towing service',
                    onTap: () => _showServiceRequestDialogSim('Towing'),
                  ),
                  EmergencyServiceCard(
                    icon: Icons.medical_services,
                    title: 'Medical',
                    subtitle: 'Emergency medical assistance',
                    onTap: () => _showServiceRequestDialogSim('Medical'),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Emergency Contacts
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Emergency Contacts',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      _showAddContactDialog(context);
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Emergency Contacts List (dynamic)
              _buildEmergencyContactsList(context),
            ],
          ),

          // Loading Overlay
          if (_isRequesting)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  void _showSOSDialog() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Emergency SOS'),
        content: const Text('What would you like to do?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _confirmAndCallEmergencyNumber();
            },
            child: const Text('Call Emergency Number'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _alertEmergencyContacts();
            },
            child: const Text('Alert My Emergency Contacts'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _confirmAndCallEmergencyNumber() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Call'),
        content: const Text('Are you sure you want to call the emergency number (112)?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _makePhoneCall('112');
            },
            child: const Text('Call'),
          ),
        ],
      ),
    );
  }

  void _alertEmergencyContacts() async {
    setState(() => _isRequesting = true);
    String locationText = '';
    String? mapsUrl;
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      mapsUrl = 'https://maps.google.com/?q=${position.latitude},${position.longitude}';
      locationText = mapsUrl;
    } catch (e) {
      locationText = 'Location unavailable.';
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isRequesting = false);
      return;
    }
    final contactsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('emergency_contacts')
        .get();
    if (contactsSnapshot.docs.isEmpty) {
      setState(() => _isRequesting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No emergency contacts to alert.')),
      );
      return;
    }
    final List<String> phoneNumbers = contactsSnapshot.docs
        .map((doc) => doc['phoneNumber']?.toString() ?? '')
        .where((number) => number.isNotEmpty)
        .toList();
    final message = 'I need help, please. This is my location -> $locationText';
    
    try {
      // Create SMS URI with all recipients
      final Uri smsUri = Uri(
        scheme: 'sms',
        path: phoneNumbers.join(','),
        queryParameters: {'body': message},
      );
      
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      } else {
        throw 'Could not launch SMS app';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send SMS: $e')),
      );
    }
    setState(() => _isRequesting = false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alert Sent'),
        content: const Text('Your emergency contacts have been alerted (SMS composer opened).'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _handleSOSRequest() {
    setState(() => _isRequesting = true);
    // Implement SOS request logic
    Future.delayed(const Duration(seconds: 2), () {
      setState(() => _isRequesting = false);
      _showServiceRequestDialogSim('Medical');
    });
  }

  void _showServiceRequestDialogSim(String serviceType) {
    final locationController = TextEditingController(text: 'Current location (editable)');
    final notesController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Request $serviceType'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: locationController,
              decoration: const InputDecoration(labelText: 'Location'),
            ),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startServiceRequestSim(serviceType, locationController.text, notesController.text);
            },
            child: const Text('Request'),
          ),
        ],
      ),
    );
  }

  void _startServiceRequestSim(String serviceType, String location, String notes) async {
    // Show searching dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: const [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Expanded(child: Text('Searching for providers…')),
          ],
        ),
      ),
    );
    await Future.delayed(const Duration(seconds: 2));
    // Simulate provider matching
    final provider = _getRandomProvider(serviceType);
    final eta = (5 + (5 * (provider.hashCode % 3))).toString();
    Navigator.pop(context); // Close searching dialog
    _showProviderStatusDialog(serviceType, location, notes, provider, eta);
    // Store request in Firestore
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('service_requests')
          .add({
        'serviceType': serviceType,
        'location': location,
        'notes': notes,
        'provider': provider,
        'eta': eta,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'matched',
      });
    }
  }

  void _showProviderStatusDialog(String serviceType, String location, String notes, String provider, String eta) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$serviceType Provider Found!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Provider: $provider'),
            Text('ETA: $eta min'),
            const SizedBox(height: 8),
            Text('Location: $location'),
            if (notes.isNotEmpty) Text('Notes: $notes'),
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

  String _getRandomProvider(String serviceType) {
    // Simulate a provider name
    final providers = {
      'Fuel Delivery': ['John Fuel', 'QuickFuel', 'FuelGo'],
      'Mechanic': ['AutoFix', 'MechPro', 'RoadRescue'],
      'Towing': ['TowMaster', 'RescueTow', 'TowPro'],
      'Medical': ['MediAid', 'HealthRescue', 'MediQuick'],
    };
    final list = providers[serviceType] ?? ['ProviderX'];
    list.shuffle();
    return list.first;
  }

  void _showServiceHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final history = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('service_requests')
        .orderBy('timestamp', descending: true)
        .get();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Service History'),
        content: SizedBox(
          width: double.maxFinite,
          child: history.docs.isEmpty
              ? const Text('No service requests yet.')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: history.docs.length,
                  itemBuilder: (context, index) {
                    final data = history.docs[index].data();
                    return ListTile(
                      title: Text(data['serviceType'] ?? ''),
                      subtitle: Text('Provider: ${data['provider'] ?? ''}\nETA: ${data['eta'] ?? ''} min\nLocation: ${data['location'] ?? ''}\nNotes: ${data['notes'] ?? ''}'),
                      trailing: Text(data['status'] ?? ''),
                    );
                  },
                ),
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

  Widget _buildEmergencyContactsList(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Not logged in'));
    }
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('emergency_contacts')
          .orderBy('createdAt', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No emergency contacts yet.'));
        }
        final contacts = snapshot.data!.docs;
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: contacts.length,
          itemBuilder: (context, index) {
            final doc = contacts[index];
            final data = doc.data() as Map<String, dynamic>;
            final name = data['name'] ?? '';
            final phone = data['phoneNumber'] ?? '';
            return EmergencyContactCard(
              name: name,
              phoneNumber: phone,
              onCall: () => _makePhoneCall(phone),
              onEdit: () => _showEditContactDialog(context, doc.id, name, phone),
              onDelete: () => _deleteContact(doc.id),
            );
          },
        );
      },
    );
  }

  void _showAddContactDialog(BuildContext context) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Emergency Contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Contact Name'),
            ),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Phone Number'),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final phone = phoneController.text.trim();
              if (name.isNotEmpty && phone.isNotEmpty) {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .collection('emergency_contacts')
                      .add({
                    'name': name,
                    'phoneNumber': phone,
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                }
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditContactDialog(BuildContext context, String contactId, String currentName, String currentPhone) {
    final nameController = TextEditingController(text: currentName);
    final phoneController = TextEditingController(text: currentPhone);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Emergency Contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Contact Name'),
            ),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Phone Number'),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final phone = phoneController.text.trim();
              if (name.isNotEmpty && phone.isNotEmpty) {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .collection('emergency_contacts')
                      .doc(contactId)
                      .update({
                    'name': name,
                    'phoneNumber': phone,
                  });
                }
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteContact(String contactId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('emergency_contacts')
          .doc(contactId)
          .delete();
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber.trim());
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        throw 'Could not launch $phoneUri';
      }
    } catch (e) {
      debugPrint('Error making phone call: $e');
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }
}