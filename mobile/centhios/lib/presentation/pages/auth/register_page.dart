import 'package:centhios/app_theme.dart';
import 'package:centhios/core/services/firebase_providers.dart';
import 'package:centhios/main.dart';
import 'package:centhios/presentation/pages/auth/login_page.dart';
import 'package:centhios/presentation/widgets/aurora_background.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  Future<void> _register() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final auth = ref.read(firebaseAuthProvider);

    try {
      final userCredential = await auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      await userCredential.user?.updateDisplayName(
        '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(e.message ?? 'Registration failed. Please try again.'),
            backgroundColor: AppTheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: ${e.toString()}'),
            backgroundColor: AppTheme.primary,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const AuroraBackground(),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Create Account',
                          style: Theme.of(context).textTheme.displayMedium),
                      const SizedBox(height: 8),
                      Text('Start your financial journey',
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(color: AppTheme.textSecondary)),
                      const SizedBox(height: 48),
                      Row(
                        children: [
                          Expanded(
                              child: TextFormField(
                                  controller: _firstNameController,
                                  decoration: const InputDecoration(
                                      labelText: 'First Name'))),
                          const SizedBox(width: 16),
                          Expanded(
                              child: TextFormField(
                                  controller: _lastNameController,
                                  decoration: const InputDecoration(
                                      labelText: 'Last Name'))),
                        ],
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(labelText: 'Email'),
                          keyboardType: TextInputType.emailAddress),
                      const SizedBox(height: 24),
                      TextFormField(
                          controller: _phoneController,
                          decoration:
                              const InputDecoration(labelText: 'Phone Number'),
                          keyboardType: TextInputType.phone),
                      const SizedBox(height: 24),
                      TextFormField(
                          controller: _passwordController,
                          decoration:
                              const InputDecoration(labelText: 'Password'),
                          obscureText: true),
                      const SizedBox(height: 48),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _register,
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    AppTheme.textPrimary))
                            : const Text('REGISTER'),
                      ),
                      const SizedBox(height: 24),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (context) => const LoginPage()),
                          );
                        },
                        child: Text('Already have an account? Login',
                            style: TextStyle(color: AppTheme.textSecondary)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
