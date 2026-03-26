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
  String? _errorMessage;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // Responsive helpers
  double get _sw => MediaQuery.of(context).size.width;
  double get _sh => MediaQuery.of(context).size.height;
  double get _hPad => (_sw * 0.065).clamp(20.0, 32.0);
  double get _cardPad => (_sw * 0.07).clamp(20.0, 32.0);
  double get _titleSize => (_sw * 0.085).clamp(26.0, 38.0);
  double get _subtitleSize => (_sw * 0.034).clamp(12.0, 16.0);
  double get _headingSize => (_sw * 0.060).clamp(18.0, 26.0);
  double get _bodySize => (_sw * 0.036).clamp(13.0, 16.0);
  double get _buttonHeight => (_sh * 0.068).clamp(48.0, 60.0);
  double get _fieldSpacing => (_sh * 0.020).clamp(12.0, 20.0);

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

  Future<void> _showForgotPassword() async {
    final c = AppColors.of(context);
    final emailCtrl = TextEditingController(text: _emailController.text.trim());
    final formKey = GlobalKey<FormState>();
    bool sending = false;
    bool sent = false;
    String? error;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: c.sheetBg,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  border: Border(top: BorderSide(color: c.cardBorder)),
                ),
                padding: EdgeInsets.fromLTRB(_cardPad, 20, _cardPad, _cardPad + 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 36, height: 4,
                        decoration: BoxDecoration(
                          color: c.divider,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    SizedBox(height: _fieldSpacing * 1.2),
                    // Icon + title
                    Row(
                      children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: c.accentBg,
                            border: Border.all(color: c.accentBorder),
                          ),
                          child: Icon(Icons.lock_reset_rounded, color: c.accent, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Reset Password',
                                style: TextStyle(fontFamily: 'Nunito',
                                    color: c.primaryText,
                                    fontSize: _headingSize * 0.88,
                                    fontWeight: FontWeight.w700)),
                            Text("We'll send a reset link to your email",
                                style: TextStyle(color: c.secondaryText, fontSize: _bodySize * 0.85)),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: _fieldSpacing * 1.4),
                    if (!sent) ...[
                      Form(
                        key: formKey,
                        child: TextFormField(
                          controller: emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.done,
                          style: TextStyle(color: c.fieldText, fontSize: _bodySize),
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          onFieldSubmitted: (_) async {
                            if (!formKey.currentState!.validate() || sending) return;
                            setSheetState(() { sending = true; error = null; });
                            try {
                              await _authService.sendPasswordResetEmail(emailCtrl.text.trim());
                              setSheetState(() { sent = true; sending = false; });
                            } on FirebaseAuthException catch (e) {
                              setSheetState(() {
                                sending = false;
                                error = e.code == 'user-not-found'
                                    ? 'No account found with this email.'
                                    : e.code == 'invalid-email'
                                        ? 'Please enter a valid email.'
                                        : 'Something went wrong. Try again.';
                              });
                            }
                          },
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Enter your email';
                            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) return 'Enter a valid email';
                            return null;
                          },
                          decoration: InputDecoration(
                            labelText: 'Email address',
                            labelStyle: TextStyle(color: c.fieldLabel, fontSize: _bodySize * 0.9),
                            prefixIcon: Icon(Icons.email_outlined, color: c.fieldIcon, size: _bodySize * 1.3),
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
                          ),
                        ),
                      ),
                      if (error != null) ...[
                        SizedBox(height: _fieldSpacing),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6B6B).withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFFF6B6B).withValues(alpha: 0.30)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Color(0xFFFF6B6B), size: 16),
                              const SizedBox(width: 8),
                              Expanded(child: Text(error!,
                                  style: TextStyle(color: const Color(0xFFFF6B6B), fontSize: _bodySize * 0.875))),
                            ],
                          ),
                        ),
                      ],
                      SizedBox(height: _fieldSpacing * 1.4),
                      SizedBox(
                        height: _buttonHeight,
                        child: ElevatedButton(
                          onPressed: sending ? null : () async {
                            if (!formKey.currentState!.validate()) return;
                            setSheetState(() { sending = true; error = null; });
                            try {
                              await _authService.sendPasswordResetEmail(emailCtrl.text.trim());
                              setSheetState(() { sent = true; sending = false; });
                            } on FirebaseAuthException catch (e) {
                              setSheetState(() {
                                sending = false;
                                error = e.code == 'user-not-found'
                                    ? 'No account found with this email.'
                                    : e.code == 'invalid-email'
                                        ? 'Please enter a valid email.'
                                        : 'Something went wrong. Try again.';
                              });
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5A9E1F),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: const Color(0xFF5A9E1F).withValues(alpha: 0.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          child: sending
                              ? SizedBox(
                                  width: _bodySize * 1.4, height: _bodySize * 1.4,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation(Colors.white),
                                  ),
                                )
                              : Text('Send Reset Link',
                                  style: TextStyle(fontSize: _bodySize, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                        ),
                      ),
                    ] else ...[
                      // Success state
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF34D399).withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF34D399).withValues(alpha: 0.30)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF34D399).withValues(alpha: 0.15),
                              ),
                              child: const Icon(Icons.check_rounded, color: Color(0xFF34D399), size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Reset link sent!',
                                      style: TextStyle(color: const Color(0xFF34D399),
                                          fontSize: _bodySize, fontWeight: FontWeight.w600)),
                                  Text('Check your inbox for ${emailCtrl.text.trim()}',
                                      style: TextStyle(color: c.secondaryText, fontSize: _bodySize * 0.85)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: _fieldSpacing * 1.4),
                      SizedBox(
                        height: _buttonHeight,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(sheetCtx),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5A9E1F),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          child: Text('Done',
                              style: TextStyle(fontSize: _bodySize, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    emailCtrl.dispose();
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
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Background gradient
          Container(
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
          ),

          // Hero image — full width from top edge, fades at bottom
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ShaderMask(
              shaderCallback: (rect) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, Colors.transparent],
                stops: [0.55, 1.0],
              ).createShader(rect),
              blendMode: BlendMode.dstIn,
              child: Image.asset(
                'assets/login.png',
                width: double.infinity,
                height: _sh * 0.36,
                fit: BoxFit.cover,
              ),
            ),
          ),

          // TeeStats text overlaid on bottom of the image
          Positioned(
            top: _sh * 0.22,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                children: [
                  Text(
                    'TeeStats',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      color: Colors.black,
                      fontSize: _titleSize,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Play  ·  Track  ·  Improve',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: _subtitleSize,
                      letterSpacing: 2.0,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom golf course decorative image
          Positioned(
            left: 0,
            right: 0,
            bottom: -4,
            child: IgnorePointer(
              child: ShaderMask(
                shaderCallback: (rect) => const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.white],
                  stops: [0.0, 0.35],
                ).createShader(rect),
                blendMode: BlendMode.dstIn,
                child: Image.asset(
                  'assets/bg_image.png',
                  fit: BoxFit.fitWidth,
                ),
              ),
            ),
          ),

          // Main content — no scroll, fits screen
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: _hPad),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Column(
                    children: [
                      // Space for hero image + overlaid text
                      SizedBox(height: _sh * 0.28),
                      _buildCard(),
                      SizedBox(height: _sh * 0.012),
                      _buildSignUpLink(),
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
                onPressed: _showForgotPassword,
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
          backgroundColor: const Color(0xFF5A9E1F),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFF5A9E1F).withValues(alpha: 0.5),
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


