import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/contact_model.dart';
import '../../providers/children_provider.dart';
import '../../providers/contact_provider.dart';
import '../../theme/app_theme.dart';
import 'contact_form_screen.dart';

class ContactListScreen extends StatefulWidget {
  const ContactListScreen({super.key});

  @override
  State<ContactListScreen> createState() => _ContactListScreenState();
}

class _ContactListScreenState extends State<ContactListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final childId = Provider.of<ChildrenProvider>(context, listen: false).selectedChild?.id ?? 'ch_01';
      Provider.of<ContactProvider>(context, listen: false).loadContacts(childId);
    });
  }

  void _confirmDelete(BuildContext context, ContactModel con) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa liên hệ?'),
        content: Text('Bạn có chắc muốn xóa "${con.name}" khỏi danh bạ an toàn của bé?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () {
              final contactProvider = Provider.of<ContactProvider>(context, listen: false);
              contactProvider.deleteContact(con.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã xóa liên hệ khỏi danh bạ an toàn!'), backgroundColor: AppTheme.danger),
              );
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  void _simulateCall(BuildContext context, ContactModel con) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.phone_in_talk_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text('Đang kết nối cuộc gọi đến ${con.name} (${con.phone})...')),
          ],
        ),
        backgroundColor: AppTheme.accent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final childrenProvider = Provider.of<ChildrenProvider>(context);
    final contactProvider = Provider.of<ContactProvider>(context);
    final child = childrenProvider.selectedChild;

    final contacts = contactProvider.contacts;

    return Scaffold(
      appBar: AppBar(
        title: Text('Danh Bạ An Toàn (${child?.name ?? "Bé"})'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_rounded, color: AppTheme.primary),
            tooltip: 'Thêm liên hệ an toàn mới',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactFormScreen()));
            },
          ),
        ],
      ),
      body: contacts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.contact_phone_outlined, size: 64, color: AppTheme.textMuted),
                  const SizedBox(height: 16),
                  const Text('Chưa có danh bạ an toàn nào', style: TextStyle(color: AppTheme.textMuted)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactFormScreen()));
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Thêm Liên Hệ Đầu Tiên'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: contacts.length,
              itemBuilder: (context, index) {
                final con = contacts[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppTheme.cardBorder),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: con.isSosContact ? const Color(0xFFFEE2E2) : AppTheme.primary.withOpacity(0.1),
                          child: Icon(
                            con.isSosContact ? Icons.emergency_rounded : Icons.person_rounded,
                            color: con.isSosContact ? AppTheme.danger : AppTheme.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      con.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textDark),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (con.isSosContact) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEE2E2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'SOS Khẩn Cấp',
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.danger),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'SĐT: ${con.phone} • Quan hệ: ${con.relationship}',
                                style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                              icon: const Icon(Icons.phone_rounded, color: AppTheme.accent, size: 20),
                              tooltip: 'Gọi điện',
                              onPressed: () => _simulateCall(context, con),
                            ),
                            const SizedBox(width: 2),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                              icon: const Icon(Icons.edit_outlined, size: 20, color: AppTheme.secondary),
                              tooltip: 'Chỉnh sửa',
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => ContactFormScreen(contact: con)));
                              },
                            ),
                            const SizedBox(width: 2),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                              icon: const Icon(Icons.delete_outline, size: 20, color: AppTheme.danger),
                              tooltip: 'Xóa',
                              onPressed: () => _confirmDelete(context, con),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactFormScreen()));
        },
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Thêm Liên Hệ', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
