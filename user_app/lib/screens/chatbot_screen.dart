import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../models/chat_message.dart';
import '../providers/auth_provider.dart';

class ChatbotScreen extends StatefulWidget {
  @override
  _ChatbotScreenState createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  
  // NOTE: If testing on Android Emulator, 10.0.2.2 points to your computer's localhost.
  // Using the live Render URL since the backend is already deployed.
  final String _webhookUrl = 'https://service-app-final.onrender.com/api/webhook/urban'; 

  @override
  void initState() {
    super.initState();
    // Add a welcome message from the bot
    _messages.add(ChatMessage(
      text: "Hi there! I am your Urban Assistant. How can I help you today?",
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // 1. Add User Message to UI
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isTyping = true;
    });

    _messageController.clear();

    // Get real User ID from Provider, fallback to 1 if testing without login
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final int userId = authProvider.user?.id ?? 1;

    // 2. Call the Node.js Webhook
    try {
      final response = await http.post(
        Uri.parse(_webhookUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'message': text,
          'platform': 'flutter',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply = data['reply'] ?? 'Sorry, I did not understand that.';
        
        setState(() {
          _messages.add(ChatMessage(
            text: reply,
            isUser: false,
            timestamp: DateTime.now(),
          ));
        });
      } else {
        _showError("Server returned an error: ${response.statusCode}");
      }
    } catch (e) {
      _showError("Failed to connect to the server. Is the backend running?");
    } finally {
      setState(() {
        _isTyping = false;
      });
    }
  }

  void _showError(String errorMsg) {
    setState(() {
      _messages.add(ChatMessage(
        text: "⚠️ $errorMsg",
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: message.isUser ? Colors.blueAccent : Colors.grey[300],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(15),
            topRight: const Radius.circular(15),
            bottomLeft: message.isUser ? const Radius.circular(15) : const Radius.circular(0),
            bottomRight: message.isUser ? const Radius.circular(0) : const Radius.circular(15),
          ),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: message.isUser ? Colors.white : Colors.black87,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Urban Assistant'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Chat Area
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),
          
          // Typing Indicator
          if (_isTyping)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 5.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Bot is typing...",
                  style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                ),
              ),
            ),
            
          // Quick Reply Chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ActionChip(
                    label: const Text("📅 My Current Booking"),
                    onPressed: () {
                      _messageController.text = "Show my current booking";
                      _sendMessage();
                    },
                    backgroundColor: Colors.blue[50],
                  ),
                  const SizedBox(width: 8),
                  ActionChip(
                    label: const Text("📜 Past Bookings"),
                    onPressed: () {
                      _messageController.text = "Show my past bookings";
                      _sendMessage();
                    },
                    backgroundColor: Colors.blue[50],
                  ),
                  const SizedBox(width: 8),
                  ActionChip(
                    label: const Text("⏰ Reschedule"),
                    onPressed: () {
                      _messageController.text = "Reschedule my booking";
                      _sendMessage();
                    },
                    backgroundColor: Colors.blue[50],
                  ),
                ],
              ),
            ),
          ),

          // Input Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.blueAccent,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
