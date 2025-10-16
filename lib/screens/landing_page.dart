import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tulai/core/app_config.dart';
import 'package:tulai/core/design_system.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _supabase = Supabase.instance.client;

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Sign in with Supabase
      final response = await _supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (response.user != null) {
        // Get user role from database
        final userData = await _supabase
            .from('users')
            .select('role')
            .eq('id', response.user!.id)
            .single();

        final userRole = userData['role'] as String;

        // Verify the user is a teacher
        if (userRole != 'teacher') {
          setState(() {
            _errorMessage = 'Access denied. Teachers only.';
            _isLoading = false;
          });
          await _supabase.auth.signOut();
          return;
        }

        // Set user type in AppConfig
        AppConfig().userType = UserType.teacher;

        // Navigate to homepage
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/homepage');
        }
      }
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 800;

    return Scaffold(
      backgroundColor: TulaiColors.backgroundSecondary,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isLargeScreen ? TulaiSpacing.xxl * 2 : TulaiSpacing.xl,
            vertical: TulaiSpacing.xl,
          ),
          child: Center(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: isLargeScreen ? 600 : 450,
              ),
              child: TulaiCard(
                child: Padding(
                  padding: EdgeInsets.all(
                      isLargeScreen ? TulaiSpacing.xxl : TulaiSpacing.xl),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo
                        Container(
                          height: isLargeScreen ? 100 : 100,
                          padding: EdgeInsets.all(
                            isLargeScreen ? TulaiSpacing.md : TulaiSpacing.md,
                          ),
                          decoration: BoxDecoration(
                            color: TulaiColors.backgroundSecondary,
                            borderRadius:
                                BorderRadius.circular(TulaiBorderRadius.xl),
                            border: Border.all(
                              color: TulaiColors.borderLight,
                              width: 2,
                            ),
                          ),
                          child: Image.asset(
                            'assets/images/als-logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                        SizedBox(
                            height: isLargeScreen
                                ? TulaiSpacing.lg
                                : TulaiSpacing.lg),

                        // Welcome Text
                        Text(
                          'Teacher Portal',
                          style: TulaiTextStyles.heading1.copyWith(
                            color: TulaiColors.primary,
                            fontSize: isLargeScreen ? 32 : 28,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: TulaiSpacing.sm),
                        Text(
                          'Sign in to access the ALS Enrollment System',
                          style: TulaiTextStyles.bodyLarge.copyWith(
                            color: TulaiColors.textSecondary,
                            fontSize: isLargeScreen ? 16 : 15,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(
                            height: isLargeScreen
                                ? TulaiSpacing.xl
                                : TulaiSpacing.lg),

                        // Email Field
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: TulaiTextStyles.bodyLarge,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            hintText: 'Enter your email',
                            prefixIcon: const Icon(
                              Icons.email_outlined,
                              color: TulaiColors.primary,
                            ),
                            filled: true,
                            fillColor: TulaiColors.backgroundSecondary,
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(TulaiBorderRadius.md),
                              borderSide: const BorderSide(
                                  color: TulaiColors.borderLight),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(TulaiBorderRadius.md),
                              borderSide: const BorderSide(
                                  color: TulaiColors.borderLight),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(TulaiBorderRadius.md),
                              borderSide: const BorderSide(
                                  color: TulaiColors.primary, width: 2),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(TulaiBorderRadius.md),
                              borderSide:
                                  const BorderSide(color: TulaiColors.error),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(TulaiBorderRadius.md),
                              borderSide: const BorderSide(
                                  color: TulaiColors.error, width: 2),
                            ),
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
                        SizedBox(height: TulaiSpacing.lg),

                        // Password Field
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: TulaiTextStyles.bodyLarge,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            hintText: 'Enter your password',
                            prefixIcon: const Icon(
                              Icons.lock_outline,
                              color: TulaiColors.primary,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: TulaiColors.textSecondary,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            filled: true,
                            fillColor: TulaiColors.backgroundSecondary,
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(TulaiBorderRadius.md),
                              borderSide: const BorderSide(
                                  color: TulaiColors.borderLight),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(TulaiBorderRadius.md),
                              borderSide: const BorderSide(
                                  color: TulaiColors.borderLight),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(TulaiBorderRadius.md),
                              borderSide: const BorderSide(
                                  color: TulaiColors.primary, width: 2),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(TulaiBorderRadius.md),
                              borderSide:
                                  const BorderSide(color: TulaiColors.error),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(TulaiBorderRadius.md),
                              borderSide: const BorderSide(
                                  color: TulaiColors.error, width: 2),
                            ),
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
                        SizedBox(height: TulaiSpacing.lg),

                        // Error Message
                        if (_errorMessage != null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(TulaiSpacing.md),
                            margin:
                                const EdgeInsets.only(bottom: TulaiSpacing.lg),
                            decoration: BoxDecoration(
                              color: TulaiColors.error.withOpacity(0.1),
                              borderRadius:
                                  BorderRadius.circular(TulaiBorderRadius.md),
                              border: Border.all(
                                color: TulaiColors.error.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: TulaiColors.error,
                                  size: 20,
                                ),
                                const SizedBox(width: TulaiSpacing.sm),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: TulaiTextStyles.bodyMedium.copyWith(
                                      color: TulaiColors.error,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Login Button
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: TulaiColors.primary,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  TulaiColors.primary.withOpacity(0.5),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(TulaiBorderRadius.md),
                              ),
                            ),
                            child: _isLoading
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      ),
                                      const SizedBox(width: TulaiSpacing.md),
                                      Text(
                                        'Signing in...',
                                        style:
                                            TulaiTextStyles.bodyLarge.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.login,
                                          color: Colors.white),
                                      const SizedBox(width: TulaiSpacing.sm),
                                      Text(
                                        'Sign In',
                                        style:
                                            TulaiTextStyles.bodyLarge.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: TulaiSpacing.md),

                        // Forgot Password Link
                        TextButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Please contact the administrator to reset your password.',
                                  style: TulaiTextStyles.bodyMedium.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                                backgroundColor: TulaiColors.primary,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      TulaiBorderRadius.sm),
                                ),
                              ),
                            );
                          },
                          child: Text(
                            'Forgot Password?',
                            style: TulaiTextStyles.bodyMedium.copyWith(
                              color: TulaiColors.primary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),

                        const SizedBox(height: TulaiSpacing.md),

                        // Admin Login Link
                        Container(
                          padding: const EdgeInsets.all(TulaiSpacing.sm),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: TulaiColors.borderLight,
                            ),
                            borderRadius:
                                BorderRadius.circular(TulaiBorderRadius.sm),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.admin_panel_settings,
                                size: 16,
                                color: TulaiColors.textSecondary,
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pushReplacementNamed(
                                      context, '/admin-login');
                                },
                                child: Text(
                                  'Admin Login',
                                  style: TulaiTextStyles.bodySmall.copyWith(
                                    color: TulaiColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
