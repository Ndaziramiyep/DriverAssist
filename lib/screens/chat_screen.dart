import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:driver_assist/models/chat_message_model.dart';
import 'package:driver_assist/providers/auth_provider.dart';
import 'package:driver_assist/widgets/chat_message_bubble.dart';
import 'package:driver_assist/widgets/chat_input_field.dart';

class ChatScreen extends StatefulWidget {
  final String serviceProviderId;
  final String serviceProviderName;

  const ChatScreen({
    super.key,
    required this.serviceProviderId,
    required this.serviceProviderName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUserId = authProvider.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
              child: Icon(
                Icons.person,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.serviceProviderName),
                const Text(
                  'Online',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone),
            onPressed: () {
              // Implement call functionality
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // Show more options
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat Messages
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(_getChatId(currentUserId!))
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
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

                final messages = snapshot.data?.docs
                    .map((doc) => ChatMessageModel.fromFirestore(doc))
                    .toList() ??
                    [];

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == currentUserId;

                    return ChatMessageBubble(
                      message: message,
                      isMe: isMe,
                    );
                  },
                );
              },
            ),
          ),

          // Message Input
          ChatInputField(
            controller: _messageController,
            onSend: _sendMessage,
            onAttachment: _showAttachmentOptions,
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }

  String _getChatId(String currentUserId) {
    // Create a unique chat ID by sorting user IDs
    final List<String> ids = [currentUserId, widget.serviceProviderId]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUserId = authProvider.currentUser?.uid;

      if (currentUserId == null) return;

      final message = ChatMessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: currentUserId,
        receiverId: widget.serviceProviderId,
        message: _messageController.text.trim(),
        timestamp: DateTime.now(),
        isRead: false,
        type: MessageType.text,
      );

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(_getChatId(currentUserId))
          .collection('messages')
          .doc(message.id)
          .set(message.toMap());

      _messageController.clear();
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending message: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.image),
                title: const Text('Send Image'),
                onTap: () {
                  Navigator.pop(context);
                  // Implement image sending
                },
              ),
              ListTile(
                leading: const Icon(Icons.location_on),
                title: const Text('Send Location'),
                onTap: () {
                  Navigator.pop(context);
                  // Implement location sharing
                },
              ),
              ListTile(
                leading: const Icon(Icons.emergency),
                title: const Text('Request Service'),
                onTap: () {
                  Navigator.pop(context);
                  // Implement service request
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}