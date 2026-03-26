import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
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
  bool _isAppleLoading = false;
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

  Future<void> _signInWithApple() async {
    setState(() {
      _isAppleLoading = true;
      _errorMessage = null;
    });
    try {
      await _authService.signInWithApple();
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _errorMessage = _friendlyError(e.code));
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code != AuthorizationErrorCode.canceled) {
        if (mounted) setState(() => _errorMessage = 'Apple sign-in failed: ${e.message}');
      }
      // Cancelled by user — silently dismiss
    } catch (e) {
      if (mounted) setState(() => _errorMessage = 'Apple sign-in failed: $e');
    } finally {
      if (mounted) setState(() => _isAppleLoading = false);
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
            SizedBox(height: _fieldSpacing * 1.2),
            _buildDivider(),
            SizedBox(height: _fieldSpacing * 1.2),
            _buildSocialButtons(),
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

  // Single row of icon-only sign-in buttons
  Widget _buildSocialButtons() {
    final c   = AppColors.of(context);
    final dia = _buttonHeight; // square buttons same height as primary button

    Widget iconBtn({
      required Widget icon,
      required bool loading,
      required VoidCallback onTap,
    }) {
      return GestureDetector(
        onTap: loading ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: dia,
          height: dia,
          decoration: BoxDecoration(
            color: c.sheetBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: c.fieldBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: loading
                ? SizedBox(
                    width: _bodySize * 1.2,
                    height: _bodySize * 1.2,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.black45),
                    ),
                  )
                : icon,
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (!kIsWeb && Platform.isIOS) ...[
          iconBtn(
            icon: FaIcon(FontAwesomeIcons.apple, size: dia * 0.42, color: c.primaryText),
            loading: _isAppleLoading,
            onTap: _signInWithApple,
          ),
          SizedBox(width: _buttonHeight * 0.4),
        ],
        iconBtn(
          icon: SvgPicture.string(
            _kGoogleLogoSvg,
            width: dia * 0.42,
            height: dia * 0.42,
          ),
          loading: _isGoogleLoading,
          onTap: _signInWithGoogle,
        ),
      ],
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

const String _kGoogleLogoSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
  <path fill="#EA4335" d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"/>
  <path fill="#4285F4" d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"/>
  <path fill="#FBBC05" d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"/>
  <path fill="#34A853" d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 2.3-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"/>
</svg>
''';

