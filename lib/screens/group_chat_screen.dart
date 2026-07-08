import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../models/room_model.dart';
import '../models/group_chat_message_model.dart';
import '../widgets/responsive_center.dart';

class GroupChatScreen extends StatefulWidget {
  final RoomModel room;
  final bool embedded; // true quando è nel pannello destro del layout tablet

  const GroupChatScreen({super.key, required this.room, this.embedded = false});

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatProvider = context.read<ChatProvider>();
      chatProvider.startRoomPolling(widget.room);
    });
  }

  @override
  void dispose() {
    context.read<ChatProvider>().stopRoomPolling();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _send() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    final success = await context.read<ChatProvider>().sendRoomMessage(widget.room.id, text);
    
    if (success) {
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    }
  }

  String _formatTime(DateTime? date) {
    if (date == null) return '';
    final localDate = date.toLocal();
    return DateFormat('HH:mm').format(localDate);
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();
    final authProvider = context.watch<AuthProvider>();
    final currentUserId = authProvider.currentUser?.id;
    final messages = chatProvider.roomMessages;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && 
          _scrollController.position.pixels < _scrollController.position.maxScrollExtent - 100) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 1,
        titleSpacing: widget.embedded ? 12 : 0,
        automaticallyImplyLeading: false,
        leading: widget.embedded
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFF0075A2),
              radius: 18,
              child: const Icon(Icons.group, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.room.nome,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  if (widget.room.indirizzo != null)
                    Text(
                      widget.room.indirizzo!,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: ResponsiveCenter(
        child: Column(
        children: [
          Expanded(
            child: chatProvider.isLoadingMessages && messages.isEmpty
                ? Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor))
                : messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.forum_rounded, color: Colors.white.withValues(alpha: 0.2), size: 64),
                            const SizedBox(height: 16),
                            Text(
                              'Nessun messaggio in questa stanza.',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final GroupChatMessageModel message = messages[index];
                          final isMe = message.mittenteUserId == currentUserId;

                          return Align(
                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.75,
                              ),
                              decoration: BoxDecoration(
                                color: isMe ? Theme.of(context).primaryColor : const Color(0xFF1E293B),
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
                                  bottomRight: isMe ? Radius.zero : const Radius.circular(16),
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  )
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (!isMe)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 4.0),
                                      child: Text(
                                        message.mittenteNomeCompleto,
                                        style: TextStyle(
                                          color: Colors.amberAccent.withValues(alpha: 0.9),
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  Text(
                                    message.testo,
                                    style: const TextStyle(color: Colors.white, fontSize: 15),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text(
                                        _formatTime(message.createdAt),
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.55),
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.only(left: 12, right: 12, bottom: 8, top: 8),
              color: const Color(0xFF1E293B),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: TextField(
                        controller: _messageController,
                        style: const TextStyle(color: Colors.white),
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: null,
                        decoration: const InputDecoration(
                          hintText: 'Scrivi al gruppo...',
                          hintStyle: TextStyle(color: Colors.white30),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor,
                    radius: 22,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white, size: 20),
                      onPressed: _send,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }
}
