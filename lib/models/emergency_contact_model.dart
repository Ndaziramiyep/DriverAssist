class EmergencyContact {
  final String id;
  final String name;
  final String phoneNumber;
  final String description;
  final String iconPath; // For custom icons if needed
  final int priority; // For sorting (1 being highest priority)

  const EmergencyContact({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.description,
    this.iconPath = '',
    this.priority = 0,
  });

  // Predefined emergency contacts
  static const List<EmergencyContact> defaultContacts = [
    EmergencyContact(
      id: 'police',
      name: 'Police',
      phoneNumber: '112',
      description: 'For reporting crimes, accidents, and other emergencies requiring police assistance.',
      priority: 1,
    ),
    EmergencyContact(
      id: 'ambulance',
      name: 'Ambulance',
      phoneNumber: '912',
      description: 'For medical emergencies requiring immediate medical attention.',
      priority: 1,
    ),
    EmergencyContact(
      id: 'fire',
      name: 'Fire Department',
      phoneNumber: '112',
      description: 'For fire emergencies and rescue operations.',
      priority: 1,
    ),
    EmergencyContact(
      id: 'roadside',
      name: 'Roadside Assistance',
      phoneNumber: '112',
      description: 'For vehicle breakdowns and roadside emergencies.',
      priority: 2,
    ),
    EmergencyContact(
      id: 'traffic',
      name: 'Traffic Police',
      phoneNumber: '113',
      description: 'For traffic-related issues and road safety concerns.',
      priority: 2,
    ),
    EmergencyContact(
      id: 'towing',
      name: 'Towing Service',
      phoneNumber: '112',
      description: 'For vehicle towing and recovery services.',
      priority: 3,
    ),
  ];

  // Get icon based on contact type
  String getIcon() {
    switch (id) {
      case 'police':
        return '🚔';
      case 'ambulance':
        return '🚑';
      case 'fire':
        return '🚒';
      case 'roadside':
        return '🛠️';
      case 'traffic':
        return '🚦';
      case 'towing':
        return '🚛';
      default:
        return '📞';
    }
  }
} 