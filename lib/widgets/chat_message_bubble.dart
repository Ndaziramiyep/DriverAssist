import 'package:flutter/material.dart';
import 'package:driver_assist/models/chat_message_model.dart';
import 'package:timeago/timeago.dart' as timeago;

class ChatMessageBubble extends StatelessWidget {
  final ChatMessageModel message;
  final bool isMe;

  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) _buildAvatar(theme),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                _buildMessageContent(context, theme),
                const SizedBox(height: 4),
                _buildMessageTime(theme),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isMe) _buildAvatar(theme),
        ],
      ),
    );
  }

  Widget _buildAvatar(ThemeData theme) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: isMe
          ? theme.colorScheme.primary.withOpacity(0.1)
          : theme.colorScheme.secondary.withOpacity(0.1),
      child: Icon(
        Icons.person,
        size: 16,
        color: isMe ? theme.colorScheme.primary : theme.colorScheme.secondary,
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context, ThemeData theme) {
    switch (message.type) {
      case MessageType.text:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isMe
                ? theme.colorScheme.primary
                : theme.colorScheme.secondary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            message.message,
            style: TextStyle(
              color: isMe ? Colors.white : theme.colorScheme.onSurface,
            ),
          ),
        );

      case MessageType.image:
        return Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.6,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isMe
                  ? theme.colorScheme.primary
                  : theme.colorScheme.secondary.withOpacity(0.1),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.network(
              message.imageUrl!,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 200,
                  color: Colors.grey[300],
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 200,
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(Icons.error),
                  ),
                );
              },
            ),
          ),
        );

      case MessageType.location:
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isMe
                ? theme.colorScheme.primary
                : theme.colorScheme.secondary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_on, color: Colors.red),
              const SizedBox(width: 8),
              Text(
                'Location Shared',
                style: TextStyle(
                  color: isMe ? Colors.white : theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        );

      case MessageType.serviceRequest:
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isMe
                ? theme.colorScheme.primary
                : theme.colorScheme.secondary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.emergency, color: Colors.orange),
              const SizedBox(width: 8),
              Text(
                'Service Request',
                style: TextStyle(
                  color: isMe ? Colors.white : theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildMessageTime(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        timeago.format(message.timestamp),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
    );
  }
}