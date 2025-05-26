import 'package:flutter/material.dart';

class EmergencyContactCard extends StatelessWidget {
  final String? name;
  final String? phoneNumber;
  final String? relationship;
  final VoidCallback? onCall;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const EmergencyContactCard({
    super.key,
    this.name,
    this.phoneNumber,
    this.relationship,
    this.onCall,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
          child: Icon(
            Icons.person,
            color: theme.colorScheme.primary,
          ),
        ),
        title: Text(
          name ?? 'Contact Name',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(phoneNumber ?? '+250 123 456 789'),
            if (relationship != null)
              Text(
                relationship!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.phone),
              onPressed: onCall,
              color: theme.colorScheme.primary,
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: onEdit,
              color: theme.colorScheme.secondary,
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: onDelete,
              color: theme.colorScheme.error,
            ),
          ],
        ),
      ),
    );
  }
}