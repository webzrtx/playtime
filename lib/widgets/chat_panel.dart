import 'package:flutter/material.dart';

/// Simple local-only chat message (no IM backend).
class ChatMessage {
  final String senderId;
  final String senderName;
  final String text;
  final DateTime timestamp;
  final bool isSelf;
  final bool isSystem;

  ChatMessage({
    required this.senderId,
    required this.senderName,
    required this.text,
    this.isSelf = false,
    this.isSystem = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// Chat panel overlay widget — WePlay-inspired dark-themed chat.
///
/// Local-only: messages are stored in widget state, not synced
/// to other users. For real multi-user chat, integrate
/// `tencent_cloud_chat_sdk`.
class ChatPanel extends StatefulWidget {
  final List<ChatMessage> messages;
  final void Function(String text) onSend;
  final VoidCallback onClose;

  const ChatPanel({
    super.key,
    required this.messages,
    required this.onSend,
    required this.onClose,
  });

  @override
  State<ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends State<ChatPanel> {
  final _textCtrl = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollCtrl = ScrollController();

  static const _accent = Color(0xFF00CCF9);
  static const _bgDark = Color(0xFF1A1A2E);
  static const _bgCard = Color(0xFF16213E);

  @override
  void initState() {
    super.initState();
    // Auto-scroll to bottom after frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _scrollToBottom() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _send() {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    widget.onSend(text);
    _textCtrl.clear();
    _focusNode.requestFocus();
    // Scroll after frame when new message renders
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _focusNode.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _bgDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // -- Header --
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: _bgCard,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  width: 4, height: 16,
                  decoration: BoxDecoration(
                    color: _accent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Chat',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: widget.onClose,
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white70, size: 18),
                  ),
                ),
              ],
            ),
          ),

          // -- Messages --
          Expanded(
            child: widget.messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 40, color: Colors.white.withOpacity(0.2)),
                        const SizedBox(height: 12),
                        Text(
                          'No messages yet',
                          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: widget.messages.length,
                    itemBuilder: (context, i) {
                      final msg = widget.messages[i];
                      return _ChatBubble(message: msg);
                    },
                  ),
          ),

          // -- Input bar --
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 12),
            decoration: BoxDecoration(
              color: _bgCard,
              border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      controller: _textCtrl,
                      focusNode: _focusNode,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Send a message...',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        border: InputBorder.none,
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _send,
                  child: Container(
                    width: 40, height: 40,
                    decoration: const BoxDecoration(
                      color: _accent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Single chat bubble — cyan for self, grey for others.
class _ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const _ChatBubble({required this.message});

  static const _accent = Color(0xFF00CCF9);

  @override
  Widget build(BuildContext context) {
    final isSelf = message.isSelf;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: isSelf ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Sender label (only for others)
          if (!isSelf)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 2),
              child: Text(
                message.senderName,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 11,
                ),
              ),
            ),
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelf ? _accent.withOpacity(0.25) : Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isSelf ? 16 : 4),
                bottomRight: Radius.circular(isSelf ? 4 : 16),
              ),
            ),
            child: Text(
              message.text,
              style: TextStyle(
                color: isSelf ? _accent : Colors.white.withOpacity(0.9),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
