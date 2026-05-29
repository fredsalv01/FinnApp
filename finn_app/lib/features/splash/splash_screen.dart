import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/sync_service.dart';
import '../../shared/services/user_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _scaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOutBack),
    );
    _pulseAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _fadeCtrl.forward();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;

    final prefs = UserPreferences();
    final done = await prefs.isOnboardingDone();
    if (!mounted) return;

    // If user has an active Supabase session, pull from cloud silently
    if (AuthService().isSignedIn) {
      SyncService().pullAll(); // fire-and-forget — don't block navigation
    }

    context.go(done ? '/' : '/onboarding');
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF00C896);

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (_, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: primary
                                  .withValues(alpha: _pulseAnim.value * 0.18),
                              width: 2,
                            ),
                          ),
                        ),
                        Container(
                          width: 155,
                          height: 155,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: primary
                                .withValues(alpha: _pulseAnim.value * 0.06),
                          ),
                        ),
                        child!,
                      ],
                    );
                  },
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF1A1A1A),
                      boxShadow: [
                        BoxShadow(
                          color: primary.withValues(alpha: 0.25),
                          blurRadius: 32,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Image.asset('assets/logo.png'),
                  ),
                ),

                const SizedBox(height: 40),

                const Text(
                  'Finn',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -1.0,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Tu finanzas, bajo control',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0x66FFFFFF),
                    letterSpacing: 0.2,
                  ),
                ),

                const SizedBox(height: 56),

                _PulsingDots(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PulsingDots extends StatefulWidget {
  @override
  State<_PulsingDots> createState() => _PulsingDotsState();
}

class _PulsingDotsState extends State<_PulsingDots>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _anims;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (_) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      );
    });
    _anims = _controllers.map((c) {
      return Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(parent: c, curve: Curves.easeInOut),
      );
    }).toList();
    _startSequence();
  }

  Future<void> _startSequence() async {
    while (mounted) {
      for (var i = 0; i < 3; i++) {
        if (!mounted) return;
        _controllers[i].forward(from: 0).then((_) => _controllers[i].reverse());
        await Future.delayed(const Duration(milliseconds: 160));
      }
      await Future.delayed(const Duration(milliseconds: 300));
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: AnimatedBuilder(
            animation: _anims[i],
            builder: (_, __) {
              return Opacity(
                opacity: _anims[i].value,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFF00C896),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
