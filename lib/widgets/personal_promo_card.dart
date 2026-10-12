import 'package:flutter/material.dart';

import '../core/core.dart';

/// Kartu promo personal di Beranda. Isinya menyesuaikan segmen RFM pelanggan.
class PersonalPromoCard extends StatelessWidget {
  final Customer me;
  const PersonalPromoCard({super.key, required this.me});

  @override
  Widget build(BuildContext context) {
    final r = store.rfmOf(me);
    final next = nextTier(me.lifetime);
    String title;
    String text;
    IconData icon;

    switch (r.segment) {
      case 'Champions':
        title = 'Spesial untuk Pelanggan Terbaik';
        text = 'Kamu salah satu pelanggan paling setia. Akses awal menu baru dan reward eksklusif sudah menunggu.';
        icon = Icons.emoji_events;
        break;
      case 'Loyal':
        title = 'Tinggal Selangkah Lagi';
        text = 'Belanja dengan poin ganda di akhir pekan supaya jenjangmu cepat naik.';
        icon = Icons.trending_up;
        break;
      case 'Potensial':
        title = 'Yuk Mampir Lagi';
        text = 'Pakai voucher kunjungan ulang di jam makan siang untuk tambahan poin.';
        icon = Icons.schedule;
        break;
      case 'Berisiko':
        title = 'Kami Kangen Kamu';
        text = 'Sudah lama tidak mampir. Klaim voucher di tab Promo, berlaku untuk kunjungan berikutnya.';
        icon = Icons.favorite;
        break;
      case 'Tidak Aktif':
        title = 'Penawaran Kembali Datang';
        text = 'Ada penawaran terbatas untuk kamu. Cek tab Promo sebelum berakhir.';
        icon = Icons.notifications_active;
        break;
      default:
        title = 'Selamat Datang';
        text = 'Lakukan pesanan pertamamu dan nikmati diskon pelanggan baru.';
        icon = Icons.waving_hand;
    }

    final nudge = (next != null && next.minPoints - me.lifetime <= 300)
        ? '\nHanya ${next.minPoints - me.lifetime} poin lagi menuju ${next.name}.'
        : '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.yellow, Color(0xFFFFD966)]),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.red, borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('PROMO PERSONAL',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
                const SizedBox(height: 2),
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('$text$nudge', style: const TextStyle(fontSize: 12, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
