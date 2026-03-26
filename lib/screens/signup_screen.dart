import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _authService = AuthService();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
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
  double get _headingSize => (_sw * 0.055).clamp(18.0, 24.0);
  double get _bodySize => (_sw * 0.036).clamp(13.0, 16.0);
  double get _buttonHeight => (_sh * 0.068).clamp(48.0, 60.0);
  double get _fieldSpacing => (_sh * 0.018).clamp(10.0, 18.0);
  double get _sectionSpacing => (_sh * 0.035).clamp(18.0, 36.0);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.10),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await _authService.signUpWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
        _nameController.text.trim(),
      );
      // Pop all screens — AuthGate will show HomeScreen
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _errorMessage = _friendlyError(e.code));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'operation-not-allowed':
        return 'Email sign-up is not enabled.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
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
          // Hero image — bleeds under status bar from the very top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ShaderMask(
              shaderCallback: (rect) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, Colors.transparent],
                stops: [0.6, 1.0],
              ).createShader(rect),
              blendMode: BlendMode.dstIn,
              child: Image.asset(
                'assets/login.png',
                width: double.infinity,
                height: _sh * 0.32,
                fit: BoxFit.cover,
              ),
            ),
          ),
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
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
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
                              // Space for hero image in Stack
                              SizedBox(height: _sh * 0.22),
                              _buildCard(),
                              SizedBox(height: _sectionSpacing * 0.8),
                              _buildSignInLink(),
                              SizedBox(height: _sectionSpacing),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    final c = AppColors.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: _hPad * 0.4, vertical: 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Container(
              width: (_sw * 0.095).clamp(34.0, 44.0),
              height: (_sw * 0.095).clamp(34.0, 44.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.iconContainerBg,
                border:
                    Border.all(color: c.iconContainerBorder),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: c.primaryText,
                size: _bodySize,
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
            _buildCardHeader(),
            SizedBox(height: _fieldSpacing * 1.4),
            _buildTextField(
              controller: _nameController,
              label: 'Full Name',
              icon: Icons.person_outline_rounded,
              textInputAction: TextInputAction.next,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter your name';
                return null;
              },
            ),
            SizedBox(height: _fieldSpacing),
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
              textInputAction: TextInputAction.next,
              onChanged: (_) => setState(() {}),
              suffixIcon: _visibilityToggle(
                _obscurePassword,
                () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Enter a password';
                if (v.length < 6) return 'Minimum 6 characters';
                return null;
              },
            ),
            SizedBox(height: _fieldSpacing),
            _buildTextField(
              controller: _confirmController,
              label: 'Confirm Password',
              icon: Icons.lock_outline,
              obscure: _obscureConfirm,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _signUp(),
              suffixIcon: _visibilityToggle(
                _obscureConfirm,
                () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Confirm your password';
                if (v != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
            if (_passwordController.text.isNotEmpty) ...[
              SizedBox(height: _fieldSpacing),
              _buildStrengthIndicator(),
            ],
            if (_errorMessage != null) ...[
              SizedBox(height: _fieldSpacing),
              _buildError(_errorMessage!),
            ],
            SizedBox(height: _fieldSpacing * 1.6),
            _buildPrimaryButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildCardHeader() {
    final c = AppColors.of(context);
    final iconSize = (_sw * 0.11).clamp(38.0, 52.0);
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create Account',
              style: TextStyle(fontFamily: 'Nunito',
                color: c.primaryText,
                fontSize: _headingSize,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Join TeeStats today',
              style: TextStyle(
                color: c.secondaryText,
                fontSize: _bodySize * 0.875,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStrengthIndicator() {
    final c = AppColors.of(context);
    final password = _passwordController.text;
    int strength = 0;
    if (password.length >= 6) strength++;
    if (password.length >= 10) strength++;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength++;
    if (RegExp(r'[0-9!@#\$%^&*]').hasMatch(password)) strength++;

    final labels = ['', 'Weak', 'Fair', 'Good', 'Strong'];
    final colors = [
      Colors.transparent,
      const Color(0xFFFF6B6B),
      const Color(0xFFFBBC05),
      const Color(0xFF8FD44E),
      const Color(0xFF5A9E1F),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(4, (i) {
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                height: 3,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: i < strength
                      ? colors[strength]
                      : c.fieldBorder,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        Text(
          'Password strength: ${labels[strength]}',
          style: TextStyle(
            color: colors[strength].withValues(alpha: 0.9),
            fontSize: _bodySize * 0.75,
          ),
        ),
      ],
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
    void Function(String)? onChanged,
    void Function(String)? onFieldSubmitted,
    String? Function(String?)? validator,
  }) {
    final c = AppColors.of(context);
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onChanged: onChanged,
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
      labelStyle: TextStyle(
          color: c.fieldLabel, fontSize: _bodySize * 0.9),
      prefixIcon:
          Icon(icon, color: c.fieldIcon, size: _bodySize * 1.3),
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
        borderSide:
            const BorderSide(color: Color(0xFFFF6B6B), width: 1.5),
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
        obscure
            ? Icons.visibility_outlined
            : Icons.visibility_off_outlined,
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
        onPressed: _isLoading ? null : _signUp,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF5A9E1F),
          foregroundColor: Colors.white,
          disabledBackgroundColor:
              const Color(0xFF5A9E1F).withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
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
                'Create Account',
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
        border: Border.all(
            color: const Color(0xFFFF6B6B).withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline,
              color: Color(0xFFFF6B6B), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                  color: const Color(0xFFFF6B6B),
                  fontSize: _bodySize * 0.875),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignInLink() {
    final c = AppColors.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account? ',
          style: TextStyle(
            color: c.secondaryText,
            fontSize: _bodySize,
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Text(
            'Sign In',
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
