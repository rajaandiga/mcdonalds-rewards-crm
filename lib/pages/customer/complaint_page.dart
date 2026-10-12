import 'package:flutter/material.dart';

import '../../core/core.dart';

// ============================================================
// KELUHAN (PELANGGAN)
// ============================================================
class ComplaintPage extends StatelessWidget {
  const ComplaintPage({super.key});

  void _detail(BuildContext context, Complaint q) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Observe((_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Pill(q.status, statusColor(q.status)),
                const SizedBox(width: 8),
                Text(q.category, style: const TextStyle(fontWeight: FontWeight.w800)),
                if (q.priority) ...[
                  const SizedBox(width: 8),
                  const Pill('Prioritas', AppColors.orange),
                ],
              ],
            ),
            const SizedBox(height: 10),
            Text(q.description),
            const SizedBox(height: 16),
            const Text('Riwayat penyelesaian', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            ...q.logs.map(
                  (l) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.circle, size: 10, color: AppColors.red),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.text, style: const TextStyle(fontSize: 13)),
                          Text(fmtDate(l.date), style: const TextStyle(fontSize: 11, color: Colors.black45)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (q.status == 'Selesai') ...[
              const Divider(height: 24),
              Text(q.rating == null ? 'Bagaimana penanganan keluhanmu?' : 'Penilaianmu',
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Row(
                children: List.generate(5, (i) {
                  final filled = q.rating != null && i < q.rating!;
                  return IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                    onPressed: q.rating == null
                        ? () async {
                      final err = await store.rateComplaint(q, i + 1);
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (context.mounted) snack(context, err ?? 'Terima kasih atas penilaianmu');
                    }
                        : null,
                    icon: Icon(filled ? Icons.star : Icons.star_border, color: AppColors.yellow, size: 32),
                  );
                }),
              ),
            ],
            const SizedBox(height: 12),
          ],
        ),
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ObserveMe((context, me) {
      final list = store.complaints.where((q) => q.customerId == me.id).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          title: const Text('Pusat Bantuan', style: TextStyle(fontWeight: FontWeight.w800)),
          centerTitle: true,
          backgroundColor: AppColors.bg,
          surfaceTintColor: Colors.transparent,
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: AppColors.red,
          foregroundColor: Colors.white,
          onPressed: () => showDialog(context: context, builder: (_) => _NewComplaintDialog(me: me)),
          icon: const Icon(Icons.edit_note),
          label: const Text('Buat Keluhan'),
        ),
        body: list.isEmpty
            ? const Center(child: Text('Belum ada keluhan. Tekan "Buat Keluhan" bila ada kendala.'))
            : ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final q = list[i];
            return InkWell(
              onTap: () => _detail(context, q),
              borderRadius: BorderRadius.circular(16),
              child: Box(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Pill(q.status, statusColor(q.status)),
                              const SizedBox(width: 8),
                              Text(q.category, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(q.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13)),
                          const SizedBox(height: 4),
                          Text(fmtDate(q.createdAt),
                              style: const TextStyle(color: Colors.black45, fontSize: 11)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.black38),
                  ],
                ),
              ),
            );
          },
        ),
      );
    });
  }
}

class _NewComplaintDialog extends StatefulWidget {
  final Customer me;
  const _NewComplaintDialog({required this.me});

  @override
  State<_NewComplaintDialog> createState() => _NewComplaintDialogState();
}

class _NewComplaintDialogState extends State<_NewComplaintDialog> {
  String _cat = complaintCategories.first;
  final _desc = TextEditingController();

  @override
  void dispose() {
    _desc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Buat Keluhan'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _cat,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Kategori', border: OutlineInputBorder()),
              items: complaintCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _cat = v ?? _cat),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _desc,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Ceritakan keluhanmu', border: OutlineInputBorder()),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.red),
          onPressed: () async {
            if (_desc.text.trim().length < 5) {
              snack(context, 'Tulis keluhan minimal 5 karakter');
              return;
            }
            final messenger = ScaffoldMessenger.of(context);
            final err = await store.addComplaint(_cat, _desc.text.trim());
            if (!mounted) return;
            if (err != null) {
              snack(context, err);
              return;
            }
            Navigator.pop(context);
            messenger.showSnackBar(const SnackBar(content: Text('Keluhan terkirim')));
          },
          child: const Text('Kirim'),
        ),
      ],
    );
  }
}
