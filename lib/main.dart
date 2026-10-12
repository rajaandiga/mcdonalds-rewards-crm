import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/core.dart';
import 'core/supabase_config.dart';
import 'pages/admin/admin_shell.dart';
import 'pages/customer/customer_shell.dart';
import 'pages/login_page.dart';

// ============================================================
// CRM MEMBER APP - STUDI KASUS MCDONALD'S
// Data disimpan di Supabase (database + login saja, tanpa hosting).
// ============================================================
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(url: SupabaseConfig.url, anonKey: SupabaseConfig.anonKey);
    await store.load();
  }
  runApp(const McdCrmApp());
}

class McdCrmApp extends StatelessWidget {
  const McdCrmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "McDonald's Rewards",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.red,
          primary: AppColors.red,
          secondary: AppColors.yellow,
        ),
        scaffoldBackgroundColor: AppColors.bg,
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: AppColors.yellow,
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      // Garis kemajuan tipis di atas layar saat ada proses ke server.
      builder: (context, child) => Stack(
        children: [
          child ?? const SizedBox.shrink(),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Observe((_) => store.working
                ? const LinearProgressIndicator(minHeight: 3)
                : const SizedBox.shrink()),
          ),
        ],
      ),
      home: SupabaseConfig.isConfigured ? const AuthGate() : const _SetupNeeded(),
    );
  }
}

/// Memilih halaman awal sesuai status login: login, admin, atau pelanggan.
/// Data dimuat ulang otomatis saat aplikasi kembali dibuka.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && store.currentId != null && !store.working) {
      store.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        if (!store.loaded) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (store.currentId == null) return const LoginPage();
        if (store.isAdmin) return const AdminShell();
        return const CustomerShell();
      },
    );
  }
}

/// Ditampilkan bila URL dan kunci Supabase belum diisi.
class _SetupNeeded extends StatelessWidget {
  const _SetupNeeded();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text(
            'Aplikasi belum terhubung ke database.\n\n'
                'Isi URL dan anon key Supabase di file\nlib/core/supabase_config.dart,\n'
                'lalu jalankan ulang aplikasi.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, height: 1.5),
          ),
        ),
      ),
    );
  }
}
