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
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        MealyTheme.nearlyOrange,
                        MealyTheme.nearlyOrange.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomRight: Radius.circular(8.0),
                      bottomLeft: Radius.circular(8.0),
                      topLeft: Radius.circular(8.0),
                      topRight: Radius.circular(40.0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: MealyTheme.nearlyOrange.withOpacity(0.4),
                        offset: const Offset(2, 4),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.restaurant_menu,
                    size: 50,
                    color: MealyTheme.white,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Welcome to Mealy',
                  style: TextStyle(
                    fontFamily: MealyTheme.fontName,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: MealyTheme.darkerText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'AI-Powered Meal Planning',
                  style: TextStyle(
                    fontFamily: MealyTheme.fontName,
                    fontSize: 16,
                    color: MealyTheme.grey,
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
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: MealyTheme.white,
                borderRadius: const BorderRadius.only(
                  bottomRight: Radius.circular(8.0),
                  bottomLeft: Radius.circular(8.0),
                  topLeft: Radius.circular(8.0),
                  topRight: Radius.circular(68.0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: MealyTheme.grey.withOpacity(0.2),
                    offset: const Offset(1.1, 4.0),
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
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  MealyTheme.nearlyOrange,
                  MealyTheme.nearlyOrange.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: MealyTheme.nearlyOrange.withOpacity(0.4),
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
                            strokeWidth: 2,
                            color: MealyTheme.white,
                          ),
                        )
                      : const Text(
                          'Sign In',
                          style: TextStyle(
                            fontFamily: MealyTheme.fontName,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: MealyTheme.white,
                          ),
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
              border: Border.all(color: MealyTheme.nearlyOrange, width: 2),
              boxShadow: [
                BoxShadow(
                  color: MealyTheme.grey.withOpacity(0.1),
                  offset: const Offset(0, 2),
                  blurRadius: 8,
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
                    Icon(Icons.play_arrow, color: MealyTheme.nearlyOrange),
                    const SizedBox(width: 8),
                    Text(
                      'Continue as Demo User',
                      style: TextStyle(
                        fontFamily: MealyTheme.fontName,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: MealyTheme.nearlyOrange,
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Don't have an account? ",
                style: TextStyle(
                  fontFamily: MealyTheme.fontName,
                  color: MealyTheme.grey,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SignupScreen()),
                  );
                },
                child: const Text(
                  'Sign Up',
                  style: TextStyle(
                    fontFamily: MealyTheme.fontName,
                    fontWeight: FontWeight.bold,
                    color: MealyTheme.nearlyOrange,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
