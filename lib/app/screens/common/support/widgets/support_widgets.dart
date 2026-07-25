import 'package:clicknow_version2/app/screens/common/support/models/support_models.dart';
import 'package:clicknow_version2/app/utils/device_utils/helperFunctions.dart';
import 'package:clicknow_version2/app/utils/device_utils/responsive_Utility.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

Color supportStatusColor(String value) {
  switch (value) {
    case 'RESOLVED':
      return const Color(0xff20B26B);
    case 'CLOSED':
      return const Color(0xff8A8A98);
    case 'IN_PROGRESS':
      return const Color(0xff3B82F6);
    case 'WAITING_FOR_USER':
      return const Color(0xffF59E0B);
    case 'WAITING_FOR_ADMIN':
      return const Color(0xffB629FF);
    case 'REOPENED':
      return const Color(0xffEF6C35);
    default:
      return const Color(0xff7B2CBF);
  }
}

Color supportPriorityColor(String value) {
  switch (value) {
    case 'URGENT':
      return const Color(0xffE63946);
    case 'HIGH':
      return const Color(0xffF97316);
    case 'LOW':
      return const Color(0xff20B26B);
    default:
      return const Color(0xff3B82F6);
  }
}

class SupportChip extends StatelessWidget {
  const SupportChip({super.key, required this.value, required this.color});

  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: ResponsiveUtility.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        SupportValues.label(value),
        style: TextStyle(
          color: color,
          fontSize: ResponsiveUtility.fontSize(10),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class SupportTicketCard extends StatelessWidget {
  const SupportTicketCard({
    super.key,
    required this.ticket,
    required this.unreadCount,
    required this.onTap,
    this.showOwner = false,
  });

  final SupportTicketModel ticket;
  final int unreadCount;
  final VoidCallback onTap;
  final bool showOwner;

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFunctions.isDarkMode(context);
    final foreground = isDark ? Colors.white : const Color(0xff15121D);
    final secondary = isDark ? Colors.white60 : Colors.black54;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: ResponsiveUtility.only(bottom: 10),
        padding: ResponsiveUtility.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xff19142D) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? const Color(0xff30284A) : const Color(0xffE1DFE8),
          ),
          boxShadow: isDark
              ? null
              : const [
                  BoxShadow(
                    color: Color(0x10000000),
                    blurRadius: 12,
                    offset: Offset(0, 5),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    ticket.subject,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: foreground,
                      fontWeight: FontWeight.w700,
                      fontSize: ResponsiveUtility.fontSize(14),
                    ),
                  ),
                ),
                if (unreadCount > 0)
                  CircleAvatar(
                    radius: 10,
                    backgroundColor: const Color(0xffB629FF),
                    child: Text(
                      '$unreadCount',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
              ],
            ),
            SizedBox(height: ResponsiveUtility.height(5)),
            Text(
              '#${ticket.ticketId.substring(0, ticket.ticketId.length.clamp(0, 10))}'
              '${showOwner ? '  •  ${ticket.raisedByName} (${SupportValues.label(ticket.raisedByRole)})' : ''}',
              style: TextStyle(
                color: secondary,
                fontSize: ResponsiveUtility.fontSize(11),
              ),
            ),
            SizedBox(height: ResponsiveUtility.height(8)),
            Wrap(
              spacing: 7,
              runSpacing: 6,
              children: [
                SupportChip(
                  value: ticket.status,
                  color: supportStatusColor(ticket.status),
                ),
                SupportChip(
                  value: ticket.priority,
                  color: supportPriorityColor(ticket.priority),
                ),
                SupportChip(
                  value: ticket.category,
                  color: const Color(0xff7B2CBF),
                ),
              ],
            ),
            SizedBox(height: ResponsiveUtility.height(9)),
            Row(
              children: [
                Icon(
                  ticket.lastMessageType == 'image'
                      ? Icons.image_outlined
                      : Icons.chat_bubble_outline,
                  size: 15,
                  color: secondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    ticket.lastMessage ?? ticket.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: secondary,
                      fontSize: ResponsiveUtility.fontSize(12),
                    ),
                  ),
                ),
                Text(
                  DateFormat(
                    'dd MMM, h:mm a',
                  ).format(ticket.lastMessageAt ?? ticket.updatedAt),
                  style: TextStyle(
                    color: secondary,
                    fontSize: ResponsiveUtility.fontSize(9),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SupportMessageBubble extends StatelessWidget {
  const SupportMessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    required this.onImageTap,
  });

  final SupportMessageModel message;
  final bool isMine;
  final VoidCallback onImageTap;

  @override
  Widget build(BuildContext context) {
    if (message.messageType == 'system') {
      return Padding(
        padding: ResponsiveUtility.symmetric(vertical: 8),
        child: Center(
          child: Container(
            padding: ResponsiveUtility.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xff7B2CBF).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              message.text ?? 'Ticket updated',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: HelperFunctions.isDarkMode(context)
                    ? Colors.white70
                    : Colors.black54,
                fontSize: ResponsiveUtility.fontSize(10),
              ),
            ),
          ),
        ),
      );
    }
    final isDark = HelperFunctions.isDarkMode(context);
    final bubbleColor = isMine
        ? const Color(0xff4B075F)
        : isDark
        ? const Color(0xff211A38)
        : const Color(0xffF2EFF7);
    final textColor = isMine || isDark ? Colors.white : Colors.black87;
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: ResponsiveUtility.width(280)),
        margin: ResponsiveUtility.only(bottom: 9),
        padding: message.messageType == 'image'
            ? ResponsiveUtility.all(5)
            : ResponsiveUtility.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(isMine ? 14 : 3),
            bottomRight: Radius.circular(isMine ? 3 : 14),
          ),
        ),
        child: Column(
          crossAxisAlignment: isMine
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (message.messageType == 'image' && message.imageUrl != null)
              GestureDetector(
                onTap: onImageTap,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    message.imageUrl!,
                    width: ResponsiveUtility.width(210),
                    height: ResponsiveUtility.height(170),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox(
                      height: 100,
                      child: Center(child: Icon(Icons.broken_image_outlined)),
                    ),
                  ),
                ),
              )
            else
              Text(
                message.text ?? '',
                style: TextStyle(
                  color: textColor,
                  fontSize: ResponsiveUtility.fontSize(13),
                ),
              ),
            SizedBox(height: ResponsiveUtility.height(3)),
            Text(
              DateFormat('h:mm a').format(message.createdAt),
              style: TextStyle(
                color: textColor.withValues(alpha: 0.55),
                fontSize: ResponsiveUtility.fontSize(8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
