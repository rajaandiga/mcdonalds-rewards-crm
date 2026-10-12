import 'package:flutter/material.dart';

import '../../core/core.dart';

// ============================================================
// PROFIL PELANGGAN
// ============================================================
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ObserveMe((context, me) {
      final tier = tierFor(me.lifetime);
      final myTxns = store.txns.where((t) => t.customerId == me.id).toList();
      final spent = myTxns.fold<int>(0, (s, t) => s + t.amount);
      final activeVouchers = store.vouchers.where((v) => v.customerId == me.id && !v.used && !v.expired).length;
      Widget row(IconData i, String l, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(i, size: 20, color: AppColors.red),
            const SizedBox(width: 12),
            Text(l, style: const TextStyle(color: Colors.black54)),
            const SizedBox(width: 12),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(v, maxLines: 1, style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ),
      );
      return Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          title: const Text('Profil', style: TextStyle(fontWeight: FontWeight.w800)),
          centerTitle: true,
          backgroundColor: AppColors.bg,
          surfaceTintColor: Colors.transparent,
          actions: [
            IconButton(
              tooltip: 'Ubah profil',
              onPressed: () => showDialog(context: context, builder: (_) => _EditProfileDialog(me: me)),
              icon: const Icon(Icons.edit_outlined),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundColor: tier.color.withValues(alpha: 0.15),
                child: Text(me.name.isEmpty ? '?' : me.name[0].toUpperCase(),
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: tier.color)),
              ),
            ),
            const SizedBox(height: 10),
            Center(child: Text(me.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800))),
            const SizedBox(height: 4),
            Center(child: Pill('Member ${tier.name}', tier.color)),
            const SizedBox(height: 20),
            Box(
              child: Column(
                children: [
                  row(Icons.badge_outlined, 'ID Member', me.memberId),
                  row(Icons.phone_outlined, 'No. HP', me.phone),
                  row(Icons.email_outlined, 'Email', me.email),
                  row(Icons.cake_outlined, 'Tanggal lahir', me.birthDate == null ? '-' : fmtDate(me.birthDate!)),
                  row(Icons.wc_outlined, 'Jenis kelamin', me.gender.isEmpty ? '-' : me.gender),
                  row(Icons.location_city_outlined, 'Kota', me.city.isEmpty ? '-' : me.city),
                  row(Icons.event_outlined, 'Bergabung', fmtDate(me.joinDate)),
                ],
              ),
            ),
            if (me.birthDate == null)
              const Padding(
                padding: EdgeInsets.only(top: 8, left: 4),
                child: Text('Lengkapi tanggal lahir untuk mendapat voucher ulang tahun (jenjang Silver ke atas).',
                    style: TextStyle(fontSize: 12, color: Colors.black54)),
              ),
            const SizedBox(height: 12),
            Box(
              child: Column(
                children: [
                  row(Icons.stars_outlined, 'Saldo poin', '${me.points}'),
                  row(Icons.trending_up, 'Total poin seumur hidup', '${me.lifetime}'),
                  row(Icons.receipt_long_outlined, 'Jumlah transaksi', '${myTxns.length}'),
                  row(Icons.payments_outlined, 'Total belanja', rp(spent)),
                  row(Icons.confirmation_number_outlined, 'Voucher aktif', '$activeVouchers'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.red,
                side: const BorderSide(color: AppColors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: store.logout,
              icon: const Icon(Icons.logout),
              label: const Text('Keluar'),
            ),
          ],
        ),
      );
    });
  }
}

class _EditProfileDialog extends StatefulWidget {
  final Customer me;
  const _EditProfileDialog({required this.me});

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  late final _name = TextEditingController(text: widget.me.name);
  late final _phone = TextEditingController(text: widget.me.phone);
  late final _city = TextEditingController(text: widget.me.city);
  late String _gender = widget.me.gender;
  late DateTime? _birth = widget.me.birthDate;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _city.dispose();
    super.dispose();
  }

  Future<void> _pickBirth() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _birth ?? DateTime(now.year - 20, 1, 1),
      firstDate: DateTime(1940),
      lastDate: now,
    );
    if (d != null) setState(() => _birth = d);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ubah Profil'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Nama lengkap', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'No. HP', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _gender,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Jenis kelamin', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: '', child: Text('Tidak disebut')),
                  DropdownMenuItem(value: 'Laki-laki', child: Text('Laki-laki')),
                  DropdownMenuItem(value: 'Perempuan', child: Text('Perempuan')),
                ],
                onChanged: (v) => setState(() => _gender = v ?? ''),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _city,
                decoration: const InputDecoration(labelText: 'Kota', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: _pickBirth,
                  icon: const Icon(Icons.cake_outlined, size: 18),
                  label: Text(_birth == null ? 'Pilih tanggal lahir' : 'Lahir: ${fmtDate(_birth!)}'),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.red),
          onPressed: () async {
            final messenger = ScaffoldMessenger.of(context);
            final err = await store.updateProfile(
              widget.me,
              name: _name.text,
              phone: _phone.text,
              birthDate: _birth,
              gender: _gender,
              city: _city.text,
            );
            if (!mounted) return;
            if (err != null) {
              snack(context, err);
              return;
            }
            Navigator.pop(context);
            messenger.showSnackBar(const SnackBar(content: Text('Profil diperbarui')));
          },
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}