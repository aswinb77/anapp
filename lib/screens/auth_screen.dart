import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/user_provider.dart';
import '../providers/feed_provider.dart';
import '../providers/favorites_provider.dart';
import '../main.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();

  static const _bg          = Color(0xFF141414);
  static const _surface     = Color(0xFF1A1A1A);
  static const _border      = Color(0xFF2A2A2A);
  static const _accent      = Color(0xFF7eafd4);
  static const _textPrimary = Color(0xFFFFFFFF);
  static const _textMuted   = Color(0x73FFFFFF);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  void _navigateToHome() {
    if (!mounted) return;
    // Kick off data loading NOW that we know the user is authenticated
    context.read<FeedProvider>().fetchPosts();
    context.read<FavoritesProvider>().reload();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainNavigation()),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _submit() async {
    final email    = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final username = _usernameController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError('Please fill in email and password');
      return;
    }

    final userProvider = context.read<UserProvider>();
    String? error;

    if (_isLogin) {
      error = await userProvider.login(email, password);
    } else {
      if (username.isEmpty) {
        _showError('Username is required');
        return;
      }
      error = await userProvider.register(username, email, password);
    }

    if (error == null) {
      _navigateToHome();
    } else {
      _showError(error);
    }
  }

  Future<void> _submitGoogle() async {
    final error = await context.read<UserProvider>().signInWithGoogle();
    if (error == null) {
      _navigateToHome();
    } else {
      _showError(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<UserProvider>().isLoading;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.film, size: 64, color: _accent),
                const SizedBox(height: 24),
                Text(
                  _isLogin ? 'Welcome back' : 'Create account',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isLogin ? 'Sign in to continue' : 'Join the community',
                  style: const TextStyle(fontSize: 14, color: _textMuted),
                ),
                const SizedBox(height: 32),
                if (!_isLogin) ...[
                  _buildTextField(
                    controller: _usernameController,
                    hint: 'Username',
                    icon: LucideIcons.user,
                  ),
                  const SizedBox(height: 16),
                ],
                _buildTextField(
                  controller: _emailController,
                  hint: 'Email address',
                  icon: LucideIcons.mail,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _passwordController,
                  hint: 'Password (min 6 chars)',
                  icon: LucideIcons.lock,
                  obscureText: true,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: _bg,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: _bg, strokeWidth: 2),
                          )
                        : Text(
                            _isLogin ? 'Sign in' : 'Sign up',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: isLoading ? null : _submitGoogle,
                    icon: const Icon(LucideIcons.chrome, size: 20, color: _textPrimary),
                    label: const Text(
                      'Continue with Google',
                      style: TextStyle(color: _textPrimary, fontSize: 16),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: _border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () => setState(() => _isLogin = !_isLogin),
                  child: Text(
                    _isLogin
                        ? "Don't have an account? Sign up"
                        : 'Already have an account? Sign in',
                    style: const TextStyle(color: _textMuted, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: _textPrimary, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _textMuted, fontSize: 15),
        prefixIcon: Icon(icon, color: _textMuted, size: 20),
        filled: true,
        fillColor: _surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _accent),
        ),
      ),
    );
  }
}
