import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:driver_assist/utils/phone_validator.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  // late TextEditingController _phoneController;
  late TextEditingController _addressController;
  bool _isLoading = false;
  String? _profileImageBase64;
  final _imagePicker = ImagePicker();
  String? _userId;
  bool _isGettingLocation = false;
  PhoneNumber _phoneNumber = PhoneNumber(isoCode: 'US'); // Initialize with a default country

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    // _phoneController = TextEditingController();
    _addressController = TextEditingController();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    _userId = user.uid;
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        _nameController.text = data['name'] ?? '';
        _emailController.text = data['email'] ?? user.email ?? '';
        //_phoneController.text = data['phoneNumber'] ?? '';
        _addressController.text = data['address'] ?? '';
        _profileImageBase64 = data['profileImageBase64'];
         // Load phone number and country code
        final String savedPhoneNumber = data['phoneNumber'] ?? '';
        if (savedPhoneNumber.isNotEmpty) {
          try {
            // Attempt to parse the saved phone number string
            _phoneNumber = await PhoneNumber.getRegionInfoFromPhoneNumber(savedPhoneNumber);
          } catch (e) {
            print('Error parsing phone number: $e');
            // Fallback if parsing fails, keep the raw number but use a default country
            _phoneNumber = PhoneNumber(isoCode: 'US', phoneNumber: savedPhoneNumber);
          }
        }
        setState(() {});
      }
    } catch (e) {
      // Optionally handle error
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    // _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 70,
      );
      if (pickedFile != null) {
        final file = File(pickedFile.path);
        final bytes = await file.readAsBytes();
        if (bytes.length > 1024 * 1024) { // 1MB
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please select an image smaller than 1MB.')),
            );
          }
          return;
        }
        final base64 = base64Encode(bytes);
        setState(() {
          _profileImageBase64 = base64;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to pick image. Please try again.')),
        );
      }
    }
  }

  Future<void> _removeProfileImage() async {
    if (_userId == null) return;
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(_userId).update({
        'profileImageBase64': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      setState(() {
        _profileImageBase64 = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile image removed.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to remove profile image.')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);
    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permission permanently denied');
      }

      // Get current position
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Get address from coordinates
      final List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final Placemark place = placemarks.first;
        final String district = place.subLocality ?? place.locality ?? '';
        final String city = place.administrativeArea ?? '';
        final String country = place.country ?? '';
        
        final String formattedAddress = '$district, $city, $country';
        _addressController.text = formattedAddress;
        
        // Update the address in Firestore
        if (_userId != null) {
          await FirebaseFirestore.instance.collection('users').doc(_userId).update({
            'address': formattedAddress,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: ${e.toString()}')),
        );
      }
    } finally {
      setState(() => _isGettingLocation = false);
    }
  }

  Widget _buildPhoneNumberField() {
    return InternationalPhoneNumberInput(
      onInputChanged: (PhoneNumber number) {
        setState(() {
          // _phoneController.text = number.phoneNumber ?? '';
          _phoneNumber = number;
        });
      },
      selectorConfig: const SelectorConfig(
        selectorType: PhoneInputSelectorType.BOTTOM_SHEET,
      ),
      // initialValue: PhoneNumber(isoCode: 'US'),
      // textFieldController: _phoneController,
      initialValue: _phoneNumber, // Use the state variable as initial value
      textFieldController: null, // Let the package manage the text controller internally
      formatInput: true,
      keyboardType: TextInputType.phone,
      inputDecoration: const InputDecoration(
        labelText: 'Phone Number',
        hintText: 'Enter your phone number',
      ),
      validator: (value) => PhoneValidator.validatePhoneNumber(value),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Information'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Profile Picture Section
                    Center(
                      child: Stack(
                        children: [
                          GestureDetector(
                            onTap: _pickImage,
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                              backgroundImage: _profileImageBase64 != null
                                  ? MemoryImage(base64Decode(_profileImageBase64!))
                                  : null,
                              child: _profileImageBase64 == null
                                  ? Icon(
                                      Icons.person,
                                      size: 50,
                                      color: theme.colorScheme.primary,
                                    )
                                  : null,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.camera_alt,
                                size: 20,
                                color: theme.colorScheme.onPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_profileImageBase64 != null)
                      TextButton.icon(
                        onPressed: _isLoading ? null : _removeProfileImage,
                        icon: const Icon(Icons.delete, color: Colors.red),
                        label: const Text('Remove Image', style: TextStyle(color: Colors.red)),
                      ),
                    const SizedBox(height: 32),
                    // Form Fields
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      enabled: false, // Email cannot be changed
                    ),
                    const SizedBox(height: 16),
                    _buildPhoneNumberField(),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      decoration: InputDecoration(
                        labelText: 'Address',
                        prefixIcon: const Icon(Icons.location_on_outlined),
                        suffixIcon: _isGettingLocation
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : IconButton(
                                icon: const Icon(Icons.my_location),
                                onPressed: _getCurrentLocation,
                                tooltip: 'Get current location',
                              ),
                        hintText: 'Tap location icon to get current address',
                      ),
                      readOnly: true,
                      maxLines: 1,
                      scrollPhysics: const BouncingScrollPhysics(),
                      style: const TextStyle(
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Update Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _updateProfile,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Save Changes'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      if (_userId == null) throw Exception('User not found');
      // Use the formatted international phone number from the _phoneNumber object
      String? internationalPhoneNumber = _phoneNumber.phoneNumber;
      final updates = {
        'name': _nameController.text.trim(),
        // 'phoneNumber': _phoneController.text.trim(),
        'phoneNumber': internationalPhoneNumber,
        'address': _addressController.text.trim(),
        if (_profileImageBase64 != null) 'profileImageBase64': _profileImageBase64,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await FirebaseFirestore.instance.collection('users').doc(_userId).set(updates, SetOptions(merge: true));
      await _loadUserProfile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred while updating your profile.')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
} 