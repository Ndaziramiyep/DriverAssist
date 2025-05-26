import 'package:flutter/material.dart';
import 'package:driver_assist/models/maintenance_reminder_model.dart';
import 'package:intl/intl.dart';

class MaintenanceReminderCard extends StatelessWidget {
  final MaintenanceReminderModel reminder;
  final VoidCallback onTap;
  final VoidCallback onComplete;

  const MaintenanceReminderCard({
    super.key,
    required this.reminder,
    required this.onTap,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: reminder.priorityColor.withOpacity(0.1),
                    child: Icon(
                      Icons.build,
                      color: reminder.priorityColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reminder.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          reminder.reminderType == 'date'
                              ? 'Due: ${DateFormat('MMM d, y').format(reminder.dueDate)}'
                              : 'Due at: ${reminder.dueMileage} km',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: reminder.priorityColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      reminder.priorityLabel,
                      style: TextStyle(
                        color: reminder.priorityColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                reminder.description,
                style: theme.textTheme.bodyMedium,
              ),
              if (reminder.notes != null) ...[
                const SizedBox(height: 8),
                Text(
                  reminder.notes!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: onComplete,
                    icon: const Icon(Icons.check),
                    label: const Text('Mark as Complete'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}