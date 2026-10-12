import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/core.dart';

// ============================================================
// HALAMAN KARTU MEMBER (DEPAN & BELAKANG)
// ============================================================
class MemberCardPage extends StatefulWidget {
  const MemberCardPage({super.key});

  @override
  State<MemberCardPage> createState() => _MemberCardPageState();
}

class _MemberCardPageState extends State<MemberCardPage> {
  final GlobalKey _frontKey = GlobalKey();
  final GlobalKey _backKey = GlobalKey();
  bool _saving = false;

  Future<Uint8List> _capture(GlobalKey key) async {
    final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }

  Future<void> _download({required bool front, required bool back}) async {
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (!await Gal.hasAccess()) {
        await Gal.requestAccess();
      }
      if (front) await Gal.putImageBytes(await _capture(_frontKey));
      if (back) await Gal.putImageBytes(await _capture(_backKey));
      final label = front && back ? 'depan dan belakang' : (front ? 'depan' : 'belakang');
      messenger.showSnackBar(SnackBar(content: Text('Kartu member ($label) tersimpan di galeri')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Gagal menyimpan kartu: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8, top: 4),
    child: Text(t, style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black54)),
  );

  @override
  Widget build(BuildContext context) {
    return ObserveMe((context, me) {
      final tier = tierFor(me.lifetime);
      final next = nextTier(me.lifetime);
      return Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          title: const Text('Kartu Member', style: TextStyle(fontWeight: FontWeight.w800)),
          centerTitle: true,
          backgroundColor: AppColors.bg,
          surfaceTintColor: Colors.transparent,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: _label('Sisi depan')),
              Center(child: RepaintBoundary(key: _frontKey, child: CardFrontView(customer: me))),
              const SizedBox(height: 16),
              Center(child: _label('Sisi belakang')),
              Center(child: RepaintBoundary(key: _backKey, child: CardBackView(customer: me))),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _saving ? null : () => _download(front: true, back: true),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.red,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: _saving
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
                    : const Icon(Icons.download),
                label: Text(_saving ? 'Menyimpan...' : 'Unduh Depan & Belakang'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving ? null : () => _download(front: true, back: false),
                      child: const Text('Depan saja'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving ? null : () => _download(front: false, back: true),
                      child: const Text('Belakang saja'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Tunjukkan QR di sisi belakang ke kasir untuk mengumpulkan poin dan memakai voucher.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, fontSize: 12),
              ),
              const SizedBox(height: 24),
              Box(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Keuntungan ${tier.name}',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    const SizedBox(height: 8),
                    ...tier.benefits.map(
                          (b) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.check_circle, size: 16, color: AppColors.red),
                            const SizedBox(width: 8),
                            Expanded(child: Text(b, style: const TextStyle(fontSize: 13))),
                          ],
                        ),
                      ),
                    ),
                    if (next != null) ...[
                      const Divider(height: 24),
                      Text('${next.minPoints - me.lifetime} poin lagi untuk naik ke ${next.name}',
                          style: const TextStyle(color: Colors.black54, fontSize: 12)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

// ============================================================
// KARTU: SISI DEPAN
// ============================================================
class CardFrontView extends StatelessWidget {
  final Customer customer;
  const CardFrontView({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    final tier = tierFor(customer.lifetime);
    final dark = Color.lerp(tier.color, Colors.black, 0.35)!;

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: 340,
        height: 220,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [tier.color, dark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -50,
              top: -60,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.10)),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const AppLogo(size: 32),
                    const SizedBox(width: 10),
                    const Text('MEMBER CARD',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 1.2, fontSize: 13)),
                    const Spacer(),
                    Icon(tier.icon, color: Colors.white, size: 18),
                    const SizedBox(width: 4),
                    Text(tier.name.toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                  ],
                ),
                const Spacer(),
                Text(customer.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(customer.memberId,
                    style: const TextStyle(color: Colors.white70, fontSize: 13, letterSpacing: 1.5)),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Member sejak\n${fmtDate(customer.joinDate)}',
                        style: const TextStyle(color: Colors.white70, fontSize: 10, height: 1.3)),
                    const Spacer(),
                    Text('${customer.points}',
                        style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
                    const SizedBox(width: 4),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Text('poin', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// KARTU: SISI BELAKANG (QR berisi ID member untuk kasir)
// ============================================================
class CardBackView extends StatelessWidget {
  final Customer customer;
  const CardBackView({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    final tier = tierFor(customer.lifetime);
    final dark = Color.lerp(tier.color, Colors.black, 0.35)!;
    final bonus = (tier.bonus * 100).round();

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: 340,
        height: 220,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [dark, tier.color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Container(height: 28, width: double.infinity, color: Colors.black87),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                        child: QrImageView(
                          data: customer.memberId,
                          version: QrVersions.auto,
                          size: 64,
                          padding: EdgeInsets.zero,
                          backgroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('ID MEMBER',
                                style: TextStyle(color: Colors.white70, fontSize: 9, letterSpacing: 1.5)),
                            const SizedBox(height: 2),
                            Text(customer.memberId,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                            const SizedBox(height: 4),
                            const Text('Tunjukkan QR ini ke kasir',
                                style: TextStyle(color: Colors.white, fontSize: 10)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Jenjang ${tier.name}: bonus poin $bonus%. Kumpulkan 1 poin tiap Rp1.000. '
                        'Poin dapat ditukar dengan reward dan voucher di aplikasi. '
                        'Kartu ini hanya untuk pemilik yang tertera di sisi depan.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 9, height: 1.35),
                  ),
                  const SizedBox(height: 6),
                  const Text('Layanan pelanggan: gunakan menu Bantuan di aplikasi',
                      style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
