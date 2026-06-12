import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../services/firebase_service.dart';
import 'caregiver_patients_screen.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
  TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final isTR = context.read<AppProvider>().language == 'TR';
    final name = _nameController.text.trim();
    final username = _usernameController.text.trim().toLowerCase();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (name.isEmpty ||
        username.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      _showMessage(
        isTR ? 'Lütfen tüm alanları doldurun' : 'Please fill in all fields',
      );
      return;
    }

    if (password.length < 6) {
      _showMessage(
        isTR
            ? 'Şifre en az 6 karakter olmalı'
            : 'Password must be at least 6 characters',
      );
      return;
    }

    if (password != confirmPassword) {
      _showMessage(
        isTR ? 'Şifreler eşleşmiyor' : 'Passwords do not match',
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final registered = await FirebaseService.registerCaregiver(
        fullName: name,
        username: username,
        password: password,
      );

      if (!mounted) return;

      if (!registered) {
        setState(() => _loading = false);
        _showMessage(
          isTR
              ? 'Bu kullanıcı adı zaten kullanılıyor'
              : 'This username is already taken',
        );
        return;
      }

      final caregiverId = await FirebaseService.loginCaregiver(
        username: username,
        password: password,
      );

      if (!mounted) return;

      context.read<AppProvider>().loginCaregiver(
        username,
        caregiverId: caregiverId ?? '',
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
            ? 'Kayıt sırasında bir hata oluştu'
            : 'An error occurred during sign up',
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
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          },
        ),
        title: Text(isTR ? 'Bakıcı Kaydı' : 'Caregiver Sign Up'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Text(
                isTR ? 'Yeni hesap oluşturun' : 'Create a new account',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF633806),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isTR
                    ? 'Bu hesap bakıcı paneline giriş yapmak için kullanılacak.'
                    : 'This account will be used to access the caregiver panel.',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _nameController,
                enabled: !_loading,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: isTR ? 'Ad Soyad' : 'Full name',
                  prefixIcon: const Icon(Icons.badge_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 14),
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
                textInputAction: TextInputAction.next,
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
              const SizedBox(height: 14),
              TextField(
                controller: _confirmPasswordController,
                enabled: !_loading,
                obscureText: _obscureConfirmPassword,
                onSubmitted: (_) => _loading ? null : _register(),
                decoration: InputDecoration(
                  labelText: isTR ? 'Şifre tekrar' : 'Confirm password',
                  prefixIcon: const Icon(Icons.lock_reset_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: _loading
                        ? null
                        : () {
                      setState(
                            () => _obscureConfirmPassword =
                        !_obscureConfirmPassword,
                      );
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
                  onPressed: _loading ? null : _register,
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
                    isTR ? 'Kayıt Ol' : 'Sign Up',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: _loading
                      ? null
                      : () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LoginScreen(),
                      ),
                    );
                  },
                  child: Text(
                    isTR
                        ? 'Zaten hesabınız var mı? Giriş yapın'
                        : 'Already have an account? Sign in',
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