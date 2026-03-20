import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  String? _errorMessage;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // Responsive helpers
  double get _sw => MediaQuery.of(context).size.width;
  double get _sh => MediaQuery.of(context).size.height;
  double get _hPad => (_sw * 0.065).clamp(20.0, 32.0);
  double get _cardPad => (_sw * 0.07).clamp(20.0, 32.0);
  double get _logoSize => (_sw * 0.20).clamp(64.0, 96.0);
  double get _logoIconSize => (_sw * 0.10).clamp(32.0, 48.0);
  double get _titleSize => (_sw * 0.085).clamp(26.0, 38.0);
  double get _subtitleSize => (_sw * 0.034).clamp(12.0, 16.0);
  double get _headingSize => (_sw * 0.060).clamp(18.0, 26.0);
  double get _bodySize => (_sw * 0.036).clamp(13.0, 16.0);
  double get _buttonHeight => (_sh * 0.068).clamp(48.0, 60.0);
  double get _fieldSpacing => (_sh * 0.020).clamp(12.0, 20.0);
  double get _sectionSpacing => (_sh * 0.040).clamp(20.0, 40.0);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.10),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await _authService.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _errorMessage = _friendlyError(e.code));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isGoogleLoading = true;
      _errorMessage = null;
    });
    try {
      await _authService.signInWithGoogle();
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _errorMessage = _friendlyError(e.code));
    } catch (_) {
      if (mounted) setState(() => _errorMessage = 'Google sign-in cancelled.');
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'invalid-email':
        return 'Please enter a valid email.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: c.bgGradient,
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: _hPad),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Column(
                    children: [
                      SizedBox(height: _sectionSpacing),
                      _buildLogo(),
                      SizedBox(height: _sectionSpacing),
                      _buildCard(),
                      SizedBox(height: _sectionSpacing * 0.8),
                      _buildSignUpLink(),
                      SizedBox(height: _sectionSpacing),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    final c = AppColors.of(context);
    return Column(
      children: [
        Container(
          width: _logoSize,
          height: _logoSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: c.iconContainerBg,
            border:
                Border.all(color: Colors.white.withValues(alpha: 0.18), width: 1.5),
          ),
          child: Icon(Icons.sports_golf, color: c.primaryText, size: _logoIconSize),
        ),
        SizedBox(height: _sh * 0.018),
        Text(
          'StatTee',
          style: TextStyle(fontFamily: 'Nunito',
            color: c.primaryText,
            fontSize: _titleSize,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        SizedBox(height: _sh * 0.008),
        Text(
          'Play  ·  Track  ·  Improve',
          style: TextStyle(
            color: c.secondaryText,
            fontSize: _subtitleSize,
            letterSpacing: 2.0,
          ),
        ),
      ],
    );
  }

  Widget _buildCard() {
    final c = AppColors.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: c.cardBorder, width: 1),
        boxShadow: c.cardShadow,
      ),
      padding: EdgeInsets.all(_cardPad),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Welcome back',
              style: TextStyle(fontFamily: 'Nunito',
                color: c.primaryText,
                fontSize: _headingSize,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: _sh * 0.006),
            Text(
              'Sign in to continue',
              style: TextStyle(
                color: c.secondaryText,
                fontSize: _bodySize * 0.9,
              ),
            ),
            SizedBox(height: _fieldSpacing * 1.4),
            _buildTextField(
              controller: _emailController,
              label: 'Email',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Enter your email';
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) {
                  return 'Enter a valid email';
                }
                return null;
              },
            ),
            SizedBox(height: _fieldSpacing),
            _buildTextField(
              controller: _passwordController,
              label: 'Password',
              icon: Icons.lock_outline,
              obscure: _obscurePassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _signIn(),
              suffixIcon: _visibilityToggle(
                _obscurePassword,
                () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Enter your password';
                return null;
              },
            ),
            SizedBox(height: _sh * 0.010),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Forgot password?',
                  style: TextStyle(
                    color: c.accent,
                    fontSize: _bodySize * 0.875,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            if (_errorMessage != null) ...[
              SizedBox(height: _fieldSpacing),
              _buildError(_errorMessage!),
            ],
            SizedBox(height: _fieldSpacing * 1.4),
            _buildPrimaryButton(),
            SizedBox(height: _fieldSpacing * 1.2),
            _buildDivider(),
            SizedBox(height: _fieldSpacing * 1.2),
            _buildGoogleButton(),
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
    TextInputAction? textInputAction,
    bool obscure = false,
    Widget? suffixIcon,
    void Function(String)? onFieldSubmitted,
    String? Function(String?)? validator,
  }) {
    final c = AppColors.of(context);
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      style: TextStyle(color: c.fieldText, fontSize: _bodySize),
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: _inputDecoration(label, icon, suffixIcon),
    );
  }

  InputDecoration _inputDecoration(
      String label, IconData icon, Widget? suffixIcon) {
    final c = AppColors.of(context);
    return InputDecoration(
      labelText: label,
      labelStyle:
          TextStyle(color: c.fieldLabel, fontSize: _bodySize * 0.9),
      prefixIcon: Icon(icon, color: c.fieldIcon, size: _bodySize * 1.3),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: c.fieldBg,
      errorStyle: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c.fieldBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c.accent, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFFF6B6B)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFFF6B6B), width: 1.5),
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: (_buttonHeight * 0.28).clamp(12.0, 18.0),
      ),
    );
  }

  Widget _visibilityToggle(bool obscure, VoidCallback onTap) {
    final c = AppColors.of(context);
    return IconButton(
      icon: Icon(
        obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        color: c.fieldIcon,
        size: _bodySize * 1.3,
      ),
      onPressed: onTap,
    );
  }

  Widget _buildPrimaryButton() {
    return SizedBox(
      height: _buttonHeight,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _signIn,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4F46E5),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFF4F46E5).withValues(alpha: 0.5),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: _isLoading
            ? SizedBox(
                width: _bodySize * 1.4,
                height: _bodySize * 1.4,
                child: const CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : Text(
                'Sign In',
                style: TextStyle(
                  fontSize: _bodySize,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }

  Widget _buildDivider() {
    final c = AppColors.of(context);
    return Row(
      children: [
        Expanded(
            child: Divider(
                color: c.divider, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'or continue with',
            style: TextStyle(
              color: c.tertiaryText,
              fontSize: _bodySize * 0.8,
            ),
          ),
        ),
        Expanded(
            child: Divider(
                color: c.divider, thickness: 1)),
      ],
    );
  }

  Widget _buildGoogleButton() {
    final c = AppColors.of(context);
    return SizedBox(
      height: _buttonHeight,
      child: OutlinedButton(
        onPressed: _isGoogleLoading ? null : _signInWithGoogle,
        style: OutlinedButton.styleFrom(
          foregroundColor: c.primaryText,
          side: BorderSide(color: c.fieldBorder),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: _isGoogleLoading
            ? SizedBox(
                width: _bodySize * 1.3,
                height: _bodySize * 1.3,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white54),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: _bodySize * 1.3,
                    height: _bodySize * 1.3,
                    child: CustomPaint(painter: _GoogleLogoPainter()),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Continue with Google',
                    style: TextStyle(
                      fontSize: _bodySize,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildError(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFF6B6B).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: const Color(0xFFFF6B6B).withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFFF6B6B), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                  color: const Color(0xFFFF6B6B), fontSize: _bodySize * 0.875),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignUpLink() {
    final c = AppColors.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account? ",
          style: TextStyle(
            color: c.secondaryText,
            fontSize: _bodySize,
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, a, b) => const SignUpScreen(),
              transitionsBuilder: (_, a, b, child) => SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1, 0),
                  end: Offset.zero,
                ).animate(
                    CurvedAnimation(parent: a, curve: Curves.easeOut)),
                child: child,
              ),
              transitionDuration: const Duration(milliseconds: 350),
            ),
          ),
          child: Text(
            'Sign Up',
            style: TextStyle(
              color: c.accent,
              fontSize: _bodySize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const segments = [
      (0.0, 0.5, Color(0xFF4285F4)),
      (0.5, 0.75, Color(0xFF34A853)),
      (0.75, 0.875, Color(0xFFFBBC05)),
      (0.875, 1.0, Color(0xFFEA4335)),
    ];
    for (final (start, end, color) in segments) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 1.5),
        start * 2 * 3.14159,
        (end - start) * 2 * 3.14159,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width * 0.16,
      );
    }
    canvas.drawRect(
      Rect.fromLTWH(
          size.width / 2, size.height / 2 - size.height * 0.15,
          size.width / 2, size.height * 0.30),
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
