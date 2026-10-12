import 'package:flutter/material.dart';

import '../../core/core.dart';
import '../../widgets/charts.dart';

// ============================================================
// ADMIN: LAPORAN CRM
// ============================================================
class AdminReportPage extends StatelessWidget {
  const AdminReportPage({super.key});

  Widget _kpi(String label, String value) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
        ],
      ),
    ),
  );

  Widget _cell(String t, {bool head = false, TextAlign align = TextAlign.center}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
    child: Text(t,
        textAlign: align,
        style: TextStyle(fontSize: 12, fontWeight: head ? FontWeight.w800 : FontWeight.w500)),
  );

  @override
  Widget build(BuildContext context) {
    return Observe((context) {
      final total = store.customers.length;
      final revenue = store.txns.fold<int>(0, (s, t) => s + t.amount);
      final aov = store.txns.isEmpty ? 0 : (revenue / store.txns.length).round();
      final repeat = store.customers.where((c) => store.rfmOf(c).frequency >= 2).length;
      final repeatRate = total == 0 ? 0 : (repeat * 100 / total).round();

      int targetSum = 0;
      int claimSum = 0;
      for (final k in store.campaigns) {
        targetSum += store.targetCount(k);
        claimSum += k.claimedBy.length;
      }
      final claimRate = targetSum == 0 ? 0 : (claimSum * 100 / targetSum).round();

      final done = store.complaints.where((q) => q.status == 'Selesai').length;
      final doneRate = store.complaints.isEmpty ? 0 : (done * 100 / store.complaints.length).round();

      final rated = store.complaints.where((q) => q.rating != null).toList();
      final avgRating = rated.isEmpty
          ? '-'
          : '${(rated.fold<int>(0, (s, q) => s + q.rating!) / rated.length).toStringAsFixed(1)} / 5';
      final positive = rated.isEmpty ? 0 : (rated.where((q) => q.rating! >= 4).length * 100 / rated.length).round();
      final vTotal = store.vouchers.length;
      final vUsed = store.vouchers.where((v) => v.used).length;
      final vUsedRate = vTotal == 0 ? 0 : (vUsed * 100 / vTotal).round();

      return Scaffold(
        backgroundColor: AppColors.bg,
        appBar: adminBar(context, 'Laporan CRM'),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(children: [
              _kpi('Rata-rata nilai pesanan', rp(aov)),
              const SizedBox(width: 10),
              _kpi('Pelanggan repeat order', '$repeatRate%'),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              _kpi('Klaim kampanye', '$claimRate%'),
              const SizedBox(width: 10),
              _kpi('Keluhan selesai', '$doneRate%'),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              _kpi('Kepuasan penanganan keluhan', avgRating),
              const SizedBox(width: 10),
              _kpi('Sentimen positif (rating 4-5)', rated.isEmpty ? '-' : '$positive%'),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              _kpi('Voucher diterbitkan', '$vTotal'),
              const SizedBox(width: 10),
              _kpi('Voucher terpakai', '$vUsedRate%'),
            ]),
            const SizedBox(height: 20),
            const SectionTitle('Penjualan 6 Bulan Terakhir'),
            const MonthlyRevenueChart(),
            const SizedBox(height: 20),
            const SectionTitle('Komposisi Segmen'),
            const SegmentDonut(),
            const SizedBox(height: 20),
            const SectionTitle('Ringkasan per Segmen'),
            Box(
              padding: const EdgeInsets.all(8),
              child: Table(
                columnWidths: const {
                  0: FlexColumnWidth(2.2),
                  1: FlexColumnWidth(1),
                  2: FlexColumnWidth(1.2),
                  3: FlexColumnWidth(2),
                },
                children: [
                  TableRow(children: [
                    _cell('Segmen', head: true, align: TextAlign.left),
                    _cell('Jumlah', head: true),
                    _cell('Rata-rata transaksi', head: true),
                    _cell('Total belanja', head: true),
                  ]),
                  ...segmentNames.map((s) {
                    final list = store.customers.where((c) => store.rfmOf(c).segment == s).toList();
                    final freq = list.fold<int>(0, (a, c) => a + store.rfmOf(c).frequency);
                    final mon = list.fold<int>(0, (a, c) => a + store.rfmOf(c).monetary);
                    final avg = list.isEmpty ? '-' : (freq / list.length).toStringAsFixed(1);
                    return TableRow(children: [
                      _cell(s, align: TextAlign.left),
                      _cell('${list.length}'),
                      _cell(avg),
                      _cell(rp(mon)),
                    ]);
                  }),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const SectionTitle('Keluhan per Kategori'),
            Box(
              child: Column(
                children: complaintCategories.map((cat) {
                  final all = store.complaints.where((q) => q.category == cat).length;
                  final open = store.complaints.where((q) => q.category == cat && q.status != 'Selesai').length;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(child: Text(cat, style: const TextStyle(fontSize: 13))),
                        Text('$all total • $open terbuka',
                            style: const TextStyle(fontSize: 12, color: Colors.black54)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
            const SectionTitle('Engagement Kampanye'),
            if (store.campaigns.isEmpty)
              const Text('Belum ada kampanye', style: TextStyle(color: Colors.black54))
            else
              ...store.campaigns.map((k) {
                final target = store.targetCount(k);
                final rate = target == 0 ? 0.0 : k.claimedBy.length / target;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Box(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(k.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: rate.clamp(0.0, 1.0),
                            minHeight: 8,
                            color: typeColor(k.type),
                            backgroundColor: Colors.black12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('${k.claimedBy.length} klaim dari $target target • dilihat ${k.viewedBy.length}',
                            style: const TextStyle(fontSize: 11, color: Colors.black54)),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      );
    });
  }
}
