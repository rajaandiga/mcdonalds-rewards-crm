import 'package:flutter/material.dart';

import '../../core/core.dart';
import '../../widgets/txn_dialog.dart';

// ============================================================
// ADMIN: DASHBOARD
// ============================================================
class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  Widget _stat(IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Observe((context) {
      final total = store.customers.length;
      final revenue = store.txns.fold<int>(0, (s, t) => s + t.amount);
      final open = store.complaints.where((q) => q.status != 'Selesai').length;
      final recent = ([...store.txns]..sort((a, b) => b.date.compareTo(a.date))).take(5).toList();

      int segCount(String s) => store.customers.where((c) => store.rfmOf(c).segment == s).length;
      int valCount(String v) => store.customers.where((c) => store.rfmOf(c).value == v).length;
      int tierCount(String n) => store.customers.where((c) => tierFor(c.lifetime).name == n).length;

      return Scaffold(
        backgroundColor: AppColors.bg,
        appBar: adminBar(context, 'Dashboard Admin'),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: AppColors.red,
          foregroundColor: Colors.white,
          onPressed: () => showTxnDialog(context),
          icon: const Icon(Icons.add),
          label: const Text('Mode Kasir'),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
          children: [
            Row(
              children: [
                _stat(Icons.people, 'Total pelanggan', '$total', AppColors.red),
                const SizedBox(width: 12),
                _stat(Icons.receipt_long, 'Total transaksi', '${store.txns.length}', AppColors.green),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _stat(Icons.payments, 'Total penjualan', rp(revenue), const Color(0xFF2E86C1)),
                const SizedBox(width: 12),
                _stat(Icons.report_problem, 'Keluhan terbuka', '$open', AppColors.orange),
              ],
            ),
            if (store.customers.isEmpty) ...[
              const SizedBox(height: 16),
              const Box(
                child: Text(
                  'Belum ada pelanggan. Data muncul setelah pelanggan mendaftar lewat aplikasi, '
                      'atau setelah data contoh dijalankan di Supabase (file 02_demo_data.sql).',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ),
            ],
            const SizedBox(height: 20),
            const SectionTitle('Segmentasi Pelanggan (RFM)'),
            Box(
              child: Column(
                children: segmentNames.map((s) {
                  final n = segCount(s);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(color: segColors[s], shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(s, style: const TextStyle(fontWeight: FontWeight.w700))),
                            Text('$n pelanggan', style: const TextStyle(color: Colors.black54, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: total == 0 ? 0 : n / total,
                            minHeight: 8,
                            color: segColors[s],
                            backgroundColor: Colors.black12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(segStrategy[s] ?? '', style: const TextStyle(fontSize: 11, color: Colors.black54)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
            const SectionTitle('Kategori Loyalitas & Customer Value'),
            Box(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Jenjang member', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: tiers.map((t) => Pill('${t.name}: ${tierCount(t.name)}', t.color)).toList(),
                  ),
                  const SizedBox(height: 14),
                  const Text('Customer value', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Pill('Tinggi: ${valCount('Tinggi')}', AppColors.green),
                      Pill('Sedang: ${valCount('Sedang')}', AppColors.orange),
                      Pill('Rendah: ${valCount('Rendah')}', const Color(0xFF7F8C8D)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const SectionTitle('Transaksi Terbaru'),
            if (recent.isEmpty)
              const Text('Belum ada transaksi', style: TextStyle(color: Colors.black54))
            else
              ...recent.map(
                    (t) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Box(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(store.customerById(t.customerId)?.name ?? '-',
                                  style: const TextStyle(fontWeight: FontWeight.w700)),
                              Text('${fmtDate(t.date)} • ${t.channel}',
                                  style: const TextStyle(color: Colors.black45, fontSize: 11)),
                            ],
                          ),
                        ),
                        Text(rp(t.amount), style: const TextStyle(fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}
