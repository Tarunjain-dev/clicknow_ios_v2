import 'package:clicknow_version2/app/routes/appRoutes.dart';
import 'package:clicknow_version2/app/screens/admin/widgets/admin_drawer.dart';
import 'package:clicknow_version2/app/screens/common/support/models/support_models.dart';
import 'package:clicknow_version2/app/screens/common/support/screens/ticket_chat_screen.dart';
import 'package:clicknow_version2/app/screens/common/support/services/support_service.dart';
import 'package:clicknow_version2/app/screens/common/support/widgets/support_widgets.dart';
import 'package:clicknow_version2/app/utils/device_utils/responsive_Utility.dart';
import 'package:clicknow_version2/app/utils/device_utils/scale_utility.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AdminSupportDisputesScreen extends StatefulWidget {
  const AdminSupportDisputesScreen({super.key});

  @override
  State<AdminSupportDisputesScreen> createState() => _AdminSupportDisputesScreenState();
}

class _AdminSupportDisputesScreenState extends State<AdminSupportDisputesScreen> {
  final _service = SupportService.instance;
  final _search = TextEditingController();
  SupportActor? _actor;
  String _status = 'ALL';
  String _role = 'ALL';
  String _priority = 'ALL';
  String _category = 'ALL';

  @override
  void initState() {
    super.initState();
    _search.text = ((Get.arguments as Map?)?['targetUserId'] ?? '').toString().trim();
    _loadActor();
    _search.addListener(() => setState(() {}));
  }

  Future<void> _loadActor() async {
    final actor = await _service.currentActor(preferredRole: 'admin');
    if (mounted) setState(() => _actor = actor);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = ScalingUtility(context: context)..setCurrentDeviceSize();
    return Container(
      color: Colors.white,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        drawer: AdminDrawer(
          scale: scale,
          activeRoute: AppRoutes.adminSupportDisputesRoute,
        ),
        body: Column(
          children: [
            _header(scale),
            Expanded(
              child: _actor == null
                  ? const Center(child: CircularProgressIndicator())
                  : _actor!.role != 'admin'
                  ? const Center(
                      child: Text(
                        'Admin access is required.',
                        style: TextStyle(color: Colors.black),
                      ),
                    )
                  : StreamBuilder<List<SupportTicketModel>>(
                      stream: _service.streamAllTicketsForAdmin(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return const Center(
                            child: Text(
                              'Unable to load support tickets.',
                              style: TextStyle(color: Colors.black),
                            ),
                          );
                        }
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        final all = snapshot.data!;
                        final filtered = all
                            .where(_matches)
                            .toList(growable: false);
                        return ListView(
                          padding: ResponsiveUtility.only(
                            left: 14,
                            right: 14,
                            top: 12,
                            bottom: 24,
                          ),
                          children: [
                            _summaries(all),
                            SizedBox(height: ResponsiveUtility.height(12)),
                            TextField(
                              controller: _search,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Search ticket, user, phone, subject, booking...',
                                hintStyle: const TextStyle(color: Colors.black54,),
                                prefixIcon: const Icon(
                                  Icons.search,
                                  color: Colors.black54,
                                ),
                                filled: true,
                                fillColor: const Color(0xffF6F4FF),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                            SizedBox(height: ResponsiveUtility.height(10)),
                            _filters(all),
                            SizedBox(height: ResponsiveUtility.height(14)),
                            if (filtered.isEmpty)
                              const Padding(
                                padding: EdgeInsets.only(top: 70),
                                child: Center(
                                  child: Text(
                                    'No matching support tickets.',
                                    style: TextStyle(color: Colors.white60),
                                  ),
                                ),
                              )
                            else
                              ...filtered.map(
                                (ticket) => SupportTicketCard(
                                  ticket: ticket,
                                  unreadCount: ticket.adminUnreadCount,
                                  showOwner: true,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => TicketChatScreen(
                                        ticketId: ticket.ticketId,
                                        actor: _actor!,
                                        showAdminActions: true,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(ScalingUtility scale) => Container(
    padding: EdgeInsets.fromLTRB(
      scale.getScaledWidth(10),
      scale.getScaledHeight(60),
      scale.getScaledWidth(12),
      scale.getScaledHeight(12),
    ),
    decoration: const BoxDecoration(
      color: Color(0xff6F18A8),
      border: Border(bottom: BorderSide(color: Color(0xffD9D9D9))),
    ),
    child: Row(
      children: [
        Builder(
          builder: (context) => IconButton(
            onPressed: () => Scaffold.of(context).openDrawer(),
            icon: const Icon(Icons.menu_rounded, color: Colors.white),
          ),
        ),
        const Expanded(
          child: Text(
            'Support & Disputes',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _summaries(List<SupportTicketModel> all) {
    final values = <(String, int, Color)>[
      (
        'Open',
        all.where((e) => e.status == 'OPEN').length,
        const Color(0xffB629FF),
      ),
      (
        'In Progress',
        all.where((e) => e.status == 'IN_PROGRESS').length,
        const Color(0xff3B82F6),
      ),
      (
        'Urgent',
        all.where((e) => e.priority == 'URGENT').length,
        const Color(0xffE63946),
      ),
      (
        'Resolved',
        all.where((e) => e.status == 'RESOLVED').length,
        const Color(0xff20B26B),
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: values
              .map(
                (item) => Container(
                  width: width,
                  padding: ResponsiveUtility.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xffF6F4FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: item.$3.withValues(alpha: 0.35)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${item.$2}',
                        style: TextStyle(
                          color: item.$3,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        item.$1,
                        style: const TextStyle(color: Colors.black),
                      ),
                    ],
                  ),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }

  Widget _filters(List<SupportTicketModel> all) {
    final categories = <String>{
      'ALL',
      ...all.map((ticket) => ticket.category),
    }.toList();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _dropdown(
          value: _status,
          values: const <String>['ALL', ...SupportValues.statuses],
          onChanged: (value) => setState(() => _status = value),
        ),
        _dropdown(
          value: _role,
          values: const <String>['ALL', 'customer', 'professional'],
          onChanged: (value) => setState(() => _role = value),
        ),
        _dropdown(
          value: _priority,
          values: const <String>['ALL', ...SupportValues.priorities],
          onChanged: (value) => setState(() => _priority = value),
        ),
        _dropdown(
          value: categories.contains(_category) ? _category : 'ALL',
          values: categories,
          onChanged: (value) => setState(() => _category = value),
        ),
      ],
    );
  }

  Widget _dropdown({
    required String value,
    required List<String> values,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xffF6F4FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xffD9D9D9)),
      ),
      child: DropdownButton<String>(
        value: value,
        underline: const SizedBox.shrink(),
        dropdownColor: Colors.white,
        style: const TextStyle(color: Colors.black54),
        items: values
            .map(
              (item) => DropdownMenuItem(
                value: item,
                child: Text(SupportValues.label(item)),
              ),
            )
            .toList(growable: false),
        onChanged: (next) {
          if (next != null) onChanged(next);
        },
      ),
    );
  }

  bool _matches(SupportTicketModel ticket) {
    if (_status != 'ALL' && ticket.status != _status) return false;
    if (_role != 'ALL' && ticket.raisedByRole != _role) return false;
    if (_priority != 'ALL' && ticket.priority != _priority) return false;
    if (_category != 'ALL' && ticket.category != _category) return false;
    final query = _search.text.trim().toLowerCase();
    if (query.isEmpty) return true;
    return <String>[
      ticket.ticketId,
      ticket.raisedByName,
      ticket.raisedByPhone,
      ticket.subject,
      ticket.relatedBookingId ?? '',
      ticket.relatedPaymentId ?? '',
      ticket.relatedRefundId ?? '',
      ticket.relatedPayrollId ?? '',
    ].any((value) => value.toLowerCase().contains(query));
  }
}
