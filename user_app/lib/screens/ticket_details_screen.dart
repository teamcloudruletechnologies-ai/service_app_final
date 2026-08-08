import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../models/models.dart';

class TicketDetailsScreen extends StatefulWidget {
  final int ticketId;
  const TicketDetailsScreen({super.key, required this.ticketId});

  @override
  State<TicketDetailsScreen> createState() => _TicketDetailsScreenState();
}

class _TicketDetailsScreenState extends State<TicketDetailsScreen> {
  final _replyCtrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _loading = true;
  bool _sending = false;
  SupportTicket? _ticket;
  XFile? _selectedImage;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  @override
  void dispose() {
    _replyCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchDetails() async {
    setState(() => _loading = true);
    try {
      final apiService = context.read<ApiService>();
      final t = await apiService.fetchSupportTicketDetails(widget.ticketId);
      setState(() {
        _ticket = t;
      });
      _scrollToBottom();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load ticket: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (img != null) {
      setState(() {
        _selectedImage = img;
      });
    }
  }

  Future<void> _sendReply() async {
    final text = _replyCtrl.text.trim();
    if (text.isEmpty && _selectedImage == null) return;

    setState(() => _sending = true);
    try {
      final apiService = context.read<ApiService>();
      await apiService.sendTicketReply(
        widget.ticketId,
        text.isNotEmpty ? text : 'Attachment uploaded.',
      );
      _replyCtrl.clear();
      setState(() {
        _selectedImage = null;
      });
      await _fetchDetails();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send reply: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _sending = false);
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return const Color(0xFFDC2626);
      case 'in progress':
      case 'in_progress':
        return const Color(0xFF2563EB);
      case 'resolved':
        return const Color(0xFF059669);
      case 'closed':
        return const Color(0xFF64748B);
      default:
        return const Color(0xFFD97706);
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeFmt = DateFormat('hh:mm a, dd MMM');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _ticket?.ticketNumber ?? 'Ticket #${widget.ticketId}',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A)),
            ),
            if (_ticket?.categoryName != null)
              Text(
                _ticket!.categoryName!,
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
              ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        actions: [
          if (_ticket != null)
            Center(
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(_ticket!.status).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _ticket!.status.toUpperCase(),
                  style: TextStyle(
                    color: _getStatusColor(_ticket!.status),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0F172A)))
          : Column(
              children: [
                // Subject & Header Card
                Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _ticket?.subject ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Created on ${DateFormat('dd MMM yyyy, hh:mm a').format(_ticket!.createdAt)}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1, color: Color(0xFFE2E8F0)),

                // Messages Timeline
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _ticket?.messages.length ?? 0,
                    itemBuilder: (context, index) {
                      final msg = _ticket!.messages[index];
                      final isUser = msg.senderType == 'user';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isUser) ...[
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF0F172A),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.support_agent_rounded, size: 16, color: Colors.white),
                              ),
                              const SizedBox(width: 10),
                            ],
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isUser ? const Color(0xFF0F172A) : Colors.white,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(16),
                                    topRight: const Radius.circular(16),
                                    bottomLeft: Radius.circular(isUser ? 16 : 4),
                                    bottomRight: Radius.circular(isUser ? 4 : 16),
                                  ),
                                  border: isUser ? null : Border.all(color: const Color(0xFFE2E8F0)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.03),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      msg.senderName ?? (isUser ? 'You' : 'Support Support'),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 11,
                                        color: isUser ? Colors.white70 : const Color(0xFF2563EB),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      msg.message,
                                      style: TextStyle(
                                        color: isUser ? Colors.white : const Color(0xFF0F172A),
                                        fontSize: 13.5,
                                        height: 1.4,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      timeFmt.format(msg.createdAt),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isUser ? Colors.white54 : const Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (isUser) const SizedBox(width: 10),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Reply Input Bar
                if (_ticket?.status.toLowerCase() != 'closed')
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                    child: SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_selectedImage != null)
                            Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.image_rounded, size: 16, color: Color(0xFF0F172A)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(_selectedImage!.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close_rounded, size: 16),
                                    onPressed: () => setState(() => _selectedImage = null),
                                  ),
                                ],
                              ),
                            ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.add_photo_alternate_outlined, color: Color(0xFF64748B)),
                                onPressed: _pickImage,
                              ),
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: TextField(
                                    controller: _replyCtrl,
                                    decoration: const InputDecoration(
                                      hintText: 'Type your message...',
                                      hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: _sending ? null : _sendReply,
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF0F172A),
                                    shape: BoxShape.circle,
                                  ),
                                  child: _sending
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                        )
                                      : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
