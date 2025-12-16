import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/router/app_router.dart';
import '../../domain/providers/auth_provider.dart';

/// Key for tracking if onboarding was shown
const String _onboardingShownKey = 'onboarding_shown';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSignUp = false;

  // For signup
  final _nameController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;

  // Animations
  late AnimationController _backgroundController;
  late AnimationController _formController;
  late AnimationController _heartController;
  late Animation<double> _formSlideAnimation;
  late Animation<double> _formFadeAnimation;

  // Floating hearts
  final List<_FloatingHeart> _hearts = [];

  @override
  void initState() {
    super.initState();

    // Background animation (continuous)
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    // Form animation
    _formController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _formSlideAnimation = Tween<double>(begin: 50, end: 0).animate(
      CurvedAnimation(parent: _formController, curve: Curves.easeOutCubic),
    );

    _formFadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _formController, curve: Curves.easeOut),
    );

    // Heart pulse animation
    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Generate floating hearts
    _generateHearts();

    // Start form animation
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _formController.forward();
    });
  }

  void _generateHearts() {
    final random = math.Random();
    for (int i = 0; i < 15; i++) {
      _hearts.add(_FloatingHeart(
        x: random.nextDouble(),
        y: random.nextDouble(),
        size: 10 + random.nextDouble() * 25,
        speed: 0.2 + random.nextDouble() * 0.5,
        opacity: 0.1 + random.nextDouble() * 0.2,
        delay: random.nextDouble() * 2,
      ));
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _confirmPasswordController.dispose();
    _backgroundController.dispose();
    _formController.dispose();
    _heartController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isSignUp && !_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to the Terms of Service'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    bool success;
    if (_isSignUp) {
      success = await ref.read(authProvider.notifier).signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
      );
    } else {
      success = await ref.read(authProvider.notifier).signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    }

    if (success && mounted) {
      await _navigateAfterAuth();
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final success = await ref.read(authProvider.notifier).signInWithGoogle();
    if (success && mounted) {
      await _navigateAfterAuth();
    }
  }

  Future<void> _navigateAfterAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final onboardingShown = prefs.getBool(_onboardingShownKey) ?? false;

    if (!mounted) return;

    if (!onboardingShown) {
      // First time auth - show onboarding
      await prefs.setBool(_onboardingShownKey, true);
      context.go('/onboarding');
    } else {
      // Already seen onboarding - go to home
      context.go(AppRoutes.home);
    }
  }

  void _toggleMode() {
    setState(() {
      _isSignUp = !_isSignUp;
      // Clear error when switching
      ref.read(authProvider.notifier).clearError();
    });
    // Animate form
    _formController.reset();
    _formController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Animated gradient background
          _buildAnimatedBackground(size),

          // Floating hearts
          ..._hearts.map((heart) => _buildFloatingHeart(heart, size)),

          // Content
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    SizedBox(height: size.height * 0.08),

                    // Animated logo
                    _buildAnimatedLogo(),

                    const SizedBox(height: 40),

                    // Form with animation
                    AnimatedBuilder(
                      animation: _formController,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _formSlideAnimation.value),
                          child: Opacity(
                            opacity: _formFadeAnimation.value,
                            child: _buildForm(authState),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground(Size size) {
    return AnimatedBuilder(
      animation: _backgroundController,
      builder: (context, child) {
        return Container(
          width: size.width,
          height: size.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF0D0D0D),
                Color.lerp(
                  const Color(0xFF1A0A10),
                  const Color(0xFF0A0A1A),
                  (math.sin(_backgroundController.value * math.pi * 2) + 1) / 2,
                )!,
                const Color(0xFF0D0D0D),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: CustomPaint(
            painter: _GlowPainter(
              animation: _backgroundController.value,
              color: AppColors.primary,
            ),
          ),
        );
      },
    );
  }

  Widget _buildFloatingHeart(_FloatingHeart heart, Size size) {
    return AnimatedBuilder(
      animation: _backgroundController,
      builder: (context, child) {
        final progress = (_backgroundController.value + heart.delay) % 1.0;
        final y = (heart.y - progress * heart.speed) % 1.0;
        final wobble = math.sin(progress * math.pi * 4) * 10;

        return Positioned(
          left: heart.x * size.width + wobble,
          top: y * size.height,
          child: Opacity(
            opacity: heart.opacity * (0.5 + 0.5 * math.sin(progress * math.pi * 2)),
            child: Icon(
              Icons.favorite,
              size: heart.size,
              color: AppColors.primary,
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedLogo() {
    return AnimatedBuilder(
      animation: _heartController,
      builder: (context, child) {
        final scale = 1.0 + 0.08 * _heartController.value;
        final glowOpacity = 0.3 + 0.2 * _heartController.value;

        return Column(
          children: [
            // Glowing heart logo
            Transform.scale(
              scale: scale,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, Color(0xFFE06B7A)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: glowOpacity),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.favorite,
                  color: Colors.white,
                  size: 50,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // App name with shimmer effect
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [
                  Colors.white,
                  AppColors.primary,
                  Colors.white,
                ],
                stops: [
                  0.0,
                  (_heartController.value),
                  1.0,
                ],
              ).createShader(bounds),
              child: Text(
                'FANCY',
                style: AppTypography.displayLarge.copyWith(
                  fontSize: 48,
                  letterSpacing: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isSignUp ? 'Create your story' : 'Find your match',
              style: AppTypography.bodyMedium.copyWith(
                color: Colors.white.withValues(alpha: 0.6),
                letterSpacing: 2,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildForm(AuthStateModel authState) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                _isSignUp ? 'Create Account' : 'Welcome Back',
                key: ValueKey(_isSignUp),
                style: AppTypography.headlineMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),

            // Name field (only for signup)
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: _isSignUp
                  ? Column(
                      children: [
                        _buildTextField(
                          controller: _nameController,
                          label: 'Name',
                          icon: Icons.person_outline,
                          textCapitalization: TextCapitalization.words,
                          validator: (value) {
                            if (_isSignUp && (value == null || value.isEmpty)) {
                              return 'Please enter your name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),

            // Email field
            _buildTextField(
              controller: _emailController,
              label: 'Email',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!value.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Password field
            _buildTextField(
              controller: _passwordController,
              label: 'Password',
              icon: Icons.lock_outline,
              obscureText: _obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your password';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),

            // Confirm password (only for signup)
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: _isSignUp
                  ? Column(
                      children: [
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _confirmPasswordController,
                          label: 'Confirm Password',
                          icon: Icons.lock_outline,
                          obscureText: _obscureConfirmPassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                            onPressed: () => setState(
                                () => _obscureConfirmPassword = !_obscureConfirmPassword),
                          ),
                          validator: (value) {
                            if (_isSignUp) {
                              if (value == null || value.isEmpty) {
                                return 'Please confirm your password';
                              }
                              if (value != _passwordController.text) {
                                return 'Passwords do not match';
                              }
                            }
                            return null;
                          },
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),

            // Forgot password (only for login)
            if (!_isSignUp) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _showForgotPasswordDialog,
                  child: Text(
                    'Forgot password?',
                    style: TextStyle(
                      color: AppColors.primary.withValues(alpha: 0.8),
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],

            // Terms checkbox (only for signup)
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: _isSignUp
                  ? Column(
                      children: [
                        const SizedBox(height: 16),
                        _buildTermsCheckbox(),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),

            const SizedBox(height: 24),

            // Error message
            if (authState.errorMessage != null)
              _buildErrorMessage(authState.errorMessage!),

            // Submit button
            _buildSubmitButton(authState),

            const SizedBox(height: 20),

            // Divider
            _buildDivider(),

            const SizedBox(height: 20),

            // Google button
            _buildGoogleButton(authState),

            const SizedBox(height: 24),

            // Toggle mode
            _buildToggleMode(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
        prefixIcon: Icon(icon, color: Colors.white.withValues(alpha: 0.5)),
        suffixIcon: suffixIcon,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: Colors.red),
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.03),
      ),
      validator: validator,
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: _agreeToTerms,
            onChanged: (value) => setState(() => _agreeToTerms = value ?? false),
            activeColor: AppColors.primary,
            side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _agreeToTerms = !_agreeToTerms),
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
                children: const [
                  TextSpan(text: 'I agree to the '),
                  TextSpan(
                    text: 'Terms of Service',
                    style: TextStyle(
                      color: AppColors.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  TextSpan(text: ' and '),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: TextStyle(
                      color: AppColors.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(AuthStateModel authState) {
    return GestureDetector(
      onTap: authState.isLoading ? null : _handleAuth,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 56,
        decoration: BoxDecoration(
          gradient: authState.isLoading
              ? LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.5),
                    const Color(0xFFE06B7A).withValues(alpha: 0.5),
                  ],
                )
              : const LinearGradient(
                  colors: [AppColors.primary, Color(0xFFE06B7A)],
                ),
          boxShadow: authState.isLoading
              ? []
              : [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Center(
          child: authState.isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isSignUp ? 'Create Account' : 'Sign In',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.white.withValues(alpha: 0.2),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'or continue with',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.2),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGoogleButton(AuthStateModel authState) {
    return GestureDetector(
      onTap: authState.isLoading ? null : _handleGoogleSignIn,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          color: Colors.white.withValues(alpha: 0.05),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(
              'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
              height: 24,
              width: 24,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    'G',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Google',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleMode() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isSignUp ? 'Already have an account? ' : "Don't have an account? ",
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
        GestureDetector(
          onTap: _toggleMode,
          child: Text(
            _isSignUp ? 'Sign In' : 'Sign Up',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: const Text(
          'Reset Password',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter your email address and we\'ll send you a link to reset your password.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Email',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: AppColors.primary),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
            ),
          ),
          TextButton(
            onPressed: () async {
              if (emailController.text.isNotEmpty) {
                final success = await ref
                    .read(authProvider.notifier)
                    .resetPassword(emailController.text.trim());
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Password reset email sent!'
                            : 'Failed to send reset email',
                      ),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Send',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Floating heart data
class _FloatingHeart {
  final double x;
  final double y;
  final double size;
  final double speed;
  final double opacity;
  final double delay;

  _FloatingHeart({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
    required this.delay,
  });
}

/// Custom painter for background glow effect
class _GlowPainter extends CustomPainter {
  final double animation;
  final Color color;

  _GlowPainter({required this.animation, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = RadialGradient(
        center: Alignment(
          math.sin(animation * math.pi * 2) * 0.3,
          math.cos(animation * math.pi * 2) * 0.3 - 0.3,
        ),
        radius: 1.2,
        colors: [
          color.withValues(alpha: 0.15),
          color.withValues(alpha: 0.05),
          Colors.transparent,
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Secondary glow
    final paint2 = Paint()
      ..shader = RadialGradient(
        center: Alignment(
          math.cos(animation * math.pi * 2 + 1) * 0.4,
          math.sin(animation * math.pi * 2 + 1) * 0.4 + 0.3,
        ),
        radius: 0.8,
        colors: [
          const Color(0xFFE06B7A).withValues(alpha: 0.1),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint2);
  }

  @override
  bool shouldRepaint(covariant _GlowPainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}
