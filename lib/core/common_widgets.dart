import 'package:flutter/material.dart';

import 'app_store.dart';
import 'constants.dart';
import 'models.dart';

// ============================================================
// WIDGET BANTU YANG DIPAKAI DI BANYAK HALAMAN
// ============================================================

/// Membangun ulang widget saat data store berubah.
class Observe extends StatelessWidget {
  final Widget Function(BuildContext) builder;
  const Observe(this.builder, {super.key});

  @override
  Widget build(BuildContext context) =>
      ListenableBuilder(listenable: store, builder: (ctx, _) => builder(ctx));
}

/// Sama seperti Observe, tetapi memberi data pelanggan yang sedang masuk.
class ObserveMe extends StatelessWidget {
  final Widget Function(BuildContext, Customer) builder;
  const ObserveMe(this.builder, {super.key});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (ctx, _) {
      final me = store.me;
      if (me == null) return const SizedBox.shrink();
      return builder(ctx, me);
    },
  );
}

class Pill extends StatelessWidget {
  final String text;
  final Color color;
  final Color fg;
  const Pill(this.text, this.color, {super.key, this.fg = Colors.white});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
    child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg)),
  );
}

class Box extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const Box({super.key, required this.child, this.padding = const EdgeInsets.all(14)});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
    child: child,
  );
}

class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(0, 4, 0, 10),
    child: Text(text, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.dark)),
  );
}

void snack(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}

/// App bar merah yang dipakai semua halaman admin.
AppBar adminBar(BuildContext context, String title, {List<Widget> extra = const []}) => AppBar(
  title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
  backgroundColor: AppColors.red,
  foregroundColor: Colors.white,
  surfaceTintColor: Colors.transparent,
  actions: [
    ...extra,
    IconButton(tooltip: 'Muat ulang', onPressed: store.refresh, icon: const Icon(Icons.refresh)),
    IconButton(tooltip: 'Keluar', onPressed: store.logout, icon: const Icon(Icons.logout)),
  ],
);

/// Logo aplikasi. Memakai file assets/images/logo.png bila ada;
/// bila belum ada, tampil ikon bawaan sehingga aplikasi tetap jalan.
class AppLogo extends StatelessWidget {
  final double size;
  const AppLogo({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size * 0.28);
    return ClipRRect(
      borderRadius: radius,
      child: Image.asset(
        'assets/images/logo.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: AppColors.yellow, borderRadius: radius),
          child: Icon(Icons.fastfood, color: AppColors.red, size: size * 0.55),
        ),
      ),
    );
  }
}

/// Banner promo di beranda. Memakai assets/images/promo_banner.png;
/// bila file belum ada, banner tidak ditampilkan.
class PromoBanner extends StatelessWidget {
  final VoidCallback? onTap;
  const PromoBanner({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Image.asset(
            'assets/images/promo_banner.png',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}
