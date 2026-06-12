import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../services/firebase_service.dart';
import 'caregiver_patients_screen.dart';
import 'register_screen.dart';
import 'user_select_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _loading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final isTR = context.read<AppProvider>().language == 'TR';
    final username = _usernameController.text.trim().toLowerCase();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showMessage(
        isTR
            ? 'Kullanıcı adı ve şifre girin'
            : 'Enter username and password',
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final caregiverId = await FirebaseService.loginCaregiver(
        username: username,
        password: password,
      );

      if (!mounted) return;

      if (caregiverId == null) {
        setState(() => _loading = false);
        _showMessage(
          isTR
              ? 'Kullanıcı adı veya şifre hatalı'
              : 'Username or password is incorrect',
        );
        return;
      }

      await context.read<AppProvider>().loginCaregiver(
        username,
        caregiverId: caregiverId,
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CaregiverPatientsScreen()),
      );
    } catch (_) {
      if (!mounted) return;

      setState(() => _loading = false);
      _showMessage(
        isTR
            ? 'Kullanıcı adı veya şifre hatalı'
            : 'Username or password is incorrect',
      );
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTR = context.watch<AppProvider>().language == 'TR';

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFBA7517),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _loading
              ? null
              : () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const UserSelectScreen()),
            );
          },
        ),
        title: Text(isTR ? 'Bakıcı Girişi' : 'Caregiver Login'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFFFAEEDA),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Center(
                  child: Text('👨‍👩‍👧', style: TextStyle(fontSize: 34)),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isTR ? 'Hesabınıza giriş yapın' : 'Sign in to your account',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF633806),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isTR
                    ? 'Hasta bilgilerini yönetmek için bakıcı hesabınızı kullanın.'
                    : 'Use your caregiver account to manage patient information.',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              TextField(
                controller: _usernameController,
                enabled: !_loading,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: isTR ? 'Kullanıcı adı' : 'Username',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _passwordController,
                enabled: !_loading,
                obscureText: _obscurePassword,
                onSubmitted: (_) => _loading ? null : _login(),
                decoration: InputDecoration(
                  labelText: isTR ? 'Şifre' : 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: _loading
                        ? null
                        : () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFBA7517),
                    disabledBackgroundColor: Colors.grey.shade400,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : Text(
                    isTR ? 'Giriş Yap' : 'Sign In',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Center(
                child: TextButton(
                  onPressed: _loading
                      ? null
                      : () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RegisterScreen(),
                      ),
                    );
                  },
                  child: Text(
                    isTR
                        ? 'Hesabınız yok mu? Kayıt olun'
                        : 'No account yet? Sign up',
                    style: const TextStyle(
                      color: Color(0xFFBA7517),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}