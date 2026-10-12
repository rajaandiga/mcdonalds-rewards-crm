import 'package:flutter/material.dart';

import '../../core/core.dart';

// ============================================================
// ADMIN: KELUHAN
// ============================================================
class AdminComplaints extends StatefulWidget {
  const AdminComplaints({super.key});

  @override
  State<AdminComplaints> createState() => _AdminComplaintsState();
}

class _AdminComplaintsState extends State<AdminComplaints> {
  String _filter = 'Semua';

  @override
  Widget build(BuildContext context) {
    return Observe((context) {
      final list = store.complaints.where((q) => _filter == 'Semua' || q.status == _filter).toList()
        ..sort((a, b) {
          if (a.priority != b.priority) return a.priority ? -1 : 1;
          return b.createdAt.compareTo(a.createdAt);
        });
      return Scaffold(
        backgroundColor: AppColors.bg,
        appBar: adminBar(context, 'Manajemen Keluhan'),
        body: Column(
          children: [
            SizedBox(
              height: 56,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                children: ['Semua', ...complaintStatuses].map((s) {
                  final n = s == 'Semua'
                      ? store.complaints.length
                      : store.complaints.where((q) => q.status == s).length;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('$s ($n)'),
                      selected: _filter == s,
                      onSelected: (_) => setState(() => _filter = s),
                    ),
                  );
                }).toList(),
              ),
            ),
            Expanded(
              child: list.isEmpty
                  ? const Center(child: Text('Tidak ada keluhan'))
                  : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final q = list[i];
                  final name = store.customerById(q.customerId)?.name ?? '-';
                  return InkWell(
                    onTap: () => showDialog(
                      context: context,
                      builder: (_) => _AdminComplaintDialog(q: q),
                    ),
                    borderRadius: BorderRadius.circular(16),
                    child: Box(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Pill(q.status, statusColor(q.status)),
                              const SizedBox(width: 8),
                              if (q.priority) ...[
                                const Pill('Prioritas', AppColors.orange),
                                const SizedBox(width: 8),
                              ],
                              Expanded(
                                child: Text('$name • ${q.category}',
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(q.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13)),
                          const SizedBox(height: 4),
                          Text('${fmtDate(q.createdAt)} • ${q.logs.length} catatan',
                              style: const TextStyle(color: Colors.black45, fontSize: 11)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _AdminComplaintDialog extends StatefulWidget {
  final Complaint q;
  const _AdminComplaintDialog({required this.q});

  @override
  State<_AdminComplaintDialog> createState() => _AdminComplaintDialogState();
}

class _AdminComplaintDialogState extends State<_AdminComplaintDialog> {
  late String _status = widget.q.status;
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.q;
    final name = store.customerById(q.customerId)?.name ?? '-';
    return AlertDialog(
      title: Text('Keluhan $name'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('[${q.category}] ${q.description}'),
              if (q.rating != null) ...[
                const SizedBox(height: 8),
                Text('Penilaian pelanggan: ${'★' * q.rating!}${'☆' * (5 - q.rating!)}',
                    style: const TextStyle(fontSize: 12, color: Colors.black54)),
              ],
              const SizedBox(height: 14),
              const Text('Riwayat penyelesaian', style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              ...q.logs.map(
                    (l) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('• ${fmtDate(l.date)}: ${l.text}', style: const TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _status,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                items: complaintStatuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) => setState(() => _status = v ?? _status),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _note,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Catatan penanganan', border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.red),
          onPressed: () async {
            final messenger = ScaffoldMessenger.of(context);
            final err = await store.updateComplaint(q, _status, _note.text);
            if (!mounted) return;
            if (err != null) {
              snack(context, err);
              return;
            }
            Navigator.pop(context);
            messenger.showSnackBar(const SnackBar(content: Text('Keluhan diperbarui')));
          },
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
