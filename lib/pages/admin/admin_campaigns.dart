import 'package:flutter/material.dart';

import '../../core/core.dart';

// ============================================================
// ADMIN: KAMPANYE
// ============================================================
class AdminCampaigns extends StatelessWidget {
  const AdminCampaigns({super.key});

  Widget _metric(String label, String value) => Expanded(
    child: Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
      ],
    ),
  );

  Future<void> _confirmDelete(BuildContext context, Campaign k) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus kampanye?'),
        content: Text('"${k.title}" akan dihapus dari daftar. Voucher yang sudah diklaim pelanggan tetap ada.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok == true) {
      final err = await store.deleteCampaign(k);
      if (err != null && context.mounted) snack(context, err);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Observe((context) {
      final list = [...store.campaigns]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return Scaffold(
        backgroundColor: AppColors.bg,
        appBar: adminBar(context, 'Kampanye CRM'),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: AppColors.red,
          foregroundColor: Colors.white,
          onPressed: () => showDialog(context: context, builder: (_) => const _NewCampaignDialog()),
          icon: const Icon(Icons.add),
          label: const Text('Kampanye Baru'),
        ),
        body: list.isEmpty
            ? const Center(child: Text('Belum ada kampanye. Tekan "Kampanye Baru" untuk membuat.'))
            : ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) {
            final k = list[i];
            final target = store.targetCount(k);
            final rate = target == 0 ? 0 : (k.claimedBy.length * 100 / target).round();
            return Box(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            Pill(k.type, typeColor(k.type)),
                            Pill('Target: ${targetLabel(k.target)}', AppColors.dark),
                            if (k.benefit.isNotEmpty) Pill(k.benefit, AppColors.green),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: () => _confirmDelete(context, k),
                        child: const Icon(Icons.delete_outline, size: 20, color: Colors.black45),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(k.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(k.desc, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text('Dibuat ${fmtDate(k.createdAt)}',
                      style: const TextStyle(color: Colors.black45, fontSize: 11)),
                  const Divider(height: 24),
                  Row(
                    children: [
                      _metric('Target', '$target'),
                      _metric('Dilihat', '${k.viewedBy.length}'),
                      _metric('Diklaim', '${k.claimedBy.length}'),
                      _metric('Engagement', '$rate%'),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      );
    });
  }
}

class _NewCampaignDialog extends StatefulWidget {
  const _NewCampaignDialog();

  @override
  State<_NewCampaignDialog> createState() => _NewCampaignDialogState();
}

class _NewCampaignDialogState extends State<_NewCampaignDialog> {
  final _title = TextEditingController();
  final _desc = TextEditingController();
  String _type = campaignTypes.first;
  String _target = 'Semua';
  String _discType = 'amount';
  final _discValue = TextEditingController();
  final _minSpend = TextEditingController(text: '0');
  final _maxDisc = TextEditingController(text: '0');

  int _num(TextEditingController c) => int.tryParse(c.text.replaceAll('.', '').trim()) ?? 0;

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _discValue.dispose();
    _minSpend.dispose();
    _maxDisc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Kampanye Baru'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Judul promo', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _desc,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Deskripsi', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _type,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Jenis kampanye', border: OutlineInputBorder()),
                items: campaignTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => setState(() => _type = v ?? _type),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _target,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Target penerima', border: OutlineInputBorder()),
                items: campaignTargets
                    .map((t) => DropdownMenuItem(value: t, child: Text(targetLabel(t))))
                    .toList(),
                onChanged: (v) => setState(() => _target = v ?? _target),
              ),
              const SizedBox(height: 6),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Jenis = tujuan promo. Target = siapa yang menerima (semua, segmen RFM, atau jenjang).',
                  style: TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ),
              const SizedBox(height: 14),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Voucher yang didapat penerima', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _discType,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Bentuk potongan', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'amount', child: Text('Potongan Rupiah')),
                  DropdownMenuItem(value: 'percent', child: Text('Diskon Persen')),
                ],
                onChanged: (v) => setState(() => _discType = v ?? _discType),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _discValue,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: _discType == 'percent' ? 'Besar diskon (%)' : 'Besar potongan (Rp)',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _minSpend,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Minimal belanja (Rp, 0 = bebas)', border: OutlineInputBorder()),
              ),
              if (_discType == 'percent') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _maxDisc,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Maksimal potongan (Rp, 0 = tanpa batas)', border: OutlineInputBorder()),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.red),
          onPressed: () async {
            if (_title.text.trim().isEmpty || _desc.text.trim().isEmpty) {
              snack(context, 'Judul dan deskripsi wajib diisi');
              return;
            }
            final value = _num(_discValue);
            if (value <= 0 || (_discType == 'percent' && value > 100)) {
              snack(context, _discType == 'percent' ? 'Diskon harus 1 sampai 100 persen' : 'Isi besar potongan voucher');
              return;
            }
            final messenger = ScaffoldMessenger.of(context);
            final err = await store.addCampaign(
              _title.text.trim(),
              _desc.text.trim(),
              _type,
              _target,
              discountType: _discType,
              discountValue: value,
              minSpend: _num(_minSpend),
              maxDiscount: _discType == 'percent' ? _num(_maxDisc) : 0,
            );
            if (!mounted) return;
            if (err != null) {
              snack(context, err);
              return;
            }
            Navigator.pop(context);
            messenger.showSnackBar(const SnackBar(content: Text('Kampanye dipublikasikan')));
          },
          child: const Text('Publikasikan'),
        ),
      ],
    );
  }
}
