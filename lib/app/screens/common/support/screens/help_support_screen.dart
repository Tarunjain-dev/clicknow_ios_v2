import 'package:clicknow_version2/app/screens/common/support/models/support_models.dart';
import 'package:clicknow_version2/app/screens/common/support/screens/raise_ticket_screen.dart';
import 'package:clicknow_version2/app/screens/common/support/screens/ticket_chat_screen.dart';
import 'package:clicknow_version2/app/screens/common/support/services/support_service.dart';
import 'package:clicknow_version2/app/screens/common/support/widgets/support_widgets.dart';
import 'package:clicknow_version2/app/utils/device_utils/helperFunctions.dart';
import 'package:clicknow_version2/app/utils/device_utils/responsive_Utility.dart';
import 'package:flutter/material.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key, required this.role});

  final String role;

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final SupportService _service = SupportService.instance;
  SupportActor? _actor;
  String _filter = 'ALL';

  @override
  void initState() {
    super.initState();
    _loadActor();
  }

  Future<void> _loadActor() async {
    final actor = await _service.currentActor(preferredRole: widget.role);
    if (mounted) setState(() => _actor = actor);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFunctions.isDarkMode(context);
    final actor = _actor;
    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xff0E0A18)
          : const Color(0xffF8F7FA),
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: isDark ? const Color(0xff171129) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 0.5,
      ),
      floatingActionButton: actor == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RaiseTicketScreen(actor: actor),
                ),
              ),
              backgroundColor: const Color(0xff4B075F),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_comment_outlined),
              label: const Text('Raise New Ticket'),
            ),
      body: actor == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<SupportTicketModel>>(
              stream: _service.streamMyTickets(actor.userId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _messageState(
                    Icons.error_outline,
                    'Could not load support tickets.',
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final all = snapshot.data!;
                final tickets = _filter == 'ALL'
                    ? all
                    : all.where((ticket) => ticket.status == _filter).toList();
                return ListView(
                  padding: ResponsiveUtility.only(
                    left: 14,
                    right: 14,
                    top: 14,
                    bottom: 95,
                  ),
                  children: [
                    Row(
                      children: [
                        _summary(
                          'Open Tickets',
                          all
                              .where(
                                (ticket) => !const <String>[
                                  'RESOLVED',
                                  'CLOSED',
                                ].contains(ticket.status),
                              )
                              .length,
                          const Color(0xffB629FF),
                        ),
                        SizedBox(width: ResponsiveUtility.width(10)),
                        _summary(
                          'Resolved Tickets',
                          all
                              .where((ticket) => ticket.status == 'RESOLVED')
                              .length,
                          const Color(0xff20B26B),
                        ),
                      ],
                    ),
                    SizedBox(height: ResponsiveUtility.height(14)),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: <String>[
                          'ALL',
                          'OPEN',
                          'IN_PROGRESS',
                          'WAITING_FOR_ADMIN',
                          'RESOLVED',
                          'CLOSED',
                        ].map(_filterChip).toList(growable: false),
                      ),
                    ),
                    SizedBox(height: ResponsiveUtility.height(14)),
                    if (tickets.isEmpty)
                      _messageState(
                        Icons.support_agent_outlined,
                        'No support tickets yet.\nNeed help? Raise a new ticket and our team will assist you.',
                      )
                    else
                      ...tickets.map(
                        (ticket) => SupportTicketCard(
                          ticket: ticket,
                          unreadCount: ticket.userUnreadCount,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TicketChatScreen(
                                ticketId: ticket.ticketId,
                                actor: actor,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
    );
  }

  Widget _summary(String title, int value, Color color) {
    final isDark = HelperFunctions.isDarkMode(context);
    return Expanded(
      child: Container(
        padding: ResponsiveUtility.all(13),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xff19142D) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$value',
              style: TextStyle(
                color: color,
                fontSize: ResponsiveUtility.fontSize(22),
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
                fontSize: ResponsiveUtility.fontSize(11),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String value) {
    final selected = _filter == value;
    return Padding(
      padding: ResponsiveUtility.only(right: 7),
      child: ChoiceChip(
        selected: selected,
        label: Text(SupportValues.label(value)),
        onSelected: (_) => setState(() => _filter = value),
        selectedColor: const Color(0xff4B075F),
        labelStyle: TextStyle(
          color: selected
              ? Colors.white
              : HelperFunctions.isDarkMode(context)
              ? Colors.white70
              : Colors.black54,
        ),
      ),
    );
  }

  Widget _messageState(IconData icon, String message) {
    return Padding(
      padding: ResponsiveUtility.symmetric(vertical: 70, horizontal: 20),
      child: Column(
        children: [
          Icon(icon, size: 52, color: const Color(0xffB629FF)),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: HelperFunctions.isDarkMode(context)
                  ? Colors.white70
                  : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
