import 'package:flutter/material.dart';

import '../core/core.dart';

// ============================================================
// LOGIN & REGISTER
// ============================================================
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _register = false;
  bool _hide = true;
  bool _busy = false;
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _id = TextEditingController();
  final _pw = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _id.dispose();
    _pw.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() => _busy = true);
    final String? err = _register
        ? await store.register(_name.text, _phone.text, _email.text, _pw.text)
        : await store.login(_id.text, _pw.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (err != null) snack(context, err);
  }

  InputDecoration _dec(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 40, 24, 48),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.red, Color(0xFFB51D12)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
                    child: Image.asset(
                      'assets/images/my_rewards.png',
                      height: 84,
                      errorBuilder: (_, __, ___) => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 6),
                        child: Text('McD Rewards',
                            style: TextStyle(color: AppColors.red, fontSize: 26, fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text("Sistem CRM McDonald's Indonesia",
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Box(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_register ? 'Daftar Member Baru' : 'Masuk',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 16),
                        if (_register) ...[
                          TextField(controller: _name, decoration: _dec('Nama lengkap', Icons.person_outline)),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _phone,
                            keyboardType: TextInputType.phone,
                            decoration: _dec('No. HP', Icons.phone_outlined),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            decoration: _dec('Email', Icons.email_outlined),
                          ),
                        ] else
                          TextField(
                            controller: _id,
                            keyboardType: TextInputType.emailAddress,
                            decoration: _dec('Email', Icons.email_outlined),
                          ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _pw,
                          obscureText: _hide,
                          decoration: _dec('Kata sandi', Icons.lock_outline).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(_hide ? Icons.visibility_off : Icons.visibility),
                              onPressed: () => setState(() => _hide = !_hide),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.red,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: _busy ? null : _submit,
                            child: Text(_busy ? 'Memproses...' : (_register ? 'Daftar' : 'Masuk')),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Center(
                          child: TextButton(
                            onPressed: () => setState(() => _register = !_register),
                            child: Text(_register ? 'Sudah punya akun? Masuk' : 'Belum punya akun? Daftar'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.yellow.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text(
                      'Belum punya akun? Pilih Daftar untuk menjadi member baru.',
                      style: TextStyle(fontSize: 12, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
