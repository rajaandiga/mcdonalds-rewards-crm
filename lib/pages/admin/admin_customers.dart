import 'package:flutter/material.dart';

import '../../core/core.dart';
import '../../widgets/txn_dialog.dart';

// ============================================================
// ADMIN: PELANGGAN
// ============================================================
class AdminCustomers extends StatefulWidget {
  const AdminCustomers({super.key});

  @override
  State<AdminCustomers> createState() => _AdminCustomersState();
}

class _AdminCustomersState extends State<AdminCustomers> {
  String _q = '';
  String _seg = 'Semua';

  void _detail(BuildContext context, Customer c0) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Observe((_) {
          final c = store.customerById(c0.id) ?? c0;
          final r = store.rfmOf(c);
          final tier = tierFor(c.lifetime);
          final list = store.txns.where((t) => t.customerId == c.id).toList()
            ..sort((a, b) => b.date.compareTo(a.date));
          Widget kv(String k, String v) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Text(k, style: const TextStyle(color: Colors.black54)),
                const Spacer(),
                Text(v, style: const TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
          );
          return ListView(
            controller: controller,
            padding: const EdgeInsets.all(20),
            children: [
              Text(c.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('${c.memberId} • ${c.phone}', style: const TextStyle(color: Colors.black54)),
              Text(c.email, style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  Pill(tier.name, tier.color),
                  Pill(r.segment, segColors[r.segment] ?? Colors.grey),
                  Pill('Value ${r.value}', AppColors.dark),
                ],
              ),
              const SizedBox(height: 16),
              Box(
                child: Column(
                  children: [
                    kv('Recency', r.recency < 0 ? '-' : '${r.recency} hari lalu'),
                    kv('Frequency', '${r.frequency} transaksi'),
                    kv('Monetary', rp(r.monetary)),
                    const Divider(),
                    kv('Skor R / F / M', '${r.r} / ${r.f} / ${r.m}'),
                    kv('Saldo poin', '${c.points}'),
                    kv('Total poin seumur hidup', '${c.lifetime}'),
                    kv('Bergabung', fmtDate(c.joinDate)),
                    kv('Tanggal lahir', c.birthDate == null ? '-' : fmtDate(c.birthDate!)),
                    kv('Jenis kelamin', c.gender.isEmpty ? '-' : c.gender),
                    kv('Kota', c.city.isEmpty ? '-' : c.city),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Box(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Strategi CRM yang disarankan', style: TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(segStrategy[r.segment] ?? '', style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.red,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => showTxnDialog(context, fixed: c),
                icon: const Icon(Icons.add),
                label: const Text('Mode Kasir'),
              ),
              const SizedBox(height: 16),
              const SectionTitle('Riwayat Transaksi'),
              if (list.isEmpty)
                const Text('Belum ada transaksi', style: TextStyle(color: Colors.black54))
              else
                ...list.take(10).map(
                      (t) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Box(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text('${fmtDate(t.date)} • ${t.channel}',
                                style: const TextStyle(fontSize: 12, color: Colors.black54)),
                          ),
                          Text(rp(t.amount), style: const TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(width: 10),
                          Text('+${t.points}',
                              style: const TextStyle(color: AppColors.green, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Observe((context) {
      final q = _q.trim().toLowerCase();
      final list = store.customers
          .where((c) =>
      (q.isEmpty || c.name.toLowerCase().contains(q) || c.memberId.toLowerCase().contains(q)) &&
          (_seg == 'Semua' || store.rfmOf(c).segment == _seg))
          .toList()
        ..sort((a, b) => store.rfmOf(b).monetary.compareTo(store.rfmOf(a).monetary));
      return Scaffold(
        backgroundColor: AppColors.bg,
        appBar: adminBar(context, 'Data Pelanggan'),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: TextField(
                onChanged: (v) => setState(() => _q = v),
                decoration: InputDecoration(
                  hintText: 'Cari nama atau ID member',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
            ),
            SizedBox(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                children: ['Semua', ...segmentNames].map((s) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(s),
                      selected: _seg == s,
                      onSelected: (_) => setState(() => _seg = s),
                    ),
                  );
                }).toList(),
              ),
            ),
            Expanded(
              child: list.isEmpty
                  ? const Center(child: Text('Tidak ada pelanggan yang cocok'))
                  : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final c = list[i];
                  final r = store.rfmOf(c);
                  final tier = tierFor(c.lifetime);
                  return InkWell(
                    onTap: () => _detail(context, c),
                    borderRadius: BorderRadius.circular(16),
                    child: Box(
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: tier.color.withValues(alpha: 0.15),
                            child: Text(c.name[0].toUpperCase(),
                                style: TextStyle(color: tier.color, fontWeight: FontWeight.w800)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(c.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: [
                                    Pill(tier.name, tier.color),
                                    Pill(r.segment, segColors[r.segment] ?? Colors.grey),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text('R${r.r}  F${r.f}  M${r.m} • ${rp(r.monetary)}',
                                    style: const TextStyle(fontSize: 11, color: Colors.black54)),
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
            ),
          ],
        ),
      );
    });
  }
}
