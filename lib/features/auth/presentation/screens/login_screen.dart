import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:jobspot_app/core/theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Image.asset('assets/images/auth_bg.png', width: 110, height: 110),

          // 3. Main Content Scroll View
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 60),

                  // Logo Placeholder (Recreated with code for portability)
                  // In a real app, replace this with: Image.asset('assets/logo.png', height: 100)
                  const JobSpotLogo(),

                  const SizedBox(height: 30),

                  Text(
                    'WELCOME',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: AppColors.primaryPurple,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Email Field
                  _CustomTextField(
                    controller: _emailController,
                    hintText: 'Email/Username',
                    keyboardType: TextInputType.emailAddress,
                  ),

                  const SizedBox(height: 16),

                  // Password Field
                  _CustomTextField(
                    controller: _passwordController,
                    hintText: 'Password',
                    obscureText: !_isPasswordVisible,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Login Button (Orange)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        // Handle Login
                        debugPrint("Login Pressed: ${_emailController.text}");
                      },
                      style: Theme.of(context).elevatedButtonTheme.style,
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Sign In Button (Light Grey)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: TextButton(
                      onPressed: () {
                        // Handle Sign In / Sign Up navigation
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.greyButtonColor,
                        foregroundColor: AppColors.primaryOrange, // Text color matches theme
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: const Text(
                        'Sign in',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      'Forgot password?',
                      style: TextStyle(color: Colors.black87),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Social Icons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _SocialButton(
                        color: Colors.red, // Google Red
                        child: const Text('G', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        onTap: () {},
                      ),
                      const SizedBox(width: 20),
                      _SocialButton(
                        color: const Color(0xFF1877F2), // Facebook Blue
                        child: const Text('f', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                        onTap: () {},
                      ),
                      const SizedBox(width: 20),
                      _SocialButton(
                        color: const Color(0xFF0077B5), // LinkedIn Blue
                        child: const Text('in', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        onTap: () {},
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Reusable Components ---

class _CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType keyboardType;

  const _CustomTextField({
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hintText,
          hintStyle: const TextStyle(color: Colors.black38),
        suffixIcon: suffixIcon,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.black12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.black12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF6A1B9A)), // Purple highlight
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final Color color;
  final Widget child;
  final VoidCallback onTap;

  const _SocialButton({
    required this.color,
    required this.child,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              offset: const Offset(0, 4),
              blurRadius: 8,
            )
          ],
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}

class _MapMarker extends StatelessWidget {
  final Color color;
  final double size;

  const _MapMarker({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.location_on,
      color: color,
      size: size,
    );
  }
}

// --- Logo Widget (Code-drawn to avoid asset dependency) ---

class JobSpotLogo extends StatelessWidget {
  const JobSpotLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 2,
              )
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [Image.asset('assets/icons/icon.png', width: 110, height: 110)
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "JobSpot",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Color(0xFF333333),
          ),
        )
      ],
    );
  }
}
