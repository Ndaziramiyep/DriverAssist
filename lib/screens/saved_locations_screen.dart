import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:driver_assist/providers/saved_locations_provider.dart';
import 'package:driver_assist/models/saved_location_model.dart';
import 'package:url_launcher/url_launcher.dart';

class SavedLocationsScreen extends StatefulWidget {
  const SavedLocationsScreen({super.key});

  @override
  State<SavedLocationsScreen> createState() => _SavedLocationsScreenState();
}

class _SavedLocationsScreenState extends State<SavedLocationsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<SavedLocationsProvider>().loadSavedLocations();
    });
  }

  Future<void> _showEditDialog(SavedLocation location) async {
    final nameController = TextEditingController(text: location.name);
    final addressController = TextEditingController(text: location.address);
    final notesController = TextEditingController(text: location.notes);

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Location'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(labelText: 'Notes (Optional)'),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await context.read<SavedLocationsProvider>().updateLocation(
                id: location.id,
                name: nameController.text,
                address: addressController.text,
                location: location.latLng,
                notes: notesController.text.isEmpty ? null : notesController.text,
              );
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteConfirmation(SavedLocation location) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Location'),
        content: Text('Are you sure you want to delete "${location.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await context.read<SavedLocationsProvider>().deleteLocation(location.id);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Locations'),
        elevation: 0,
      ),
      body: Consumer<SavedLocationsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${provider.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.loadSavedLocations(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (provider.savedLocations.isEmpty) {
            return const Center(
              child: Text('No saved locations yet'),
            );
          }

          return ListView.builder(
            itemCount: provider.savedLocations.length,
            itemBuilder: (context, index) {
              final location = provider.savedLocations[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.location_on, color: Colors.blue),
                  title: Text(location.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (location.address != null && location.address!.isNotEmpty)
                        Text(location.address!),
                      if (location.notes != null && location.notes!.isNotEmpty)
                        Text(
                          location.notes!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.directions, color: Colors.blue),
                        tooltip: 'Directions',
                        onPressed: () {
                          final url = 'https://www.google.com/maps/dir/?api=1&destination=${location.latitude},${location.longitude}&travelmode=driving';
                          launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.orange),
                        tooltip: 'Edit',
                        onPressed: () => _showEditDialog(location),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: 'Delete',
                        onPressed: () => _showDeleteConfirmation(location),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
} 