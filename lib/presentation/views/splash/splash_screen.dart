// Flutter imports:
import 'dart:math' as math;
import 'package:flutter/material.dart';

// Project imports:
import 'package:cv_tech/core/constants/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Main logo animation
  late AnimationController _logoController;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _logoRotation;

  // Bounce/pulse effect
  late AnimationController _pulseController;
  late Animation<double> _pulseScale;

  // Text slide-up animations
  late AnimationController _textController;
  late Animation<Offset> _titleSlide;
  late Animation<double> _titleOpacity;
  late Animation<Offset> _subtitleSlide;
  late Animation<double> _subtitleOpacity;

  // Floating particles
  late AnimationController _particleController;

  // Loading bar
  late AnimationController _loadingController;

  @override
  void initState() {
    super.initState();

    // ── Logo: scale up from 0 + fade in + slight rotation ──
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
      ),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );
    _logoRotation = Tween<double>(begin: -0.15, end: 0.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    // ── Continuous gentle pulse ──
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );
    _pulseScale = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // ── Text slide up ──
    _textController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
    ));
    _titleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );
    _subtitleSlide = Tween<Offset>(
      begin: const Offset(0, 0.8),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
    ));
    _subtitleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeIn),
      ),
    );

    // ── Floating particles ──
    _particleController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    // ── Loading bar ──
    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    // Start animation sequence
    _startAnimations();
  }

  void _startAnimations() async {
    // Start particles immediately
    // Logo appears
    _logoController.forward();

    // After logo lands, start pulse + text
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    _pulseController.repeat(reverse: true);
    _textController.forward();

    // Start loading bar
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    _loadingController.forward();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _pulseController.dispose();
    _textController.dispose();
    _particleController.dispose();
    _loadingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
              Color(0xFF0F3460),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Floating particles background
            _buildParticles(),

            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 3),

                  // ── Animated Logo ──
                  AnimatedBuilder(
                    animation: Listenable.merge([_logoController, _pulseController]),
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _logoRotation.value,
                        child: Transform.scale(
                          scale: _logoScale.value * _pulseScale.value,
                          child: Opacity(
                            opacity: _logoOpacity.value,
                            child: Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(36),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFF26E22).withOpacity(0.4),
                                    blurRadius: 50,
                                    spreadRadius: 10,
                                  ),
                                  BoxShadow(
                                    color: const Color(0xFF1E293B).withOpacity(0.4),
                                    blurRadius: 70,
                                    spreadRadius: 6,
                                    offset: const Offset(10, 20),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(36),
                                child: Image.asset(
                                  'assets/logo/cvtech_logo.png',
                                  width: 200,
                                  height: 200,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => Container(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFFF26E22), Color(0xFF1E293B)],
                                      ),
                                      borderRadius: BorderRadius.circular(36),
                                    ),
                                    child: const Center(
                                      child: Text('CV', style: TextStyle(
                                        fontSize: 72, fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                      )),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 40),

                  // ── App Name ──
                  SlideTransition(
                    position: _titleSlide,
                    child: FadeTransition(
                      opacity: _titleOpacity,
                      child: ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [
                            Color(0xFFFFB07C),
                            Color(0xFFF26E22),
                            Color(0xFFE5530A),
                          ],
                        ).createShader(bounds),
                        child: const Text(
                          'CvTech',
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 3,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Subtitle ──
                  SlideTransition(
                    position: _subtitleSlide,
                    child: FadeTransition(
                      opacity: _subtitleOpacity,
                      child: const Text(
                        'Votre CV professionnel intelligent',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white60,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ),
                  ),

                  const Spacer(flex: 2),

                  // ── Animated loading indicator ──
                  AnimatedBuilder(
                    animation: _loadingController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _loadingController.value.clamp(0.0, 1.0),
                        child: Column(
                          children: [
                            // Gradient loading bar
                            Container(
                              width: 180,
                              height: 3,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(2),
                                color: Colors.white12,
                              ),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: AnimatedBuilder(
                                  animation: _loadingController,
                                  builder: (context, child) {
                                    return Container(
                                      width: 180 * _loadingController.value,
                                      height: 3,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(2),
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFFFFB07C),
                                            Color(0xFFF26E22),
                                            Color(0xFFE5530A),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Chargement...',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white38,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 60),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Floating Particles ──
  Widget _buildParticles() {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        return CustomPaint(
          size: MediaQuery.of(context).size,
          painter: _ParticlePainter(_particleController.value),
        );
      },
    );
  }
}

/// Draws subtle floating particles that drift upward
class _ParticlePainter extends CustomPainter {
  final double progress;
  _ParticlePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42); // Fixed seed for consistent positions
    final colors = [
      const Color(0xFFF26E22),
      const Color(0xFFFFB07C),
      const Color(0xFF1E293B),
      const Color(0xFFE5530A),
      const Color(0xFF64748B),
    ];

    for (int i = 0; i < 20; i++) {
      final baseX = random.nextDouble() * size.width;
      final baseY = random.nextDouble() * size.height;
      final speed = 0.3 + random.nextDouble() * 0.7;
      final particleSize = 2.0 + random.nextDouble() * 4.0;

      // Each particle drifts upward and wraps around
      final y = (baseY - progress * size.height * speed) % size.height;
      // Slight horizontal sway
      final x = baseX + math.sin(progress * math.pi * 2 + i) * 15;

      final opacity = 0.1 + random.nextDouble() * 0.25;
      final color = colors[i % colors.length].withOpacity(opacity);

      canvas.drawCircle(
        Offset(x, y),
        particleSize,
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
