import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  bool _loading = false;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() => _loading = true);
    final result = await AuthService().signInWithGoogle();
    if (!mounted) return;
    setState(() => _loading = false);

    switch (result) {
      case SignInResult.success:
        ScaffoldMessenger.of(context).showSnackBar(
          _snack('Cuenta conectada correctamente', isSuccess: true),
        );
        context.pop();
      case SignInResult.cancelled:
        break;
      case SignInResult.error:
        ScaffoldMessenger.of(context).showSnackBar(
          _snack('Error al conectar. Verifica tu conexión.'),
        );
    }
  }

  SnackBar _snack(String msg, {bool isSuccess = false}) {
    return SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      content: Row(
        children: [
          Icon(
            isSuccess ? Icons.check_circle_rounded : Icons.error_outline_rounded,
            color: isSuccess ? const Color(0xFF00C896) : Colors.redAccent,
            size: 18,
          ),
          const SizedBox(width: 10),
          Flexible(child: Text(msg)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const Spacer(),

                // Logo
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: cs.primary.withValues(alpha: 0.2),
                        blurRadius: 24,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Image.asset('assets/logo.png'),
                ),
                const SizedBox(height: 28),

                const Text(
                  'Conecta tu cuenta',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'Sincroniza tus finanzas en todos tus\ndispositivos de forma segura.',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white.withValues(alpha: 0.5),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                // Benefits
                _BenefitRow(
                  icon: Icons.cloud_done_rounded,
                  color: cs.primary,
                  text: 'Backup automático en la nube',
                ),
                const SizedBox(height: 14),
                _BenefitRow(
                  icon: Icons.sync_rounded,
                  color: cs.secondary,
                  text: 'Accede desde cualquier dispositivo',
                ),
                const SizedBox(height: 14),
                const _BenefitRow(
                  icon: Icons.lock_rounded,
                  color: Color(0xFF8B5CF6),
                  text: 'Datos cifrados y solo tuyos (RLS)',
                ),

                const Spacer(),

                // Google button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _signIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.black54,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Google "G" logo
                              Container(
                                width: 22,
                                height: 22,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.g_mobiledata_rounded,
                                    size: 26, color: Colors.black87),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'Continuar con Google',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                TextButton(
                  onPressed: () => context.pop(),
                  child: Text(
                    'Usar sin cuenta',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 14,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  'Al conectar aceptas que tus datos se almacenen\nen Supabase con cifrado y acceso solo tuyo.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.2),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const _BenefitRow({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 14),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
