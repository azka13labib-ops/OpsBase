import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _handleLogin() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthService.loginWithDiscord();
    } catch (e) {
      debugPrint('Login error details: $e');
      setState(() => _error = 'Gagal membuka halaman login: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Pure white background to match image
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Top spacing to push content down slightly like the image
                const SizedBox(height: 40),

                // Illustration Image
                Image.asset(
                  'assets/images/login_illustration.png',
                  height: 280,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const SizedBox(
                      height: 280,
                      child: Center(
                        child: Icon(Icons.broken_image,
                            size: 64, color: Colors.grey),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 48),

                // LOGIN Title
                const Text(
                  "Welcome Back",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle
                const Text(
                  "Securely authenticate with your Discord account.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 48),

                if (_error != null) ...[
                  Text(_error!,
                      style: const TextStyle(color: Colors.redAccent)),
                  const SizedBox(height: 16),
                ],

                // Discord Login Button
                SizedBox(
                  width: 240, // Wider to fit the icon and text nicely
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xFF5865F2), // Discord Blurple
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.discord, size: 24),
                    label: const Text(
                      'Login with Discord',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 48),

                // Simple Help Link that opens WhatsApp
                TextButton(
                  onPressed: () async {
                    final Uri waUrl = Uri.parse('https://wa.me/6283155761573');
                    try {
                      await launchUrl(waUrl,
                          mode: LaunchMode.externalApplication);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Tidak dapat membuka WhatsApp')),
                        );
                      }
                    }
                  },
                  child: const Text(
                    "Need Help?",
                    style: TextStyle(
                      color: Colors.black45,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),

                const SizedBox(height: 48),

                // Access Note
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    "Only server administrators & moderators are authorized to access this panel.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black38,
                      height: 1.5,
                    ),
                  ),
                ),

                const SizedBox(height: 48), // Bottom padding
              ],
            ),
          ),
        ),
      ),
    );
  }
}
