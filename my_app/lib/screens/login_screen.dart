import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/mealy_theme.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  AnimationController? animationController;
  Animation<double>? logoAnimation;
  Animation<double>? formAnimation;
  Animation<double>? buttonAnimation;

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    logoAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animationController!,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    formAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animationController!,
        curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
      ),
    );

    buttonAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animationController!,
        curve: const Interval(0.6, 1.0, curve: Curves.elasticOut),
      ),
    );

    animationController?.forward();
  }

  @override
  void dispose() {
    animationController?.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (mounted && !success && authProvider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error!),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              MealyTheme.background,
              MealyTheme.nearlyWhite,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  return Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildLogo(),
                        const SizedBox(height: 48),
                        _buildLoginCard(authProvider),
                        const SizedBox(height: 24),
                        _buildDemoButton(authProvider),
                        const SizedBox(height: 32),
                        _buildSignUpLink(),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: animationController!,
      builder: (context, child) {
        return FadeTransition(
          opacity: logoAnimation!,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - logoAnimation!.value)),
            child: Column(
              children: [
                // Enhanced logo with pulsing animation
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        MealyTheme.nearlyOrange,
                        MealyTheme.nearlyRed,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: MealyTheme.nearlyOrange.withOpacity(0.5),
                        offset: const Offset(0, 8),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: MealyTheme.nearlyRed.withOpacity(0.3),
                        offset: const Offset(0, 4),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: MealyTheme.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.restaurant,
                      size: 60,
                      color: MealyTheme.white,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Enhanced welcome text with gradient
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      MealyTheme.nearlyOrange,
                      MealyTheme.nearlyRed,
                    ],
                  ).createShader(bounds),
                  child: const Text(
                    'Welcome to Mealy',
                    style: TextStyle(
                      fontFamily: MealyTheme.fontName,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: MealyTheme.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        MealyTheme.nearlyGreen.withOpacity(0.2),
                        MealyTheme.nearlyYellow.withOpacity(0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 18,
                        color: MealyTheme.nearlyGreen,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'AI-Powered Meal Planning',
                        style: TextStyle(
                          fontFamily: MealyTheme.fontName,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: MealyTheme.darkerText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoginCard(AuthProvider authProvider) {
    return AnimatedBuilder(
      animation: animationController!,
      builder: (context, child) {
        return FadeTransition(
          opacity: formAnimation!,
          child: Transform.translate(
            offset: Offset(0, 50 * (1 - formAnimation!.value)),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: MealyTheme.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: MealyTheme.nearlyOrange.withOpacity(0.1),
                    offset: const Offset(0, 10),
                    blurRadius: 30.0,
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: MealyTheme.grey.withOpacity(0.05),
                    offset: const Offset(0, 4.0),
                    blurRadius: 12.0,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: MealyTheme.nearlyGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.login,
                          color: MealyTheme.nearlyGreen,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Sign In',
                        style: TextStyle(
                          fontFamily: MealyTheme.fontName,
                          fontWeight: FontWeight.w600,
                          fontSize: 20,
                          color: MealyTheme.darkerText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Email Field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: 'Enter your email',
                      prefixIcon: Icon(Icons.email_outlined, color: MealyTheme.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: MealyTheme.grey.withOpacity(0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: MealyTheme.grey.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: MealyTheme.nearlyOrange, width: 2),
                      ),
                      filled: true,
                      fillColor: MealyTheme.background,
                    ),
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
                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'Enter your password',
                      prefixIcon: Icon(Icons.lock_outline, color: MealyTheme.grey),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: MealyTheme.grey,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: MealyTheme.grey.withOpacity(0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: MealyTheme.grey.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: MealyTheme.nearlyOrange, width: 2),
                      ),
                      filled: true,
                      fillColor: MealyTheme.background,
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
                  const SizedBox(height: 8),
                  // Forgot Password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Password reset coming soon!'),
                            backgroundColor: MealyTheme.nearlyOrange,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      },
                      child: Text(
                        'Forgot Password?',
                        style: TextStyle(
                          fontFamily: MealyTheme.fontName,
                          color: MealyTheme.nearlyOrange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Login Button
                  _buildLoginButton(authProvider),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoginButton(AuthProvider authProvider) {
    return AnimatedBuilder(
      animation: animationController!,
      builder: (context, child) {
        return ScaleTransition(
          scale: buttonAnimation!,
          child: Container(
            height: 58,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  MealyTheme.nearlyOrange,
                  MealyTheme.nearlyRed,
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: MealyTheme.nearlyOrange.withOpacity(0.5),
                  offset: const Offset(0, 8),
                  blurRadius: 20,
                ),
                BoxShadow(
                  color: MealyTheme.nearlyRed.withOpacity(0.3),
                  offset: const Offset(0, 4),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: authProvider.isLoading ? null : _handleLogin,
                child: Center(
                  child: authProvider.isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: MealyTheme.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Sign In',
                              style: TextStyle(
                                fontFamily: MealyTheme.fontName,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: MealyTheme.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              color: MealyTheme.white,
                              size: 22,
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDemoButton(AuthProvider authProvider) {
    return AnimatedBuilder(
      animation: animationController!,
      builder: (context, child) {
        return FadeTransition(
          opacity: buttonAnimation!,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: MealyTheme.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: MealyTheme.nearlyGreen, 
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: MealyTheme.nearlyGreen.withOpacity(0.15),
                  offset: const Offset(0, 4),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: authProvider.isLoading
                    ? null
                    : () async {
                        _emailController.text = 'demo@mealy.com';
                        _passwordController.text = 'demo123';
                        await _handleLogin();
                      },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.explore_outlined, 
                      color: MealyTheme.nearlyGreen,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Try Demo Mode',
                      style: TextStyle(
                        fontFamily: MealyTheme.fontName,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: MealyTheme.nearlyGreen,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSignUpLink() {
    return AnimatedBuilder(
      animation: animationController!,
      builder: (context, child) {
        return FadeTransition(
          opacity: buttonAnimation!,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            decoration: BoxDecoration(
              color: MealyTheme.nearlyYellow.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: MealyTheme.nearlyYellow.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_add_outlined,
                  color: MealyTheme.darkerText,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  "Don't have an account? ",
                  style: TextStyle(
                    fontFamily: MealyTheme.fontName,
                    color: MealyTheme.darkerText,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SignupScreen()),
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Sign Up',
                    style: TextStyle(
                      fontFamily: MealyTheme.fontName,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: MealyTheme.nearlyOrange,
                      decoration: TextDecoration.underline,
                      decorationColor: MealyTheme.nearlyOrange,
                      decorationThickness: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
