import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'partner_data.dart';
import 'partner_ui.dart';

class _Bubble {
  final String text;
  final bool mine;
  final DateTime? at;

  _Bubble(this.text, this.mine, this.at);
}

class _ChatView extends StatefulWidget {
  final String title;
  final Stream<List<_Bubble>> messages;
  final Future<void> Function(String text) onSend;
  final String emptyText;
  final List<Widget>? actions;

  const _ChatView({
    required this.title,
    required this.messages,
    required this.onSend,
    required this.emptyText,
    this.actions,
  });

  @override
  State<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<_ChatView> {
  final _input = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final t = _input.text.trim();
    if (t.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await widget.onSend(t);
      _input.clear();
    } catch (e) {
      if (mounted) pxToast(context, 'Could not send the message. $e', ok: false);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPxBg,
      appBar: pxBackAppBar(context, widget.title, actions: widget.actions),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<_Bubble>>(
              stream: widget.messages,
              builder: (context, snap) {
                if (!snap.hasData) return const PxLoading();
                final list = snap.data!;
                if (list.isEmpty) return Center(child: PxEmpty(widget.emptyText, icon: Icons.chat_bubble_outline));
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(12),
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final m = list[list.length - 1 - i];
                    return Align(
                      alignment: m.mine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.75),
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                        decoration: BoxDecoration(
                          color: m.mine ? const Color(0xFF5A5F63) : kPxSurface2,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(m.text, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              m.at == null ? '' : DateFormat('h:mm a').format(m.at!).toLowerCase(),
                              style: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 9),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      minLines: 1,
                      maxLines: 4,
                      cursorColor: kPxGreen,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'Type your Message...',
                        hintStyle: const TextStyle(color: kPxMuted, fontSize: 13),
                        filled: true,
                        fillColor: kPxBg,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(color: Color(0xFF3A3A3A)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(color: kPxGreen),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _send,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(color: kPxGreen, shape: BoxShape.circle),
                      child: _sending
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    ),
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

class PartnerDriverChatScreen extends StatefulWidget {
  final String driverId;
  final String driverName;

  const PartnerDriverChatScreen({super.key, required this.driverId, required this.driverName});

  @override
  State<PartnerDriverChatScreen> createState() => _PartnerDriverChatScreenState();
}

class _PartnerDriverChatScreenState extends State<PartnerDriverChatScreen> {
  late final Stream<List<_Bubble>> _messages = Px.db
      .collection('vendor_driver_messages')
      .where('driver_id', isEqualTo: widget.driverId)
      .where('vendor_id', isEqualTo: Px.uid)
      .snapshots()
      .map((s) {
    final list = s.docs.map((d) {
      final m = d.data();
      return _Bubble(Px.text(m['text']), Px.text(m['sender']) == 'vendor', Px.date(m['created_at']));
    }).toList();
    list.sort((a, b) => (a.at ?? DateTime.now()).compareTo(b.at ?? DateTime.now()));
    return list;
  });

  Future<void> _send(String text) async {
    await Px.db.collection('vendor_driver_messages').add({
      'vendor_id': Px.uid,
      'driver_id': widget.driverId,
      'text': text,
      'sender': 'vendor',
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return _ChatView(
      title: widget.driverName.isEmpty ? 'Chat with Driver' : widget.driverName,
      messages: _messages,
      onSend: _send,
      emptyText: 'No messages yet. Say hello to your driver.',
    );
  }
}

class PartnerSupportChatScreen extends StatefulWidget {
  final String topic;

  const PartnerSupportChatScreen({super.key, this.topic = ''});

  @override
  State<PartnerSupportChatScreen> createState() => _PartnerSupportChatScreenState();
}

class _PartnerSupportChatScreenState extends State<PartnerSupportChatScreen> {
  late final DocumentReference<PxMap> _chat = Px.db.collection('support_chats').doc(Px.uid);
  late final Stream<List<_Bubble>> _messages = _chat.collection('messages').orderBy('created_at').snapshots().map(
        (s) => s.docs.map((d) {
          final m = d.data();
          return _Bubble(Px.text(m['text']), Px.text(m['sender']) == 'user', Px.date(m['created_at']));
        }).toList(),
      );

  Future<void> _send(String text) async {
    final batch = Px.db.batch();
    batch.set(_chat.collection('messages').doc(), {
      'sender': 'user',
      'text': text,
      'created_at': FieldValue.serverTimestamp(),
    });
    batch.set(
      _chat,
      {
        'status': 'open',
        'role': 'vendor',
        if (widget.topic.isNotEmpty) 'topic': widget.topic,
        'last_message_preview': text.length > 200 ? text.substring(0, 200) : text,
        'last_message_at': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    return _ChatView(
      title: 'Chat with Support',
      messages: _messages,
      onSend: _send,
      emptyText: widget.topic.isEmpty
          ? 'Tell us what you need help with.'
          : 'Tell us about your ${widget.topic.toLowerCase()} question.',
      actions: [
        IconButton(
          onPressed: () => pxToast(context, 'Messages here go to the PoolX support team.'),
          icon: const Icon(Icons.info_outline, color: Colors.white, size: 20),
        ),
      ],
    );
  }
}
