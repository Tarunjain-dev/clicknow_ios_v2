import 'dart:io';

import 'package:clicknow_version2/app/screens/common/support/models/support_models.dart';
import 'package:clicknow_version2/app/screens/common/support/services/support_service.dart';
import 'package:clicknow_version2/app/screens/common/support/widgets/support_widgets.dart';
import 'package:clicknow_version2/app/utils/device_utils/app_snackbar.dart';
import 'package:clicknow_version2/app/utils/device_utils/helperFunctions.dart';
import 'package:clicknow_version2/app/utils/device_utils/responsive_Utility.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class TicketChatScreen extends StatefulWidget {
  const TicketChatScreen({
    super.key,
    required this.ticketId,
    required this.actor,
    this.showAdminActions = false,
  });

  final String ticketId;
  final SupportActor actor;
  final bool showAdminActions;

  @override
  State<TicketChatScreen> createState() => _TicketChatScreenState();
}

class _TicketChatScreenState extends State<TicketChatScreen> {
  final _service = SupportService.instance;
  final _message = TextEditingController();
  final _scroll = ScrollController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _service.markMessagesRead(ticketId: widget.ticketId, actor: widget.actor);
  }

  @override
  void dispose() {
    _message.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _sendText() async {
    if (_message.text.trim().isEmpty || _sending) return;
    final text = _message.text;
    _message.clear();
    await _perform(
      () => _service.sendTextMessage(
        ticketId: widget.ticketId,
        actor: widget.actor,
        text: text,
      ),
    );
  }

  Future<void> _sendImage() async {
    if (_sending) return;
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 78,
      maxWidth: 1600,
    );
    if (picked == null) return;
    await _perform(
      () => _service.sendImageMessage(
        ticketId: widget.ticketId,
        actor: widget.actor,
        imageFile: File(picked.path),
      ),
    );
  }

  Future<void> _perform(Future<void> Function() action) async {
    setState(() => _sending = true);
    try {
      await action();
    } catch (error) {
      AppSnackbar.error('Support Action Failed', _error(error));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFunctions.isDarkMode(context);
    return StreamBuilder<SupportTicketModel?>(
      stream: _service.streamTicket(widget.ticketId),
      builder: (context, ticketSnapshot) {
        final ticket = ticketSnapshot.data;
        return Scaffold(
          backgroundColor: isDark
              ? const Color(0xff0E0A18)
              : const Color(0xffF8F7FA),
          appBar: AppBar(
            title: Text(ticket?.subject ?? 'Support Ticket'),
            backgroundColor: isDark ? const Color(0xff171129) : Colors.white,
            foregroundColor: isDark ? Colors.white : Colors.black,
            actions: [
              if (ticket != null)
                Padding(
                  padding: ResponsiveUtility.only(right: 10),
                  child: Center(
                    child: SupportChip(
                      value: ticket.status,
                      color: supportStatusColor(ticket.status),
                    ),
                  ),
                ),
            ],
          ),
          body: ticket == null
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    _ticketInfo(ticket, isDark),
                    if (widget.showAdminActions) _adminActions(ticket),
                    if (const <String>[
                      'RESOLVED',
                      'CLOSED',
                    ].contains(ticket.status))
                      _resolutionBanner(ticket),
                    Expanded(
                      child: StreamBuilder<List<SupportMessageModel>>(
                        stream: _service.streamMessages(widget.ticketId),
                        builder: (context, snapshot) {
                          final messages = snapshot.data ?? const [];
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (_scroll.hasClients) {
                              _scroll.jumpTo(_scroll.position.maxScrollExtent);
                            }
                          });
                          if (!snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          return ListView.builder(
                            controller: _scroll,
                            padding: ResponsiveUtility.all(14),
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              final message = messages[index];
                              return SupportMessageBubble(
                                message: message,
                                isMine: message.senderId == widget.actor.userId,
                                onImageTap: () => _openImage(message.imageUrl),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    if (ticket.status != 'CLOSED') _inputBar(isDark),
                  ],
                ),
        );
      },
    );
  }

  Widget _ticketInfo(SupportTicketModel ticket, bool isDark) {
    return ExpansionTile(
      tilePadding: ResponsiveUtility.symmetric(horizontal: 14),
      backgroundColor: isDark ? const Color(0xff171129) : Colors.white,
      collapsedBackgroundColor: isDark ? const Color(0xff171129) : Colors.white,
      title: Text(
        '#${ticket.ticketId} • ${SupportValues.label(ticket.category)}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        widget.actor.role == 'admin'
            ? '${ticket.raisedByName} • ${ticket.raisedByPhone}'
            : 'Priority: ${SupportValues.label(ticket.priority)}',
      ),
      childrenPadding: ResponsiveUtility.only(left: 14, right: 14, bottom: 12),
      children: [
        Align(alignment: Alignment.centerLeft, child: Text(ticket.description)),
        if (ticket.relatedBookingId != null)
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Booking: ${ticket.relatedBookingId}'),
          ),
        if (ticket.relatedPaymentId != null)
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Payment: ${ticket.relatedPaymentId}'),
          ),
        if (ticket.relatedRefundId != null)
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Refund: ${ticket.relatedRefundId}'),
          ),
        if (ticket.relatedPayrollId != null)
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Payroll: ${ticket.relatedPayrollId}'),
          ),
        if (ticket.initialAttachmentUrl != null) ...[
          SizedBox(height: ResponsiveUtility.height(10)),
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => _openImage(ticket.initialAttachmentUrl),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  ticket.initialAttachmentUrl!,
                  height: ResponsiveUtility.height(120),
                  width: ResponsiveUtility.width(170),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _adminActions(SupportTicketModel ticket) {
    return Container(
      color: const Color(0xff201431),
      padding: ResponsiveUtility.symmetric(horizontal: 10, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _action(
              'Assign to me',
              () => _perform(
                () => _service.assignToAdmin(
                  ticketId: ticket.ticketId,
                  adminActor: widget.actor,
                ),
              ),
            ),
            ...<String>[
              'IN_PROGRESS',
              'WAITING_FOR_USER',
              'WAITING_FOR_ADMIN',
              'RESOLVED',
              'CLOSED',
              'REOPENED',
            ].map(
              (status) => _action(
                SupportValues.label(status),
                () => _perform(
                  () => _service.updateStatus(
                    ticketId: ticket.ticketId,
                    status: status,
                    actor: widget.actor,
                  ),
                ),
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'Change priority',
              onSelected: (priority) => _perform(
                () => _service.updatePriority(
                  ticketId: ticket.ticketId,
                  priority: priority,
                  actor: widget.actor,
                ),
              ),
              itemBuilder: (_) => SupportValues.priorities
                  .map(
                    (value) => PopupMenuItem(
                      value: value,
                      child: Text(SupportValues.label(value)),
                    ),
                  )
                  .toList(growable: false),
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Text('Priority', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _action(String label, VoidCallback onTap) => Padding(
    padding: ResponsiveUtility.only(right: 7),
    child: OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
      child: Text(label),
    ),
  );

  Widget _resolutionBanner(SupportTicketModel ticket) => Container(
    width: double.infinity,
    padding: ResponsiveUtility.symmetric(horizontal: 14, vertical: 9),
    color: supportStatusColor(ticket.status).withValues(alpha: 0.14),
    child: Row(
      children: [
        Expanded(
          child: Text(
            ticket.status == 'CLOSED'
                ? 'This ticket is closed.'
                : 'This ticket was marked resolved.',
          ),
        ),
        if (widget.actor.role != 'admin')
          TextButton(
            onPressed: () => _perform(
              () => _service.updateStatus(
                ticketId: ticket.ticketId,
                status: 'REOPENED',
                actor: widget.actor,
              ),
            ),
            child: const Text('Reopen'),
          ),
      ],
    ),
  );

  Widget _inputBar(bool isDark) => SafeArea(
    top: false,
    child: Container(
      padding: ResponsiveUtility.symmetric(horizontal: 10, vertical: 8),
      color: isDark ? const Color(0xff171129) : Colors.white,
      child: Row(
        children: [
          IconButton(
            onPressed: _sending ? null : _sendImage,
            icon: const Icon(Icons.add_photo_alternate_outlined),
          ),
          Expanded(
            child: TextField(
              controller: _message,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: 'Write a message...',
                filled: true,
                fillColor: isDark
                    ? const Color(0xff211A38)
                    : const Color(0xffF2EFF7),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          IconButton.filled(
            onPressed: _sending ? null : _sendText,
            icon: _sending
                ? const SizedBox.square(
                    dimension: 17,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_rounded),
          ),
        ],
      ),
    ),
  );

  void _openImage(String? url) {
    if (url == null) return;
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: InteractiveViewer(child: Image.network(url)),
      ),
    );
  }
}

String _error(Object error) =>
    error.toString().replaceFirst(RegExp(r'^(Bad state|StateError):\s*'), '');
